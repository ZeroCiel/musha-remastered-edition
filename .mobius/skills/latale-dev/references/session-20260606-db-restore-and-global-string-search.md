# 2026-06-06 Session: Database Recovery, Global String Search, SAVEPOINT繁转简

## 数据库恢复关键发现

### C:\JSQL2008x 备份源
`C:\JSQL2008x\JSQL2008\MSSQL10_50.JSQL2008\MSSQL\DATA\` 含有同版本（SQL 2008 R2）的彩虹岛数据库mdf/ldf文件，可作为恢复源使用。文件列表：
- dbLataleWorld_2.mdf (79691776)
- dbLataleWorld_2_1.ndf (58982400)
- dbLataleWorld_2_2.LDF (110100480)
- dbLataleAccount.MDF (23068672)
- dbLataleAccount_1.ldf (11534336)

### D:\LaTale\db_backup_20260605_完整备份 版本不兼容
此目录的mdf是SQL 2014格式（版本号782），当前JSQL2008是2008 R2（版本号663），无法附加。已删除该目录。

### 当前备份位于
- `D:\LaTale\db_backup_now\` — 最新.bak备份
- `D:\LaTale\db_backup_now\*_from_JSQL2008x.*` — 从JSQL2008x复制过来的旧mdf/ldf（停服后复制）

## GLOBAL_STRING 消息文本

"彩虹岛有您更精彩~" 在 ROWID.SPF 偏移 0xf752d2

## SAVEPOINT.xls 繁转简

两轮替换共约1166处：
- 第一轮：764处（常见繁体字）
- 第二轮：402处（补充 經/歷/險/領/稱/礦/蕭/蹤 等遗漏）

## Point表结构确认
- id(int), UID(varchar存登录名如'Ciel'), balance(int), bonus(int)
- UID是varchar存名字不是数字！`SELECT * FROM Point WHERE UID='Ciel'`

## BK文件当前状态
- dbLataleWorld_2: 还原到2026-06-06清库后的状态（月3级+咕西1级，332件物品→已清为新手物品）
- dbLataleAccount: Ciel密码=123456, Point 700+34140
