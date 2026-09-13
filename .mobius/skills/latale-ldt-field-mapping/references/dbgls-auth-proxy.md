# dbgls.dll 认证分析记录

## 背景

彩虹岛S2他乡包（D:\彩虹岛单机）的 `dbgls.dll`（3,395,584字节，3.2MB）是客户端exe硬链接依赖的组件，兼具内挂功能（彩虹助手）和登录认证功能。

## 加壳分析

利用 `check_dll.py` 脚本分析PE结构：

| 区段 | 虚拟大小 | 说明 |
|------|---------|------|
| .text | 0xF904E | 正常代码段 |
| .rdata | 0x641E0 | 只读数据 |
| .data | 0x6D9EC | 数据段 |
| **.vmp0** | **0x2A4C08** | **VMProtect 虚拟化代码** |
| **.vmp1** | **0x338D40** | **VMProtect 加密数据** |
| .reloc | 0xF4 | 重定位 |
| .rsrc | 0x155D | 资源 |

**结论：VMProtect加壳（不是UPX），区段名 `.vmp0`/`.vmp1`**。无法反编译。

## Wireshark 抓包分析

### 环境
- 工具：Wireshark 4.6.6
- 捕获接口：Adapter for loopback traffic capture
- 分析命令：`tshark.exe`

### 关键发现

**抓包前修改客户端端口失败：** 将 `开始游戏.bat` 中的 `/LoginServer:127.0.0.1:19999` 改为 `19998` 并启动代理（监听19998→转发19999），结果客户端无法登录。因为 **dbgls.dll 的认证不走19999端口**。

**正确抓包方式：不修改端口，直接抓 `127.0.0.1:19999` 的流量。**

### 抓包结果

**端口使用情况（完整抓包100秒，约2500个包）：**

| 端口 | 用途 |
|------|------|
| 59157 | JSQL2008 (SQL Server数据库) |
| 10001 | MgmtServer 管理端口 |
| 10020 | AccountServer |
| 19999 | LoginServer（LaTaleClient标准登录） |
| 22002 | 服务端进程注册/管理端口 |
| 10002 | 未知服务端口 |
| 9210~9219 | 未知服务 |
| 6769 | dbgls.dll 发送UDP包的目标端口（无监听） |
| 56649~57102 | 未知 |

**LoginServer（19999）登录协议：**
```
[服务端先发] 10字节: 0a 00 00 00 64 00 00 00 00 01
  长度=10, 类型=0x64(100), 标记=00 01

[客户端回复] 加密数据包（自定义算法，不是标准TLS/SSL）

Wireshark识别为 SSL Continuation Data（因为负载看起来像加密流）
```

**两个TCP流（流194和206）：** 都是LaTaleClient.exe（非dbgls.dll）和LoginServer的标准登录交互。dbgls.dll 没有出现在19999端口的通信中。

### dbgls.dll 认证路径推测

基于抓包数据，dbgls.dll 可能通过以下方式认证：

1. **UDP 6769端口** — 抓到大量 `64xxx → 6769` 的UDP包（约130字节/包），但6769端口没有服务监听（返回ICMP Port Unreachable）。这可能是dbgls.dll尝试连接远程认证服务器失败。

2. **进程内存注入** — dbgls.dll 在 `DllMain` 时 hook 了 LaTaleClient.exe 的Socket API（`connect`, `send`, `recv`），篡改认证数据包。这种修改在Wireshark层面看不出异常。

3. **共享内存/命名管道** — 通过非网络IPC方式与LaTaleClient.exe通信。

### 页面提示：无法通过代理中间人解决
中间人代理只能转发TCP流量，dbgls.dll 不走19999端口，所以：
- 代理改端口 → 客户端连不上服务器（而非抓到认证包）
- 不改端口直接抓 → 只抓到标准登录协议，dbgls认证数据不经过网络层

## 可行方案

1. **问卖家要dbgls.dll源码或纯认证版** — 最快
2. **用易语言自己写一个替代DLL**（需逆向分析认证协议，难度高）
3. **换不带壳的S2端** — 省事但可能需要重新适配

## 相关脚本

- `scripts/proxy_login.py` — 19999端口代理抓包（已废弃，因dbgls不走19999）
- `C:\Users\Administrator\Temp\check_dll.py` — 检测DLL加壳类型脚本
- `C:\Users\Administrator\Temp\read_pcap.py` — 读取pcapng文件脚本
