# LoginServer 能连但客户端卡"连接中"

## 现象

- LoginServer 启动成功，显示 `SessionCount=[1]`（客户端 TCP 连上了）
- 客户端窗口显示"连接中"不消失
- LoginServer 没有进一步输出（未收到登录包或握手包）

## 四步协议握手

客户端连接 LoginServer 的完整流程：

```
Step 1: TCP connect → 端口 19999
Step 2: 加密握手 (Cipher) — 交换密钥/初始化向量
Step 3: 客户端发送登录包（账号/密码）
Step 4: LoginServer 返回服务器列表（来自 MgmtServer）
```

**`SessionCount=[1]` 只表示 Step 1 成功。** 卡在 Step 2 说明 Cipher 加密握手不匹配。卡在 Step 4 说明 MgmtServer 未运行。

## 原因分类

### 1. MgmtServer 未运行（最常见）

LoginServer 只负责 TCP 连接和**登录验证**。客户端连上后，LoginServer 会返回**服务器列表**（可选的大区/频道），这个列表来自 **MgmtServer**（端口 10001）。

MgmtServer 正常启动时会向 LoginServer 注册自己，RegisterServerReq 包含 WorldID、ServerID、IP:Port 等信息。LoginServer 汇总后返回给客户端。

如果 MgmtServer 没有运行，LoginServer 返回空列表，客户端卡在"连接中"（协议层等待列表响应超时）。

### 2. Cipher 加密握手不匹配

即使 `Cipher_Mode=0` 和 `Cipher_UseEncryption=0`，客户端的 exe 可能仍然期待加密握手（编译时硬编码），或者服务端的 Cipher 模块在连接建立后主动发送了加密握手包。

**测试方法**：将 LoginServer 配置中的 Cipher 全设为 0，重启 LoginServer。如果仍卡住，问题不在 Cipher。

### 3. 客户端协议版本不匹配

客户端和服务端 exe 都来自 2017 年的"他乡彩虹岛"发布包，理论上应该匹配。但如果之前混用了不同版本的客户端/服务端文件，可能导致协议不兼容。

验证方式：查看 LoginServer 的版本号 `Version=[300.121]` 和客户端 exe 的编译日期是否匹配。

### 4. GameGuard / nProtect 拦截

客户端的 `GameGuard/` 文件夹包含反作弊驱动，可能拦截本地回环连接。

**测试方法**：将 `D:\彩虹岛\彩虹岛S2\GameGuard` 改名为 `GameGuard_old`，然后启动客户端。

### 5. CHDS.dll 硬编码 IP 校验

服务端 BIN2 目录下的 `CHDS.dll` 可能包含硬编码的 IP 校验逻辑，在握手阶段验证客户端 IP 或服务端 PublicIP。

## 解决

1. **必须让 MgmtServer（10001）先启动并正常运行**，再启动 LoginServer（19999），最后客户端才能看到服务器列表。
2. 如果 MgmtServer 无法启动（Division/PVP 初始化失败），参考 `hex-patch-mgmtserver.md` 进行 patch
3. Cipher 全设 0 后仍卡住：检查 GameGuard 和 CHDS.dll
4. 仍然不行：客户端 exe 与服务端不匹配，需要同一套发布包

## 绕过尝试

跳过 MgmtServer 直连 GameServer **不可行** — 客户端协议设计为 Login→List→Select→Connect 四步握手，没有提供直连参数。无法通过命令行参数或修改配置文件跳过。

## 排查确认

```cmd
netstat -ano | findstr 10001
```

应有 LISTENING 输出。如果没有，MgmtServer 未启动。
