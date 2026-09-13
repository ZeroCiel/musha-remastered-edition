# Hex 补丁 MgmtServer

## 背景

MgmtServer 启动时 Division/Guild 初始化失败会调用 `getchar()` 阻塞，导致"Press any Key to continue..."卡住。源码已修改为非致命，但二进制是第三方修改的 2017 版，无法直接重编。

## 核心诊断流程

当 exe 启动后闪退但没有任何输出时：

1. **确定 exe 类型**：`file LataleMgmtServer.exe` — console 还是 GUI
2. **在桌面 cmd.exe 运行**（不是终端工具）— 双击或原生 cmd 才能看到 console 输出
3. **观察输出终止位置** — 输出停在哪里就是哪里卡住或失败了
4. **从停的位置反向分析** — 在 exe 中搜索对应字符串，找到引用它的函数，patch 条件分支
5. **最暴力方案**：在确认的函数入口处 patch 成 `mov al,1; ret` (B0 01 C3)

## 二进制信息

- 编译工具: VS2012 (链接 MSVCR110.dll)
- Image base: `0x400000`
- getchar IAT RVA: `0x714C8`, VA: `0x4714C8`
- 文件大小: 731,136 字节

## 寻找 getchar 调用点

```python
data = open('LataleMgmtServer.exe', 'rb').read()
getchar_iat = bytes([0xff, 0x15, 0xc8, 0x14, 0x47, 0x00])
for i in range(len(data)-6):
    if data[i:i+6] == getchar_iat:
        ctx = data[max(0,i-16):i+16]
        print(f'0x{i:x}: {ctx.hex()}')
```

## 当前 BIN2 exe 的 getchar 调用点

| 文件偏移 | 后续指令 | 含义 |
|---|---|---|
| 0xc077 | `b0 01; ret` | ✅ 正常返回 |
| 0xdaa3 | `b0 01; ret` | ✅ 正常返回 |
| 0x13e24 | `push 1; call Sleep; ...; ret 8` | ⚠️ 资源加载失败后 Sleep 1 秒，继续 |
| 0x13ec2 | `push 1; call Sleep; xor eax,eax; ret` | ❌ **PVP Division 失败 → return false** |

## 补丁方案

### 方案 A：NOP getchar + 改 return value（已测试，部分有效）

NOP getchar 调用 + 把 `xor eax,eax; ret` 改成 `mov al,1; ret`：

```python
# NOP getchar (6 bytes): FF 15 C8 14 47 00 → 90 90 90 90 90 90
data[0x13ec2:0x13ec2+6] = bytes([0x90] * 6)
# return false → return true: 33 C0 C3 → B0 01 C3
data[0x13ed0:0x13ed0+3] = bytes([0xB0, 0x01, 0xC3])
```

### 方案 B：改条件跳转指令（推荐）

跳过 Division 失败的输出和 PVP Division 失败的分支：

```python
# Division 失败检测的 JNZ → JMP（跳过失败信息，继续执行）
# 75 1E (jnz +0x1E) → EB 1E (jmp +0x1E)
# JNZ 的意思是"如果不为零则跳过"——Init 返回 false 时 eax=0，不会跳
# 改成 JMP 后无条件跳过失败处理
data[0x13e61] = 0xEB  # 原 75 → EB

# PVP Division 失败检测的 JE → NOP
# 74 0A (je +0xA) → 90 90
# JE 的意思是"如果为零则跳入 fail 分支"——Init 返回 false 时 al=0，跳入
# NOP 掉后无论 Init 返回什么，都继续执行成功路径
data[0x13e98] = 0x90
data[0x13e99] = 0x90
```

**方案 B 的优点**：不需要精确定位 getchar 位置，只需要找到条件判断指令。判断指令更容易定位（通常在 printf 输出附近）。

## 偏移量说明

所有偏移量（0x13e61, 0x13e98, 0x13ec2, 0x13ed0）仅适用于 731,136 字节版本的 `LataleMgmtServer.exe`。不同编译版本的偏移量不同。每次应用补丁前**必须**通过 PE 分析工具验证。

## 已知限制

即使 PVP 补丁生效，第三方修改的 2017 版 exe 仍可能在其他路径退出：
- Division 失败后直接 getchar（与源码行为不一致）
- `ServerTemplate2::Init()` 中其他检查失败
- DLL 依赖缺失
- ODBC 数据库连接失败

## 恢复

备份保存在 `LataleMgmtServer.exe.patchbak`
