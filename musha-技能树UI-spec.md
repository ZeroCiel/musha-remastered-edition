# 技能树 UI 规格（横向拖动 + 图标 + 悬停说明 + 竖线前置）

> 2026-09-18 用户口述定稿（原话见文末）。**这是法师线的前提**：
> 法师是唯一允许多技能的职业（设定里的唯一例外），多技能必须靠这套树来"看+点"。
> 现状：面板技能页 = `scripts\screens\musha_panel_screen.lua`（竖排、文字在图标后面、无连线、不可拖）

---

## 一、交互规格（用户原话 → 可执行）

| # | 要什么 | 落地做法 |
|---|---|---|
| 1 | **左右拖动**看技能目录 | 容器用横向 `ScrollingGrid`（已有）或 ScrollableList；鼠标按住拖动 = 平移整棵树，不翻页 |
| 2 | 技能格**只显示图标** | 每个节点 = 1 个 `ImageButton`（图标 + 等级角标 "Lv2/3"），**图标后面/旁边不放任何说明文字** |
| 3 | **鼠标移上去才显示内容**（文字 + 主体） | 复用 `scripts\widgets\musha_item_info.lua` 的悬停信息面板（已有 `PinBottomRight()`，物品栏在用）→ 技能节点 hover 时喂：名称 / 效果人话（`SKILL_UI.fmt`）/ 前置要求 / 消耗技能点 |
| 4 | **竖线 = 前置依赖** | 节点之间画直线：只有前置技能达到要求等级，后面的节点才可点（灰 → 亮）。线用 1px `Image` 拉伸（竖线/斜线各一种），坐标由节点位置算 |
| 5 | 渲染不好看 → 用**旧版文字框架** | `scripts\widgets\musha_text.lua`（`MushaText`：直设字号，不走 `LOC.GetTextScale()`；有 SetColour/SetSize/SetFont/旋转/缩放）。现在只有 `musha_note_screen.lua` 在用，新树 UI 直接 require 它 |

## 二、数据规格（技能树 = 节点 + 前置 + 坐标）

```lua
-- 现在的渲染源（musha_profession_component.lua:969 / :978）：只有顺序，没有坐标和前置
local SKILL_ORDER = { saber = { "slash_qi", "last_stand" }, guardian = { "iron_will", "life_leech" }, ... }
local SKILL_UI    = { saber = { slash_qi = { name = "剑气斩", fmt = function(v) ... end, tip = "..." } } }
```

要加一张**布局表**（建议放在同一个文件、紧跟 SKILL_ORDER）：

```lua
-- x/y = 图标在树里的格子坐标（列/行）；req = 前置（技能ID → 需要的最低等级）
local SKILL_TREE_POS = {
    saber = {
        slash_qi   = { x = 0, y = 0, req = {} },                    -- 根节点
        last_stand = { x = 1, y = 0, req = { slash_qi = 1 } },      -- 需要剑气斩 1 级
    },
    guardian = {
        iron_will  = { x = 0, y = 0, req = {} },
        life_leech = { x = 0, y = 1, req = { iron_will = 1 } },
    },
    mage = { ... },   -- 法师那一版：多技能 + 多条前置链，全靠这张表撑
}
-- 图标：images/musha_skill_icons/<tree>_<skill>.png（64²，走 inventoryimages 那套 tex/xml 流程）
```

**加点判定（服务端）**：`CanUpgradeSkill` 里已有的门槛（角色等级 + 技能点 + 技能书解锁技）再加一条 → **前置未达标直接返回"需要先学 X"**（客户端也要灰掉，防改包）。

## 三、分步与估期

