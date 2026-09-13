# LataleLoginServer 从源码编译（2026-05-24）

## 概况

成功从源码（`D:\LaTaleServer-\LataleLoginServer\`）编译 LoginServer 并绕过 Cipher 加密。

## 编译方法

### 源文件（21 个）

跳过了有问题的文件：
- `LataleWorkerThread_Login.cpp` — 依赖旧的 `CIOCPThread` 类，源码中不存在
- `ServerMGMTThread.cpp` / `ServerMGMTThread.h` — 依赖 `NamedPipe.h`，源码中不存在
- `ConnectOnly.cpp` / `Connector2MW.cpp` — MW（MasterWorld）组件，单机不需要

### 编译标志

```bash
cl /nologo /c /MT /O2 /W1
   /I<LataleLoginServer> /I<include> /I<src> /I<Common>
   /DWIN32 /DNDEBUG /D_CONSOLE /D_LATALE_SERVER /D_OSP_LOGIN
   /D_SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS
   /D_CRT_SECURE_NO_WARNINGS /D_ALLOW_RTCc_IN_STL /D_HAS_EXCEPTIONS=0
   /FIstdafx.h
   /Fo<Release_v120>\
```

### CIOCPThread 兼容性

`LataleWorkerThread_Login.h` 继承自 `CIOCPThread`（旧的 IOCP 线程类），它和 `CIOCPThread2` 是不同的类。

`CIOCPThread` 在 Src 目录下没有真实实现。如果在源码中有其定义（可能在旧版本或其他项目如 LataleGameServer 中），可以包含真实头文件。否则无法编译这个文件。

**解决方法**：跳过 `LataleWorkerThread_Login.cpp`。LoginServer 的实际工作线程是 `CLataleLoginWorkerThreadWithMQ`（集成消息队列），它继承 `CIOCPThread2`。

### 链接依赖

LoginServer 链接：
```bash
ServerCore.lib ServerBase.lib OSPAPI.lib MonsterAPI.lib ws2_32.lib
```

额外需要 MgmtServer 的 `MgmtStubs.obj`（提供 CIOCP、Cipher、AtzChecker、LogManager2 的 stub 实现）。

### Stub 文件：LoginServerStubs.cpp

```cpp
// CIOCPThread2 extra stubs (not in ServerBase)
bool CIOCPThread2::SendQueue_Append(CSessionContext*, char const*, unsigned long const&, bool) { return true; }

// Cipher stubs — LoginServer checks these but won't use encryption
extern "C" {
    int Cipher_GetMode() { return 0; }
    int Cipher_GetClientDynCode() { return 0; }
}

// CNamedPipe stubs (for ServerMGMTThread, not compiled in final build)
class CNamedPipe { /* all methods return true/0 */ };
```

## 结果

- LoginServer 编译成功（253,952 bytes）
- 启动正常，输出 `LOGINServer was Started!!!`
- 客户端连接显示 `SessionCount=[1]`
- 但客户端仍卡在"连接中"（登录无反应）
- 可能原因：2017 客户端和源码的协议版本有差异，或者 `AUTH_CS_LOGIN` vs `AUTH_CS_LOGIN_EX` 协议选择问题

## Cipher 加密绕过

编译版本完全没有 Cipher 代码（源码中没有任何 Cipher 引用）。因此不需要配置 `Cipher_Mode=0` 或担心加密握手。

如果仍需使用旧版 LoginServer（无法编译），可通过 hex patch 禁用 Cipher：
1. 在 exe 中定位 `Cipher_Init` 调用
2. 将其替换为 `mov eax, 1; ret 4`（返回成功）
3. 将 `Cipher_Decrypt` 调用替换为直接返回原始数据
