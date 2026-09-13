# 用 Python 脚本批量编辑 Lua 的坑（DST mod）

用脚本（str.replace / 正则）批量改大 Lua 文件（如 3000 行的 speech 文件）容易引入语法错误。真实踩过的坑：

## 坑 1：替换匹配串吞掉行尾逗号
- `"KEY = \"value\""` 匹配串若**不含行尾逗号**，原文件 `KEY = "value",` 会被替换成 `KEY = "newvalue"`（逗号被吞）→ 后续字段语法断裂
- **规则**：替换串永远带原行行尾的逗号；或替换后检查新行尾有没有逗号
- 本例：`ANNOUNCE_HOT = "Need... ice... or... shade!"`（原带逗号）替换后丢逗号 → `'}' expected near 'ANNOUNCE_INSANITY'`

## 坑 2：插入块插到表外面
- Lua 多行表定义：`\tDESCRIBE =\n\t{ ... }`——`DESCRIBE =` 和 `{` 之间**不能**插内容
- 用 `src.replace("\tDESCRIBE =\n", "\tDESCRIBE =\n" + block)` 会把 block 插在表和 `{` 之间（表外）→ 语法错乱
- **规则**：锚点要包含 `{`：`"\tDESCRIBE =\n\t{"`，block 插在 `{` 之后

## 坑 3：孤立逗号 / 重复 key
- 插入块末尾 + 原文件残句可能拼出单独一行 `,`（语法错误）
- 插入块的 key 若与原文件已有 key 重复（如 ANNOUNCE_CRAFTING_FAIL），Lua 不报错但**后者覆盖前者**——中文会被后面的英文原句覆盖。插入前 grep 目标 key 是否已存在

## 验证：luaparser（推荐）
```bash
python -m pip install luaparser
```
```python
from luaparser import ast
ast.parse(open(path, encoding='utf-8').read())  # 抛 SyntaxException = 有错
```
- 错误信息常是 `syntax errors: None`（antlr 恢复机制），不提供行号——用**对照法**定位：解析官方同类型文件（如 data/databundles/scripts/speech_wilson.lua）确认工具本身无误报，然后二分截断文件找失败段
- 官方文件都能过 = 工具可靠，报错就是我们文件的真实问题
- 也可对全项目批量跑：改过的 lua 全量 parse，一次抓完所有语法错

## 其他
- write_file 保存 python 脚本时注意三引号字符串里的转义（\n、\t 会被解释）；本案例插入块用真实 Tab 缩进没问题
- 中文内容用 utf-8 读写（`io.open(path, 'w', encoding='utf-8')`）
- 批量替换后必须 grep 检查：逗号、孤立 `,`、重复 key、`= "..."` 后跟非字段行