| 步 | 内容 | 估期 |
|---|---|---|
| **S1 只读树**（先看得到） | 横拖 + 图标 only + hover 说明（复用 item_info）+ 竖线前置（灰/亮）+ `MushaText` 换文字 | **1.5~2 天** |
| **S2 加点**（能点） | 节点点击 → 已有 RPC `musha_skill_upgrade`（`rpcs\musha_rpcs.lua:126`）+ 前置校验 + 面板刷新 | **0.5~1 天** |
| **S3 拖入快捷栏生效**（你真正想要的那半） | 槽位数据 + 按键 + 冷却显示 + 联机同步 + 存档 | **2~3 天**（有 `references\mingsheng-drag-sort-complete-guide.md` 抄本，原 3~5 天） |

依赖顺序：**S1 → S2**（这两个是法师的前提）→ S3 可以晚（法师那波一起做）。

## 四、已定（2026-09-18 用户逐条回答）

| # | 问题 | 用户答复 → 落地 |
|---|---|---|
| 1 | 旧版 2.0 源码在哪 | **Gitee `ZeroCiel/Musha-beta`**（2022-02-16 那版 = 2.0）。已 clone 到 `D:\wsl-dl\Musha-beta`；关键文件已抄进工程 `references\musha_beta_2.0\`：`my_image.lua`（**旧文字框架**）、`_animbutton.lua`、`Norse_mythology_System.lua`（旧 Wiki/技能页）、`08.Musha_Skill.lua`、`Musha_All_Career.lua`。另 clone 了 `ZeroCiel/norse_mythology`（原 Musha 三期代码转型）到 `D:\wsl-dl\norse_mythology` |
| 2 | 拖拽怎么实现 | **抄明生的拖拽排序，改横向**（抄本 `references\mingsheng-drag-sort-complete-guide.md`） |
| 3 | 两本书命名 | 「**剑士徽记 / 近卫徽记**」，我直接写码 |
| 4 | 技能图标 | **先用普通灰色图占位**（我程序化生成），之后换正式图 |
| 5 | 竖线风格 | **以横线为主的正交连线**（横+竖）；**斜线只用来连"其它技能"——那种连法只有法师才用得上** |

### 旧版"文字框架"到底是什么（2026-09-18 挖出来的真相）

`references\musha_beta_2.0\my_image.lua` = `My_Image` 控件：**图片控件自带一个文字子控件**
（`self.text = self:AddChild(Text(NEWFONT, 40))`，可设色 / `VAlign = ANCHOR_MIDDLE`），
旧版所有菜单、书页、提示都用 `MyImage(atlas, tex, default_tex, 文字)` 这一种控件拼出来 —— 所以看着统一、美观：
**排版由图片定，文字挂在图片上，不走 `LOC.GetTextScale()`**。
→ 新树 UI 照这个模式做：**图标控件自带 hover 文本**（而不是像现在的面板那样用裸 `Text` + 手写坐标，所以容易飘）。


## 六、临时双版开关（2026-09-18 用户拍板）

**技能页右上角并排两个橙色按钮**（未选中 = 灰色，选中 = 橙色）：

| 按钮 | 作用 |
|---|---|
| 按钮 1 | 切 **旧版竖排**（现在的技能页 = `musha_panel_screen.lua` 那套排布） |
| 按钮 2 | 切 **新版横排**（本 spec 的横向技能树） |

**生命周期**：这是**临时**开关 —— **更新到法师那一版时，把旧版竖排和这两个按钮一起删掉**。
用户原话的分量：直接砍掉旧版上新版，"用户的意见肯定是太高灵感、好看，但后面肯定挨骂" →
所以先留退路（一键切回），等法师版验证过了再拆。

**默认值**：默认 = **新版横排**（你要看效果）；旧版一键可切回。选择存进玩家设置（`musha_player_settings.lua`，跟其它设置页开关同一套），重进游戏记得住。



## 七、用户原话（2026-09-18）

> 拖动可以向右 左右拖动显示技能目录 不在后面显示技能说明 只有图标，移动上去才显示内容，文字和主体，
> 如果渲染有问题 去找 musha2.0 版本旧版本的代码，用那边的文字框架，美观很多。
> 但是要做竖线————也就是必须加点哪些部分，才能加点后来哪些部分，这个是魔法师的前提。
