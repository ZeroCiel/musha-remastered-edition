---
name: hermes-data-migration
description: Backup, migrate, or restore Hermes Agent data (memory, skills, chat history, API keys) between machines. 用户要备份/转移/恢复 Hermes 数据（技能、记忆、聊天记录、密钥）、换机器、重装系统前备份时使用。与内置 hermes-agent 技能互补（那个管配置，这个管数据搬运）。
---

# Hermes 数据备份/迁移/恢复

## 触发条件
用户要求备份/转移/恢复 Hermes 数据（技能、记忆、聊天记录、密钥），换机器、重装系统、异地保存。

## 数据目录
Windows: `C:\Users\<user>\AppData\Local\hermes\`（即 HERMES_HOME）

## 必须打包的内容
| 路径 | 内容 | 备注 |
|---|---|---|
| memories/MEMORY.md + USER.md | 记忆 + 用户画像 | 核心 |
| skills/ | 全部技能（含自建技能） | 核心 |
| state.db + state.db-shm + state.db-wal | 全部聊天记录/日记 | session_search 数据源，三个文件必须一起拷 |
| sessions/ | 请求 dump | 补充 |
| cron/ + scripts/ | 定时任务 + 脚本 | 别忘了，cron 引用的脚本在里面 |
| SOUL.md | 人设 | |
| .hermes_history | CLI 历史 | |
| config.yaml + .env | API 密钥 | 文件级单独复制，见坑 2 |

## 关键决策：日记（聊天记录）要放吗
**要。** 聊天记录存在 state.db 里，session_search 查历史全靠它。只带技能+记忆 = 恢复后知道"用户是谁"但查不到以前干过什么，项目上下文（NPCTRADE、DST 明生、ONI 那些坑）全丢。用户问"日记要不要放"时直接答：放，并解释原因。

## 步骤
1. 一次性打包所有文件（tar 不能追加压缩包！）：
   `cd <HERMES_HOME> && tar czf /d/备份/Hermes_Data/hermes_backup_$(date +%Y%m%d).tar.gz memories skills sessions cron scripts SOUL.md .hermes_history state.db state.db-shm state.db-wal`
2. 密钥单独文件级复制：`cp .env config.yaml <备份目录>/`
3. 校验：`tar tzf <包>` 列内容，`grep -c` 数密钥字段确认拷贝完整
4. 恢复：解压到新机器的数据目录，密钥文件放回原位
5. 提醒用户：备份含密钥 = 敏感，别传公开渠道（网盘/聊天软件），U盘或加密压缩

## 坑
- **tar 不能向已压缩归档追加文件**（报 "Cannot update compressed archives"）→ 要么一次打全，要么后续文件直接 cp 进备份目录，不要试图 tar r/rf 追加
- **Hermes 终端输出打码密钥**（config.yaml 的 redact_secrets: true）：grep/cat .env 里密钥值显示为 `***`，读不到明文 → 转移密钥靠文件级 cp，不要尝试读取后重写
- **state.db 体积**：250MB+，tar.gz 压缩后约一半（129MB）；Hermes 运行中打包时 wal 可能有未合并数据，db/shm/wal 三件套一起拷
- config.yaml 里可能有密钥存在非 .env 位置（本机实例在 openai.api_key 段存了讯飞星火 key），迁移前 grep config.yaml 的 api_key 别漏

## 参考
- 用户备份位置：`D:\备份\Hermes_Data\`（示例产物 hermes_backup_YYYYMMDD.tar.gz + .env + config.yaml）
- 本机实际生效密钥：DEEPSEEK_API_KEY、DASHSCOPE_API_KEY（.env）+ 讯飞星火 api_key（config.yaml openai 段）
