# DST API 坑速查（2026-08-23 明生 8 月测试报告批量修复实测）

## 不存在的 API（调用即 LUA ERROR，报 `attempt to call method 'X' (a nil value)`）

| 你以为有的 | DST 正确写法 | 场景 |
|---|---|---|
| `TheSim:FindFirstEntityWithGuid(guid)` | 全局表 `Ents[guid]`（判空 + `ent:IsValid()` 防幽灵引用） | 按 GUID 查世界实体是否存活（如记录点绑定木牌） |
| `locomotor:ClearPath()` | `locomotor:Stop()` | 传送/打断移动后清路径 |
| `AnimState:PlayAnimation("oversized")`（farm 作物） | `PlayAnimation("grow_oversized", false)` + `PushAnimation("crop_oversized", true)` | 见 farm-plant-system.md：播不存在的动画名会让贴图+碰撞消失 |

排查"功能没生效/直接报错"先怀疑 API 不存在：DST 组件方法名和 DS 单机、老教程差异很大，报 nil value 先 grep 原版 `data/databundles/scripts.zip` 里对应组件的真实方法名（`unzip -p scripts.zip scripts/components/<name>.lua`）。

## 传送后人物自动走回传送前位置

`Physics:Teleport` / `Transform:SetPosition` 不会清玩家移动状态。传送后立即：
```lua
if player.components.locomotor then
    player.components.locomotor:Stop()
end
if player.ClearBufferedAction then
    player:ClearBufferedAction()   -- 清缓冲动作（可能残留移动指令）
end
```
单人和联机 RPC 服务端传送两处都要加。

## 全屏 Screen 的 CONTROL_ACCEPT 会被鼠标点击触发
- 鼠标点击 UI 空白/背景会映射成 `CONTROL_ACCEPT`，且时序上 `TheInput:IsMouseDown(MOUSEBUTTON_LEFT)` 判断不可靠（抬起瞬间为 false，被误判成"键盘回车"）。
- 结论：**危险动作（传送/消耗/删除）不要放在 Screen:OnControl 的 ACCEPT 分支**，只挂按钮 OnClick（键盘/手柄聚焦按钮后按确认同样触发按钮）。再配合"默认不选中任何条目"，双击边框也不会误触发。
- 若必须支持键盘确认，用选中状态 + 显式按钮，别用裸 ACCEPT。

## 角色命名贴图 region 名规则

- `images/names_<build>.xml` 和 `images/names_gold_<build>.xml` 的 `<Element name>` **必须 = `<build>.tex`**（如 `mingsheng.tex`），不是文件名 `names_mingsheng.tex`。
- 错了的症状：日志 `WARNING! Could not find region 'mingsheng.tex' from atlas '.../names_mingsheng.xml'`，角色名贴图显示异常。
- 其他 atlas（inventoryimages/map_icons/teleport 等）region 名 = 贴图名（代码 imagename 传什么就是什么），只有 names 系列特殊。

## eater 食物拒绝（"太恶心" = 原版 YUCKY 翻译，2026-08-23 实测修正）

**玩家吃食物的真正闸门是 `eater:PrefersToEat(food)`（查 preferseating），不是 CanEat！** 两条路径都查它：
- `stategraphs/SGwilson.lua` 的 `ACTIONS.EAT` handler（~1168 行）：`if not inst.components.eater:PrefersToEat(obj) then inst:PushEvent("wonteatfood")`
- `actions.lua` 的 `ACTIONS.EAT.fn`（~2371 行）：同样 PrefersToEat，false → `wonteatfood`

`wonteatfood` 事件 → player_common `OnWontEatFood` → `ANNOUNCE_EAT.YUCKY`（中文客户端即"太恶心了"）。**CanEat/caneat 只是喂食/其他系统的检查，玩家自己右键吃走 PrefersToEat/preferseating。**

