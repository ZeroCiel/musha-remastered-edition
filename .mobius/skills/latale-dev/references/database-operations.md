# 数据库操作

## 连接信息
- 服务器：127.0.0.1,59157
- 账号：sa
- 密码：123456
- 账号库：dbLataleAccount
- 游戏库：dbLataleWorld_2

## 连接方式（终端）
```
sqlcmd -S "tcp:127.0.0.1,59157" -U sa -P "123456" -d dbLataleWorld_2 -Q "SELECT ..."
```

## 角色表：tbluPC
| 字段 | 类型 | 说明 |
|------|------|------|
| uID | int | 账号UID |
| charID | int | 角色ID（唯一） |
| charName | varchar | 角色名 |
| lv | smallint | 等级 |
| class | tinyint | 职业 |
| Del | tinyint | 删除标记（0=正常, 1=已删） |

## 物品表：tbluItem2
| 字段 | 类型 | 说明 |
|------|------|------|
| ItemNo | bigint | 物品唯一编号 |
| UID | int | 所属账号 |
| CharID | int | 所属角色 |
| ContainerType | tinyint | 容器类型（2=背包, 3=装备, 4=时装, 6=快捷栏, 10=仓库） |
| ContainerSlot | tinyint | 格子位置 |
| TypeID | int | 物品模板ID |
| Cnt | smallint | 数量 |
| Rare | tinyint | 稀有度 |

## 账号表：tbluAccount（dbLataleAccount）
| 字段 | 类型 | 说明 |
|------|------|------|
| UID | int | 数字UID |
| ID | varchar | 登录账号名（如'Ciel'） |
| PW | varchar | 明文密码 |
| Name | varchar | 显示名 |
| NickName | varchar | 昵称 |

## Point表（点券）
- 库：dbLataleAccount
- 结构：id(int), UID(varchar), balance(int), bonus(int)
- **UID是varchar类型，存的是账号名（如'Ciel'），不是数字UID**
- 查询：`SELECT * FROM Point WHERE UID='Ciel'`
- balance=点券, bonus=红利

## 角色名占用相关表（dbLataleAccount库）

| 表 | 作用 | 清除方式 |
|----|------|---------|
| `tbluUsedCharName` | 角色名历史记录（包含已删角色的名称，创角卡\"名字已使用\"的根因） | `DELETE FROM tbluUsedCharName WHERE ID='账号ID'` |
| `CharInfo` | 角色完整信息（含Status标记O/X） | `DELETE FROM CharInfo WHERE UID=账号UID` |
| `SubCharInfo` | 子角色信息 | `DELETE FROM SubCharInfo WHERE UID=账号UID` |

**注意**：这三张表都在 dbLataleAccount 库中，不是 dbLataleWorld_2。

## 完整角色清除流程（创角卡住/名字已使用）

当创建角色卡在初始界面或提示「名字已使用」时，依次执行：

### 步骤1：查账号
```sql
USE dbLataleAccount
SELECT UID, ID, Name FROM tbluAccount
SELECT * FROM Point WHERE UID='Ciel'
```

### 步骤2：查角色 + 物品残留
```sql
USE dbLataleWorld_2
SELECT uID, charID, charName, lv FROM tbluPC WHERE uID=7
SELECT COUNT(*) FROM tbluItem2 WHERE UID=7
```

### 步骤3：清游戏库
```sql
USE dbLataleWorld_2
-- 清物品（⚠️ 见下方商城已购栏陷阱）
DELETE FROM tbluItem2 WHERE UID=7
-- 清其他角色关联表（所有含CharID或UID的表）
DELETE FROM tbluWorldShared WHERE UID=7
```
其他含CharID的表：tbluQuest, tbluSkill, tbluEffect, tbluQuickSlot, tbluWayPoint, tbluAchieve, tbluAchvMission, tbluMission, tbluPCExt, tbluPCStyle, tbluPCProfession, tbluPCContainer, tbluCoolTime, tbluEventMission, tbluFestival, tbluTitle, tbluCollectMob, tbluCollectItem, tbluMyPoint, tbluFriendList, tbluBlockList, tbluCardBinder, tbluSubPC, tbluPCIndun, tbluPCPVP, tbluRandomQuestList, tbluItem2Old, tbluLimitDropChar

### 步骤4：清账号库（最重要——角色名占用在此）
```sql
USE dbLataleAccount
DELETE FROM tbluUsedCharName WHERE ID='Ciel'
DELETE FROM CharInfo WHERE UID=7
DELETE FROM SubCharInfo WHERE UID=7
DELETE FROM tbluWorldPC WHERE UID=7
```

### 步骤5：验证
```sql
USE dbLataleWorld_2
SELECT COUNT(*) FROM tbluItem2 WHERE UID=7
USE dbLataleAccount
SELECT COUNT(*) FROM tbluUsedCharName WHERE ID='Ciel'
```

## 商城已购栏陷阱（重要）
`DELETE FROM tbluItem2 WHERE UID=X` 会删除该账号下**所有**角色的所有物品，包括：
- 背包里的物品
- 装备栏里的物品
- **商城已购栏（购买后未取出的物品）** —— 玩家把时装放到商城已购栏准备转移时，数据仍在tbluItem2中，会被一起删掉
- 仓库里的物品
- 快捷栏里的物品

商城已购栏不是走单独数据库表的，它只是tbluItem2中容器状态未变更的物品。删除前必须确认该账号下没有未领取的商城购买物品。

