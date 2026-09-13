# GS 启动报错诊断

## QUEST_DROP_ITEM.LDT : FAILED ! iMonsterID

**症状**: GS启动日志显示 `QUEST_DROP_ITEM.LDT : FAILED ! iMonsterID = [810002615]` 或类似数字。

**原因**: GS exe 内部硬编码了一个 MonsterID 去查询 QUEST_DROP_ITEM.LDT，但这个 LDT 表中 **没有 MonsterID 列**（它只有 8 组 {ItemID, Probability} 字段结构和一行 _Description），所以 GS 校验时必然失败。

**与 ITEM_2 修改的关系**: ❌ **无关**。修改 ITEM_2._CashCheck 不会影响 QUEST_DROP_ITEM 的加载。这个错误在 ITEM_2 修改前可能就存在，只是用户之前没注意到 GS 启动日志里有这行。

**排查方法**:
1. 确认 QUEST_DROP_ITEM.LDT 的结构：它只有 ItemID1~8 + Probability1~8 + Description 共17列，没有 MonsterID
2. 用 `search_files` 在所有 LDT 中搜报错的数字（如 810002615），确认不存在于任何 LDT 中
3. 在 GS exe 二进制中搜索该数字，确认是硬编码

**处理建议**:
- 如果 GS 只是报 FAILED 但 **继续启动** 并且 **功能正常** → 忽略，这是 GS exe 的残留校验
- 如果 GS 因此 **闪退** → 需要修补 QUEST_DROP_ITEM.LDT（加 MonsterID 行）或修补 exe

## CASH_SHOP.LDT : FAILED ! iPackageID

**症状**: `CASH_SHOP.LDT : FAILED ! iPackageID = [数字]`

**原因**: CASH_SHOP.LDT 中某行的 `_ItemID1` 引用了在 ITEM_3.LDT 中不存在的道具ID。

**与 ITEM_2._CashCheck 修改的关系**: 可能有关。如果改 ITEM_2._CashCheck 后 GS 闪退，**先检查是不是 CASH_SHOP 的问题**：
1. 确认 CASH_SHOP.LDT 所有行的 `_ItemID1` 在 ITEM_3 中都存在
2. 确认 ITEM_2._CashCheck 改的是第10列（int）而不是字符串区域
3. 验证 ITEM_2.LDT 结构完整性（行数、数据区未越界）

**排查方法**:
```python
# 查 FAILED 的 iPackageID 在哪个表
search_files(pattern="数字", path="D:\\彩虹岛\\resource\\ROWID\\DATA\\LDT")
# 查 ITEM_3 是否有该ID
read_item3_by_id(数字)
```

## 启动时无错误日志直接闪退

通常不是 ITEM_2 修改导致，优先排查：
1. LDT 结构损坏（行数不匹配、数据区截断）
2. CASH_SHOP 引用了无效 ItemID
3. "设计"二字被替换（触发GS exe校验）
