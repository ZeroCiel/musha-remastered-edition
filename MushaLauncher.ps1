# ===================================================================
# MushaLauncher v0.3 —— 饥荒联机版 · 一键开世界 + 本地mod选择
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

# ---------------- 扫描本地 mod ----------------
function Get-LocalMods($gamePath) {
    $modsDir = Join-Path $gamePath 'mods'
    if (-not (Test-Path $modsDir)) { return @() }
    $results = @()
    foreach ($d in (Get-ChildItem $modsDir -Directory -ErrorAction SilentlyContinue)) {
        $modinfo = Join-Path $d.Name 'modinfo.lua'
        $name = $d.Name
        if (Test-Path (Join-Path $d 'modinfo.lua')) {
            $content = Get-Content (Join-Path $d 'modinfo.lua') -Raw -ErrorAction SilentlyContinue
            if ($content -match 'name\s*=\s*"([^"]+)"') { $name = $matches[1] }
        }
        $results += [PSCustomObject]@{ Dir = $d.Name; DisplayName = $name; Path = $d.FullName }
    }
    return $results
}

# ---------------- 窗口 ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = 'MushaLauncher · 饥荒一键开世界'
$form ClientSize = New-Object System.Drawing.Size(520, 640)
$form.StartPosition = 'CenterScreen'
$form.TopMost = $true
$form.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', 9)

function New-Label($text, $y) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text; $l.Location = New-Object System.Drawing.Point(12, $y + 4)
    $lAutoSize = $true; $form.Controls.Add($l)
}
function New-Box($y, $w, $val) {
    $b = New-Object System.Windows.Forms.TextBox
    $b.Text = $val; $b.Location = New-Object System.Drawing.Point(115, $y)
    $b.Width = $w; $form.Controls.Add($b); return $b
}

# --- 游戏目录 ---
New-Label '游戏目录' 15
$txtGame = New-Box 15 335 (CfgGet 'game' (Find-DST))
$btnBrowseGame = New-Object System.Windows.Forms.Button
$btnBrowseGame.Text = '…'; $btnBrowseGame.Location = New-Object System.Drawing.Point(463, 13)
$btnBrowseGame.Width = 30; $form.Controls.Add($btnBrowseGame)

# --- 模式 ---
New-Label '模式' 48
$cboMode = New-Object System.Windows.Forms.ComboBox
$cboMode.MouseDown = 'DropDownList'
[void]$cboMode.Items.AddRange(@('survival', 'wilderness'))
    $cboMode.Text = CfgGet 'mode' 'wilderness'
$cboMode.Location = New-Object System.Drawing.Point(115, 45); $cboMode.Width = 100
$form.Controls.Add($cboMode)

# --- 启动参数 ---
New-Label '启动参数' 81
$txtArgs = New-Box 81 335 (CfgGet 'args' '-console')

# --- 本地服务器 ---
New-Label '本地服务器' 114
$chkServer = New-Object System.Windows.Forms.CheckBox
$chkServer.Text = '开本地服(联机/测试)'; $chkServer.Location = New-Object System.Drawing.Point(115, 112)
$chkServerAutoSize = $true
$chkServer.Checked = ((CfgGet 'server_on' 'False') -eq 'True')
$form.Controls.Add($chkServer)

New-Label '服务器目录' 147
$txtServer = New-Box 147 335 (CfgGet 'server' '')
$btnBrowseServer = New-Object System.Windows.Forms.Button
$btnBrowseServer.Text = '…'; $btnBrowseServer.Location = New-Object System.Drawing.Point(463, 145)
$btnBrowseServer.Width = 30; $form.Controls.Add($btnBrowseServer)

New-Label '集群文件夹' 180
$txtCluster = New-Box 180 150 (CfgGet 'cluster' 'Cluster_1')

# --- 崩溃收集 ---
$chkCrash = New-Object System.Windows.Forms.CheckBox
$chkCrash.Text = '崩溃自动收集 → 本地mod (启动器保持开着才生效)'
$chkCrash.Location = New-Object System.Drawing.Point(15, 211)
$chkCrashAutoSize = $true
$chkCrash.Checked = ((CfgGet 'crash_on' 'False') -eq 'True')
$form.Controls.Add($chkCrash)

