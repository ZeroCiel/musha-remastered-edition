#!/usr/bin/env python3
"""
全量编译彩虹岛服务端所有依赖库 (VS2013 v120 /MT)
从 .vcxproj 解析源文件列表，逐个编译为 .obj，打包为 .lib

用法: python build_all_libs.py
输出: D:\LaTaleServer-\bin\*.lib (覆盖)
日志: D:\LaTaleServer-\build_all_v120.log
"""

import subprocess, os, sys, glob, time, xml.etree.ElementTree as ET, shutil

BASE = r'D:\LaTaleServer-'
LOG_FILE = os.path.join(BASE, 'build_all_v120.log')

VS2013_BIN = r'D:\VS2013\VC\bin'
VS2013_INC = (
    r'D:\VS2013\VC\include;'
    r'D:\VS2013\VC\atlmfc\include;'
    r'C:\Program Files (x86)\Windows Kits\8.0\Include\shared;'
    r'C:\Program Files (x86)\Windows Kits\8.0\Include\um;'
    r'C:\Program Files (x86)\Windows Kits\8.0\Include\WinRT;'
    r'C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Include'
)
VS2013_LIB = (
    r'D:\VS2013\VC\lib;'
    r'D:\VS2013\VC\atlmfc\lib;'
    r'C:\Program Files (x86)\Windows Kits\8.0\Lib\Win8\um\x86;'
    r'C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Lib'
)

env = os.environ.copy()
env['PATH'] = VS2013_BIN + ';' + env.get('PATH', '')
env['INCLUDE'] = VS2013_INC
env['LIB'] = VS2013_LIB

NS = {'ms': 'http://schemas.microsoft.com/developer/msbuild/2003'}

def log(msg):
    ts = time.strftime('%H:%M:%S')
    line = f'[{ts}] {msg}'
    print(line)
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(line + '\n')

def parse_vcxproj(vcxproj_path):
    """Parse .vcxproj and return (source_files, include_dirs, defines)"""
    tree = ET.parse(vcxproj_path)
    root = tree.getroot()

    # Source files
    srcs = []
    for inc in root.findall('.//ms:ClCompile', NS):
        f = inc.get('Include', '')
        if f:
            # Filter out stdafx.cpp (PCH, not needed)
            if 'stdafx' not in f.lower():
                srcs.append(f)

    # Include dirs and defines from the first ClCompile definition
    includes = []
    defines = []
    for defn in root.findall('.//ms:ClCompile', NS):
        for child in defn:
            tag = child.tag.split('}')[1] if '}' in child.tag else child.tag
            text = child.text or ''
            if tag == 'AdditionalIncludeDirectories':
                parts = text.split(';')
                includes = [x.strip() for x in parts 
                           if x.strip() and not x.strip().startswith('%(')]
            elif tag == 'PreprocessorDefinitions':
                parts = text.split(';')
                defines = [x.strip() for x in parts 
                          if x.strip() and not x.strip().startswith('%(')]

    return srcs, includes, defines

def build_lib(name, vcxproj_name, cwd):
    """Build a static library from its vcxproj"""
    vcxproj = os.path.join(cwd, vcxproj_name)
    if not os.path.exists(vcxproj):
        log(f'  SKIP: {vcxproj} not found')
        return False

    log(f'=== Building {name} ===')
    srcs, extra_includes, extra_defines = parse_vcxproj(vcxproj)
    log(f'  Source files: {len(srcs)}')

    # Base CL flags
    cl_flags = ['/nologo', '/c', '/MT', '/O2', '/W1']

    # Include dirs
    inc_dirs = ['.', os.path.join(BASE, 'include'), os.path.join(BASE, 'src')]
    for d in extra_includes:
        if d.startswith('..') or d.startswith('.\\'):
            d2 = os.path.normpath(os.path.join(cwd, d))
            inc_dirs.append(d2)
        elif d not in ('.', ';'):
            inc_dirs.append(d)
    for d in inc_dirs:
        cl_flags.append(f'/I{d}')

    # Defines
    for d in extra_defines:
        if d and not d.startswith('%('):
            cl_flags.append(f'/D{d}')

    # Output dir
    out_dir = os.path.join(cwd, 'Release_v120')
    os.makedirs(out_dir, exist_ok=True)
    cl_flags.append(f'/Fo{out_dir}\\')

    ok = fail = 0
    obj_files = []

    for src_rel in srcs:
        src_full = os.path.normpath(os.path.join(cwd, src_rel))
        if not os.path.exists(src_full):
            log(f'  SKIP (not found): {src_rel}')
            continue

        proc = subprocess.Popen(
            [r'D:\VS2013\VC\bin\cl.exe'] + cl_flags + [src_full],
            cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
        out_b, _ = proc.communicate(timeout=120)
        out_text = out_b.decode('utf-8', errors='replace')

        obj_name = os.path.basename(src_rel).replace('.cpp', '.obj')
        obj_path = os.path.join(out_dir, obj_name)

        if proc.returncode == 0:
            ok += 1
            if os.path.exists(obj_path):
                obj_files.append(obj_path)
        else:
            fail += 1
            errors = [l.strip() for l in out_text.split('\n') if 'error' in l.lower()]
            log(f'  FAIL: {src_rel}')
            for e in errors[:2]:
                log(f'    {e}')

    log(f'  Compiled: {ok} OK, {fail} FAILED')
    if fail > 0:
        return False
    if not obj_files:
        log(f'  No objs to link!')
        return False

    # Link .lib
    lib_path = os.path.join(BASE, 'bin', f'{name}.lib')
    link_cmd = [r'D:\VS2013\VC\bin\lib.exe', '/nologo', f'/out:{lib_path}'] + obj_files
    proc = subprocess.Popen(link_cmd, cwd=cwd,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
    out_b, _ = proc.communicate(timeout=60)
    if proc.returncode == 0:
        size = os.path.getsize(lib_path)
        log(f'  OK: {name}.lib ({size:,} bytes)')
        return True
    else:
        log(f'  LINK FAILED: {name}')
        log(out_b.decode('utf-8', errors='replace')[:500])
        return False


if __name__ == '__main__':
    libraries = [
        ('ServerCore', 'ServerCore.vcxproj', os.path.join(BASE, 'ServerCore')),
        ('ServerBase', 'ServerBase.vcxproj', os.path.join(BASE, 'ServerBase')),
        ('LataleMapLoader', 'LataleMapLoader.vcxproj', os.path.join(BASE, 'LataleMapLoader')),
        ('LataleBattleSystem', 'LataleBattleSystem.vcxproj', os.path.join(BASE, 'LataleBattleSystem')),
        ('LataleCheatSystem', 'LataleCheatSystem.vcxproj', os.path.join(BASE, 'LataleCheatSystem')),
        ('OSPAPI', 'OSPAPI.vcxproj', os.path.join(BASE, 'OSPAPI')),
        ('MonsterAPI', 'MonsterAPI.vcxproj', os.path.join(BASE, 'MonsterAPI')),
    ]

    open(LOG_FILE, 'w', encoding='utf-8').close()

    results = {}
    for name, vcxproj, cwd in libraries:
        ok = build_lib(name, vcxproj, cwd)
        results[name] = ok
        log('')

    log('=' * 60)
    log('BUILD SUMMARY:')
    failed = []
    for name, ok in results.items():
        log(f'  {name}: {"OK" if ok else "FAILED"}')
        if not ok:
            failed.append(name)
    log('=' * 60)

    if failed:
        log(f'FAILED libraries: {", ".join(failed)}')
        sys.exit(1)
    else:
        log('All libraries built successfully!')
