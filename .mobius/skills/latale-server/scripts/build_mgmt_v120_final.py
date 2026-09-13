#!/usr/bin/env python3
"""
One-shot build script for LataleMgmtServer.exe (VS2013 /MT / stubs).
Rebuilds all 7 dependency libs + LataleGameLogic stub + MgmtServer EXE.

Usage:
    python build_mgmt_v120_final.py

Requires:
    VS2013 at D:\VS2013\VC\bin\
    Windows Kits 8.0 at C:\Program Files (x86)\Windows Kits\8.0\
    LaTale server source at D:\LaTaleServer-\
"""

import subprocess, os, glob, shutil, sys, time, xml.etree.ElementTree as ET

BASE = r'D:\LaTaleServer-'
BIN = os.path.join(BASE, 'bin')
LOG = os.path.join(BASE, 'build_mgmt_v120_final.log')

VS_BIN = r'D:\VS2013\VC\bin'
VS_INC = (
    r'D:\VS2013\VC\include;'
    r'D:\VS2013\VC\atlmfc\include;'
    r'C:\Program Files (x86)\Windows Kits\8.0\Include\shared;'
    r'C:\Program Files (x86)\Windows Kits\8.0\Include\um;'
    r'C:\Program Files (x86)\Windows Kits\8.0\Include\WinRT;'
    r'C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Include'
)
VS_LIB = (
    r'D:\VS2013\VC\lib;'
    r'D:\VS2013\VC\atlmfc\lib;'
    r'C:\Program Files (x86)\Windows Kits\8.0\Lib\Win8\um\x86;'
    r'C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Lib'
)

CL = os.path.join(VS_BIN, 'cl.exe')
LIB_EXE = os.path.join(VS_BIN, 'lib.exe')
LINK = os.path.join(VS_BIN, 'link.exe')

env = os.environ.copy()
env['PATH'] = VS_BIN + ';' + env.get('PATH', '')
env['INCLUDE'] = VS_INC
env['LIB'] = VS_LIB

NS = {'ms': 'http://schemas.microsoft.com/developer/msbuild/2003'}
CL_BASE = [
    '/nologo', '/c', '/MT', '/O2', '/W1',
    '/DWIN32', '/DNDEBUG', '/D_LIB', '/D_LATALE_SERVER',
    '/D_WIN32_WINNT=0x0602', '/D_SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS',
    '/D_CRT_SECURE_NO_WARNINGS'
]

def log(msg):
    ts = time.strftime('%H:%M:%S')
    line = f'[{ts}] {msg}'
    print(line)
    with open(LOG, 'a', encoding='utf-8') as f:
        f.write(line + '\n')

def clean_defines(defines):
    return [d for d in defines if d and not d.startswith('%(')]

def parse_vcxproj(path):
    tree = ET.parse(path)
    root = tree.getroot()
    srcs = [inc.get('Include', '') for inc in root.findall('.//ms:ClCompile', NS) if inc.get('Include', '')]
    defines = []
    includes = []
    for defn in root.findall('.//ms:ClCompile', NS):
        for child in defn:
            tag = child.tag.split('}')[1] if '}' in child.tag else child.tag
            if tag == 'PreprocessorDefinitions':
                defines = clean_defines((child.text or '').split(';'))
            elif tag == 'AdditionalIncludeDirectories':
                parts = (child.text or '').split(';')
                includes = [x.strip() for x in parts if x.strip() and not x.strip().startswith('%(')]
    return srcs, defines, includes

