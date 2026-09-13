# DST 服务器/世界设置 & TUNING —— 运行期到底能改什么

用户原话：「游戏内是否允许更改所有服务器设置？」「能不能通过 TUNING 实现，或者固定的值来实现？——
怪物生成、任务数量、能量恢复、生命恢复这些公开设置的规则」。

下面每条都对着本机 `D:\SteamLibrary\steamapps\common\Don't Starve Together\data\databundles\scripts\` 源码核过。

---

## 一、三类设置 + 入口（都不在游戏内）

| 类别 | 存哪 | 唯一入口 | 运行期可改？ |
|---|---|---|---|
| A 世界设置 World Settings<br>（世界大小/地形/季节长度/怪物数量/死亡惩罚） | `cluster.ini`、`worldgenoverride.lua` | 主菜单 → 世界 → 编辑世界 / 创建世界 | 只能改内存表，见下 |
| B 服务器设置 Server Settings<br>（PVP/最大人数/密码/语言/允许新玩家/shard 结构） | `cluster.ini`、`server.ini` | 主菜单 → 服务器设置 | 脚本只有「读」接口，写权在引擎侧 |
| C 模组配置（`modinfo.lua` 的 `configuration_options`） | modsettings | Mods 界面 | 游戏 UI 改不了；改完普遍要重启/重进 |

### A 的细节：`worldsettings` 组件只有 24 行
`components/worldsettings.lua` 全文就是一张内存表：
```lua
function WorldSettings:GetSetting(setting) return self.settings[setting] end
function WorldSettings:SetSetting(setting, value) self.settings[setting] = value end
-- 另监听 TheWorld 的 "ms_setworldsetting" 事件（由 worldsettings_overrides.lua 的世界重置流程推）
```
- **不落盘、不触发重生成**。改了只影响「运行期实时读它」的代码。
- 全脚本 `grep worldsettings:GetSetting` 只有 **`gamemodes.lua`**（`GetWorldSetting`）。所以运行期改
  `spawn_mode` 只影响 gamemode 那套分支，**不会改怪物刷新率**。
- 真正的刷新率/地形/生物群系是**世界生成阶段**读 `worldgenoverride.lua` 的，运行期改不动。

### B 的细节：只有 Get，能读不能写
`TheNet:GetPVPEnabled()`、`TheNet:GetServerPVP()` 等（用例见 `components/worldoverseer.lua:311`）。
Set 类接口不在脚本里（引擎侧），mod 拿不到。

---

## 二、TUNING：能改，但看「这个值是什么时候被读走的」

`TUNING` 就是启动时载入的普通全局 Lua 表。modmain 里 `GLOBAL.TUNING.X = v` 覆盖后，之后所有读它的地方都用新值；
**运行期再赋值同样有效**（它只是一张表）。真正的坑是读的时机：

1. **实体构造时读一次** → 只影响「以后新生成的」，地上已有的不变
   - `prefabs/spider.lua:760` → `inst.components.health:SetMaxHealth(TUNING.SPIDER_HEALTH)`
   - `prefabs/deerclops.lua:508` → `inst.components.health:SetMaxHealth(TUNING.DEERCLOPS_HEALTH)`
   - 要改已存在的实体，只能自己遍历改
2. **世界生成时读**（刷新率、地形、生物群系）→ 运行期改了完全没用
3. **每次逻辑跑都读** → 实时生效

另外：TUNING 覆盖是**全局的**，影响使用该 mod 的所有存档；没有「按存档」的粒度。

---

## 三、推荐做法（回答用户时给这个，别只答「不行」）

- **想「游戏内改规则」** → 用你自己的数据层（组件表 / 玩家 `userdata` / 世界存档）+ 自己的 UI，
  改完调一次你的「应用」函数。
  Musha 现成例子：`class_traits` 里的 `warrior.health_regen` / `mp_regen_base` 这类数值改完调
  `ApplyProfessionData()` 即可立刻生效。
- **想改原版怪的血量/伤害** → `AddPrefabPostInit` 或生成后现场改。比动 TUNING 精准：只改你要改的那个，
  不污染全局，且对新生成的立刻生效。
- **想改刷新率** → 自己起计时器 / 监听事件 `SpawnPrefab`，别去碰世界设置。
- **只读的东西**（`TheNet:Get*`、`worldsettings:GetSetting`）能读不能写，别承诺。

## 四、回答这类「能不能」问题的格式（用户偏好）
结论先行（能 / 不能 / 分情况），然后**在哪一层能做、哪一层做不到 + 原因（引用具体文件:行）**，
最后给一条可执行的下一步（例：「要不要我在 Musha 面板上做一页设置页当样例：怪物生成开关+数量、
任务数量、回血回蓝倍率，存进玩家 userdata，改完立刻生效」）。用户认可这种「给样例走通一条路」的收尾。
