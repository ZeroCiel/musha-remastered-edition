---
name: magic-ring-shop-port
description: 新神魔环(magic-ring)商店系统分析笔记，准备移植到明生mod
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [windows, linux, macos]
---

# 新神魔环商店系统 → 明生移植

## 仓库
- `~/magic-ring/` - 已下载的完整源码（缺 images/shop/ 的 .tex 大图）
- 源码：https://gitee.com/ZeroCiel/magic-ring

## 移植进度（2026-08）
- ✅ **ScrollingGrid 算法已移植**：明生传送框 `mingsheng_teleportscreen.lua` 已重写为
  TEMPLATES.ScrollingGrid 版（固定 4 行 + 下拉滚动；拖拽曾重写但被用户否决，
  终版 = 每行星星热区传送按钮）。完整做法见
  dst-modding skill → `references/scrolling-grid-truescrolllist-api.md`
- ⏳ 商店本体（5 分类 + 商品格子 + 购买 RPC）未开始，需要时加载 dst-modding 参考

## 商店系统结构（原始源码分析）

### 入口（源mod实现）
**按 F（CONTROL_ACCEPT）打开/关闭商店**

`shenmohuan_control_shop.lua`（scripts/widgets/ 下）
- 监听键盘 `CONTROL_ACCEPT` → 触发 `self.owner:PushEvent("shenmohuan_shop_onclick")`
- 支持拖拽+记忆位置（保存到 PersistentString）
- UI 上是一个按钮图 `images/widgets/shop.xml`

`shenmohuan_shop.lua`（scripts/widgets/ 下）
- 监听 `shenmohuan_shop_onclick` 事件 → 切换显隐
- 背景图 `images/shop/shop_widgets.xml`
- 5 个分类标签按钮：`dstitem_list`, `food_list`, `synthetic_list`, `item_list`, `vip`
- 点击标签切换右侧 `ScrollingGrid`（6行4列，自动滚动）
- 默认打开 `dstitem_list`
- 关闭按钮 `images/shop/onclose.xml`
- 商品图标通过 `GetAtlas()` 自动查找 inventoryimages 或 mod 自定义图

### 移植方向（用户偏好：不要自己发明，参考其他mod的现成实现）

**用户明确偏好：不要用 net_bool 模式**（之前试过发现不靠谱）。

使用 `SendModRPCToServer` + `AddModRPCHandler` 模式。

**ScrollingGrid 算法已验证可行**：商店的 `TEMPLATES.ScrollingGrid` 固定大小+下拉算法
已成功移植到明生传送框（mingsheng_teleportscreen.lua，ScrollingGrid 版，含拖拽排序重写）。
完整 API、widget 复用机制、SetShown/scroll_offset 坑 → 见 `dst-modding` 技能的
`references/scrolling-grid-truescrolllist-api.md`。商店本体移植可直接照抄该模式。

## 最直接的参考：明生mod自身已有的RPC

明生mod的 `modmain.lua` 第864行已经有现成的 `AddModRPCHandler`：

```lua
-- mingsheng/modmain.lua:864
AddModRPCHandler("mingsheng", "CONFIRM_TELEPORT", function(player, wp_index, shard)
    if not player or not player:IsValid() then return end
    local storage = player.components.mingsheng_teleport_player
    if not storage then return end
    local wp_list = storage:GetWaypoints(shard or "surface")
    if wp_index < 1 or wp_index > #wp_list then return end
    local wp = wp_list[wp_index]
    -- ... 传送逻辑
end)
```

客户端发送（`mingsheng_teleportscreen.lua` 第286-288行）：
```lua
local rpc_id = MOD_RPC and MOD_RPC["mingsheng"] and MOD_RPC["mingsheng"]["CONFIRM_TELEPORT"]
if rpc_id then
    pcall(SendModRPCToServer, rpc_id, self.selected, "cave")
end
```

## 第二个参考：bronya（workshop-1430350339）的RPC模式

**服务端注册（可直接放在widget文件底部，不一定要modmain.lua）：**
```lua
-- workshop-1430350339/scripts/widgets/bronya_skill.lua:18
AddModRPCHandler("bronya", "chooseskill", function(inst, id)
    if inst.components.bronyaskill then
        local item = id % 10
        local pos = (id - item) / 10
        inst.components.bronyaskill:LearnSkill(pos, item)
    end
end)
```

**客户端发送（按钮点击回调）：**
```lua
-- workshop-1430350339/scripts/widgets/bronya_skill.lua:30
local function fn()
    SendModRPCToServer(MOD_RPC["bronya"]["chooseskill"], self.id)
end
self.avatar:SetOnClick(fn)
```

**无参数RPC示例：**
```lua
-- workshop-1430350339/scripts/widgets/bronya_ui.lua:71
AddModRPCHandler("bronya", "cleanskill", function(inst)
    if inst.components.bronyaskill then inst.components.bronyaskill:ClearSkill() end
end)

-- 客户端：参数可省略
SendModRPCToServer(MOD_RPC["bronya"]["cleanskill"])
```

## RPC参数签名速查

| 方向 | 注册 | 发送 |
|------|------|------|
| 客户端->服务端 | `AddModRPCHandler(ns, name, fn(player, ...))` | `SendModRPCToServer(MOD_RPC[ns][name], ...)` |

- handler 第一个参数自动是玩家实体（inst），后续参数按顺序传
- 无参数时 `SendModRPCToServer(MOD_RPC[ns][name])` 即可，不需要传额外参数
- `MOD_RPC` 表由 DST 自动生成，可以用 `MOD_RPC["ns"]["key"]` 或 `MOD_RPC.ns.key` 两种语法

