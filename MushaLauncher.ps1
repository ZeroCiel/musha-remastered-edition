# ===================================================================
# MushaLauncher v0.2 —— 饥荒联机版 · 一键进世界 + 崩溃日志收集
# 保存时请用 UTF-8 with BOM 编码(否则中文会乱码)
# 运行方式: 右键本文件 →「使用 PowerShell 运行」
#   或命令行: powershell -ExecutionPolicy Bypass -File MushaLauncher.ps1
# ===================================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$appId   = '322330'
$cfgFile = Join-Path $PSScriptRoot 'launcher.config.json'

# ---------------- 配置读写 ----------------
$cfg = @{}
if (Test-Path $cfgFile) {
    try {
        (Get-Content $cfgFile -Raw -Encoding UTF8 | ConvertFrom-Json).PSObject.Properties |
            ForEach-Object { $cfg[$_.Name] = "$($_.Value)" }
    } catch { }
}
function CfgGet($key, $default) { if ($cfg.ContainsKey($key)) { $cfg[$key] } else { $default } }
function SaveCfg { $cfg | ConvertTo-Json | Set-Content $cfgFile -Encoding UTF8 }

function Get-KleiRoot {
    Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Klei\DoNotStarveTogether'
}

# ---------------- 自动找游戏目录 ----------------
function Find-DST {
    $steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamPath
    if (-not $steam) { return '' }
    $commonDirs = @((Join-Path $steam 'steamapps\common'))
    $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
    if (Test-Path $vdf) {
        (Select-String -Path $vdf -Pattern '"path"[\s]*"([^"]+)"' -AllMatches).Matches | ForEach-Object {
            $lib = $_.Groups[1].Value -replace '\\\\', '\'
            $commonDirs += (Join-Path $lib 'steamapps\common')
        }
    }
    foreach ($c in $commonDirs) {
        $p = Join-Path $c "Don't Starve Together"
        if (Test-Path (Join-Path $p 'bin64\dontstarve_steam.exe')) { return $p }
    }
    return ''
}

# ---------------- 窗口 ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = 'MushaLauncher · 饥荒一键开世界'
$form.ClientSize = New-Object System.Drawing.Size(450, 480)
$form.StartPosition = 'CenterScreen'
$form.TopMost = $true
$form.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', 9)

function New-Label($text, $y) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text; $l.Location = New-Object System.Drawing.Point(12, $y + 4)
    $l.AutoSize = $true; $form.Controls.Add($l)
}
function New-Box($y, $w, $val) {
    $b = New-Object System.Windows.Forms.TextBox
    $b.Text = $val; $b.Location = New-Object System.Drawing.Point(115, $y)
    $b.Width = $w; $form.Controls.Add($b); return $b
}

New-Label '游戏目录' 15
$txtGame = New-Box 15 275 (CfgGet 'game' (Find-DST))
$btnBrowseGame = New-Object System.Windows.Forms.Button
$btnBrowseGame.Text = '…'; $btnBrowseGame.Location = New-Object System.Drawing.Point(398, 13)
$btnBrowseGame.Width = 30; $form.Controls.Add($btnBrowseGame)

New-Label '模式' 48
$cboMode = New-Object System.Windows.Forms.ComboBox
$cboMode.DropDownStyle = 'DropDownList'
[void]$cboMode.Items.AddRange(@('survival', 'wilderness'))
$cboMode.Text = CfgGet 'mode' 'survival'
$cboMode.Location = New-Object System.Drawing.Point(115, 45); $cboMode.Width = 100
$form.Controls.Add($cboMode)

New-Label '启动参数' 81
$txtArgs = New-Box 81 313 (CfgGet 'args' '-console')

New-Label '本地服务器' 114
$chkServer = New-Object System.Windows.Forms.CheckBox
$chkServer.Text = '开本地服(联机/测试)'; $chkServer.Location = New-Object System.Drawing.Point(115, 112)
$chkServer.AutoSize = $true
$chkServer.Checked = ((CfgGet 'server_on' 'False') -eq 'True')
$form.Controls.Add($chkServer)

New-Label '服务器目录' 147
$txtServer = New-Box 147 275 (CfgGet 'server' '')
$btnBrowseServer = New-Object System.Windows.Forms.Button
$btnBrowseServer.Text = '…'; $btnBrowseServer.Location = New-Object System.Drawing.Point(398, 145)
$btnBrowseServer.Width = 30; $form.Controls.Add($btnBrowseServer)

New-Label '集群文件夹' 180
$txtCluster = New-Box 180 150 (CfgGet 'cluster' 'Cluster_1')

$chkCrash = New-Object System.Windows.Forms.CheckBox
$chkCrash.Text = '崩溃自动收集 → 本地mod (启动器保持开着才生效)'
$chkCrash.Location = New-Object System.Drawing.Point(15, 211)
$chkCrash.AutoSize = $true
$chkCrash.Checked = ((CfgGet 'crash_on' 'False') -eq 'True')
$form.Controls.Add($chkCrash)

New-Label '本地mod名' 244
$txtMod = New-Box 244 275 (CfgGet 'modname' '')

New-Label '存档槽' 277
$cboSlot = New-Object System.Windows.Forms.ComboBox
$cboSlot.DropDownStyle = 'DropDownList'
[void]$cboSlot.Items.AddRange(@('1', '2', '3'))
$cboSlot.Text = CfgGet 'slot' '1'
$cboSlot.Location = New-Object System.Drawing.Point(115, 274); $cboSlot.Width = 60
$form.Controls.Add($cboSlot)

