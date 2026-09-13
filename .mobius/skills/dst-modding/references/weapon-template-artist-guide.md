# 武器模板 + 画师动画说明参考

## 用途

给画师/单主提供武器制作的完整参考，包含：
1. 完整的 DST 武器 mod 目录结构
2. 武器 prefab 代码模板（书砸人示例）
3. 给画师的动画需求说明
4. 用游戏现带动画做占位的技巧（让mod立即可运行测试）

## 典型场景

单主需要做一个书砸人的武器，问"应该怎么画"——你需要：
1. 新建一个完整可运行的武器模板mod（含modmain、modinfo、prefab）
2. 从游戏 data/anim/ 拷贝现带动画做占位，让mod能立即进游戏测试
3. 写一份给画师的动画需求说明，涵盖动画帧设计、参考动作、需要哪些资源

## 制作可运行武器模板的步骤

### 1. 建mod目录结构

```
book_weapon_template/
├── modinfo.lua
├── modmain.lua
├── 画师动画说明.txt
├── 动画结构参考.txt           # 完整帧清单+DST动画机制说明
├── modicon.tex/.xml          # 占位图标（可从其他mod复制）
├── anim/                     # ← 拷贝游戏现带动画过来
├── scripts/
│   └── prefabs/
│       └── book_weapon.lua
└── images/
    └── inventoryimages/
        └── book_weapon.tex/.xml
```

### 2. 拷贝占位动画

从 `data/anim/` 拷贝到 `anim/`。推荐组合：

| 用途 | 源文件 | 说明 |
|------|--------|------|
| 本体显示 | `books.zip` | 书的样子（Wendy的书） |
| 手持攻击 | `swap_batbat.zip` | 蝙蝠棒砸的动作，模拟书砸人 |
| 备用攻击 | `swap_spear.zip` | 标准近战刺击 |
| 备用 | `swap_cane.zip` | 棍棒动作 |
| 备用 | `swap_books.zip` | 书施法动作（不砸人） |

Python快捷拷贝：
```python
import shutil, os
src = r"C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Together\data\anim"
dst = r"<mod_path>/anim"
for fname in ["swap_spear.zip","swap_batbat.zip","swap_books.zip","swap_cane.zip",
              "spear.zip","batbat.zip","books.zip"]:
    if os.path.exists(os.path.join(src, fname)):
        shutil.copy2(os.path.join(src, fname), os.path.join(dst, fname))
```

### 3. 写prefab代码（占位版）

```lua
local assets = {
    Asset("ANIM", "anim/books.zip"),          -- 占位：书本体
    Asset("ANIM", "anim/swap_batbat.zip"),    -- 占位：手持砸动作
    Asset("ATLAS", "images/inventoryimages/book_weapon.xml"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_batbat", "swap_batbat")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)
    inst.AnimState:SetBank("books")
    inst.AnimState:SetBuild("books")
    inst.AnimState:PlayAnimation("idle")
    inst:AddTag("weapon")
    inst:AddTag("book")
    MakeInventoryFloatable(inst)
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end
    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/book_weapon.xml"
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(34)
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    MakeHauntableLaunch(inst)
    return inst
end
return Prefab("book_weapon", fn, assets)
```

关键：本体用 `books` 动画，手持用 `swap_batbat` 动画，这样游戏里显示为书但攻击动作是砸。

### 4. 占位→最终迁移

画师做完动画后，改 `book_weapon.lua` 中三处：

```lua
-- 1. assets 表的动画路径
Asset("ANIM", "anim/book_weapon.zip"),
Asset("ANIM", "anim/swap_book_weapon.zip"),

-- 2. 本体动画名
inst.AnimState:SetBank("book_weapon")
inst.AnimState:SetBuild("book_weapon")

-- 3. 手持覆盖symbol
owner.AnimState:OverrideSymbol("swap_object", "swap_book_weapon", "swap_book_weapon")
```

### 5. 写画师说明

包含两部分，可放在mod目录下供单主直接转发：

#### 第一部分：动画帧设计（可截图发画师）

**书砸人动作（3阶段，5-8帧）：**

```
frame 1 (预备):  双手抓书，举到右肩后方/脑后，身体略后仰
frame 2 (蓄力):  书举到最高点，身体后仰到最大，书脊朝上
frame 3 (砸下):  身体前倾，书从头顶向前下方砸出，书脊朝前下
frame 4 (命中):  书砸到地面/目标位置，书页散开
frame 5 (收招):  书收回到身边，恢复待机姿势
```

**需要的zip包：**

1. `anim/book_weapon.zip` — build: book_weapon
   - idle (待机)

2. `anim/swap_book_weapon.zip` — build: swap_book_weapon
   - idle (手持待机：抱书在胸前)
   - attack (砸人，见上文帧设计)

**参考动作：**
- 热血教师：老师用教科书打人
- 死神 斑目一角：棍子砸地（把书当棍子）
- DST 火腿棍/蝙蝠棒的 attack 动画

**注意事项：** 书脊朝下砸，不是封面朝下；书本体做厚实些。

#### 第二部分：DST动画结构说明（给画师理解机制）

```
DST武器需要两组动画:

A. 本体 (放在地上) — anim/xxx.zip
   build: 武器名 (如 spear, books)
   必选: idle

B. 手持 (角色手上) — anim/swap_xxx.zip  
   build: swap_xxx (如 swap_spear, swap_batbat)
   必选: idle, attack
   
攻击动作 (attack) 帧序列:
   起手预备 → 蓄力顶点 → 砸下 → 命中(书页散开) → 收回
```

