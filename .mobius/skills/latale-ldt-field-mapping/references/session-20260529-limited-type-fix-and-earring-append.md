# 2026-05-29: Limited_Time_Type 修复与耳环批量追加

## Limited_Time_Type 真相

**现象**：GS启动时报 `CASH_PRICE_RATIO.LDT No Data {RowId}`，其中Limited_Time_Type=2。

**根因**：Limited_Time_Type不是简单的0/1/2，而是指向CASH_PRICE_RATIO.LDT的RowId。
当前怀旧端 CASH_PRICE_RATIO.LDT 只有两行：
- RowId=1001 → 7天比率28（_Price_Ratio7=28）
- RowId=1002 → 30天比率100（_Price_Ratio30=100, _Price_Ratio90=249）

正确值：
- 永久：`_Limited_Time_Type = 0`
- 7天限时：`_Limited_Time_Type = 1001`
- 30天限时：`_Limited_Time_Type = 1002`

他乡端同版本也是这两行，数据一致。

**修复过程**：
1. 首发型追加时256行Limited都被设成了2 → GS从2541开始连续报错
2. 逐个测试：2540(爱心耳环,永久)通过，2541(银瀑布水耳环7天,限时)失败
3. 看用户发来的正常行确认规律：`...|1|1|1002|`（Limited=1002）
4. 将2541~2636的Limited修正为1001/1002，GS启动成功 ✅

## 写入CASH_SHOP的GS验证

成功标准：日志末尾出现 `GetCashShopInfoManager()::Init() : [OK]`，无FAILED行。

排查工具：直接tail GS日志
```bash
tail -30 /d/彩虹岛/bin2/Log/20260529_Latalegameserver_101_101.log | grep -E "CASH_SHOP|FAILED|OK]"
```

## 耳环批量追加

从发型_xls导出.txt提取了171件耳环类（含耳环/指南针/耳朵），删除了4件"不使用"/"测试用"的行。
写入CASH_SHOP.RowId=2637~2802。

分类过滤用名称关键词匹配：`['耳环', '耳環', '指南针', '指南針', '耳朵']`

## 鞋子筛选

从时装列表_逐行.txt（2137件）中按PosID1=7筛选出66件鞋子。
需注意：PosID1=7在ITEM_2中对应的是鞋子装备槽，但_NAME可能显示为"手套"（如"白虎手套"实际是鞋子类）。用PosID1判断部位，不要被_NAME/DESCRIPTION迷惑。
