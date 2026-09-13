# Direct SQL Item Granting (背包直接添加道具)

## When to Use

GM工具只能发基础属性道具（装备、消耗品等基础Item表里的道具）。**商城物品**（发型券、时装、特殊道具等）不能通过GM工具发放。必须通过SQL直接写入 `tbluItem2` 表。

## Table Structure

```sql
-- dbLataleWorld_2.dbo.tbluItem2
ItemNo           bigint       -- 自增主键，不用手动设
UID              int          -- 用户账号ID
CharID           int          -- 角色ID
ContainerType    tinyint      -- 1=背包(Inventory), 2=仓库, 3=装备栏等
ContainerSlot    tinyint      -- 格子编号，从1开始
TypeID           int          -- 道具ID (对应ITEM_1/2/3.LDT中的_RowId)
Cnt              smallint     -- 数量（时装/装备类=1）
Rare             tinyint      -- 品质/星级 (0~5)
IsCash           bit          -- 是否现金道具 (0/1)
```

## 查询角色信息

```cmd
sqlcmd -S tcp:127.0.0.1,59157 -U sa -P 123456 -d dbLataleWorld_2 -Q "SELECT UID, CharID, CharName FROM tbluPC WHERE CharName = '月'"
```

**UID=7 (admin_gm账户), CharID=11541 (角色"月")**

## 查找空背包格

```cmd
sqlcmd -S tcp:127.0.0.1,59157 -U sa -P 123456 -d dbLataleWorld_2 -Q "SELECT ContainerSlot FROM tbluItem2 WHERE UID=7 AND CharID=11541 AND ContainerType=1 ORDER BY ContainerSlot"
```

空Slot就是查询结果中不存在的编号。常用空位：13, 14, 34+（随当前背包填充情况变化）。

## INSERT 添加道具

```cmd
sqlcmd -S tcp:127.0.0.1,59157 -U sa -P 123456 -d dbLataleWorld_2 -Q "
INSERT INTO tbluItem2 (UID, CharID, ContainerType, ContainerSlot, TypeID, Cnt, Rare, IsCash)
VALUES (7, 11541, 1, 13, 40153236, 1, 5, 0);
"
```

| 参数 | 说明 |
|------|------|
| ContainerType=1 | 背包 |
| Cnt=1 | 时装/装备/翅膀等不可堆叠道具数量为1 |
| Rare=5 | 5星品质（如闪亮的天使翅膀） |
| IsCash=0 | 非现金道具（也可设为1让道具标记为现金物品） |

## 验证

```cmd
sqlcmd -S tcp:127.0.0.1,59157 -U sa -P 123456 -d dbLataleWorld_2 -Q "
SELECT ContainerSlot, TypeID, Rare, Cnt
FROM tbluItem2
WHERE UID=7 AND CharID=11541 AND ContainerType=1
  AND ContainerSlot IN (13,14)
ORDER BY ContainerSlot
"
```

## 常见道具示例

| 道具ID | 名称 | 来源表 | Rare |
|--------|------|--------|------|
| 40153236 | 闪亮的天使翅膀 | ITEM_2 (时装翅膀) | 5 |
| 911110255 | 天使翅膀+4 | ITEM_2 (强化翅膀) | 1 |
| 40140151 | 银色翅膀 | ITEM_2 | - |
| 40153303 | 大天使翅膀 | ITEM_2 | - |

## 注意事项

- ItemNo是自增列，INSERT时不要指定
- 不需要设OptType/OptVal/TimeType/LifeTime等可选字段——默认为NULL/0
- 添加后**需要客户端重新登录**才能看到新道具（背包数据在登录时加载）
- 如果与游戏服务器在同一台机器，添加后无需重启服务端
- JSQL2008端口=59157, 密码=123456
