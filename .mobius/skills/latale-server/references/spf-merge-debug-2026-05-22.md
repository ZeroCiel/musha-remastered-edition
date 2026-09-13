# SPF 合并排障 — 2026-05-22

## 合并版 SPF 崩溃的根因

替换 101 个结构兼容 LDT 后，MgmtServer 控制台输出并卡住：
```
GUILD infos loading... Division Failed!!!
Press any Key to continue....
```

### 伪报错：GLOBAL_SYS.LDT

AS 控制台输出 `......DATA/LDT/GLOBAL_SYS.LDT : FAILED ! (This LDT is Not Exist.)`
是**红鲱鱼**。源码确认：
- MgmtServer `LataleMgmtServerApp.cpp:119-124`：`GetDivisionInfoList()->Init()` 失败 → `getchar()` 暂停
- `LataleMgmtServerApp.cpp:151-155`：`LoadGlobalSysLDT()` 失败 → 只记日志 + return false，**不暂停**
- 原始 SPF 也会报 GLOBAL_SYS 错误，但随后 `GlobalSys::Init() : [OK]` 自动恢复

### 真正问题文件

通过二分法排查（101→50→25→12→6→3→1）确认：
- ATTACK_TREE.LDT、BEATTACKED.LDT、ACTION_INTERFACE.LDT 等核心战斗数据替换后导致 Division 初始化失败
- 即使这些文件字段结构兼容（同字段数+同类型），运行时数据差异仍会触发问题

### 安全替换范围

21 个纯文本文件已验证不会引发崩溃：
GLOBAL_STRING, SKILL_TXT, SKILL_CONTENT, GLOBAL_MOB, PVP_SKILL_TXT,
QUEST_LIST, QUEST_ESSENTIAL, NPCTRADE, CHAT_COMMAND, CHAT_MACRO, CHAT_TYPE,
CASHSHOP_HELP, CASHSHOP_DEFAULT, CASH_SHOP_HOT, CASH_SHOP_LIMIT,
CLASS_CHANGE, CLASS_EFFECT, ITEMSET_A, ITEMSET_B, CARDBINDER, SEALSKILL_LEVEL

## GS_101 无法启动（25MB 卡死）

- 进程存在但内存固定 ~25MB，无端口监听，不创建日志
- 两个版本均卡死：`Latalegameserver_101.exe`（下划线）和 `LataleGameServer101.exe`（无下划线）
- 07:34 时 `Latalegameserver_101.exe` 曾成功加载到 500MB+，原因不明
- 推测：免费版樱花网关不提供 GS 的 OSP 握手信号，GS 在 main() 前挂起

## VS 编译

- VS2003 .vcproj 格式，MSBuild 2022 报 MSB4025
- MgmtServer .vcxproj 已生成，但编译遇到 hash_map/typeinfo.h 兼容性问题
- 源码修改已完成（Division/Guild/GLOBAL_SYS → 非致命）
- VS Build Tools 装于 D:\VSBuildTools（C 盘需先清 Temp 腾空间）
