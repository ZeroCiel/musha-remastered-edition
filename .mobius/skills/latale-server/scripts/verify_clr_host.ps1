# Verify CLRCreateInstance works (should return S_OK)
# Usage: powershell -ExecutionPolicy Bypass -File verify_clr_host.ps1

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class CLRHostTest {
    [DllImport("mscoree.dll")]
    public static extern int CLRCreateInstance(ref Guid clsid, ref Guid riid, out IntPtr ppInterface);
    
    public static int Test() {
        Guid CLSID_CLRMetaHost = new Guid("9280188D-0E8E-4867-B30C-7FA83884E8DE");
        Guid IID_ICLRMetaHost = new Guid("D332DB9E-B9B3-4125-8207-A14884F53216");
        IntPtr ptr;
        int hr = CLRCreateInstance(ref CLSID_CLRMetaHost, ref IID_ICLRMetaHost, out ptr);
        return hr;
    }
}
"@

$hr = [CLRHostTest]::Test()
if ($hr -eq 0) {
    Write-Host "CLRCreateInstance: S_OK (0x00000000) — CLR hosting API works"
    exit 0
} else {
    Write-Host "CLRCreateInstance: FAILED 0x$($hr.ToString('X8'))"
    exit 1
}
