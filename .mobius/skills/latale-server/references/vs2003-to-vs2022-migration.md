# VS2003 → VS2022 源码迁移踩坑

## 架构

- 所有 exe/lib 原始编译: VS2012 (MSVCR110.dll, image base 0x400000)
- 源码格式: VS2003 .vcproj (encoding: `ks_c_5601-1987`)
- 目标: VS2022 v143 工具链

## 依赖库编译状态

| 库 | 源码 | 编译 | 备注 |
|---|---|---|---|
| ServerCore | ✅ | ✅ | 补了 stdafx.h 缺 `<string><vector>` |
| ServerBase | ✅ | ✅ | 补了 `<stdio.h><stdlib.h>` |
| LataleMapLoader | ✅ | ✅ | 补了 `_RES_BELOS` + `binary_function` 修复 |
| LataleGameLogic | ❌(头文件库) | ✅(自制桩) | 无官方 .vcproj，创建 LataleGameLogicStub.cpp include 全部 144 头文件 |
| LataleBattleSystem | ✅ | ✅ | 补了 `../src` include path |
| LataleCheatSystem | ✅ | ✅ | — |
| OSPAPI | ✅ | ✅ | — |
| MonsterAPI | ✅ | ✅ | — |

## MgmtServer 编译

### 必须修复的文件

1. `Common/stdafx.h` — 缺 `<map><string><queue><hash_map>`, `SAFE_DELETE`, `SC_ERROR`, `MAX_PACKET_SIZE`
2. `LataleMgmtServer.vcxproj` — include path 加 `.;`, RuntimeLibrary 改 `/MD`
3. 源码已改: Division/Guild/PVPDivision/PVPMatch → non-fatal continue

### git-bash 中 MSBuild 注意事项

- 用 `-p:Config=Release` 不用 `/p:`
- 路径用 `D:/xxx/` 不用 `D:\xxx\`
- 中文路径给 MSBuild 时需妥善处理

## 预编译 lib 的 ABI 问题

预编译 `LataleGameLogic.lib` 是 VS2012 编译:
- 符号全部 `__imp_` 前缀（DLL import from MSVCR110.dll）
- std::string layout 与 VS2022 不同 (v143 CRT 用 VCRUNTIME140.dll)
- 无法混合链接

解决方案: 创建 `LataleGameLogicStub.cpp` include 全部 144 个头文件，重新编译为 VS2022 .lib

## 通用 vcproj→vcxproj 转换脚本

见 `scripts/convert_vcproj.py`

核心要点:
- ks_c_5601-1987 编码不受 Python XML 库支持 → 用正则解析
- ExcludedFromBuild 文件需跳过
- Include path 必须添加 `.;`
- 预编译头用 `ForcedIncludeFiles` + `NotUsing`
- 添加 `_WIN32_WINNT=0x0602` (RtlCaptureContext 需要)
- 添加 `_SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS`
- 添加 `_HAS_AUTO_PTR_ETC=1` (修复 binary_function 移除)
