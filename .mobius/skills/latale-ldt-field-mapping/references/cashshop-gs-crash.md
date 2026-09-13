# GS启动CASH_SHOP.LDT崩溃排查指南

## 症状
GS启动到初始化商城时退出，日志最后几行显示：
```
(CCashShopInfo::SetItems,71) : CASH_SHOP.LDT : Invalid Data 1708 xxx 0 <ItemID> 0
......DATA/LDT/CASH_SHOP.LDT : FAILED !    iPackageID = [1708]
GetCashShopInfoManager()::Init() : [FAILED]
CLataleGameServerApp::OnCleanup(0)
```

## 根因
CASH_SHOP.LDT中某行引用的`_ItemID1`（实际道具ID）在ITEM_3.LDT中不存在。

具体检查:
- GS日志中的`Invalid Data 1708` → 第1708行（即item_id=1708的记录）
- 日志中的5位数字（如`51771679`）→ 实际道具ID，在ITEM_3.LDT中查不到

## 修复方法

### 方法1：删除无效行（推荐）
1. 用彩虹岛编辑器或LDT工具打开CASH_SHOP.LDT
2. 找到item_id=1708（或日志报错的iPackageID）的行
3. 删除整行

### 方法2：补充道具
1. 在ITEM_3.LDT中新增该道具ID的记录
2. 打包后重启GS

## 预防
修改CASH_SHOP.LDT前，先确认引用的道具ID在ITEM_3.LDT中存在。
查询命令：`grep "<ItemID>" ITEM_3.csv`
