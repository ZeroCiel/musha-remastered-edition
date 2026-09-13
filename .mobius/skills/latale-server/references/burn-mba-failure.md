# VS2012/VS2013 Burn MBA CLR Hosting Failure on Win11

## Symptom

`vs_ultimate.exe` (VS2013) and VS2012 equivalent run but exit silently with code 0. No window appears. All `/quiet`, `/passive`, `/uninstall` modes fail identically.

## Root Cause

The WiX Burn bootstrapper's Managed Bootstrapper Application (MBA) — a .NET 4.5 assembly compiled for VS2013 — fails to load via CLR hosting on Win11 with .NET 4.8.1.

Error chain:
```
Burn Engine → CLRCreateInstance() ✅ S_OK (verified via PowerShell P/Invoke)
           → Extract MBA from payload (may succeed, temp .ba1 file seen)
           → Host CLR, create AppDomain
           → Load MBA assembly ❌ 0x80131902
           → Fusion log: 0 entries (CLR never reaches assembly binding stage)
           → Silent exit
```

Error code `0x80131902` is Burn's custom HRESULT `E_MBAFAILED`.

## Diagnostic Commands

Run with Burn logging:
```cmd
vs_ultimate.exe /log burn_log.txt
```

Key log excerpt from a failing run:
```
Loading managed bootstrapper application.
Error 0x80131902: Failed to create the managed bootstrapper application.
Error 0x80131902: Failed to create UX.
Error 0x80131902: Failed to load UX.
...
Variable: WixBundleInstalled = 1
Variable: CustomInstallPath = D:\VS2013
Error 0x80131902: Failed to run per-user mode.
Exit code: 0x80131902, restarting: No
```

## Bundle Info (VS2013 Ultimate Update 4 CHS)

- Bundle name: `Microsoft Visual Studio Ultimate 2013(含 Update 4)`
- Bundle version: `12.0.31101.0`
- Provider key: `{bcd80ff3-e475-4742-9bdc-aad70123dad4}`
- Burn cache: `%ProgramData%\Package Cache\{bcd80ff3-e475-4742-9bdc-aad70123dad4}`
- MBA .NET package: `netfxfullredist_43`
- Install path detected: `D:\VS2013`

## Verified Failed Fixes

| Fix Attempt | Result |
|-------------|--------|
| `.config` file with `useLegacyV2RuntimeActivationPolicy` | No effect |
| `regsvr32 mscoree.dll` (both 32/64) | Doesn't create CLR hosting COM entries |
| .NET 4.5.1 repair (`NDP451-KB2858728-x86-x64-AllOS-CHS.exe /q /repair`) | Blocked by 4.8.1 (in-place upgrade only) |
| Compatibility mode (Win7 RTM via registry AppCompatFlags) | No effect |
| Clear Burn cache (`state.rsm` delete/rename) | MBA still fails; bundle still detects install |
| Fusion assembly binding logging | 0 log entries produced |
| `regsvr32 mscoree.dll` | No effect on CLR hosting COM registration |

## Workaround

VS2013 toolchain works perfectly without the installer. If files exist at the install path:

```cmd
call D:\VS2013\VC\vcvarsall.bat x86
cl.exe   # 18.00.31101 (VS2013 Update 4)
link.exe # 12.00.31101.0
```

## Unverified Fixes (to try)

1. Windows in-place upgrade repair
2. .NET Framework Repair Tool (`NetFxRepairTool.exe` from Microsoft)
3. `sfc /scannow`
4. `dism /online /cleanup-image /restorehealth` (needs `MSYS_NO_PATHCONV=1` on git-bash)
5. Disable then re-enable .NET 3.5/4.8 via Windows Features
6. Clean reboot, then run from a different physical disk as Administrator

## General Cleanup Steps (may help)

```cmd
reg delete "HKLM\SOFTWARE\Microsoft\Visual Studio\Setup" /f
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Visual Studio\Setup" /f
rmdir /s /q "%ProgramData%\Package Cache\{bcd80ff3-e475-4742-9bdc-aad70123dad4}"
del /q "%TEMP%\dd_VisualStudioSetup_decompression_log.txt"
```
