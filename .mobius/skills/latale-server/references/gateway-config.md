# 樱花网关配置详情与故障排查

## 网关架构

樱花网关 (`彩虹岛樱花网关.exe`) 是一个 GUI 管理工具，充当游戏客户端与后端服务之间的中间层：

```
客户端 (LataleClient)
    │
    ├── OSP 登录 (端口 5217) ──→ 樱花网关 ──→ LataleLoginServer (19999)
    ├── OSP 商城 (端口 5317) ──→ 樱花网关 ──→ 数据库 (59157)
    └── 游戏连接              ──→ 樱花网关 ──→ LataleGameServer (20001-20005)
                                                  LataleLobbyServer (10002)
                                                  LataleBayServer (10006)
                                                  LataleRoomServer (10007)
```

## 网关 GUI 界面

- **SQL配置** 标签：设置数据库连接参数，连接测试，保存
- **控制台** 标签：一键启动（弹窗 9 个服务窗口）、一键关闭
- **扩展应用** 标签：通用功能（在线注册、无限红利、无限金币等）

## IP 一致性校验详解

### 校验逻辑

网关启动时执行以下校验：

1. 读取 `Latale_ODBC.ini` / `Global_ODBC.ini` 中的数据库 IP（如 `127.0.0.1,59157`）
2. 读取 `configure.ini` 和 `configure_share.ini` 中所有服务器的 `PublicIP`
3. 逐项比对：如果任一 PublicIP ≠ 数据库 IP，整个启动流程中止

### 为什么会有外网 IP

私服版本通常从卖家处获得，配置文件保留了卖家原始服务器的外网 IP。常见残留位置：

- `configure_share.ini` → `[LataleLobbyServer] PublicIP` — 常为卖家公网 IP（如 `183.136.213.131`）
- `configure.ini` → `[LataleGameServer_181] PublicIP` — 常为另一个外网 IP（如 `121.204.252.173`）

### 批量检查脚本

```python
import os, re

bin2 = r"D:\彩虹岛\彩虹岛物语服务端\Server\BIN2"
db_ip = "127.0.0.1"  # 目标数据库 IP
non_local_pattern = re.compile(
    r'^(?!(127\.|192\.168\.|10\.|172\.(1[6-9]|2\d|3[01])\.))'
)

for fname in ['configure.ini', 'configure_share.ini']:
    fpath = os.path.join(bin2, fname)
    with open(fpath, 'r', encoding='gb18030', errors='ignore') as f:
        for i, line in enumerate(f, 1):
            m = re.search(r'PublicIP\s*=\s*(\S+)', line)
            if m:
                ip = m.group(1).strip()
                if ip and ip != db_ip:
                    print(f"⚠️ {fname} L{i}: PublicIP = {ip} (应为 {db_ip})")
```

## 网关日志分析

日志位置：`BIN2\网关日志_\YYYY_M_D.log`，GBK 编码。

### 初始化成功日志示例

```
16:03:07  【樱花初始化】2.数据库连接成功。
16:03:08  【樱花初始化】4.读取网关配置完成。
16:03:09  【樱花初始化】5.读取服务端配置 读取完成。
16:03:14  秒表线程i 创建成功。
16:03:52  【游戏返回】登陆服务器 反馈成功。
16:03:52  【商城返回】商城 反馈成功。
```

### IP 不一致失败日志

```
05:40:27  【通用_启动】配置IP与数据库IP不一致，运行失败！！！！！！！！！！！！！
```

### 玩家活动日志

```
16:06:59  【游戏】登陆成功。（账号|1|IP|127.0.0.1|密码|1
16:10:11  【游戏】在线注册成功（账号|666666|IP|127.0.0.1|密码|
16:10:11  账号:666666赠送金币成功
16:10:11  账号:666666赠送红利成功
```

## 端口冲突处理

网关 OSP 服务占用端口 **5217**（登录）和 **5317**（商城）。如果先前已有一个网关实例在运行，
新启动的网关检测到端口被占，初始化会卡住或报错。

### 排查与解决

```bash
# 1. 查看端口占用
netstat -ano | grep -E "5217|5317"

# 2. 找到 PID 后强杀旧进程
taskkill /PID <PID> /F

# 3. 确认端口释放后重新启动网关
```

注意：`彩虹岛樱花网关.exe` 即使 GUI 关闭，后台进程可能仍持有端口。
杀掉 PID 后必须确认端口 LISTENING 消失再重启。

## CHDS.DLL IP 嵌入（部分版本）

某些服务端版本的 `CHDS.dll` 内嵌了服务器 IP 地址（在 `BIN2\` 目录下）。
如果配置文件 IP 全部正确但网关仍报 IP 不一致，需要用十六进制编辑器（如 HxD）检查：

1. 用 HxD 打开 `CHDS.dll`
2. 搜索 `127.0.0.1`（8 进制/16 进制视工具而定）
3. 将找到的 IP 改为目标 IP（外网联机改为公网 IP，单机保持 127.0.0.1）
4. 保存（HxD 会自动生成 .bak 备份）

此 DLL 被多个服务器 EXE 加载，修改后影响频道列表显示和连接路由。

## 编码注意事项

彩虹岛服务端的配置文件使用多种编码：

| 文件 | 编码 |
|---|---|
| `configure.ini` | GBK (cp936) |
| `configure_share.ini` | GB18030 |
| `CHDny.ini` | GBK |
| `*.ODBC.ini` | ASCII |
| `*.bat` | GBK + LF 换行 |
| `*.reg` | UTF-16 LE |
| 网关日志 | GBK |

**读取中文配置文件时必须指定正确的编码**，否则会显示为乱码：
```python
with open(path, 'r', encoding='gb18030', errors='ignore') as f:
    content = f.read()
```
