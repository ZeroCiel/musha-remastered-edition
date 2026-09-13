# SKILL.LDT 技能名/描述编码错位修复记录（2026-06-06）

## 现象
- 技能名显示为"饭骇捞"、"剧颊八 付胶磐府[檬鞭]"、"沥飞狼 泪犁仿"
- GS启动报 `SKILL_USE.LDT : FAILED ! Not Exist in Skill.LDT (iKey = 8000302)`
- 世界频道发消息出现乱码如"饭骇捞 何练钦聪促"

## 根因
原文本用UTF-8编码写入SKILL.LDT，彩虹岛编辑器按GBK解码读取，字节边界错位。这是**不可逆的编码损坏**——3字节UTF-8被拆成2字节GBK读，无法还原原始字符。

SPF编辑器只负责解包/打包，不校验LDT内部数据编码，所以打包工具不会报错。

## 修复流程

### 准备工作
- 当前端：D:\LaTale\S4\resource\ROWID\DATA\XLS\SKILL.xls（要修的文件）
- 对照端：D:\ROWID\DATA\XLS\SKILL.xls（怀旧端，文本正常） 或 D:\LaTale\彩虹岛S3\ROWID\DATA\XLS\SKILL.xls（S3台服版）
- 备份原xls文件（.bak）

### ID体系验证
当前端和对照端的SKILL ID体系不同版本的**不能直接套用**：
- S4他乡端：ID=8000301/1000015系列，42列
- 版本B怀旧端：ID=3000217/7001131系列，44列
- S3台服：ID=8000301/1000015系列，42列（与S4一致）

ID体系一致的才能按ID匹配替换_Name和_Description。

### Name乱码判断标准
```python
cjk = sum(1 for c in name if '\u4e00' <= c <= '\u9fff')
is_garbled = cjk < len(name) * 0.3 if len(name) > 0 else True
```
CJK统一表意文字占比<30%则判定为乱码。

### 结果
- 从S3对照修复：Name 1846条（+3条S3特有），_Description 16条
- 仍有2213行Description残留"饭骇"——S3的描述大部分也是乱的
- XLS改好后必须用彩虹岛编辑器写回SKILL.LDT才能生效

## 注意
- 改xls不改LDT，GS加载的还是旧数据，会继续报 `Not Exist in Skill.LDT`
- SAVEPOINT.LDT的繁转简同样需要在xls上操作再写回LDT
- 不能用等长二进制替换修复编码错位——字节本身就是错的
