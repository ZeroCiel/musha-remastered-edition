# S2 他乡包 MgmtServer Division 致命退出（2026-05-28）

## 现象

`D:\LaTale\Server2\BIN2\LataleMgmtServer.exe` 启动后输出以下信息然后立即退出（exit code 0）：

```
Load configure from Security INI.
[ServerInfo] [W1S11] IP:PORT=[127.0.0.1(127.0.0.1):10001]
[LataleMGMTServer] [RELEASE] Build Time : Oct  5 2017 13:33:29
ServerKey = [X] MSA_UDPPort=[10011]
Version=[300.121]
>>------------------------------------------LataleMGMTServer_W1S11
	 GUILD infos loading... Division Failed!!! 
```

进程存活不到 3 秒，端口 10001 不绑定。

## 根因

这是旧版源码中 `CDivisionInfoList::Init()` 从 SPF 加载 LDT 失败后执行的 fatal 错误路径。源码中该路径包含 `printf` + `getchar()` + `return false`，导致 MgmtServer 退出。

## 关键观察

1. 这个 exe 读的是 `Security INI` 而非 configure.ini（CHDS.dll/VMProtect 的保护机制）
2. SPF 是他乡加密版，exe 在 pack=1 模式下读加密 SPF 包时 LDT 加载失败
3. 2017 原始 exe 的 PVPDivision bug（与之前 VS2013 编译版遇到的完全相同）
4. CHDS.dll 如果被改名，exe 也不会启动（不输出任何日志直接退出）

## 已测试的修复尝试（均失败）

| 尝试 | 结果 |
|------|------|
| Pack=1 → Pack=0 目录模式 | ❌ exe 直接退出，无日志（CHDS.dll 保护拦截） |
| 改名 CHDS.dll → 再 Pack=0 | ❌ exe 直接退出，无日志 |
| 重定向 resourceDir 到 extracted/DATA | ❌ exe 读 Security INI 时路径固定 |

## 结论

这个 Server2 的 S2 他乡 exe 包（2022-06-06 版本，Build Time 2017-10-05）在本环境无法启动。

核心障碍：
1. SPF 加密（exe 魔改读取逻辑，标准 SPF 读法不行）
2. CHDS.dll 保护（防止 Pack=0 目录模式，防止改名绕开）
3. Division 初始化 fatal（源码级 bug）
4. 无打包工具可用（SFP v1.6 打包按钮灰色）
5. 源码不完整无法编译其他服务
