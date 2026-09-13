#!/usr/bin/env python3
"""
Build LataleLoginServer.exe from source with VS2013 (/MT, v120).
Compiles .cpp files listed in the .vcproj, links against the rebuilt dependency libs.
Output: D:\LaTaleServer-\bin\LataleLoginServer.exe  (~254KB)
"""

import subprocess, os, glob, shutil, sys

BASE = r'D:\LaTaleServer-'
LS_DIR = os.path.join(BASE, 'LataleLoginServer')
BIN_DIR = os.path.join(BASE, 'bin')
OBJ_DIR = os.path.join(LS_DIR, 'Release_v120')

env = os.environ.copy()
env['PATH'] = r'D:\VS2013\VC\bin;' + env.get('PATH', '')
env['INCLUDE'] = (
    r'D:\VS2013\VC\include;'
    r'D:\VS2013\VC\atlmfc\include;'
    r'C:\Program Files (x86)\Windows Kits\8.0\Include\shared;'
    r'C:\Program Files (x86)\Windows Kits\8.0\Include\um;'
    r'C:\Program Files (x86)\Windows Kits\8.0\Include\WinRT;'
    r'C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Include'
)
env['LIB'] = (
    r'D:\VS2013\VC\lib;'
    r'D:\VS2013\VC\atlmfc\lib;'
    r'C:\Program Files (x86)\Windows Kits\8.0\Lib\Win8\um\x86;'
    r'C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Lib'
)

SRC_FILES = [
    'LataleLoginServer.cpp',
    'LataleLoginServerApp.cpp',
    'LataleLoginWorkerThreadWithMQ.cpp',
    'LataleWorkerThread_auth.cpp',
    'LataleWorkerThread_Auth_Ex.cpp',
    'LataleWorkerThread_MGMT.cpp',
    'LataleWorkerThread_World.cpp',
    'LataleCallbackTimer_Login.cpp',
    os.path.join('..', 'Common', 'MakeDSNString.cpp'),
    'ODBC4AccountDB.cpp',
    'ServerMainThread.cpp',
    'StringTable.cpp',
    os.path.join('..', 'Common', 'ServerLog.cpp'),
    'ConnectorLS2MS.cpp',
    os.path.join('..', 'Common', 'OnlineUserInfo.cpp'),
    os.path.join('..', 'Common', 'UserManager.cpp'),
    os.path.join('..', 'LataleMapLoader', 'LataleVersionDef.cpp'),
    'VersionCheckForResourceData.cpp',
    'LataleLoginServer_Char.cpp',
    'LoginServerStubs.cpp',
]

CFLAGS = ['/nologo', '/c', '/MT', '/O2', '/W1',
    '/I' + LS_DIR, '/I' + os.path.join(BASE, 'include'), '/I' + os.path.join(BASE, 'src'),
    '/I' + os.path.join(BASE, 'Common'),
    '/DWIN32', '/DNDEBUG', '/D_CONSOLE', '/D_LATALE_SERVER', '/D_OSP_LOGIN',
    '/D_SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS',
    '/D_CRT_SECURE_NO_WARNINGS', '/D_ALLOW_RTCc_IN_STL', '/D_HAS_EXCEPTIONS=0',
    '/FIstdafx.h', f'/Fo{OBJ_DIR}\\']

if os.path.exists(OBJ_DIR):
    shutil.rmtree(OBJ_DIR)
os.makedirs(OBJ_DIR)

print(f'Compiling {len(SRC_FILES)} source files...')
ok = fail = 0
for src_rel in SRC_FILES:
    src_full = os.path.normpath(os.path.join(LS_DIR, src_rel))
    name = os.path.basename(src_rel)
    if not os.path.exists(src_full):
        print(f'  SKIP: {src_rel}')
        continue
    proc = subprocess.Popen([r'D:\VS2013\VC\bin\cl.exe'] + CFLAGS + [src_full],
        cwd=LS_DIR, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
    out, _ = proc.communicate(timeout=120)
    if proc.returncode == 0: ok += 1
    else: fail += 1; print(f'  FAIL: {name}')
print(f'{ok} OK, {fail} FAILED')
if fail > 0: sys.exit(1)

objs = sorted(glob.glob(os.path.join(OBJ_DIR, '*.obj')))
for o in [os.path.join(BASE, 'LataleMgmtServer', 'Release_v120', 'MgmtStubs.obj'),
          os.path.join(BASE, 'LataleMgmtServer', 'Release_v120', 'MgmtSymbolStubs.obj')]:
    if os.path.exists(o): objs.append(o)

print(f'Linking {len(objs)} objs...')
link_args = [r'D:\VS2013\VC\bin\link.exe', '/nologo',
    f'/OUT:{os.path.join(BIN_DIR, "LataleLoginServer.exe")}', '/SUBSYSTEM:CONSOLE',
    f'/LIBPATH:{BIN_DIR}', f'/LIBPATH:{os.path.join(BASE, "Lib")}'
] + objs + ['ServerCore.lib', 'ServerBase.lib', 'OSPAPI.lib', 'MonsterAPI.lib', 'ws2_32.lib']

proc = subprocess.Popen(link_args, cwd=LS_DIR, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
out, _ = proc.communicate(timeout=60)
for line in out.decode('utf-8', errors='replace').split('\n'):
    if 'error' in line.lower() or 'fatal' in line.lower():
        print(f'  {line.strip()}')
if proc.returncode != 0: print('LINK FAILED'); sys.exit(1)
exe = os.path.join(BIN_DIR, 'LataleLoginServer.exe')
print(f'*** SUCCESS! {os.path.getsize(exe):,} bytes ***')