- `preferseating` 默认 = `{ FOODGROUP.OMNI }`。**OMNI.types 实际 = {MEAT, VEGGIE, INSECT, SEEDS, GENERIC, GOODIES}（不含 HORRIBLE！）**——所以"怪物肉能吃、熟肉/南瓜不能吃"这种反直觉现象，说明 preferseating 被改成了含 HORRIBLE 但不含 MEAT/VEGGIE 的列表，或 override 链被别的 mod 覆盖。
- 防御/强制食谱：角色 master_postinit 显式 `SetDiet(diet, diet)`（caneat 和 preferseating 都设；SetDiet 只改数据不改方法）。硬编码 FOODTYPE 列表比 `{FOODGROUP.OMNI}` 稳（OMNI 定义随版本可能变）。
- **排查决策树（决定性调试）**：在 PrefersToEat override 里加 print（食物 prefab/foodtype/preferseating 内容/返回值）：
  1. 吃食物时**没有** `[tag] PrefersToEat` 日志 → override 被其他 mod 覆盖（加载顺序靠后的 mod 直接替换了方法）→ 查冲突 mod
  2. 有日志 + ret=true → 判定没问题，问题在更下游（吃动作/状态机）
  3. 有日志 + ret=false → preferseating 实际内容会暴露被谁改窄
- 之前误以为"PrefersToEat 只影响 AI 偏好、CanEat 才是拒绝闸门"——**错**，玩家自吃路径全走 PrefersToEat。
- **最终修复方案（2026-08-23 定稿，用户拍板"固定全食谱、非鱼都能吃"）**：PrefersToEat 和 CanEat **双重 override**——只改 PrefersToEat 不够，喂食等系统查 CanEat：
  ```lua
  local oldfn = inst.components.eater.PrefersToEat
  inst.components.eater.PrefersToEat = function(self, food)
      if food ~= nil and food.components.edible ~= nil then
          return not IsFish(food)
      end
      return oldfn(self, food)
  end
  -- CanEat 同结构 override（old_caneat 保存后，非鱼 → true）
  ```
- **⚠️ 官方 FOODTYPE 里没有 FISH！**（constants.lua 实测：GENERIC/MEAT/VEGGIE/ELEMENTAL/GEARS/HORRIBLE/INSECT/SEEDS/BERRY/RAW/BURNT/NITRE/ROUGHAGE/WOOD/GOODIES/MONSTER/LUNAR_SHARDS/CORPSE/MIASMA，无 FISH）。`FOODTYPE.FISH == nil`，写 `ed.foodtype == FOODTYPE.FISH` 实际变成 `ed.foodtype == nil`——判定彻底失效（有 foodtype 的食物全放行、真鱼也漏，等于没做不吃鱼）。官方鱼是 **FOODTYPE.MEAT**（海洋鱼 oceanfish_medium_5/small_5 甚至是 VEGGIE）+ 碎片化标签。
- **官方鱼 tag 不统一**（用户原话"fish 有多个标签"）：
  - pondfish/pondeel → `fish` tag（pondfish.lua:89）
  - oceanfish_* → `oceanfish` tag（oceanfish.lua:310；部分另带 `fish` tag 在 454 行）
  - eel → `fishmeat` tag（eel.lua:33）
  - fish.lua 的鱼块（fish/fishmeat 系列）→ 只有 meat/catfood/pondfish tag，**没有 fish tag**
  - quagmire_fish → meat/catfood，无 fish tag
  - 所以单查 `HasTag("fish")` 会漏掉大部分官方鱼；正确做法是 **prefab 名单为主 + tag 兜底**：
  ```lua
  local function IsFish(food)
      if food == nil then return false end
      if food:HasTag("fish") or food:HasTag("oceanfish") or food:HasTag("fishmeat") or food:HasTag("pondfish") then
          return true
      end
      if food.prefab ~= nil then
          local p = food.prefab
          if p:find("^oceanfish", 1) ~= nil or p:find("^fishmeat", 1) ~= nil then return true end
          if p == "fish" or p == "eel" or p == "eel_cooked" or
             p == "pondfish" or p == "pondeel" or p == "quagmire_fish" then return true end
      end
      return false
  end
  ```
  wobster（龙虾）无 fish tag 且不算鱼，明生可吃（合理）。
- 纯 SetDiet 硬编码数据层曾失败（用户反馈"判定难写成所有兼容格式"）——最终靠**判定函数 override** 兜底，而不是数据层。若 override 后仍拒吃，问题就不在 eater 判定，转查吃动作/状态机，且吃那一刻的日志（LUA ERROR / wonteatfood）一票定死。

