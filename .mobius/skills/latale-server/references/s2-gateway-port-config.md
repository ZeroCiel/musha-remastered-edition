# S2网关端口配置与SQL连接诊断经验

## 现象

S2端启动后，网关/GS连不上SQL Server，表现为：
- 登录器可以打开但连不上服务器
- GS进程启动后闪退
- 没有任何数据库错误日志

## 根因

**`Latale_ODBC.ini` 中写死了端口 1433**，但 SQL Server 实例实际监听的是其他端口（如 59157）。

S2端的 `Latale_ODBC.ini` 配置：
```ini
[AccountDB]
IP = 127.0.0.1,1433        ← 旧配置，端口不对
ID = sa
PW = 123456

[GameDB]
IP = 127.0.0.1,1433
ID = sa
PW = 123456
```

如果 SQL 实例是命名实例（如 `JSQL2008`）且绑定了自定义端口（如 59157），1433 就不可用。

## 诊断步骤

1. **确认 SQL 实际监听端口**：
   ```powershell
   netstat -ano | findstr LISTENING
   ```
   找 `sqlservr.exe` 对应的端口

2. **查配置文件中的端口**：
   打开 `bin2/Latale_ODBC.ini` 检查 `IP =` 行的端口号

3. **不匹配则改**：
   把 `1433` 改成实际端口号（如 `59157`），改完重启 GS。

## 特别注意

- 命名实例（如 `MSSQL$JSQL2008`）默认使用动态端口
- 如果改过 SQL 配置管理器中 TCP/IP 端口的固定值，实际端口就是那个值
- 不需要动实例名——S2 通过 `IP,Port` 直接连接，不依赖实例名解析
- 如果 SQL Browser 服务没开（私服环境默认不开），必须手动指定端口
