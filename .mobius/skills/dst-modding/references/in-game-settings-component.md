# 局内设置组件（world + player 双组件）—— 落地实现与坑

适用：用户要「**在游戏内改规则**」（怪物生成 / 每日任务数 / 回血回蓝倍率 / 经验倍率），
说法通常是「做成组件、允许局内改、改完立刻生效」。

- 「原版设置到底能不能在游戏内改」→ `references/server-settings-and-tuning.md`
- 「面板怎么扩成多页 / 导航怎么抽」→ `references/screen-scrolling-grid.md` 的「面板多页化」节
- **本文件 = 已跑通的实现骨架**（musha 0.7.6，2026-09-10 P1）

## 文件布局
- `scripts/components/musha_world_settings.lua`（挂 TheWorld）
- `scripts/components/musha_player_settings.lua`（挂玩家）
- 服务端方法**挂在已有的 profession 组件上**（`GetSettingsView / PushSettings / SetMushaSetting`）——
  别再开一个新组件去存"视图"，省一套同步。
- RPC 加在 `scripts/rpcs/musha_rpcs.lua`

## 组件模式：SPEC 表 + Get/Set/OnSave/OnLoad
每项形如 `{ default=…, kind="bool"|"choice"|"number", choices={…} 或 min,max,step }`

```lua
function X:Get(key)      -- key 为 nil → 返回全部值的**副本**
function X:Set(key, value)
    -- 校验：choice 遍历白名单；number tonumber+clamp；未知 key 直接 false,"unknown_key"
    -- 成功后 self.inst:PushEvent("musha_world_settings_changed", {...})
function X:OnSave()  return { values = self.values } end
function X:OnLoad(data)  -- 只认 SPEC 里存在的 key，其余丢弃
```

- `Set()` 是**服务端唯一可信点**，所有类型/范围校验都放这里，RPC 层不校验。
- ★ **bool 的取值坑**：ModRPC 传过来的是数字，而 **Lua 里 `0` 也是真值**。
  必须写 `value = (value == true or value == 1)`。
  写成 `value and true or false` 会把 `0` 判成 `true`（关闭按钮点了没反应）。
- 客户端显示表里 `default` 要和 SPEC 完全一致（首帧用），不一致会闪一下再被服务端值覆盖。

## 挂载：世界组件必须"早挂"，否则 OnSave/OnLoad 失效
```lua
AddPrefabPostInit("world",  AddWorldSettings)
AddPrefabPostInit("forest", AddWorldSettings)
AddPrefabPostInit("cave",   AddWorldSettings)
```
- ★ `data/databundles/scripts/prefabs/world.lua` 里确实有 `return MakeWorld("world", …)`
  （注册了名为 `"world"` 的 prefab），但**运行时世界实体是 `forest` / `cave`**
  （`prefabs/forest.lua` 末尾 `return MakeWorld("forest", …)`）。
  只挂 `"world"` 可能永远不触发 → **三个都挂**。
- ★ **组件必须在世界"读档时"已存在**，否则存档里那份 OnSave 数据喂不到 OnLoad（数据就丢了）。
  所以不能只在玩家加入时惰性 `AddComponent` —— 那晚了一整个存档周期。
- 惰性兜底（`EnsureWorldSettings()` 里 `if not w.components.X then w:AddComponent("X") end`）
  仍保留做保险，但**别把它当唯一挂载点**。
- 挂载函数要 `if inst.components.X == nil then inst:AddComponent(...) end` 幂等（client 侧也会跑）。

## 同步：零新增网络变量（复用已有的 DoUpdata 通道）
★ 不要为设置新开 net_string。把设置快照塞进 **userdata 的副本**，复用已有的
`replica:DoUpdata(json)` → net_string dirty → `PushEvent("gamedata_dirty")` 通道：

```lua
function Musha_Profession_Component:PushSettings()
    if not self.inst.replica.musha_profession_component then return false end
    local d = {}
    for k, v in pairs(self.userdata) do d[k] = v end   -- ★必须拷贝
    d.settings = self:GetSettingsView()                -- { world={…}, player={…}, can_edit=bool }
    return pcall(function() self.inst.replica.musha_profession_component:DoUpdata(d) end)
end
```

- ★ **必须拷贝**：`OnSave()` 返回 `{ userdata = self.userdata }`，直接把 `settings` 写进
  `self.userdata` 会**污染存档**（存一份永远用不上的快照）。拷出去推，存档干净。
- 客户端面板既有的 `GetUserData()` 返回 `replica.cached_data.userdata`，
  于是 `md.settings` 自然就有了 —— **读取端零改动**（不用改 replica 文件、不用改 modmain 的
  AddReplicableComponent）。
- 面板打开时拉一次最新值：客户端 `SendModRPCToServer(GetModRPC("musha","musha_request_settings"))`
  → 服务端 `pc:PushSettings()` 回推。

## RPC 与权限
```lua
GLOBAL.AddModRPCHandler("musha", "musha_set_setting", function(player, scope, key, value) … end)
```
- **3 参签名**；开头 `if not GLOBAL.TheWorld.ismastersim then return end`。
- 权限判定：`player.Network:IsServerAdmin()`（全脚本 grep 到的现成用法在
  `widgets/playerdeathnotification.lua`、`widgets/worldresettimer.lua`）。
  客户端侧对应 `TheNet:GetIsServerAdmin()` / `TheNet:GetIsHosting()`（只在"本机"有意义，服务端别用）。
- **用 `pcall` 包起来**，别让它把整个 RPC 打崩：
  实测状态「服务端是否恒可用」未验证；若不生效，备选 `TheNet:GetIsHosting()` + userid 名单。
