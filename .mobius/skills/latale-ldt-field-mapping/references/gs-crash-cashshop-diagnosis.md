# GameServer CASH_SHOP.LDT 崩溃诊断

## 错误症状
GS初始化到CASH_SHOP时退出，日志尾部出现：
```
(CCashShopInfo::SetItems,71) : CASH_SHOP.LDT : Invalid Data 1708 白天使服装 0 51771679 0
......DATA/LDT/CASH_SHOP.LDT : FAILED !    iPackageID = [1708]
GetCashShopInfoManager()::Init() : [FAILED]
CLataleGameServerApp::OnCleanup(0)
```

## 错误格式
`Invalid Data <RowId> <ItemName> 0 <BadItemId> 0`
- RowId = CASH_SHOP 的行ID（item_id列）
- ItemName = 商品名（如"白天使服装"）
- BadItemId = 在 ITEM_1/2/3.LDT 中不存在的道具ID

## 修复步骤
1. 用 `ldt_tool.exe` 导出 CASH_SHOP.LDT → CASH_SHOP.csv
2. `grep <BadItemId> CASH_SHOP.csv` 定位行
3. 删除该行
4. 重打包 ROWID.SPF
5. 重启GS验证

## 典型原因
- 从他乡包导入的商城数据引用了不存在的道具
- 手动编辑时写错了 _ItemID 值
- ITEM_*.LDT 被修改后某些道具ID被删除
