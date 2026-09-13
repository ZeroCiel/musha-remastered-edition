# Musha 装备/属性面板（网游式）设计稿 V1
2026-09-13 用户提出：「武器和装备一类最好我们也能看得到，做成网游面板那样的显示吧？」
本文件 = 设计稿（按用户习惯：**大功能先出设计稿，拍板后再写码**）。

## 0. 一句话
面板里加一块**只读**的"角色装备 + 属性"页：左边 3 个装备格（头/身/手），右边 12 行属性数值，
网游角色面板的排版。**不出手、不改数据**，纯显示。

## 1. 放哪儿（待用户三选一）
- a **改造现有「图鉴」页** —— 图鉴页现在只有一句占位 `图鉴 · 装备表待填`，本来就是留给它的
- b 新加第 7 个导航页「装备」（导航 6 → 7 项，要重排导航条位置）
- c 放在「主页」下半部分（主页已有等级/职业信息，会和属性行重叠，需要挪）
→ 我推荐 **a**（零导航改动，且图鉴页现在的占位文案就是在等这张表）

## 2. 版式（页内区域 890 x 600，内容区约 856 x 566）
```
┌─ 装备 · 属性 ───────────────────────────────┐
│  ┌────┐   生命    120 / 150        │
│  │ 头 │   饥饿     98 / 150        │
│  └────┘   理智    180 / 200        │
│  ┌────┐   能量     40 / 60   ▓▓░░░  │
│  │ 身 │   ─────────────────────    │
│  └────┘   攻击力   34  (+63%)      │
│  ┌────┐   减伤     80%              │
│  │ 手 │   移速     +15%             │
│  └────┘   保暖     120              │
│           隔热     0                │
│           职业     战士 → 剑士 · Lv 12│
│           经验     340 / 520        │
│           技能点   3                │
└────────────────────────────────────┘
```
- 左栏中心 x = -250：装备格 64x64，y = +150 / +60 / -30（竖排），格名小字标在格子左侧
- 右栏中心 x = +170（宽 480），行高 26，**左对齐**用 `SetRegionSize` + `SetHAlign(ANCHOR_LEFT)`
  （DST 坑：只写 SetHAlign 无效；且 SetPosition 指区域中心，不是左缘）
- 数值列右对齐到 x = +400（灰色名称 + 深墨数值，风格同现有书页风）
- 页标题沿用 `PAGE_H/2 - 46` 那一套定位

## 3. 数据来源（已在本机 DST 源码里核对过，⚠️ 有三个反直觉的坑）
| 要显示 | 取法 | 备注 |
|---|---|---|
| 装备槽 | `inst.components.inventory.equipslots[EQUIPSLOTS.HANDS/HEAD/BODY]` | ⚠️ **这版没有 `Inventory:GetEquips()`**（网上教程里那个函数在 data/databundles/scripts/components/inventory.lua 里搜不到）|
| 槽位名单 | `EQUIPSLOTS = { HANDS, HEAD, BODY, BEARD }` (constants.lua:650) | ⚠️ 只有 4 个，**没有 AMULET 槽** |
| 减伤 | `item.components.armor.absorb_percent` | armor.lua:41 InitCondition 写入 |
| 保暖/隔热 | `item.components.insulator:GetInsulation()` | insulator.lua:27 |
| 移速 | `inst.components.locomotor:GetRunSpeed()` / `:GetSpeedMultiplier()` | locomotor.lua:590/594 |
| 生命/饥饿/理智 | 各自 `:GetCurrent()` / `:GetMax()` | |
| 能量 MP | `inst.components.musha_mp`（本项目自建） | |
| 职业/等级/经验/技能点 | `inst.components.musha_profession` / `musha_player_settings` | 面板已有一套读法，复用 |
| ❌ 最终攻击伤害 | **取不到** | ⚠️ 这版 `combat.lua` **没有 `Combat:GetDamage()`**：伤害是在文件内部 `local CalcDamage()`（combat.lua:871 附近）里算的 → 客户端拿不到「最终伤害」 |

## 4. 攻击力怎么办（V1 口径）
- V1 显示 **`combat.defaultdamage` + 加成百分比**（`externaldamagemultipliers` 全表和），
  即 `攻击力 34 (+63%)`，**不显示"最终砍出去多少"**
- 想显示最终伤害 → 需要 V3：加一个 RPC 让服务端用本机同一个算法算好回推（多一次通信，但准）
- 用户拍板点：**V1 够不够**（够 → 不做 RPC；不够 → 排 V3）

## 5. 分期
- **V1（能看）**：装备 3 格（图标 + 名称）+ 12 行属性，纯客户端只读，实时每 0.2 秒刷新
- **V2（能问）**：鼠标悬停装备格 → 弹该装备详情（直接复用 `scripts/widgets/musha_item_info.lua` 的 `BuildLines`）
- **V3（能算）**：最终伤害 RPC（见 §4）；以及装备对比（换装前后差多少）
> 用户原则：**超出就是放飞**。V2 之后没有明确指令就不做 V3。

## 6. 坑清单（写码前先看）
1 `inventory.equipslots` 是**表**不是函数；槽 key 是字符串 `"hands"/"head"/"body"`
2 装备格图标：`item.replica.inventoryitem:GetImage()`（客户端可用）或 prefab 的 atlas
3 该页必须**纯客户端**——服务端算的东西（如最终伤害）不能直接读
4 面板是所有 Screen；悬停面板（右下角那个）也会在面板打开时显示 → 注意不要两层叠在一起
5 刷新频率别每帧重算（ScrollingGrid 会重建行 → 卡）：0.2 秒节流 + 只改文本不重建
