# 2026-05-27 繁简转换分批测试记录

## 背景

对D:\彩虹岛\resource\ROWID\DATA\LDT\进行繁体→简体批量转换。
目标端是怀旧端（非他乡端），无SPF防篡改保护，pack=1模式（读ROWID.SPF包）。

## 核心发现

### 1. "设计"二字不能改

**现象**：无论改哪个LDT文件，只要包含"设→设""计→计"替换，GS启动后立即崩溃退出，无错误日志。
**确认方式**：多次独立测试，去掉"设计"后所有改动正常。
**推测**：exe源码中可能将"设计"作为签名/校验字符串硬编码，LDT文本被改后校验失败。

### 2. 特效/技能类文件改后导致时尚商店失效

**现象**：第2批文件（EFFECT, FX_GROUP, FX_UNIT, FX_UNIT_ROBOT, PVP_EFFECT, PVP_SKILL_USE, SKILL_USE）改了后，GS能启动，但游戏内"时尚商店"报"关闭中，请稍后再使用"。
**原因**：这些文件的string字段包含作为**功能标识Key**的文本（如状态名、技能触发器的名称字符串），改了后exe内部按Key查找时找不到。
**未定位具体是哪个文件**：因为当时未逐个文件测试。

### 3. "艾丽丝"是简体"艾"而非繁体"爱"

**原因**：台服原始LDT中写的是"艾丽丝"（b0ac=艾），不是繁体"愛麗絲"（b0ae=爱）。之前繁转简脚本只映射了"愛→爱"，没碰到"艾"。
**修复**："艾"(b0ac) → "爱"(b0ae)，单字节差异，直接二进制替换。
**影响范围**：QUEST_1(114处), QUEST_2(72处), QUEST_INFO_1(308处), QUEST_INFO_2(1678处)，共2172处。
**注意**：这个替换会把所有"艾"字都改掉（包括NPC名"艾咪""艾温"等），用户未提出异议。

### 4. LDT导出XLS/XLSX的陷阱

- CSV导出：Excel会自动把大数字（如道具ID 40153236）转换为科学计数法（4.02E+07）
- XLSX导出：用openpyxl设number_format='@'（文本格式），可避免科学计数法
- 老版XLS导出：用xlwt，写入的字符串在Excel中显示正常
- 用户尝试用Excel的"审阅→繁转简"功能失败（不会自动替换）

## 分批测试结果

### 第1批：安全文件（12个，23处改动）
- ACHIEVE.LDT, ACTION_INTERFACE.LDT, COLLECT_MOB.LDT, GIFT_INFO.LDT
- ITEM_2.LDT, ITEM_3.LDT, NPCTALK.LDT
- QUEST_1.LDT, QUEST_2.LDT, QUEST_INFO_1.LDT, QUEST_INFO_2.LDT
- SAVEPOINT.LDT
- **结果**：GS启动正常 ✅

### 第2批：特效/技能文件（7个，50处改动）
- EFFECT.LDT, FX_GROUP.LDT, FX_UNIT.LDT, FX_UNIT_ROBOT.LDT
- PVP_EFFECT.LDT, PVP_SKILL_USE.LDT, SKILL_USE.LDT
- **结果**：GS启动正常，但时尚商店报"关闭中" ❌

### 第3批：数据表/系统文件（计划但未实施）
- ITEM_ENCHANT, ITEM_UPGRADE, ITEM_UPGRADE_P, GAMBLE_REWARD
- MAPEVENT, NPC_EVENT, NPC_EVENT_DETAIL, CP_EVENT_MISSION, QUEST

## 后续计划（用户与AI商定）

1. 从v0原始版本开始，按模块逐批测试：
   - 任务文本 → 剧情文本 → 道具文本 → 技能文本
2. 跳过"设计"二字
3. 特效/技能类文件先不改，等后面单独处理
4. 备份策略：ROWID_v0.SPF = 原始版
