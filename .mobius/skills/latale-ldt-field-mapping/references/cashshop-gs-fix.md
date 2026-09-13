# CASH_SHOP.LDT 导致 GS 启动失败排查记录

## 症状
GameServer 启动到初始化 CashShop 时退出。
日志末尾：
```
(CCashShopInfo::SetItems,71) : CASH_SHOP.LDT : Invalid Data 1708 精灵使装 0 51771679 0
......DATA/LDT/CASH_SHOP.LDT : FAILED !
GetCashShopInfoManager()::Init() : [FAILED]
CLataleGameServerApp::OnCleanup(0)
```

## 根因
CASH_SHOP.LDT 中某行 `_ItemID1` 引用了 ITEM_1/2/3.LDT 中不存在的道具ID。
上例：200行 item_id=1708（不是道具ID，是行号），_ItemID1=51771679，该道具不在任何 ITEM 表中。

## 排查步骤
1. 用 `latale_ldt_tool` 导出 CASH_SHOP.LDT → CSV
2. `grep 51771679 CASH_SHOP.csv` 定位到目标行
3. 确认该行 `_ItemID1` = 51771679
4. 检查 `ITEM_1.csv` / `ITEM_2.csv` / `ITEM_3.csv` 中是否存在 51771679 → 不存在
5. 修复：删除该行或替换为有效的道具ID

## 避免方法
在 CASH_SHOP.LDT 中填入 `_ItemID1~_ItemID8` 之前，先确认道具ID在 ITEM 表中存在。

## 用户给的CASH_SHOP一行示例
```
1708,1,7,22,0,991707,1,白天使服装,,10001212,204,0,1,88,0,1,51771679,1,1,1,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,true,true,0
```
字段顺序：_CategoryView, _CategoryIndex, _CategoryIndex2, _CategoryIndex3, _PositionIndex, _EventType, _Name, _Description, _IconFile, _IconIndex, _Gender, _PriceType, _CashPrice, _SalePrice, _EventIcon, _ItemID1, _ItemRare1, _ItemCount1, _PriceRate1, _ItemID2…

## 注意
- 不要用 Python/sed 修改含中文的 GBK 编码 LDT → 用彩虹岛编辑器或 latale_ldt_tool
- 修改后必须重新打包 SPF 才能生效
- 修改 CASH_SHOP.LDT 后文件大小可能变化，无法做 SPF 原位字节替换