## 随从/仆从仇恨：shadow 标签是真正的闸门（2026-08-23 实测 + 2026-09-01 补全）

- 原版影怪（crawlinghorror 等）带 `shadowcreature` 标签，**普通生物不攻击影怪**。
- 若给随从（如暗影明生 shadow_mingsheng）也加了这个标签：随从**不受攻击**，且随从打怪后怪物无法索敌它 → **仇恨全部转移到随从主人身上**（玩家被集火）。
- **但 shadowcreature 只是表象，真正的硬闸门是 `shadow` 标签**：`scripts/components/combat_replica.lua` 的 `IsValidTarget` 里有
  ```lua
  not (target:HasTag("shadow") and self.inst.replica.sanity == nil and not self.inst:HasTag("crazy"))
  ```
  目标带 `shadow` 标签 + 攻击方无 sanity 组件（猎犬/蜘蛛等普通怪物都没有）→ **直接判定无效目标**，永远不索敌、被打也不还手。玩家/疯狂生物（有 sanity 或 crazy 标签）不受此限，所以"戴护符的明生自己/影怪能打它、普通怪物不打"的现象极易误导排查。
- 修复：随从**不要带 `shadow` 和 `shadowcreature` 两个标签**（用自定义 shadowminion/companion 标签即可）。症状对照：随从"无仇恨、不被攻击、攻击后仇恨记本体"。
- 同批注意：随从若需被正常索敌，也别带 `notarget` 之类防索敌标签。
- `illusion` 标签不在 combat 排除列表里（虚影随从 illusion_mingsheng 可被正常索敌，与 shadow 不同）。

## 装备型容器物品：被动刷新必须 onequip 和 OnItemGetOrLose 两处都调

症状：知天命（hand_inv 容器武器）脱手再装备后，书页被动（伤害/位面/发光）失效，必须取出告示再放回才恢复。根因：被动计算函数只在 `OnItemGetOrLose`（容器物品变化回调）里调用，`onequip` 里漏了。装备动作和容器变化是两条独立回调链——脱手再装只触发 equip/unequip，不触发容器变化。教训：这类"容器内容决定属性"的装备，刷新函数要在 `onequip`（装备时）和 `OnItemGetOrLose`（放入/取出时）都调；`onunequip` 负责对称清理。

## inventoryitem 没有 RemoveFromInventory 方法；右键使用时物品已在 LIMBO（2026-09-01 Musha 实测）

- `inst.components.inventoryitem:RemoveFromInventory()` **不存在**，调用即 `attempt to call method 'RemoveFromInventory' (a nil value)`（组件存在但方法 nil）。
- 右键使用物品（buffered action）执行时，物品已被从背包取出进入 **LIMBO** 状态（日志可见 `musha_jobbook_warrior(LIMBO)`）。此时消费/移除物品直接 `inst:Remove()` 即可，无需（也无法）先 RemoveFromInventory。
- 若需要在非 LIMBO 路径移除背包物品：`doer.components.inventory:RemoveItem(item, drop)`（drop=false 不落地），或 `RemoveItemBySlot(slot, drop)`。

## ImageButton 继承 Button 不是 Image：没有 SetSize/SetTint（2026-09-01 Musha 实测）

- `widgets/imagebutton.lua`：`ImageButton = Class(Button, ...)`，Button 继承 Widget——**没有 `SetSize`/`SetTint`**（那是 Image 的方法）。调用即 `attempt to call method 'SetSize' (a nil value)`。
- 正确 API：`ForceImageSize(x, y)` 设尺寸；`SetImageNormalColour/SetImageFocusColour/SetImageDisabledColour/SetImageSelectedColour(r,g,b,a)` 设颜色（透明按钮用 `SetImageNormalColour(1,1,1,0)` + focus 微亮）。
- 构造函数：`ImageButton(atlas, normal, focus, disabled, down, selected, scale, offset)`，点击回调 `SetOnClick(fn)`。
- 透明点击区套路：`ImageButton` 图片色全透明覆盖在装饰文字（如 ✕）上，正常态隐形、悬停微亮。

## DST Widget 没有 SetVisible / SetHRegPoint（2026-09-01 Musha 实测）

