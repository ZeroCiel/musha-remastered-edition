# dbLataleAccount 数据库表结构

连接到 `dbLataleAccount` 后可用 `SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES` 查询完整列表。

## tbluAccount (账号表) ⭐ 核心

| 列名 | 类型 | 空 | 说明 |
|---|---|---|---|
| UID | int | NO | 自增主键 (IDENTITY)，禁止手动插入 |
| ID | varchar(20) | NO | 登录账号名 |
| PW | varchar(20) | NO | 密码 (明文) |
| mail | varchar(50) | YES | 邮箱 |
| latestLoginTime | datetime | YES | 最后登录时间 |
| failedLoginTimes | tinyint | YES | 失败登录次数 |
| createdTime | datetime | YES | 创建时间 |
| Block | tinyint | NO | 封禁标志 (0=正常) |
| Name | varchar(50) | YES | 显示名 |
| SSN | varchar(20) | YES | 身份证号 (韩国游戏用) |
| Gender | tinyint | YES | 性别 |
| NickName | varchar(50) | YES | 昵称 |
| DigitID | bigint | YES | 数字 ID |
| BlockTime | datetime | YES | 封禁时间 |
| ip | varchar(50) | YES | 注册 IP |
| tid | int | YES | - |
| ElaspedMin | int | YES | 在线时长(分钟) |
| IsOnlineStatus | tinyint | YES | 在线状态 |
| yhcj | int | YES | - |
| djfl | int | YES | - |
| jqm | varchar(200) | YES | - |
| mxfl | int | YES | - |

⚠️ 该表有 INSERT/UPDATE 触发器，不能用 OUTPUT 子句。

## tbluGM (GM 表)

| 列名 | 类型 | 说明 |
|---|---|---|
| GMNum | int | GM 编号 |
| GMID | varchar(20) | GM 账号 |
| GMPW | varchar(20) | GM 密码 |
| GMPermit | tinyint | 权限等级 |
| GMName | varchar(20) | GM 显示名 |
| GMSubPermit | tinyint | 子权限 |

## tblsSystem (系统配置)

| 列名 | 类型 | 说明 |
|---|---|---|
| var | char(20) | 配置键 (如 'KeyCashShop') |
| value | bigint | 配置值 |

## tblsWorldList (世界列表)

| 列名 | 类型 | 说明 |
|---|---|---|
| wid | int | 世界 ID |
| name | varchar(50) | 世界名称 |
| lobbySID | int | 大厅服务器 ID |
| ip | varchar(16) | IP 地址 |
| port | int | 端口 |
| enable | bit | 是否启用 |
| sortIndex | int | 排序 |

## 其他重要表

- **CharInfo** / **SubCharInfo**: 角色信息 (MemberID, WorldID, CharName, Class, Level, Money 等)
- **mem_acct**: 游戏账号与会员账号关联
- **tbluUsedCharName**: 已使用的角色名
- **GuildInfo** / **GuildCharInfo**: 公会信息
- **ItemInfo**: 商城道具信息
- **Gift** / **GiftInfo**: 礼物/赠品
- **Point**: 点数余额
- **tbluVIP**: VIP 信息
