# 2026-06-07 野外同步问题 + SAVEPOINT繁转简补充

## 野外同步异常（掉怪/掉线/无伤害）

### 现象
- 野外怪物从天上掉下来
- 打怪无伤害（新建1级号用初始武器也一样）
- 掉线
- 城内/副本正常

### 已排除的原因
1. **SPF资源包** — 换AJJIYA/ROWID/JINSSAGA三个包，无效
2. **GS exe版本匹配** — 试了3种：
   - S4他乡端 GS101 4MB（LataleGameServer101.exe）
   - 普通端 GS 2.6MB（LataleGameServer.exe 复制为 GS101）
   - S1旧版 GS 2MB（GameServer101.exe，2016年）
   均无效
3. **客户端exe匹配** — 确认客户端exe(3.8MB 2020版)与服务端GS101配套，仍无效
4. **网络参数** — configure.ini的SendBuffSize/RecvBuffSize调大无效
5. **版本校验** — SkipVersionCheck=1 已设

### 结论
根因推测为服务端exe本身（阉割版）不具备正常的战斗同步功能，非LDT/SPF/配置可解决。

### 已知能正常工作的版本
`D:\LaTale\彩虹岛S1` — S1单机端
- 服务端GS: GameServer101.exe (2MB, 2016版)
- 客户端: LaTaleClient.exe (6.9MB, 2012版)
- 互相配套，野外/战斗正常但功能有限

## SAVEPOINT.xls 繁转简补充

### 首次替换遗漏的繁体字
| 繁体 | 简体 | 出现次数 |
|------|------|---------|
| 稱 | 称 | 6 |
| 礦 | 矿 | 5 |
| 經 | 经 | 12 |
| 歷 | 历 | 4 |
| 險 | 险 | 4 |
| 領 | 领 | 14 |
| 蕭 | 萧 | 1 |
| 蹤 | 踪 | 3 |

### 验证残留集合
```python
checks = '稱礦領戰鬥經歷冒險領域經蕭蹤'
# 搜GBK编码是否存在
for ch in checks:
    n = data.count(ch.encode('gbk'))
    print(ch, n)
```

### GLOBAL_STRING消息ID翻译（简体对照）
80011~80020, 90001~90016 这些消息的繁简体文本基本一致（"字元→字符"、"数位→数字"等极个别差异），可直接用。80018和80019有乱码需从编辑器XLS中取原始文本校对。
