> **状态：已废弃。** 以下手拆版方案已由完整安装版取代。
>
> VS2012 Express for Desktop 在 Win11 上可以成功安装！
> 安装器下载链接：(Visual Studio Express 2012 for Windows Desktop Web Installer)
> 安装后路径：`C:\Program Files (x86)\Microsoft Visual Studio 11.0\`
> vcvarsall.bat 自动创建注册表键，系统重装后仍然可用。
>
> 不需要手动拆 CAB 了。见 `references/compilation.md` 中的编译环境设置章节。

> 2026-05-23: 尝试在 Win11 上获取 VS2012 (v110) 工具链来编译 MgmtServer。
> 根本原因：LataleGameLogic.lib (76MB) 是 VS2012 /GL LTCG 预编译库，
> VS2013(v120) 和 VS2022(v143) 均拒绝链接（C1047: 对象文件是用较旧编译器创建的）。

## 失败路径（不要重试）

| 方法 | 结果 | 原因 |
|------|------|------|
| VS2012 Ultimate ISO 安装器 | 闪退 | Win11 不兼容 GUI |
| VS2012 Ultimate `vs_ultimate.exe /quiet` | exit 0 但未安装 | Win11 兼容性问题 |
| VS2012 Express CHS ISO 安装器 | 闪退 | 同上 |
| VS2012 Express `wdexpress_full.exe /quiet` | exit 0 但未安装 | 同上 |
| MSI 独立安装 (`msiexec /i`) | exit 103/86 | MSI 是链式包，需 setup bootstrapper |
| MSI 管理安装 (`msiexec /a`) | 挂起/103 | 同样问题 |
| VS2022 安装器添加 v110 组件 | exit 0 但未安装 | VS2022 Build Tools 不支持 v110 |
| NuGet `VisualCppTools.Community.VS2012CTP` | 404 BlobNotFound | 链接已失效 |

## 部分成功：手拆工具链

从 VS2012 Express ISO 的 CAB 包手动提取工具链组件：

### 编译器二进制 (vc_compilerCore86)
- `cl.exe` (17.00.50727.1) — MSVC 2012 编译器
- `c2.dll` — 编译器后端
- `link.exe` (11.00.50727.1) — MSVC 2012 链接器
- `lib.exe` — 库管理器

### 链接器依赖 DLL（必须同目录）
- `mspdb110.dll` — PDB 数据库 (来自 `vc_compilerCore86` CAB)
- `mspdbcore.dll` — PDB 核心
- `mspdbsrv.exe` — PDB 服务
- `clui.dll` — 语言资源 (来自 `vc_compilerCore86res` CAB)
- `linkui.dll` — 链接器语言资源

⚠️ 语言 DLL 必须放在 `bin\2052\` 或 `bin\1033\` 子目录。

### CRT 库 (vc_librarycore86)
从 CAB 中按 `file` 类型识别：
- `libcmt.lib` — 静态 CRT
- `libcpmt.lib` — 静态 C++ CRT
- `msvcrt.lib` — 动态 CRT 导入库 (→ msvcr110.dll)
- `msvcprt.lib` — 动态 C++ CRT 导入库
- `oldnames.lib` — 旧名称映射
- `comsupp.lib` — COM 支持
- 共 35 个 .lib 文件

### CRT 头文件
❌ 未能提取。CAB 中文件使用 MSI GUID 命名，无法映射到真实文件名。
CRT 头文件 (stdio.h, stdlib.h 等) 在 VS2012 中位于 Windows SDK 8.0，
不在 vc_librarycore 包中。

## 混合编译方案（进行中）

```
VS2022 cl.exe 编译 MgmtServer .cpp → .obj (v143)
VS2012 link.exe 链接 .obj + 所有 .lib → .exe

