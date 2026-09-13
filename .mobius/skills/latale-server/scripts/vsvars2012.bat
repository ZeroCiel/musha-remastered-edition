@echo off
REM Wrapper for VS2012 vcvarsall at its canonical complete-install path.
REM Use this when vcvarsall.bat's registry keys might be missing after reinstall.
REM The complete-install path has working headers/SDK; D:\VS2012 hand-extract does not.
set VS12=C:\Program Files (x86)\Microsoft Visual Studio 11.0
if exist "%VS12%\VC\vcvarsall.bat" (
    call "%VS12%\VC\vcvarsall.bat" x86
    if errorlevel 1 (
        echo WARN: vcvarsall.bat failed - trying manual env setup
        goto manual_setup
    )
    goto :done
)

:manual_setup
REM Fallback when vcvarsall can't determine location (registry missing)
set KIT=C:\Program Files (x86)\Windows Kits\8.0
set PATH=%VS12%\VC\bin;%VS12%\Common7\IDE;%PATH%
set INCLUDE=%VS12%\VC\include;%KIT%\Include\shared;%KIT%\Include\um;%KIT%\Include\winrt
set LIB=%VS12%\VC\lib;%KIT%\Lib\win8\um\x86
set LIBPATH=%KIT%\References\CommonConfiguration\Neutral

:done
echo VS2012 v110 environment ready