- `widget:SetVisible()` **不存在**（Unity 式 API），显示/隐藏用 `widget:Show()` / `widget:Hide()`。
- `widget:SetHRegPoint()/SetVRegPoint()` **不存在**（Widget/Text/Image 都没有）。要做左对齐/右对齐：手动算中心位置（中文全角字符宽=字号，`中心 = 左缘 + 文本宽/2`）；"靠左增长的进度条"用 `SetSize(w*pct, h)` + `SetPosition(左端 + (w*pct)/2, y)` 动态定位。
- 通用排查：报 `attempt to call method 'Xxx' (a nil value)` 且对象是 widget → 先查原版 `scripts/widgets/*.lua` 确认该方法是否存在；DST 的 widget API 和常见 UI 框架（Unity/其他 Lua UI）差异很大。

## DST UI 面板布局：锚点陷阱 + 装饰层/内容层解耦（2026-09-01 Musha 职业面板实测）

- **TOP/RIGHT 锚点 + 小偏移 = 面板飞出屏幕被裁**：`SetVAnchor(ANCHOR_TOP)` 时 `SetPosition(x, y)` 的 y 是"widget 中心距屏幕顶的偏移"，不是"面板顶距屏幕顶"。面板半高 240、偏移 -120 → 上半截 120px 在屏幕外，只剩一角背景，标题/按钮全被裁（症状："只露出一块色块、内容全没、像脱离 HUD"）。修法：**居中锚点 `SetHAnchor(0)/SetVAnchor(0)` + 屏幕中心大偏移**（如 `SetPosition(300, 60)`），手动保证 `中心±半宽/半高` 落在 1920x1080 虚拟空间（x ±960、y ±540）内。数字 0 = 居中（已验证，比 ANCHOR_* 常量稳）。
- **背景装饰层与内容层解耦**：内容（标题/经验条/任务列表）围绕 root (0,0) 按**内容逻辑尺寸**排（如 360x440），背景图只当装饰垫底（原图直接铺或 SetTint 微调，别半透明到看不见——用户明确不接受 50% 透明背景），**不要让内容坐标依赖背景图尺寸/边缘**。root 统一 `SetScale` 控制整体大小，位置用 root 的锚点+偏移一次定。
- **布局迭代节奏**：用户会给"评价式"反馈（结构对了→调位置/尺寸/状态高亮）。每轮改一处可测的（位置→尺寸→配色状态→装饰），别一次大改。无职业/有职业要用颜色状态切换表达（无职业灰棕降饱和、有职业亮金+蓝经验条），不是只改文字。

## Widget 没有 SetHRegPoint/SetVRegPoint：左对齐/靠左增长用手动中心计算（2026-09-01 Musha 实测）

- DST 的 `Text`/`Image`（Widget 基类）**没有 `SetHRegPoint`/`SetVRegPoint`**，调用即 `attempt to call method 'SetHRegPoint' (a nil value)`。
- 替代：中心锚点手动算。文本宽 ≈ 字号 × 字符数（中文字符 = 字号宽），`SetPosition(左端 + 宽/2, y)` 模拟左对齐；多行/长文本按最长可能文本算，保证不越界（如面板左缘 -200，最长 4 字 40 号 → 中心 -120）。
- 经验条"靠左增长"：填充 Image 以中心锚定，每次 `SetSize(w, h)` 后同步 `SetPosition(左端 + w/2, y)`（或预先算 `左端 = 底轨中心 - 底轨宽/2`）。

## DST 面板 UI 布局：背景装饰层与内容层解耦，根容器统一缩放（2026-09-01 Musha 职业面板重做）

- 症状：书页背景（竖版 700x1026）硬塞横排内容（860x490），头部元素按"假想大纸"坐标排全部溢出纸外。
- 正确做法：**背景是装饰，内容是内容**。一个 root Widget 当面板容器：背景图挂 root 只做装饰（不参与内容坐标计算），所有内容元素也挂 root，围绕 root (0,0) 按自己的逻辑区排；root 统一 `SetScale` 缩放 + `SetHAnchor/SetVAnchor` + `SetPosition` 定位（如 `ANCHOR_RIGHT`+`ANCHOR_TOP` 贴屏幕右上，避开 HUD 血脑饿）。
- 信息卡比书页更适合状态/任务/进度类面板：标题 → 等级/经验条 → 任务竖列表，装饰在边角、功能信息左对齐、关闭按钮在右上。
- 修改单个元素坐标时按"逻辑区中心"重排（y 整体平移让内容垂直居中），不要按背景图边缘算。

