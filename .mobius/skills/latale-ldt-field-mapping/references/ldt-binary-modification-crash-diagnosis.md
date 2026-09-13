# 2026-06-04 LDT 崩溃诊断实录

## BayServer ITEM_2崩溃

### 现象
- BayServer日志停在 `GlobalSys::Init() : [OK]` 后无任何后续行
- 进程退出 code 139 (SIGSEGV)
- 没有生成 .dmp 文件
- 其他服务（Lobby、Login、GS 101/102/151）日志正常

### 根因
Python 直接修改 ITEM_2.LDT 的 string 字段时，去掉"【韩国专属合作道具，其他国家服无法使用】"前缀后，新名字比原名短。
用空格(0x20)填充剩余区域时，有些条目没填到等长，或没用正确的填充方式，
导致该行后续字段的 \x00 终止边界被破坏 → BayServer 在 GlobalSys::Init() 过程中加载到该行时 segfault。

### 修复
1. 从 BARY.rar 恢复原始 ITEM_2.LDT
2. 重新打包 BARY.SPF
3. 重启网关

### 教训
- LDT 的 string 字段是 \x00 终止的变长结构
- 覆盖写入新字符串后，**剩余字节必须用 0x20（空格）填满到原名长度**，不能用 0x00
- 0x00 是字符串终止符，会把后续字段内容变为空字符串
- 优先用彩虹岛编辑器修改，不要二进制直接改


## RoomServer QUIZ_INFO崩溃

### 现象
```
LoadQuizInfoLDT() : [FAILED]
LataleRoomServerApp::OnCleanup(0)
```

### 原因
QUIZ_INFO.LDT 文件不存在。pack=1 时从 SPF 读不到该文件，pack=0 时从目录读（如果有的话）。

### 影响
RoomServer 无法启动，但不影响核心游戏功能（地图、战斗、商城等）。

### 修复
- 确认 QUIZ_INFO.LDT 是否存在于 `resource/ROWID/DATA/LDT/` 目录
- 如果存在，重新打包进 BARY.SPF
- 如果不存在但原来能跑，可能是他乡端版本没有这个文件
