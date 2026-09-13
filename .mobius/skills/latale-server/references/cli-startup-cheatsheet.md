# 樱花网关 + 服务端 CLI 启动速查卡

## 快速启动流程

```powershell
# 0. 确认 SQL Server 运行中
tasklist | findstr sqlservr

# 1. 启动网关（工作目录必须是 BIN2！）
Start-Process -FilePath 'D:\彩虹岛\彩虹岛物语服务端\Server\彩虹岛樱花网关.exe' `
  -WorkingDirectory 'D:\彩虹岛\彩虹岛物语服务端\Server\BIN2' -WindowStyle Minimized
Start-Sleep 12

# 2. 验证网关
netstat -ano | findstr "5217"
# 应看到 LISTENING

# 3. 启动核心服务（严格顺序）
$b = 'D:\彩虹岛\彩虹岛物语服务端\Server\BIN2'
Start-Process "$b\LataleMgmtServer.exe" -WorkingDirectory $b -WindowStyle Minimized
Start-Sleep 6
Start-Process "$b\LataleAS.exe" -WorkingDirectory $b -WindowStyle Minimized
Start-Sleep 6
Start-Process "$b\LataleLoginServer.exe" -WorkingDirectory $b -WindowStyle Minimized
Start-Sleep 4

# 4. 验证核心端口
netstat -ano | findstr "10001"  # Mgmt
netstat -ano | findstr "10020"  # AS
netstat -ano | findstr "19999"  # Login

# 5. 其余服务
Start-Process "$b\LataleLobbyServer.exe" -WorkingDirectory $b -WindowStyle Minimized
Start-Process "$b\LataleBayServer.exe" -WorkingDirectory $b -WindowStyle Minimized
Start-Process "$b\LataleRoomServer.exe" -WorkingDirectory $b -WindowStyle Minimized
```

## 常见失败速查

| 症状 | 命令 | 修复 |
|---|---|---|
| 网关端口不监听 | 检查工作目录 | 必须 BIN2，不是 Server\ |
| taskkill 报错 | git-bash 搞乱 /F | `cmd /c "taskkill /F /PID N"` |
| 客户端连不上 | 服务端重启了 | 杀掉旧客户端重开 |
| Division Failed + 暂停 | MgmtServer 正常日志 | 按键继续即可 |

## SPF 回滚

```bash
# 回滚到原始 S2 版本
cp /d/Server/SPF/ROWID.SPF.bak2 /d/Server/SPF/ROWID.SPF

# 或切换到合并版（101个文件替换）
cp /d/Server/SPF/ROWID_NEW.SPF /d/Server/SPF/ROWID.SPF
```