## 条件触发型被动（夜视）别被回 san 道具打断

症状：戴梦魇护符（san 强制 0）时用「卜算·遭遇」（回 50 理智）→ 夜视滤镜消失。根因：夜视在 `sanitydelta` 监听里按 `san <= 阈值` 判断，回 san 把 san 抬过阈值 → 被动被关。修复：判定条件里加"佩戴触发条件的装备则无视阈值"（`wearing_amulet or san <= threshold`），而不是只靠阈值。

## 事件监听与 handler 对称性审计（2026-09-01 Musha 任务系统审计）

排查"某功能永远不生效 / 接了任务卡死"的静态检查法，grep 两个方向：

1. **监听的事件 → handler 必须存在**：`inst:ListenForEvent("xxx", function(_,data) self:OnXxx(data) end)`，全文件搜 `function MUSHA_XXX:OnXxx`。不存在 = 事件一触发就 LUA ERROR（attempt to call method 'OnXxx' (a nil value)）——定时炸弹，平时不触发极易漏。修法：删掉该监听或补空方法。
2. **handler 定义 → 必须有调用点**：`grep -rn "OnCollected\|OnDayPassed\|OnHealUsed"` 全 mod（排除定义文件）。定义了但没人调用 = 功能永久卡死（如 collect/survive/heal 类任务进度永远不动）。修法：在正确事件点补调用（拾取挂 pickup 事件、存活天数挂天时钟、技能次数在施放处）。
3. **事件名要与原版一致**：监听的 "craftitem"/"killed"/"harvest"/"areatrigger" 等事件名必须真实存在且 data 结构对（对照原版 player_common.lua / 组件源码），别想当然。

## 物品原地改造（SetPrefabName）不持久化 — 重进游戏后行为丢失（2026-09-01 Musha 实测）

- 症状：物品用后 `inst:SetPrefabName("xxx")` + 改 tag / 改 action 回调 / 改图标 / 改 anim build，当场能用；**存档重进后物品按目标 prefab 重新实例化，所有运行时修改全丢**（tag、musha_action 回调、build 都不进存档），右键行为回到目标 prefab 默认 → "重进游戏后打不开 / 变哑巴"。
- 根因：SetPrefabName 只改 GUID 注册名；tag/回调这类运行时状态不持久化（组件不 OnSave 就不存）。
- 修复：不要原地改造旧物品——`RemoveFromInventory()` + `inst:Remove()` + `SpawnPrefab(目标)` + `GiveItem`（"重新给一份"）。目标 prefab 本身必须自带正确 tag 和右键行为，这样重进游戏后新实例行为一致。

## 服务端 PushEvent 不跨端：客户端 UI 弹出要用 net_bool（且必须复位）（2026-09-01 Musha 实测）

- 症状：服务端 `doer:PushEvent("open_panel")`，客户端 `owner:ListenForEvent("open_panel")` 监听**收不到** → 面板打不开。玩家实体的自定义事件不跨端。
- 正确链路（角色 prefab common_postinit，SetPristine 前）：
  ```lua
  inst._panel_net = net_bool(inst.GUID, "panel_net", "panelchanged")  -- 第三个参数=dirty事件名
  inst:ListenForEvent("panelchanged", function()
      if TheWorld.ismastersim then return end   -- ❌ 单机/主机模式会打不开！
      if inst._panel_net and inst._panel_net:value() then
          inst:PushEvent("open_panel")  -- 本地事件触发 UI
      end
  end)
  ```