## tbluCashShop表确认
两个库（dbLataleWorld_2和dbLataleAccount）中的tbluCashShop表只有ShopID和Cnt两列，无UID/CharID列，且始终为空。商城暂存栏不是走数据库的，而是服务端exe内存管理。

## 角色删除操作
必须先清空背包再标记删除，否则服务端可能拒绝删除：
```sql
BEGIN TRANSACTION
-- 1. 清空角色所有物品
DELETE FROM tbluItem2 WHERE UID=<UID> AND CharID=<charID>
-- 2. 标记删除
UPDATE tbluPC SET Del=1 WHERE UID=<UID> AND charID=<charID>
COMMIT TRANSACTION
```

## 数据库备份与恢复

### 版本兼容性
JSQL2008是SQL Server 2008 R2（内部版本号663）。SQL 2014（版本782）的mdf文件无法附加到此实例，报错：
`数据库 'xxx' 的版本为 782，无法打开。此服务器支持 663 版及更低版本。不支持降级路径。`

### 推荐备份方式（.bak文件）
```sql
BACKUP DATABASE [dbLataleWorld_2] TO DISK = N'D:\LaTale\db_backup_now\xxx.bak' WITH INIT
BACKUP DATABASE [dbLataleAccount] TO DISK = N'D:\LaTale\db_backup_now\xxx.bak' WITH INIT
-- 还原
RESTORE DATABASE [dbLataleWorld_2] FROM DISK = N'D:\LaTale\db_backup_now\xxx.bak' WITH REPLACE
RESTORE DATABASE [dbLataleAccount] FROM DISK = N'D:\LaTale\db_backup_now\xxx.bak' WITH REPLACE
```

### mdf文件替换法（仅限同版本）
1. `net stop MSSQL$JSQL2008`
2. 复制旧mdf/ldf覆盖 `C:\JSQL2008\MSSQL10_50.JSQL2008\MSSQL\DATA\`
3. `net start MSSQL$JSQL2008`
4. 如果报\"可疑或恢复挂起\"：`EXEC sp_resetstatus 'dbLataleWorld_2'`
5. 如果报\"版本xxx无法打开\"：跨大版本不兼容，找同版本的mdf源

### 可用恢复源
`C:\JSQL2008x\JSQL2008\MSSQL10_50.JSQL2008\MSSQL\DATA\` 存放着同版本（SQL 2008 R2）的彩虹岛数据库文件。

### 还原后Bay/Room崩溃修复（ODBC登录失败）
mdf替换后Bay/Room报 `m_GameDB.DriverConnect : [FAILED]` / `ODBC SQL Server Driver 登录失败`，原因是数据库用户和服务器登录名映射失效：
```sql
-- 1. 重启SQL Server
-- 2. 设多用户模式
ALTER DATABASE [dbLataleWorld_2] SET MULTI_USER
ALTER DATABASE [dbLataleAccount] SET MULTI_USER
-- 3. 修复孤立用户映射
USE [dbLataleWorld_2]
EXEC sp_change_users_login 'Auto_Fix', 'sa'
USE [dbLataleAccount]
EXEC sp_change_users_login 'Auto_Fix', 'sa'
```
如果设MULTI_USER时报\"单用户模式，当前已有用户连接\"，重启SQL Server服务后再试。

### 当前数据库状态（2026-06-06备份）
- db_backup_now/ 目录下：当前最新完整备份（.bak），包含清库后重建的角色
- db_backup_now/ 目录下：来自JSQL2008x的mdf备份（月98级带装备）

## UID7角色列表
| charID | 角色名 | 等级 | 备注 |
|--------|--------|------|------|
| 11539 | 雪儿 | 5 | 已删 |
| 11541 | 月 | 97/98 | 主角色（JSQL2008x旧数据），最近一次新建月=11552(3级) |
| 11542 | 2333 | 1 | 已删 |
| 11543 | 999 | 31 | 未删 |
| 11549 | G大哥 | 1 | 旧端角色 |
| 11552 | 月（新版） | 3 | 清库后重建 |
| 11553 | 咕西 | 1 | 清库后重建 |

月咪（98级，月的前身）的charID已不可查，其装备清单：白色恋人爱心羽翼法杖、白色丝袜、不二喵裙装、白色迷你裙、可爱的花冠面纱、星星月亮耳环。

⚠️ **角色名乱码**：sqlcmd输出中文时显示为乱码（编码问题），实际数据库存的是正确中文。用Python decode('gbk') 或在工具/客户端看可正常显示。

## 常见排查

## 登录密码错误

tbluAccount.PW存的是明文密码。如果账号在旧库有数据但登录报错，检查是否有加密校验（dbgls.dll或exe层），直接改密码为123456测试。若写入被拒（"回避恢复模式"），需先设数据库为ONLINE+MULTI_USER。

## SQLCMD输出中文乱码

在bash(git-bash)中使用sqlcmd时，中文输出显示为乱码（GBK编码被终端当UTF-8解码）。两种处理方式：

**方案A**：在Python中subprocess调用sqlcmd，用decode('gbk')解码输出
```python
import subprocess
proc = subprocess.run(['sqlcmd', ...], capture_output=True)
text = proc.stdout.decode('gbk')
```

**方案B**：用PowerShell的 `sqlcmd -f 65001`（但bash下不可用）

**注意**：数据库中实际存储的中文是正确的，乱码只是终端显示问题。