### 数据来源
`main/Shop.lua`：
- `TUNING.DSTITEM_LIST` - DST基础物品
- `TUNING.FOOD_LIST` - 食物
- `TUNING.SYNTHETIC_LIST` - 合成材料
- `TUNING.ITEM_LIST` - 物品

每条数据格式：`{name="prefab名", diamond=钻石价, price=镇魂币价, size=数量, recycle=回收价, xml=贴图覆盖}`

### 注册方式
`shenmohuan_register.lua`（scripts/widgets/ 下）
- `AddClassPostConstruct("widgets/controls", ...)` 挂载到 controls
- 同时挂载了：`shenmohuan_system`, `shenmohuan_shop`, `shenmohuan_control`, `shenmohuan_control_shop`

### 自定义 ImageButton
`shenmohuan_imagebutton.lua`（scripts/widgets/ 下）- 还未拉取，需要时再下

### 依赖的图片资源
- `images/shop/shop_widgets.tex/.xml` - 商店主背景
- `images/shop/onclose.tex/.xml` - 关闭按钮
- `images/shop/dstitem_list.tex/.xml` - 各分类标签
- `images/shop/food_list.tex/.xml`
- `images/shop/synthetic_list.tex/.xml`
- `images/shop/item_list.tex/.xml`
- `images/shop/vip.tex/.xml`
- `images/shop/itemwidgets.tex/.xml` - 物品格子背景
- `images/widgets/shop.tex/.xml` - 打开商店的按钮图标

注意：.tex 大图还没下到（网络慢），需要时手动从 gitee 下载或使用 mod 自带贴图

## 已落地成果（2026-08-20）

明生传送框已按 ScrollingGrid 算法重写完成（scripts/screens/mingsheng_teleportscreen.lua）：
- TEMPLATES.ScrollingGrid 单列版：widget_width=387, widget_height=65, num_visible_rows=4, num_columns=1, allow_bottom_empty_row=true
- 列表位置 (-5, -15)，滚动条 offset=10
- 条目 = slot ImageButton(scale 0.42, 922x154) + Text(NEWFONT 38) + highlight 图（选中黄色高亮）
- 固定大小+滚轮/滚动条下拉自动生效（TrueScrollList 管理，无需手写 scroll_offset——原代码 scroll_offset 死变量是 bug 根源）
- 拖拽排序最终被用户否决（每行手柄像"骨头"）；终版交互：**每行右侧透明热区(tp_btn, blank.tex 全透明 150x60 @x=120)=传送按钮**，覆盖在 slot 底图自带的星星装饰上，点击=SelectEntry+DoTeleport；底部 confirm 按钮已删（grep 确认无残留），条目本体点击=选择，回车=传送。apply_fn 里要 widget.tp_btn:Show()，不要 drag 相关残留
- **星星是 slot.png 底图自带的装饰，不是 drag.tex**（PIL 列扫描证实；drag.tex 是灰色骨头，用户嫌丑）。判断 UI 元素在底图还是独立图：用 PIL 按列统计 alpha>100 像素数 + 黄色像素数
- DST 坑：Image 没有 SetShown 方法，只有 Show/Hide（神魔环代码里 SetShown 是其自定义 ImageButton 扩展）
- DST 坑：ScaleToSize 是 Image 的方法，ImageButton 上不存在——`btn:ScaleToSize(w,h)` 直接崩溃 "attempt to call method 'ScaleToSize' (a nil value)"，必须 `btn.image:ScaleToSize(w,h)`
- DST 坑：鼠标点击 ImageButton 会被映射成 CONTROL_ACCEPT 事件，焦点不在条目上时冒泡到 Screen:OnControl 的 CONTROL_ACCEPT 分支 → 误触发 DoTeleport。修复：`if not self.drag_mode and not TheInput:IsMouseDown(MOUSEBUTTON_LEFT) then DoTeleport() end` 区分鼠标点击（只选择）和键盘回车（才传送）
- 条目尺寸计算：slot 922x154 * scale 0.42 = 387x65 → widget_width=387, widget_height=65
- Lua 语法检查：hermes venv 无 pip，用系统 Python311（C:\Users\Administrator\AppData\Local\Programs\Python\Python311\python.exe）装 luaparser 后 `ast.parse(src)` 验证，无需 luac
- DST 已挪到 D:\SteamLibrary\steamapps\common\Don't Starve Together（不在 C 盘！）

## 移植决策记录（2026-08-19 → 08-20）

**目标：明生传送框（mingsheng_teleportscreen.lua）固定大小+下拉滚动**

神魔环商店用的是 `TEMPLATES.ScrollingGrid`（6行4列固定），这就是"固定大小+下拉"的标准算法。明生传送框现状问题：
- `self.scroll_offset` 第27行声明、249-250行读取，但**全程从未赋值** → MAX_VISIBLE=4 时第5-7个传送点永久隐形，无滚动手段（这是 bug，不是设计）
- 传送框原有拖拽柄排序功能（drag_handle 换 order），与 ScrollingGrid 的 widget 复用池冲突

方案演进（已定案）：
1. ScrollingGrid + 上下移按钮排序 → 未采用
2. 保留拖拽 + 手写滚轮滚动 → 未采用
3. **ScrollingGrid + displayed_start_index 重写拖拽映射 → 采用了**，拖拽技术上跑通，但用户最终否决拖拽（骨头丑）
4. **终版：ScrollingGrid 纯滚动列表 + 每行星星图标=传送按钮**（见上方"已落地成果"）

ScrollingGrid/TrueScrollList 的机制和接口细节存于 `dst-modding` skill 的 `references/scrolling-grid-truescrolllist-api.md`。