# --- 本地 mod 列表（自动扫描） ---
$lblMods = New-Object System.Windows.Forms.Label
$lblMods.Text = '本地 mod（自动扫描游戏目录\\mods）'; $lblMods.Location = New-Object System.Drawing.Point(12, 248)
$lblModsAutoSize = $true; $form.Controls.Add($lblMods)

$chkModList = New-Object System.Windows.Forms.Panel
$chkModList.Location = New-Object System.Drawing.Point(115, 248)
$chkModList.Width = 380
$chkModList.Height = 130
$chkModList.AutoScroll = $true
$chkModList BorderStyle = 'Fixed3D'
$form.Controls.Add($chkModList)

$script:modChecks = @{}
$script:allMods = @()

function Refresh-ModList {
    $chkModList.Controls.Clear()
    $script:modChecks = @()
    $script:allMods = @()
    $game = $txtGame.Text.Trim().Trim('"')
    $mods = Get-LocalMods $game
    $script:allMods = $mods
    $y = 5
    foreach ($m in $mods) {
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text = $m.DisplayName
        $cb.Location = New-Object System.Drawing.Point(5, $y)
        $cb.Width = 260
        $cbAutoSize = $true
        # 默认全选
        $cb.Checked = $true
        $chkModList.Controls.Add($cb)
        $script:modChecks[$m.Dir] = $cb
        $y += 20
    }
    if ($mods.Count -eq 0) {
        $hint = New-Object System.Windows.Forms.Label
        $hint.Text = '(未扫描到 mod，检查游戏目录是否正确)'
        $hint.Location = New-Object System.Drawing.Point(5, 5)
        $hintAutoSize = $true
        $chkModList.Controls.Add($hint)
    }
}

# 游戏目录改变时自动刷新 mod 列表
$txtGame.Add_lostFocus({ Refresh-ModList })

# --- 存档槽 ---
New-Label '存档槽' 395
$cboSlot = New-Object System.Windows.Forms.ComboBox
$cboSlot.DrawMode = 'OwnerDrawFixed'
[void]$cboSlot.Items.AddRange(@('1', '2', '3'))
$cboSlot.Text = CfgGet 'slot' '1'
$cboSlot.Location = New-Object System.Drawing.Point(115, 392); $cboSlot.Width = 60
$form.Controls.Add($cboSlot)

# --- 按钮 ---
$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = '刷新 mod'; $btnRefresh.Location = New-Object System.Drawing.Point(195, 392)
$btnRefresh.Width = 80; $form.Controls.Add($btnRefresh)
$btnRefresh.Add_Click({ Refresh-ModList })

$btnGo = New-Object System.Windows.Forms.Button
$btnGo.Text = '🚀 开世界'; $btnGo.Location = New-Object System.Drawing.Point(115, 430)
$btnGo.Width = 140; $btnGo.Height = 36; $form.Controls.Add($btnGo)

$btnCopy = New-Object System.Windows.Forms.Button
$btnCopy.Text = '复制开世界命令'; $btnCopy.Location = New-Object System.Drawing.Point(270, 430)
$btnCopy.Width = 160; $btnCopy.Height = 36; $form.Controls.Add($btnCopy)

$btnSaveMods = New-Object System.Windows.Forms.Button
$btnSaveMods.Text = '保存mod选择'; $btnSaveMods.Location = New-Object System.Drawing.Point(440, 430)
$btnSaveMods.Width = 60; $btnSaveMods.Height = 36; $form.Controls.Add($btnSaveMods)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Multiline = $true; $txtLog.ReadOnly = $true
$txtLog.Location = New-Object System.Drawing.Point(12, 480)
$txtLog.Size = New-Object System.Drawing.Size(496, 130)
$txtLog.ScrollBars = 'Vertical'
$form.Controls.Add($txtLog)

function Log($msg) {
    $txtLog.Text += "[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n"
}

