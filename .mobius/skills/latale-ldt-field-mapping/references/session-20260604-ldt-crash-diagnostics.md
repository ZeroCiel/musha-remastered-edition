# ITEM_2.LDT 二进制改名导致 BayServer 崩溃（2026-06-04）

## 症状
- BayServer 日志停在 `GlobalSys::Init() : [OK]`，无后续
- 没有 `m_GameDB.DriverConnect : [OK]`
- exit code 139（SIGSEGV）
- 不产生 dmp 文件

## 根因
二进制修改 ITEM_2.LDT 的 string 字段时，新名字比原名短，用空格(0x20)或0x00填充后破坏了 `\x00` 字符串边界。

## 恢复方法
1. 从 BARY.rar 解包出原始 ITEM_2.LDT
2. 覆盖 `D:\LaTale\S2\resource\ROWID\DATA\LDT\ITEM_2.LDT`
3. 重新打包 BARY.SPF，重启网关

## 教训
- 彩虹岛 LDT 的 string 字段是 `\x00` 终止的变长结构
- 二进制替换必须 **等长**（短了用空格(0x20)填满到原名长度）
- 不要用 `\x00` 填充剩余字节（会破坏下一个字段的起始边界）
- 推荐用彩虹岛编辑器改名字，不要二进制直接改

---

# QUIZ_INFO.LDT 缺失导致 RoomServer 崩溃（2026-06-04）

## 症状
- RoomServer 日志：`LoadQuizInfoLDT() : [FAILED]` → 立即退出
- 之后重启还是同样错误

## 根因
- pack=1 时只读 SPF 包，QUIZ_INFO.LDT 不在 SPF 内
- pack=0 时读目录 LDT，目录下有文件所以能过
- 但 pack=0 时另一个问题（ITEM_2.LDT 损坏）导致 Bay 崩溃

## 修复方法
1. 确认 QUIZ_INFO.LDT 是否存在于 `resource/ROWID/DATA/LDT/` 目录
2. 如果存在但不完整，从他乡端解包目录复制
3. 如果没有此文件，检查是不是之前误删了
4. 重新打包 BARY.SPF（包含此文件）

# GS 报 SetID/EffectID 无效导致崩溃（2026-06-04）

## 症状
```
Item Info Loading.........DATA/LDT/ITEM_2.LDT : FAILED !
iItemID = 30371402, EffectID = 16777216

Item Info Loading.........SetID does not exist in SETITEM_B
iSetID(65536)
```
- GS（频道1）启动时报这个，可以是任何频道
- BayServer 可能正常启动

## 根因
- ITEM_2.LDT 中某行数据的 EffectID 或 SetID 字段被误写为无效值（如 16777216 = 0x1000000, 65536 = 0x10000）
- SETITEM_B.LDT 文件本身不存在（他乡端没有这个文件），但 ITEM_2 中引用了它的 SetID
- 这些值可能是编辑器保存时误写，或打包工具标记位被当做数值写入

## 诊断
1. 从报错拿到 iItemID（如 30371402）
2. 用彩虹岛编辑器打开 ITEM_2.LDT，找到该行
3. 检查 EffectID 和 SetID 列，看是否有 16777216 / 65536 等异常值
4. 异常值通常在 48个int列 中的某一列（索引不确定，凭编辑器查看）

## 修复
1. 用彩虹岛编辑器打开 ITEM_2.LDT，找到对应行
2. 把有异常值的列（EffectID、SetID 等）改为 0
3. 保存并重新打包 BARY.SPF

## 批量发现问题
如果 LDT 中大量存在 65536 值（本端实测有 12830 处）：
- 这是端本身的遗留问题，不是我们修改导致的
- 只有引用了 SetID 列且该列值为 65536 的行才会触发 GS 报错
- 批量修复建议：用彩虹岛编辑器将所有道具行的 SetID 清 0

## 教训
- ITEM_2 改 CashCheck（0→1）本身不会导致 GS 崩溃
- 但 CashCheck=1 后 GS 会加载该道具的完整数据（包括 EffectID/SetID），如果这些值无效就会炸
- 因此**先检查 ITEM_2 数据完整性，再改 CashCheck**