$btnGo = New-Object System.Windows.Forms.Button
$btnGo.Text = '🚀 开世界'; $btnGo.Location = New-Object System.Drawing.Point(115, 310)
$btnGo.Width = 140; $btnGo.Height = 36; $form.Controls.Add($btnGo)

$btnCopy = New-Object System.Windows.Forms.Button
$btnCopy.Text = '复制开世界命令(c_start)'; $btnCopy.Location = New-Object System.Drawing.Point(270, 310)
$btnCopy.Width = 160; $btnCopy.Height = 36; $form.Controls.Add($btnCopy)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Multiline = $true; $txtLog.ReadOnly = $true
$txtLog.Location = New-Object System.Drawing.Point(12, 358)
$txtLog.Size = New-Object System.Drawing.Size(426, 110)
$txtLog.ScrollBars = 'Vertical'
$form.Controls.Add($txtLog)

function Log($msg) {
    $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n")
}

# ---------------- 行为 ----------------
function Pick-Folder($box) {
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    if ((Test-Path $box.Text) -and $box.Text) { $dlg.SelectedPath = $box.Text }
    if ($dlg.ShowDialog() -eq 'OK') { $box.Text = $dlg.SelectedPath }
}
$btnBrowseGame.Add_Click({ Pick-Folder $txtGame })
$btnBrowseServer.Add_Click({ Pick-Folder $txtServer })

$btnCopy.Add_Click({
    $cmd = ('c_start("{0}","default",{1})' -f $cboMode.Text, $cboSlot.Text)
    [System.Windows.Forms.Clipboard]::SetText($cmd)
    Log '已复制开世界命令 → 游戏里按左上角反引号键开控制台, Ctrl+V 回车即进世界'
})

$btnGo.Add_Click({
    $game = $txtGame.Text.Trim().Trim('"')
    if (-not (Test-Path (Join-Path $game 'bin64\dontstarve_steam.exe'))) {
        [System.Windows.Forms.MessageBox]::Show("游戏目录不对, 请点 … 选择 Don't Starve Together 文件夹", '提示')
        return
    }
    if ($chkServer.Checked) {
        $sdir = $txtServer.Text.Trim().Trim('"')
        $srv = Get-ChildItem $sdir -Recurse -Filter '*dedicated*.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($srv) {
            Start-Process $srv.FullName -ArgumentList ('-cluster {0} -shard Master' -f $txtCluster.Text)
            Log "本地服已启动: $($srv.Name)"
        } else {
            Log '⚠ 服务器目录里没找到 *dedicated*.exe, 跳过'
        }
    }
    $argline = $txtArgs.Text.Trim()
    $uri = "steam://run/$appId//"
    if ($argline) { $uri += ($argline -replace ' ', '%20') }
    Start-Process $uri
    Log '客户端已通过 Steam 拉起...'
    Save-CfgNow
})

function Save-CfgNow {
    $cfg['game'] = $txtGame.Text;  $cfg['mode'] = $cboMode.Text
    $cfg['slot'] = $cboSlot.Text;  $cfg['args'] = $txtArgs.Text
    $cfg['server'] = $txtServer.Text;  $cfg['cluster'] = $txtCluster.Text
    $cfg['server_on'] = "$($chkServer.Checked)"
    $cfg['crash_on'] = "$($chkCrash.Checked)"
    $cfg['modname'] = $txtMod.Text
    SaveCfg
}
$form.Add_FormClosing({ Save-CfgNow })

# ---------------- 崩溃日志收集 ----------------
# 崩溃日志位置: 文档\Klei\DoNotStarveTogether\save\crash\crashNNNN\
# 规则: 目标 mod 必须存在于本地 mods 目录(= 本地模式), 否则拒绝收集;
#       只在已存在的本地 mod 里创建 crash_reports 子文件夹, 绝不碰工坊目录。
$script:crashSeen = $null
$chkCrash.Add_CheckedChanged({ $script:crashSeen = $null })

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 3000
$timer.Add_Tick({
    if (-not $chkCrash.Checked) { $script:crashSeen = $null; return }
    $klei  = Get-KleiRoot
    $crash = Join-Path $klei 'save\crash'
    if (-not (Test-Path $crash)) { return }
    $dirs = @(Get-ChildItem $crash -Directory -ErrorAction SilentlyContinue)
    if ($null -eq $script:crashSeen) {
        # 首次建立基线: 启动前就存在的旧崩溃不算"新崩溃"
        $script:crashSeen = @{}
        foreach ($d in $dirs) { $script:crashSeen[$d.Name] = $true }
        return
    }
    foreach ($d in $dirs) {
        if ($script:crashSeen.ContainsKey($d.Name)) { continue }
        $script:crashSeen[$d.Name] = $true
        $name = $txtMod.Text.Trim()
        if (-not $name) {
            Log "发现新崩溃 [$($d.Name)], 但「本地mod名」为空, 未收集"
            continue
        }
        $modBase = Join-Path (Join-Path $klei 'mods') $name
        if (-not (Test-Path $modBase)) {
            # 文档目录没有 mods → 兜底认游戏目录下的 mods 为本地模式
            $gamePath = $txtGame.Text.Trim().Trim('"')
            $modBase = Join-Path (Join-Path $gamePath 'mods') $name
        }
        if (-not (Test-Path $modBase)) {
            Log "⚠ 本地 mods 目录里没有 '$name' (文档与游戏目录都找不到), 拒绝收集"
            continue
        }
        $dest = Join-Path $modBase 'crash_reports'
        if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
        $dst = Join-Path $dest $d.Name
        if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
        Copy-Item $d.FullName $dst -Recurse -Force
        Log "✔ 已收集崩溃 [$($d.Name)] → mods\$name\crash_reports"
    }
})
$timer.Start()

[void]$form.ShowDialog()