def compile_srcs(name, src_list, cwd, obj_dir, extra_defs=None, extra_incs=None, exclude=None):
    os.makedirs(obj_dir, exist_ok=True)
    cl_flags = list(CL_BASE) + [f'/Fo{obj_dir}\\']
    
    inc_dirs = ['.', os.path.join(BASE, 'include'), os.path.join(BASE, 'src')]
    if extra_incs:
        for d in extra_incs:
            if d.startswith('..'):
                inc_dirs.append(os.path.normpath(os.path.join(cwd, d)))
            elif d not in ('.', ';'):
                inc_dirs.append(d)
    for d in inc_dirs:
        cl_flags.append(f'/I{d}')
    
    defs = list(CL_BASE)
    if extra_defs:
        defs += extra_defs
    for d in defs:
        cl_flags.append(f'/D{d}' if not d.startswith('/') else d)
    
    ok, fail = 0, 0
    obj_files = []
    for src_rel in src_list:
        src_full = os.path.normpath(os.path.join(cwd, src_rel))
        if not os.path.exists(src_full):
            log(f'  SKIP (missing): {src_rel}')
            continue
        name_base = os.path.basename(src_rel)
        if exclude and name_base in exclude:
            continue
        
        proc = subprocess.Popen([CL] + cl_flags + [src_full], cwd=cwd,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
        out, _ = proc.communicate(timeout=120)
        if proc.returncode == 0:
            ok += 1
            obj_name = name_base.replace('.cpp', '.obj')
            obj_path = os.path.join(obj_dir, obj_name)
            if os.path.exists(obj_path):
                obj_files.append(obj_path)
        else:
            fail += 1
            errors = [l.strip() for l in out.decode('utf-8', errors='replace').split('\n') if 'error' in l.lower()]
            log(f'  FAIL: {src_rel}')
            for e in errors[:2]:
                log(f'    {e}')
    
    log(f'  {name}: {ok} OK, {fail} FAIL')
    return obj_files, ok, fail

def link_lib(name, obj_list, out_dir):
    if not obj_list:
        log(f'  {name}: no objs to link')
        return False
    lib_path = os.path.join(out_dir, f'{name}.lib')
    proc = subprocess.Popen([LIB_EXE, '/nologo', f'/out:{lib_path}'] + obj_list,
        cwd=os.path.dirname(obj_list[0]), stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
    out, _ = proc.communicate(timeout=60)
    if proc.returncode == 0:
        log(f'  {name}.lib: {os.path.getsize(lib_path):,} bytes')
        return True
    log(f'  {name}.lib LINK FAILED: {out.decode("utf-8", errors="replace")[:300]}')
    return False

open(LOG, 'w').close()

# --- Phase 1: Dependency Libs ---
libs = [
    ('ServerCore', 'ServerCore/ServerCore.vcxproj', os.path.join(BASE, 'ServerCore'), None, None, ['stdafx.cpp']),
    ('ServerBase', 'ServerBase/ServerBase.vcxproj', os.path.join(BASE, 'ServerBase'), None, None, ['stdafx.cpp']),
    ('LataleMapLoader', 'LataleMapLoader/LataleMapLoader.vcxproj', os.path.join(BASE, 'LataleMapLoader'), None, None, ['stdafx.cpp', 'LDPLoader.cpp']),
    ('LataleBattleSystem', 'LataleBattleSystem/LataleBattleSystem.vcxproj', os.path.join(BASE, 'LataleBattleSystem'), None, None, ['stdafx.cpp']),
    ('LataleCheatSystem', 'LataleCheatSystem/LataleCheatSystem.vcxproj', os.path.join(BASE, 'LataleCheatSystem'), None, None, ['stdafx.cpp']),
    ('OSPAPI', 'OSPAPI/OSPAPI.vcxproj', os.path.join(BASE, 'OSPAPI'), None, None, ['stdafx.cpp']),
    ('MonsterAPI', 'MonsterAPI/MonsterAPI.vcxproj', os.path.join(BASE, 'MonsterAPI'), None, None, ['stdafx.cpp']),
]

for name, vcxproj_path, cwd, extra_defs, extra_incs, exclusions in libs:
    log(f'Building {name}...')
    srcs, defs, incs = parse_vcxproj(os.path.join(cwd, vcxproj_path.split('/')[-1]))
    obj_dir = os.path.join(cwd, 'Release_v120')
    if os.path.exists(obj_dir):
        shutil.rmtree(obj_dir)
    obj_list, _, fails = compile_srcs(name, srcs, cwd, obj_dir, defs, incs, exclusions)
    if fails == 0 and obj_list:
        link_lib(name, obj_list, BIN)
    log('')

# --- Phase 2: LataleGameLogic stub ---
log('Building LataleGameLogic stub...')
lgl_dir = os.path.join(BASE, 'LataleGameLogic')
lgl_obj = os.path.join(lgl_dir, 'Release_v120')
os.makedirs(lgl_obj, exist_ok=True)

proc = subprocess.Popen([
    CL, '/nologo', '/c', '/MT', '/O2',
    '/I.', '/I' + os.path.join(BASE, 'include'), '/I' + os.path.join(BASE, 'src'),
    '/I' + os.path.join(BASE, 'LataleGameServer'),
    '/DWIN32', '/DNDEBUG', '/D_LIB', '/D_LATALE_SERVER', '/D_WIN32_WINNT=0x0602',
    '/D_HAS_AUTO_PTR_ETC=1', '/D_SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS',
    '/D_CRT_SECURE_NO_WARNINGS', '/FIstdafx.h',
    f'/Fo{lgl_obj}\\',
    os.path.join(lgl_dir, 'LataleGameLogicStub.cpp')
], cwd=lgl_dir, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
out, _ = proc.communicate(timeout=120)
if proc.returncode == 0:
    stub_obj = os.path.join(lgl_obj, 'LataleGameLogicStub.obj')
    subprocess.Popen([LIB_EXE, '/nologo', f'/out:{os.path.join(BIN, "LataleGameLogic.lib")}', stub_obj],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env).communicate(timeout=30)
    log(f'  LataleGameLogic.lib: {os.path.getsize(os.path.join(BIN, "LataleGameLogic.lib")):,} bytes')
else:
    log(f'  FAILED: {out.decode("utf-8", errors="replace")[:500]}')
log('')

# --- Phase 3: MgmtServer compile ---
log('Building MgmtServer...')
mgmt_dir = os.path.join(BASE, 'LataleMgmtServer')
mgmt_obj = os.path.join(mgmt_dir, 'Release_v120')
if os.path.exists(mgmt_obj):
    shutil.rmtree(mgmt_obj)

# Collect source files from vcxproj
mgmt_srcs, _, _ = parse_vcxproj(os.path.join(mgmt_dir, 'LataleMgmtServer.vcxproj'))
mgmt_objs = []
# Add Common dir sources manually
mgmt_srcs += [
    os.path.join('..', 'Common', 'ServerLog.cpp'),
    os.path.join('..', 'Common', 'ServerStatistics.cpp'),
    os.path.join('..', 'Common', 'OnlineUserInfo.cpp'),
    os.path.join('..', 'Common', 'MakeDSNString.cpp'),
]

mgmt_cl = [
    '/nologo', '/c', '/MT', '/O2', '/W1',
    '/I' + mgmt_dir, '/I' + os.path.join(BASE, 'include'), '/I' + os.path.join(BASE, 'src'),
    '/I' + os.path.join(BASE, 'Common'), '/I' + os.path.join(BASE, 'LataleGameLogic'),
    '/DWIN32', '/DNDEBUG', '/D_CONSOLE', '/D_LATALE_SERVER', '/D_LATALE_MS',
    '/D_SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS',
    '/D_CRT_SECURE_NO_WARNINGS', '/D_ALLOW_RTCc_IN_STL', '/D_HAS_EXCEPTIONS=0',
    '/FIstdafx.h', f'/Fo{mgmt_obj}\\'
]
exclude = {'stdafx.cpp', 'ServerStatInfoThread.cpp'}

for src_rel in mgmt_srcs:
    src_full = os.path.normpath(os.path.join(mgmt_dir, src_rel))
    if not os.path.exists(src_full):
        continue
    base = os.path.basename(src_rel)
    if base in exclude:
        continue
    proc = subprocess.Popen([CL] + mgmt_cl + [src_full], cwd=mgmt_dir,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
    out, _ = proc.communicate(timeout=120)
    if proc.returncode != 0:
        log(f'  COMPILE FAIL: {base}')
        log(out.decode('utf-8', errors='replace')[:500])

all_mgmt_objs = sorted(glob.glob(os.path.join(mgmt_obj, '*.obj')))
log(f'  MgmtServer: {len(all_mgmt_objs)} objs')

# --- Phase 4: MgmtServer link ---
log('Linking MgmtServer...')
link_args = [
    LINK, '/nologo',
    '/OUT:' + os.path.join(BIN, 'LataleMgmtServer.exe'),
    '/SUBSYSTEM:CONSOLE',
    '/LIBPATH:' + BIN, '/LIBPATH:' + os.path.join(BASE, 'Lib')
] + all_mgmt_objs + [
    'ServerCore.lib', 'ServerBase.lib', 'LataleMapLoader.lib',
    'LataleGameLogic.lib', 'LataleBattleSystem.lib', 'LataleCheatSystem.lib',
    'OSPAPI.lib', 'MonsterAPI.lib', 'ws2_32.lib'
]

proc = subprocess.Popen(link_args, cwd=mgmt_dir,
    stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
out, _ = proc.communicate(timeout=60)
out_text = out.decode('utf-8', errors='replace')

if proc.returncode == 0:
    exe_path = os.path.join(BIN, 'LataleMgmtServer.exe')
    log(f'*** SUCCESS! {os.path.getsize(exe_path):,} bytes ***')
else:
    log(f'LINK FAILED (RC={proc.returncode})')
    for line in out_text.split('\n'):
        if 'LNK2001' in line or 'LNK2019' in line:
            log(f'  {line.strip()[:120]}')
    # Stub resolution hint
    unresolved = [l for l in out_text.split('\n') if 'LNK2001' in l or 'LNK2019' in l]
    if unresolved:
        log(f'\nTip: Add stub definitions in MgmtStubs.cpp for unresolved symbols:')
        for u in unresolved[:5]:
            mangled = u.split()[-1] if u.split() else ''
            if mangled:
                log(f'  {mangled}')
