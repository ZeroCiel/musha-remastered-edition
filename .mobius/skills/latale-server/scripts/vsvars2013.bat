@echo off
REM VS2013 env wrapper — works without registry (e.g. after system reinstall)
REM Usage: vsvars2013.bat <cl/link args...>
REM   or: call vsvars2013.bat && cl ...
setlocal
set VSROOT=D:\VS2013
set KITROOT=C:\Program Files (x86)\Windows Kits\8.0

set PATH=%VSROOT%\VC\bin;%PATH%
set INCLUDE=%VSROOT%\VC\include;%KITROOT%\Include\shared;%KITROOT%\Include\um
set LIB=%VSROOT%\VC\lib;%KITROOT%\Lib\win8\um\x86

if "%1"=="" (
    echo VS2013 (v120) env ready — cl.exe, link.exe available
    echo INCLUDE=%INCLUDE%
    echo LIB=%LIB%
    goto :eof
)

%*
