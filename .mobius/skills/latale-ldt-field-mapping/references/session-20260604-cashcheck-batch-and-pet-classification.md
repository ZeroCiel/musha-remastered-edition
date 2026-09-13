# 2026-06-04 批量改CashCheck 0→1 + 宠物分类修复

## 背景

桌面 item2_clean.txt 经过13轮筛选，从10056条精简到7163条。需要：
1. ITEM_2.LDT 中 CashCheck 0→1（允许上架）
2. CASH_SHOP.XLS 中宠物/宠物装备移到正确分类（Cat=2,7,0）
3. 游戏启动验证

## 重要发现：65536/16777216 污染

**整个ITEM_2.LDT中有大量 65536（0x10000）和16777216（0x1000000）**——这是彩虹岛编辑器/打包工具在保存时产生的位标记值污染了数据字段。

**实测结果**：ITEM_2.LDT（10053行，前48个int列）中 **12830处 65536**。

**影响**：
- 当某个道具的 EffectID / SetID / 或其他int列被污染为 65536/16777216
- CashCheck=0 时 GS跳过该道具 → 没问题
- **CashCheck改为1后 GS完整加载该行 → 发现无效SetID → `SetID does not exist in SETITEM_B` → 崩溃**

**安全流程**：
1. 搜LDT所有int列中值为 65536/16777216 的 → 改为0
2. 再改 CashCheck 0→1
3. 最后改 CASH_SHOP 分类

否则：在7316条中可能有一个道具的SetID被污染，CashCheck改为1后GS启动就崩。

## CASH_SHOP 宠物分类映射

| 类型 | Cat= | 说明 |
|------|------|------|
| 领养券（限时） | 2,7,0 | `企鹅 (15日)`、`想成为英雄的卡哇伊 (15日)` |
| 宠物本体 | 7,23,0 | 怀旧端也是这个分类 |
| 宠物装备 | 7,22,0 | 白虎帽子、企鹅帽子等 |
| 其他宠物装备 | 7,24,0 | 少数几个 |
| 宠物用品 | 2,8,0 | 重置拼图、伤害拼图等消耗品 |

**修复目标**：宠物本体 + 宠物装备都移到 2,7,0

宠物名称关键词：白虎、熊猫、纽扣兔、羞羞兔、金雷欧、布朗妮、马戏团小丑、乔朗伊、卡哇伊、企鹅、浣熊、黑色恶魔、甜美天使、水精灵、九尾狐、鬼火、舞扇忍者、海贼猴、噗波、银河（仅限宠物）、女仆（仅限领养券）、天使（仅限宠物型）

**误判案例**：`阴森住宅女仆裙子`、`大天使手套`、`银河上衣`、`花天使裙子` 等是普通时装而非宠物装备，需要排除。

## ITEM_2.XLS 批量改 CashCheck

彩虹岛编辑器的 .xls 实际上是 **TAB分隔的GBK文本**（非真实Excel），文件头魔数= `Type\t3\t3`。

| 行 | 内容 |
|---|------|
| 第1行 | 列类型号 |
| 第2行 | 列名 |
| 第3行起 | 数据（TAB分隔） |

**CashCheck 在第12列（index 11，0-based）**。
在 XLS 中找到所有该列值为 `0` 的行 → 改为 `1`。可直接用二进制字节替换（不涉及字符串长度变化）。

## 服务器启动验证

| 服务 | 日志文件 | 正常启动标志 |
|------|---------|------------|
| BayServer | `Latalebayserver.log` | 到达 `m_GameDB.DriverConnect : [OK]` |
| GS(101) | `Latalegameserver_101_101.log` | 到达 `CLevelUpManager::Init() : [OK]` |
| GS(102) | `Latalegameserver_102_102.log` | 同上 |
| RoomServer | `Lataleroomserver.log` | 不报 `LoadQuizInfoLDT() : [FAILED]` |
| Lobby | `Latalelobbyserver.log` | 到达所有WorkerThread启动 |

**BayServer崩溃诊断**：
- exit code 139（SIGSEGV）且无dmp → LDT字符串修改破坏了二进制结构
- 停在 `GlobalSys::Init() : [OK]` 无后续 → ITEM_2加载失败
- 停在后续步骤 → 可能是DB连接或其他问题

## GS崩溃 `SetID does not exist in SETITEM_B`

**报错**：
```
Item Info Loading.........SetID does not exist in SETITEM_B     iSetID(65536)
```

**根因**：
- ITEM_2某道具的 SetID 列被污染为 65536
- 该端不存在 `SETITEM_B.LDT` 文件，只有 `SETITEM.LDT`（且全0）
- 改 CashCheck 0→1 前该行被跳过 → 没事
- 改 CashCheck 0→1 后 GS 加载该行全部数据 → 发现无效SetID → 崩溃

**修复**：在 ITEM_2.LDT 中找到 SetID 列值为 65536 的行 → 改为0。
**最佳实践**：成批改 CashCheck 前先全LDT搜 65536/16777216 → 全清0。