链接器: D:\VS2012\VC\bin\link.exe (11.00.50727.1)
CRT lib: D:\VS2012\VC\lib\msvcrt.lib (VS2012)
SDK lib: C:\Program Files (x86)\Windows Kits\10\Lib\10.0.22621.0\
```

### 混合编译已知问题
- VS2022 编译的 .obj 使用 UCRT CRT，VS2012 的 msvcrt.lib 提供 MSVCRT
- 符号可能不匹配（`__imp_??1exception@@UAE@XZ` 等 C++ 异常符号）
- ⚠️ MSYS bash 会将 `/nologo` 路径转换为 `C:/Program Files/Git/nologo.obj`
  → 必须用 `cmd.exe /c` 包裹

## 最终正确方案

**必须下载 VS2012 Express for Desktop 并成功安装后才能编译。**

唯一可靠路径：在 Win10 或更早的 Windows 上安装 VS2012 Express for Desktop。
Win11 上 VS2012 安装器完全不兼容。

如果必须在 Win11 上编译，可考虑：
1. Windows 10 虚拟机 + VS2012 Express
2. Docker Windows Server 2012 容器 (需要 Hyper-V)
3. 从他人获取已编译的 v110 工具链绿色包

## 2026-05-23 晚更新：发现 VS2013 工具链路可走

用 VS2012 link.exe 链接 MgmtServer 时发现新事实：

- **MgmtServer 的 obj 文件是用 VS2015 (v140, _MSC_VER=1900, /MD) 编译的** — 不是 VS2012！
- ServerCore.lib 和 LataleMapLoader.lib 是 VS2013 (v120, _MSC_VER=1800, /MT)
- 还有 RuntimeLibrary 冲突：obj 用 /MD，lib 用 /MT

这意味着 MgmtServer obj 本身就是 v140，跟 LataleGameLogic.lib 的问题是两个独立瓶颈。

### 新策略：用 VS2013 统一编译链

`D:\\VS2013\\` 有完整可用的 VS2013 工具链（安装器失败但文件完整）：

```
VS2013 cl.exe 编译 MgmtServer → _MSC_VER=1800, /MT obj
VS2013 link.exe 链接 → 匹配 ServerCore(1800) + LataleMapLoader(1800)
```

**LataleGameLogic.lib 仍会报 C1047** — 它比 VS2013 更老，但可能可绕过（/FORCE:MULTIPLE 在 rsp 中已有，且该库只是头文件聚合，不含新符号）。

### VS2012/2013 安装器在 Win11 的共同根因（2026-05-23 实际日志诊断）

两个安装器都无法启动，运行后静默退出（exit code 0，无窗口，无输出）。

**不是 SHA-1 签名问题，不是 .NET bootstrapper** — `vs_ultimate.exe` 是**原生 C++ WiX Burn bootstrapper**（非 .NET），数字签名有效未过期。

**实际根因**（通过 Burn `/log` 诊断得出）：

```
Line 39: Loading managed bootstrapper application.
Line 40: Error 0x80131902: Failed to create the managed bootstrapper application.
Line 41: Error 0x80131902: Failed to create UX.
Line 42: Error 0x80131902: Failed to load UX.
Line 59: Variable: IsInstalled = 1        ← 检测到已安装 D:\VS2013
Line 321: Variable: WixBundleInstalled = 1
Line 331: Error 0x80131902: Failed to run per-user mode.
Line 332: Exit code: 0x80131902
```

Burn 引擎 (v3.7.3424.0) 启动后：
1. 检测到 `D:\VS2013` 已有安装 (IsInstalled=1)
2. 尝试加载 **MBA (Managed Bootstrapper Application)** — 嵌入的 .NET UI 组件
3. MBA 加载失败 (0x80131902 = .NET CLR 相关错误)
4. 无 UI 可显示 → 静默退出

**MBA 加载失败的深入诊断（2026-05-23）**：

进一步测试排除了以下假说：
- ❌ Defender/TEMP 权限 — 本地磁盘运行同样失败，无 Zone.Identifier 标记
- ❌ SHA-1 签名 — 签名有效未过期
- ❌ .NET Framework 损坏 — 简单 C# 程序编译运行正常，32/64-bit CLR 均 OK
- ❌ ICLRMetaHost COM 注册 — `CLRCreateInstance()` 返回 S_OK
- ❌ DISM RestoreHealth — 超时且无法修复
- ❌ .NET 4.5.1 修复安装 — 被 4.8.1 阻止降级
- ❌ 兼容模式 (Win7) — 无效
- ❌ .config 强制 CLR 版本 — 无效
- ❌ 清除 Burn 缓存 — 无效

**关键诊断信号**：启用 Fusion 日志后运行安装器 — **产生 0 条日志**。这说明 CLR 根本没走到程序集绑定阶段，失败发生在更早的 AppDomain 创建或 CLR 初始化阶段。

**本质根因**：VS2013 Burn bundle 内嵌的 MBA (Managed Bootstrapper Application) 是面向 .NET 4.5 编译的。Win11 上 .NET 4.8.1 替代了 4.5，CLR 托管层存在兼容性断裂。这不是注册表或文件损坏问题，而是 CLR 版本演进造成的 ABI 兼容问题。修复可能需要 Windows 就地升级或 .NET Framework 完全重装。

**Fusion 日志诊断技术**（调试 CLR 程序集加载失败）：
```bash
# 1. 启用 Fusion 日志（32-bit 和 64-bit 都要设置）
reg add "HKLM\SOFTWARE\Microsoft\Fusion" /v ForceLog /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Fusion" /v LogFailures /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Fusion" /v LogPath /t REG_SZ /d "D:\fusion_logs" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Fusion" /v ForceLog /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Fusion" /v LogFailures /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Fusion" /v LogPath /t REG_SZ /d "D:\fusion_logs" /f

# 2. 运行目标程序

# 3. 检查日志 — 0 条 = CLR 未到达程序集加载阶段
dir D:\fusion_logs\

# 4. 关闭日志
reg add "HKLM\SOFTWARE\Microsoft\Fusion" /v ForceLog /t REG_DWORD /d 0 /f
```

**如何获取 Burn 日志**：
```bash
G:\vs_ultimate.exe /log D:\burn_log.txt
```
日志包含完整变量转储、安装状态和错误链。Bundle provider key 也可从日志中获取用于清理安装检测缓存。

**实用结论**：既然 D:\VS2013 工具链文件完整可用，无需修复安装器 — 直接用 vcvarsall.bat 配置环境即可。
