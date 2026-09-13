# SQL 数据库 — 账号/角色管理

## 连接

```bash
# sqlcmd 路径
\"/c/Program Files/Microsoft SQL Server/110/Tools/Binn/sqlcmd\"

# 连接参数
-S 127.0.0.1,59157 -U sa -P 123456 -d dbLataleAccount

# 中文版列名查询（不用 -s "|" 时输出列名）
```

## 账号管理

### 查看账号
```sql
-- 账号表在 dbLataleAccount 的 tbluAccount
SELECT UID, ID, PW FROM tbluAccount

-- 账号密码是 SHA256 哈希
-- UID=5  admin_gm
-- UID=7  Ciel
-- UID=8  test
```

### 查看角色
```sql
-- 角色表 CharInfo（注意在 dbLataleAccount 下）
SELECT UID, CharName, Level, Class FROM CharInfo

-- 中文名用 CONVERT(varbinary, CharName) 查看GBK十六进制
-- 然后 Python 解码：bytes.fromhex(hex_str).decode('gbk')
```

### 删除角色
```sql
DELETE FROM CharInfo WHERE CharName = '角色名'  -- 不靠谱，中文乱码
DELETE FROM CharInfo WHERE UID = <UID>           -- 按UID删除

-- 注意：同一个UID下可能有多个角色（同账号的多角色）
```

## 背包物品管理

### tbluItem2（角色背包）
在 dbLataleWorld_2 数据库下。

```sql
-- 查看表结构
SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='tbluItem2'

-- 关键列
-- ItemNo (bigint)     — 物品实例ID
-- UID (int)          — 用户ID
-- CharID (int)       — 角色ID
-- ContainerType (tinyint) — 容器类型（1=背包）
-- ContainerSlot (tinyint)  — 格子位置
-- TypeID (int)       — 道具ID（对应 ITEM_*.LDT 的 item_id）
-- Cnt (smallint)     — 数量
-- Rare (tinyint)     — 稀有度
```

### 发道具到背包
```sql
INSERT INTO tbluItem2 (UID, CharID, ContainerType, ContainerSlot, TypeID, Cnt, Rare)
VALUES (<UID>, <CharID>, 1, <空位>, <ItemID>, 1, 1)
```

## 常用sqlcmd语法

```bash
# 查询输出为竖线分隔
sqlcmd -S 127.0.0.1,59157 -U sa -P 123456 -d dbLataleAccount -Q "SELECT ..." -s "|"

# 删除
sqlcmd -S 127.0.0.1,59157 -U sa -P 123456 -d dbLataleAccount -Q "DELETE FROM CharInfo WHERE UID=<N>"

# 列出所有数据库
sqlcmd -S 127.0.0.1,59157 -U sa -P 123456 -Q "SELECT name FROM sys.databases"

# 列出表
sqlcmd -S 127.0.0.1,59157 -U sa -P 123456 -d dbLataleWorld_2 -Q "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'"
```