# ---------------- 行为 ----------------
function Pick-Folder($box) {
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    if ((Test-Path $box.Text) -and $box.Text) { $dlg.SelectedPath = $box.Text }
    if ($dlg.ShowDialog() -eq 'OK') { $box.Text = $dlg.SelectedPath }
}
$btnBrowseGame.Add_Click({ Pick-Folder $txtGame; Refresh-ModList })
$btnBrowseServer.Add_Click({ Pick-Folder $txtServer })

# 获取选中的 mod 列表（逗号分隔，DST modloadfile 格式）
function Get-SelectedMods {
    $selected = @()
    foreach ($kv in $script:modChecks) {
        if ($kv.Value.Checked) { $selected += $kv.Key }
    }
    return ($selected -join ',')
}

$btnCopy.Add_Click({
    $cmd = 'c_start("{0}",{1})' -f $cboMode.Text, $cboSlot.Text
    [System.Windows.Forms.Clipboard]::SetText($cmd)
    Log '已复制开世界命令 → 游戏里按左上角反引号键开控制台, Ctrl+V 回车即进世界'
})

$btnSaveMods.Add_Click({
    $selected = Get-SelectedMods
    $cfg['modname'] = $selected
    SaveCfg
    Log "已保存 mod 选择: $selected"
})

$btnGo.Add_Click({
    $game = $txtGame.Text.Trim().Trim('"')
    if (-not (Test-Path (Join-Path $game 'bin64\dontstarve_steam.exe'))) {
        [System.Windows.Forms.MessageBox]::Show('游戏目录不对, 请点 … 选择 Don't Starve Together 文件夹', '提示')
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
    $cfg['slot'] = $cboSlot.Text; $cfg['args'] = $txtArgs.Text
    $cfg['server'] = $txtServer.Text; $cfg['cluster'] = $txtCluster.Text
    $cfg['server_on'] = "$($chkServer.Checked)"
    $cfg['crash_on'] = "$($chkCrash.Checked)"
    $cfg['modname'] = Get-SelectedMods
    SaveCfg
}
$form.Add_FormClosing({ Save-CfgNow })

# ---------------- 崩溃日志收集 ----------------
$script:crashSeen = $null
$chkCrash.Add InitializeComponent({ $script:crashSeen = $null })

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 3000
$timer.Add_Tick({
    if (-not $chkCrash.Checked) { $script:crashSeen = $null; return }
    $klei  = Get-KleiRoot
    $crash = Join-Path $klei 'save\crash'
    if (-not (Test-Path $crash)) { return }
    $dirs = @(Get-ChildItem $crash -Directory -ErrorAction SilentlyContinue)
    if ($null -eq $script:crashSeen) {
        $script:crashSeen = @{}
        foreach ($d in $dirs) { $script:crashSeen[$d.Name] = $true }
        return
    }
    foreach ($d in $dirs) {
        if ($script:crashSeen.ContainsKey($d.Name)) { continue }
        $script:crashSeen[$d.Name] = $true
        # 从选中的 mod 里逐个找
        $gamePath = $txtGame.Text.Trim().Trim('"')
        $kleiMods = Join-Path $klei 'mods'
        $gameMods = Join-Path $gamePath 'mods'
        $collected = $false
        foreach ($kv in $script:modChecks) {
            if (-not $kv.Value.Checked) { continue }
            $name = $kv.Key
            $modBase = $null
            if (Test-Path (Join-Path $kleiMods $name)) {
                $modBase = Join-Path $kleiMods $name
            } elseif (Test-Path (Join-Path $gameMods $name)) {
                $modBase = Join-Path $gameMods $name
            }
            if (-not $modBase) { continue }
            $dest = Join-Path $modBase 'crash_reports'
            if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
            $dst = Join-Path $dest $d.Name
            if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
            Copy-Item $d.FullName $dst -Recurse -Force
            Log "✔ 已收集崩溃 [$($d.Name)] → mods\$name\crash_reports"
            $collected = $true
        }
        if (-not $collected) {
            Log "⚠ 发现新崩溃 [$($d.Name)] 但选中的 mod 目录里都找不到, 未收集"
        }
    }
})
$timer.Start()

# ---------------- 启动时自动扫描 ----------------
Refresh-ModList

[void]$form.ShowDialog()