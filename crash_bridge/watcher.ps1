# ============================================================================
# watcher.ps1 —— 崩溃桥 agent 侧（PS 5.1，1s 轮询）2026-09-26
# 职责：① 读 mod 的 challenge.txt → 用共享协议算 HMAC-SHA256 应答（tmp+rename）
#       ② 收 out_*.txt 崩溃报告 → 挪进 crash_inbox\ 等 agent 处理
#       ③ watcher.log 心跳/诊断（key_fp 与 mod client_log 里的 key_fp 应一致）
# 协议（与 scripts/musha_crash_bridge.lua 严格一致，改一处必须两处同步）：
#   key_hex = SHA256_HEX("musha-crash-bridge/v1|" + sid)   -- sid 取自 challenge
#   h       = HMAC_SHA256(ASCII(key_hex), nonce)
# ============================================================================
$ErrorActionPreference = 'Stop'
$prefix = 'musha-crash-bridge/v1'
$bridge = Split-Path -Parent $MyInvocation.MyCommand.Path
$log    = Join-Path $bridge 'watcher.log'
$inbox  = Join-Path $bridge 'crash_inbox'
if (-not (Test-Path $inbox)) { New-Item -ItemType Directory -Path $inbox | Out-Null }

function Log([string]$msg) {
    if ((Test-Path $log) -and ((Get-Item $log).Length -gt 1MB)) {
        Move-Item -LiteralPath $log -Destination ($log + '.old') -Force
    }
    $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
    Add-Content -LiteralPath $log -Value $line -Encoding UTF8
}

function Get-Hex([byte[]]$bytes) {
    ($bytes | ForEach-Object { $_.ToString('x2') }) -join ''
}

$lastChal = ''
Log "watcher start bridge=$bridge"

while ($true) {
    try {
        # ---- ① 挑战应答 ----
        $chalPath = Join-Path $bridge 'challenge.txt'
        if ([IO.File]::Exists($chalPath)) {
            $raw = [IO.File]::ReadAllText($chalPath)
            if ($raw -ne $lastChal) {
                $sid = $null; $n = $null
                if ($raw -match '(?m)^sid=(\d+)$') { $sid = $Matches[1] }
                if ($raw -match '(?m)^n=([0-9a-f]+)\s*$') { $n = $Matches[1] }
                if ($sid -and $n) {
                    $sha = [Security.Cryptography.SHA256]::Create()
                    try {
                        $keyHex = Get-Hex ($sha.ComputeHash(
                            [Text.Encoding]::ASCII.GetBytes("$prefix|$sid")))
                    } finally { $sha.Dispose() }
                    $hmac = New-Object System.Security.Cryptography.HMACSHA256 -ArgumentList (,[Text.Encoding]::ASCII.GetBytes($keyHex))
                    try {
                        $h = Get-Hex ($hmac.ComputeHash(
                            [Text.Encoding]::ASCII.GetBytes($n)))
                    } finally { $hmac.Dispose() }
                    $tmp = Join-Path $bridge 'agent_response.txt.tmp'
                    [IO.File]::WriteAllText($tmp, "v=1`nn=$n`nh=$h`n")
                    Move-Item -LiteralPath $tmp `
                              -Destination (Join-Path $bridge 'agent_response.txt') -Force
                    $lastChal = $raw
                    Log ("responded n={0}.. sid={1} key_fp={2}" -f `
                        $n.Substring(0, [Math]::Min(8, $n.Length)), $sid, $keyHex.Substring(0, 16))
                } else {
                    Log "challenge parse fail (partial write?)"
                }
            }
        }

        # ---- ② 崩溃报告收入 inbox ----
        Get-ChildItem -LiteralPath $bridge -Filter 'out_*.txt' -File -ErrorAction SilentlyContinue |
            ForEach-Object {
                $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
                $dest = Join-Path $inbox ($stamp + '_' + $_.Name)
                try {
                    Move-Item -LiteralPath $_.FullName -Destination $dest -Force
                    Log "crash captured -> $dest"
                } catch {
                    Log "outbox move fail: $($_.Exception.Message)"
                }
            }
    } catch {
        Log "ERR $($_.Exception.Message)"
    }
    Start-Sleep -Milliseconds 1000
}