## Spriter/Source-File Workflow (exported/ Directory)

This is the workflow used when the **artist works with Spriter source files** (SCML + PNG sprites), not just compiled `.zip` animations. See `references/scml-standard-weapon-template.md` for the complete SCML template with full XML structure reference.

### Directory Structure

The `exported/` directory mirrors the mod's animation pipeline:

```
exported/<build_name>/
├── BUILD/                    # ← Spriter project output: subdirectories per sprite layer
│   ├── <layer1>/
│   │   ├── <layer1>-0.png
│   │   └── <layer1>-1.png
│   ├── <layer2>/
│   └── ...
├── <build_name>.scml         # Spriter project file (references BUILD/ pngs)
└── 参考_*.scml / 参考_*.png   # Reference files from other mods
```

The `BUILD/` folder is what Spriter outputs after auto-compilation. It contains one subfolder per sprite layer (e.g. `arm_upper/`, `hand/`, `torso/`), each with numbered frame pngs.

### Getting Reference Material

When you need to show an artist what a weapon animation structure looks like:

1. **From Musha mod**: grab `book_skill/` — has a book SCML and single idle png
2. **From Musha mod**: grab `musha_jobbook/` — has multi-tome pngs (warrior, mage, ranger, rogue) + SCML
3. **From Mingsheng mod**: the character's full exported project gives the most complete reference — multiple layers, skeleton structure, SWAP_ICON template

### Compilation Pipeline

```
Spriter (.scml + .png)  →  Autocompiler / Krane  →  anim/<build>.zip
                              ↓
                     exported/<build>/BUILD/
```

The `anim/` zip is what DST actually reads at runtime. The `exported/` source files are what the artist edits in Spriter.

### Key Paths

| Component | Path | Note |
|-----------|------|------|
| Source (Spriter) | `exported/<name>/<name>.scml` | Edit this in Spriter |
| Frames | `exported/<name>/BUILD/<layer>/<layer>-N.png` | Auto-generated by Spriter |
| Runtime | `anim/<name>.zip` | Compiled, what DST loads |

### Writing SCML By Hand

When the artist provides png frames in `exported/<name>/BUILD/`, you may need to **write the SCML files by hand** rather than copying from other mods (most are empty 0KB placeholders).

Key rules:
- entity name = build name (must match `SetBank()` / `OverrideSymbol()` in Lua)
- folder path includes subfolder: `BUILD/BUILD-01.png`, not `BUILD-01.png`
- pivot: weapons use (0.5, 0.5) = center
- animation keys: `mainline key` + matching `timeline key`, linked by folder/file id

See `references/scml-standard-weapon-template.md` for complete XML templates and common pitfalls.

### What to Say to the Artist

When the user has an `exported/book_weapon/BUILD/` directory ready:

> 动画源文件在 `exported/book_weapon/` 下。BUILD文件夹已经建好，里面放你的png分帧。
> 
> 参考：
> - `参考_book_skill.scml` / `参考_book_skill_idle.png` — Musha的书动画
> - `参考_战士书.png` / `参考_法师书.png` / `参考_游侠书.png` / `参考_盗贼书.png` — 各种风格的书
> - `参考_明生角色/` — 完整角色Spriter项目
>
> 需要的动画：
> 1. 书本体 `book_weapon` — idle
> 2. 手持 `swap_book_weapon` — idle, attack
>
> attack动作：书脊朝下砸，3阶段（预备→砸下→命中），参考batbat的动作结构

## 完整模板目录结构（最终）

```
book_weapon_template/
├── modinfo.lua                 # 模组信息
├── modmain.lua                 # 注册prefab + Assets
├── 画师动画说明.txt            # ← 直接给画师看
├── 动画结构参考.txt            # ← 完整DST武器动画机制
├── modicon.tex/.xml           # 占位图标
├── anim/
│   ├── books.zip              # 占位：书本体
│   ├── swap_batbat.zip        # 占位：砸动作
│   ├── swap_spear.zip         # 备用
│   ├── swap_books.zip         # 备用
│   ├── swap_cane.zip          # 备用
│   ├── spear.zip              # 备用
│   └── batbat.zip             # 备用
├── scripts/
│   └── prefabs/
│       └── book_weapon.lua    # 占位版代码
└── images/
    └── inventoryimages/
        └── book_weapon.tex/.xml
```

## 可用DST手持武器动画源列表

从 `data/anim/` 可用作占位的手持武器动画（swap_前缀）：

| 文件 | 动作风格 | 最适合模拟 |
|------|---------|-----------|
| swap_spear.zip | 前刺 | 长矛/剑 |
| swap_batbat.zip | 挥砸 | 锤/棍/书砸人 |
| swap_cane.zip | 轻挥 | 手杖/短棍 |
| swap_books.zip | 施法摊开 | 法术书 |
| swap_axe.zip | 劈砍 | 斧/大刀 |
| swap_hammer.zip | 下砸 | 锤子 |
| swap_blowdart.zip | 吹箭 | 远程 |
| swap_boomerang.zip | 投掷 | 回旋镖 |

可用本体动画源：
| 文件 | 样子 |
|------|------|
| books.zip | 书 |
| spear.zip | 长矛 |
| batbat.zip | 蝙蝠棒 |
| cane.zip | 手杖 |
