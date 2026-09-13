---
name: fix-stale-pip-launcher-windows
description: Fix pip launcher errors when old venv paths linger in Windows PATH
category: devops
---

# Fix Stale Pip Launcher on Windows

## Trigger
A pip-installed CLI fails with:
```
Fatal error in launcher: Unable to create process using '"X:\old-path\.venv\Scripts\python.exe" ...'
```
This means PATH still contains `X:\old-path\.venv\Scripts` but that venv is gone.

## Diagnosis (PowerShell)

```powershell
# 1. Check which .exe PowerShell resolves to
Get-Command <tool> | Format-List *

# 2. Check all PATH entries containing the tool name
$env:Path -split ';' | Select-String <tool>

# 3. Find whether it is in User or Machine (System) vars
[Environment]::GetEnvironmentVariable("Path", "User") -split ';' | Select-String <tool>
[Environment]::GetEnvironmentVariable("Path", "Machine") -split ';' | Select-String <tool>
```

## Fix (PowerShell)

```powershell
# Remove stale entries from User PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$cleanPath = ($userPath -split ';' | Where-Object { $_ -ne 'X:\old-path\.venv\Scripts' }) -join ';'
[Environment]::SetEnvironmentVariable("Path", $cleanPath, "User")

# Add the correct venv Scripts to User PATH
[Environment]::SetEnvironmentVariable("Path", $cleanPath + ';C:\correct-path\.venv\Scripts', "User")
```

Must **restart PowerShell** after changes.

## Pitfalls
- PowerShell caches command lookup; must restart the terminal
- A git-tracked `./project-name` Python script with `#!/usr/bin/env python3` can shadow the pip launcher
- User PATH can have duplicate entries; clean all occurrences
- System PATH requires admin PowerShell to modify