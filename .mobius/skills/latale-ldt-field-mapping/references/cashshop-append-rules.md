# CASH_SHOP.LDT 追加道具规则

## 核心规则
- **CASH_SHOP.LDT不能直接用二进制工具追加写入** — 即时二进制写入成功，string字段（如_Name）长度与原值不同时会导致整行后续字段偏移错位，GS加载崩溃。
- **所有CASH_SHOP追加操作必须手动用彩虹岛编辑器从txt复制粘贴**。发CASH_SHOP格式txt时必须含`_RowId`列（65列格式）。
- CASH_SHOP只适合直接从txt导入/手动编辑，不要试图用Python/脚本写LDT文件。

## 追加前必备检查

### 1. 去重检查
**追加新道具前，必须检查ItemID是否已在CASH_SHOP中存在。**
- 去重要点：按ItemID1维度去重（不是RowId）
- 简单方法：从现有CASH_SHOP.LDT读出所有ItemID1，跟要追加的行交叉对比
- 如果ItemID1已存在，跳过该行

### 2. CashCheck前置检查
- 引用ITEM_2查所有追加道具的_CashCheck是否=1
- 批量改为1之后再追加到CASH_SHOP
- 否则GS加载到对应行时报 `Invalid Data` 崩溃

### 3. Name字段内容校验
- 确认_Name取自ITEM_2的_Name，不是_Description
- Name长度应在2~20字节内（正常道具名范围）
- 如果Name长于30字节，极可能是描述而非道具名

## GS加载失败排查流程

当GS日志显示 `CASH_SHOP.LDT : FAILED !` 时：

1. **看报错的是哪个RowId** — 日志最后一条 `iPackageID = [{RowId}]` 就是问题行
2. **检查问题行的字段**：
   - `Limited_Time_Type` 是不是指向了CASH_PRICE_RATIO存在的RowId？(1001或1002)
   - `EventType` 是不是0或1？不是的话改成0（永久）或1（限时）
   - `ItemID1` 在ITEM_2中是否存在？
3. **如果报 `CASH_PRICE_RATIO.LDT No Data`** → Limited_Time_Type错了
4. **如果只报 `Invalid Data` 没有No Data** → 可能是ItemID在ITEM_2中不存在，或CashCheck=0

## Name字段长度陷阱（最常见失败原因）
- CASH_SHOP的`_Name`(col6)是string类型，写入时带2字节长度头
- **如果写入的Name长度与原行不同，会导致该行后续所有int字段偏移错位**
- 唯一可靠的追加方式：从txt复制到彩虹岛编辑器，编辑器会自动处理行内偏移

## Limited_Time_Type（第64列）
- 不是简单的0/1/2！
- **指向 CASH_PRICE_RATIO.LDT 的RowId**
- `0` = 永久, `1001` = 7天限时, `1002` = 30天限时
- 设成2之类的值GS会报 `CASH_PRICE_RATIO.LDT No Data` 导致启动失败

## EventType（第7列）
- `0` = 永久类, `1` = 限时类
- 填错会导致GS加载到该行时 FAILED

## 字段规则速查
| 字段 | 值 |
|------|-----|
| PriceType | 1 = 点券 |
| CashPrice | 发型统一240 |
| _CategoryView | 0=隐藏, 1=可见 |
| _Buy_Disable | 必须=1 |
| _Give_Disable | 必须=1 |
| RowId/PositionIndex | 跳号完全没问题 |
