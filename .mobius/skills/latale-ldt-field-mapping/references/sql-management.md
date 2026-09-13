# 彩虹岛私服 SQL 管理

## 数据库连接
- 服务器: `127.0.0.1,59157`
- 用户: `sa`
- 密码: `123456`
- 账号库: `dbLataleAccount`
- 世界库: `dbLataleWorld_2`

### 客户端工具
`sqlcmd` (SQL Server 110):
```
"/c/Program Files/Microsoft SQL Server/110/Tools/Binn/sqlcmd" -S 127.0.0.1,59157 -U sa -P 123456 -d <DatabaseName> -Q "SQL"
```
中文名查詢用 `CONVERT(varbinary, ColumnName)` 取hex後用Python decode('gbk')解碼。

## 账号管理 (tbluAccount)

```sql
-- 查所有账号
SELECT UID, CONVERT(varbinary, ID) AS ID_Hex, CONVERT(varbinary, Name) AS Name_Hex FROM tbluAccount
-- ID_Hex和Name_Hex用Python bytes.fromhex().decode('ascii')解密
```

| UID | 账号 | 说明 |
|-----|------|------|
| 5 | admin_gm | 管理员(不动) |
| 7 | Ciel | 用户主账号(不动) → 角色"月"(95级)、"雪儿"(5级) |
| 8 | test | 测试账号 |

## 角色管理 (CharInfo / tbluPC)

### CharInfo (账号库)
```sql
SELECT UID, CONVERT(varbinary, CharName) AS NameHex, Level, Class FROM CharInfo
```
- 角色名用GBK编码
- CharID关联到世界库的tbluItem2等表

### tbluPC (世界库)
角色属性主表，CharID关联。

## 点券/红利管理 (Point表)

```sql
SELECT * FROM Point
```
- `balance` — 点券余额
- `bonus` — 红利(赠送点券)

### 删除指定账号点券
```sql
DELETE FROM Point WHERE UID NOT IN ('保留的账号1', '保留的账号2')
```

## 背包物品管理 (tbluItem2)

### 表结构
| 字段 | 类型 | 说明 |
|------|------|------|
| ItemNo | bigint | 主键，自增 |
| UID | int | 账号ID |
| CharID | int | 角色ID |
| ContainerType | tinyint | 0=普通背包, 3=装备栏 |
| ContainerSlot | tinyint | 格子编号(1开始) |
| TypeID | int | 道具ID(对应ITEM_3的item_id) |
| Cnt | smallint | 数量 |
| Rare | tinyint | 稀有度 |

### 查某角色所有道具
```sql
SELECT ItemNo, ContainerType, ContainerSlot, TypeID, Cnt FROM tbluItem2 WHERE CharID=<CharID> ORDER BY ContainerType, ContainerSlot
```

### 常见CharID
- UID=7 (Ciel) → CharID=11541 (角色"月")

### 清理重复道具
```sql
DELETE FROM tbluItem2 WHERE ItemNo IN (<重复的ItemNo>)
```
注意：ContainerSlot=1并不是唯一的格子标识，多个道具可以共享同一个ContainerSlot值（游戏客户端自己处理显示）。

## 邮件系统 (tbluMailBox)

表字段: MailID, Receiver, SendTime, DeliveryTime, VerifyTime, ExpireTime, Sender, Subject, Memo, Ely, ItemNo, SenderUserID, SenderCharID, ReceiverUserID, ReceiverCharID, ReadFlag, Type

ItemNo字段关联tbluItem2的ItemNo，不是直接填道具ID。发带附件的邮件需要先在tbluItem2中创建一条道具记录，然后把ItemNo填入邮件表。

## 服务进程管理

### 启动顺序
Mgmt(10001) → AS(10020) → Login(19999) → Lobby → Bay → Room → GS

### exe位置
`D:\彩虹岛\bin2\`

### 查进程
```
cmd.exe //c "tasklist /FI "IMAGENAME eq LataleGameServer.exe" 2>nul"
```

### 查所有GS
```
cmd.exe //c "tasklist | grep -i game"
```
GS进程名: Latalegameserver_101.exe, _102.exe, _151.exe

### 重启GS
```
cmd.exe //c "taskkill /F /IM Latalegameserver_101.exe 2>nul"
cmd.exe //c "start /D D:\彩虹岛\bin2 Latalegameserver_101.exe"
```

### GS日志位置
`D:\彩虹岛\bin2\Log\2026xxxx_Latalegameserver_101_101.log`
- 启动报错重点关注最后几行
- CASH_SHOP加载失败会在日志末尾显示 `CASH_SHOP.LDT : FAILED` + 具体iPackageID