- **world 级要卡权限，player 级不卡**（各改各的）。失败时 `talker:Say("只有房主/管理员能改世界设置")`。

## 设置页 UI
- 控件三件套全用 `ImageButton("images/global.xml","square.tex")` + 子 `Text` 拼，不依赖美术：
  `bool` = 一个"开/关"按钮；`choice` = `< 值 >`；`number` = `- 值 +`。
  choice 循环、number 到端点回绕（`NextSettingValue(def, cur, dir)`）。
- 行数少（≤7）**直接绝对定位排**，不必上 ScrollingGrid；超了再换。
- 每次 `Refresh` 里调 `RefreshSettings(md)`：刷新控件文字 / 按钮态，
  并把"无权改"的 world 行**行名淡化**（Widget 没有 SetTint，逐个改子 Text 的 `SetColour`）。
- 点击提交走 RPC，**不要本地先改再等服务端**（服务端是唯一真源，回推会覆盖）。

### ★ 整页"整体上移 N 像素"→ 改基准常量，别逐行改
7 行都是 `row:SetPosition(0, ROW_Y0 - (i-1)*ROW_GAP)` 算出来的 → 用户说「设置部分都上移 30」
（实测连着两轮：80 → 110 → 134）就**只改 `ROW_Y0` 一个数**，所有行自动跟着走。
逐行改坐标最容易改漏；排一组绝对定位控件时先看一眼有没有共同基准量。

### ★ 给一组绝对定位控件加底板
```lua
-- 必须在"行之前" AddChild：渲染顺序 = 添加顺序，底板得先加才在下面
local bg = self.pages.set:AddChild(Image("images/global.xml", "square.tex"))
bg:SetSize(780, 500)
bg:SetPosition(0, -52)                        -- 中心 y =（顶边 + 底边）/ 2
bg:SetTint(0.78, 0.68, 0.56, 0.94)            -- 橙灰，和信箱内层同色，整套面板统一
```
底板尺寸按行范围推：顶边 = `ROW_Y0 + 行高/2 + 留白`，
底边 = `ROW_Y0 - (n-1)*ROW_GAP - 行高/2 - 留白`，中心取两者中点。留白先给 40，嫌大再收。

### 配色：橙灰底 + 橙字的对比度
- 底 `(0.78,0.68,0.56)` → 字必须选**比底暗**的深橙 `(0.85,0.32,0.08)`
  （和导航当前页高亮同一支橙，整套面板统一）。
- 次要信息（「世界 / 个人」这种标签）用**同色降 alpha**（0.78），不要另换颜色。
- ★ **按钮内部的字不要跟着改**：按钮自带蜡黄底 `(0.70,0.62,0.42)`，橙字压上去对比不足。
  要按钮字也变橙，得先把按钮底换成深色 —— 等用户点名再做。

## ★ 切页时会踩的可见性坑
`SetActivePage(name)` 用 `Show()` 批量显示某一页的 widget —— 但有些 widget 的可见性
是 `Refresh()` 在管的（例：任务列表的"暂无任务 / 暂无职业"空状态文字）。
直接 `Show()` 会把本该隐藏的空状态字样翻出来。

```lua
if name == "home" then
    self.default_focus = self.list
    self:Refresh()          -- ★补刷，免得空状态被 Show 出来
end
```

## 生效接线：哪些能"立刻生效"
| 设置 | 接线点 | 难度 |
|---|---|---|
| 玩家级倍率（回血/回蓝） | 改完调一次应用函数（`ApplyProfessionData()`） | 低 |
| 经验倍率 | `AddExperience(amount)` 开头乘一遍 `math.max(1, floor(amount*mult+0.5))` | 低 |
| 每日任务数 | modmain 初始化玩家时写 `q.daily_count_override`，**优先读世界设置、其次 modinfo** | 低 |
| 怪物生成倍率 | **只能存值** —— 原版刷新率 worldgen 阶段定死，运行期改不动 | 高（要自建刷怪器） |

- 怪物生成要生效必须**自建刷怪器**（挂 TheWorld 的 `OnUpdate` 按倍率 `SpawnPrefab`）。
  别去改世界设置：`TheWorld.components.worldsettings:SetSetting` 只改内存表、不落盘，
  且全脚本只有 `gamemodes.lua` 实时读它。
- 旧的"测试用常量"（如 `TEST_DAILY_COUNT = 8`）在设置接管后要改成 `nil`，否则设置永远不生效。
  顺手把它的取数范围（`n >= 3 and n <= 5`）放宽到和设置一致（1..10），否则改大了仍被拒。

## 一期落地顺序（别一次全上）
1. 两个设置组件（SPEC + Get/Set/OnSave/OnLoad）
2. modmain：世界三个 prefab 挂载 + 玩家挂载
3. profession 组件：`GetSettingsView / PushSettings / SetMushaSetting`
4. RPC：set + request（3 参、pcall 权限）
5. 面板：多页容器 + 导航 + 设置页 + `RefreshSettings`
6. **只接 1–2 个"立刻能验"的效果**（经验倍率、每日任务数），其余留后面
7. 每步跑 `scripts/lua_syntax_check.py`（多文件循环一起校验）

## 交付回话里必须点明的"风险点"
用户吃这套：直接列出「待验证：权限判定 / 挂载是否触发 / 坐标位置 / 三角字符」+ 每条的备选方案。
不要写成"已完成，请测试" —— 把不确定的地方自己标出来，他一句话就能给方向。