- **⚠️ 不要加 `if TheWorld.ismastersim then return end` 过滤**：单机/主机模式下玩家自己就是服务端，服务端 `set(true)` 时**本端也触发 dirty 事件**，被这行过滤掉 → 主机自己永远打不开（症状："右键有菜单但点了没反应"（当时 B 键却能开——B 键绕过 net_bool 直接调 UI；**注：B 键入口 2026-09-24 已按用户要求移除，别再拿它当对照**）。修法：两端都处理，靠 `value()` 判断即可（set(false) 复位时 value=false 自然不触发）。
- **net_bool 必须复位才能反复触发**：`set(true)` 只在值变化时发 dirty。连续右键第二次若值仍是 true 不会触发 → 服务端 `set(true)` 后 `DoTaskInTime(0, set(false))` 复位，下次才能再开。
  服务端触发：`doer._panel_net:set(true)`。
- **坑：net_bool 值不变不触发 dirty**——set(true) 后再 set(true) 第二次无效。必须 0 帧后复位：
  ```lua
  doer._panel_net:set(true)
  doer:DoTaskInTime(0, function() doer._panel_net:set(false) end)
  ```

## ComponentAction 右键菜单按 tag 路由（2026-09-01 Musha 实测）

- `AddComponentAction("INVENTORY", "comp", fn)` 的 fn 里靠 `inst:HasTag("xxx")` 决定插入哪个 ACTIONS。**prefab 没加对应 tag → 右键菜单根本没有该项**（右键无动作），action fn 写得再好也没用。
- tag 必须在 `inst.entity:SetPristine()` **之前** `AddTag`——客户端 replica 才可见，右键菜单是客户端构建的。

## DST UI 尺寸计算（2026-09-01 职业面板审计）

- Image 实际渲染尺寸 = `SetSize(w,h)` × `SetScale(s)`；子元素 `SetPosition(x,y)` 是**相对父 widget 中心的局部坐标**（父中心=0,0）。
- 代码注释里的"实际渲染约 xxx"可能和代码不符——以 SetSize×SetScale 为准，别信注释。
- 排错法：算父 widget 局部边界（±渲染宽/2, ±渲染高/2），把所有子元素位置套进去，超出边界的即溢出（飘在纸/框外）。竖版背景图强拉横版（SetSize 改比例）会变形。

## 批量 bug 修复的调试流程（测试报告模式）

用户丢来 N 条测试反馈时的有效姿势：
1. 先建 todo 清单（每条一个问题）
2. 能静态定位的立即修（搜代码 + 读原版组件确认 API），修完立刻在 todo 标完成
3. API 报错（LUA ERROR）优先处理——通常是"以为存在的方法不存在"，grep 原版组件确认
4. 改完提醒用户**重启游戏**（DST mod 脚本不热更新），并给每条修复的验证点
5. 日志贴回来先看 `[标签]` 前缀的 print 格式是否是新版——旧版文件未加载时先别排查逻辑

## anim bank 加载排查（"Could not find anim bank [xxx]"）

症状：某物品/实体 SetBank 报 `Could not find anim bank [prefab名]`，地上贴图消失。排查步骤（2026-08-23 实测，脚本工具：python zipfile 读 anim zip）：
1. **Asset 声明**：prefab 文件的 assets 表必须有 `Asset("ANIM", "anim/<name>.zip")`，且 PrefabFiles 注册了该 prefab。
2. **zip 内 build 名**：`unzip -p <name>.zip build.bin`，BILD 格式偏移 16 起 4 字节是 build 名长度、20 起是名字——**必须等于 SetBank/SetBuild 的名字**（build 名 ≠ zip 文件名时 bank 注册名对不上）。
3. **anim.bin 动画名**：ANIM magic 后是版本/动画数/动画名（如唯一动画 `idle`）——SetBank 后 PlayAnimation 的动画名必须在里面。
4. **atlas-0.tex 格式**：必须是 Klei 纹理（头部 `KTEX ` magic），不是 PNG/DDS 改名。
5. **对照法**：拿一个已知正常的 zip（角色本体/其他同类物品）逐一比文件清单、大小、压缩方式（deflate=8 常见）、build 名——告示类 zip 相互间通常完全同构，单独一个坏多半是重导时内容问题。
6. 若结构全对仍报错，且只有**被实例化过的** prefab 报错 → 可能是共性问题（其他同类没实例化所以没报）或渲染层（客户端 log）信息更多；让用户丢地上对照测试同类物品区分"只有这个坏" vs "全部坏"。
