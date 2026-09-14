# 可移动携带的建筑（portablestructure）—— 参考笔记
2026-09-14 · 用户给了 gitee 上 `norse_mythology_portablepot.lua` 说"这个可以留着"，顺手把原版样板也挖出来了

## 核心就一个原版组件：`portablestructure`
`scripts/components/portablestructure.lua`（**全文件才 17 行**）只有两样：
```lua
function PortableStructure:SetOnDismantleFn(fn) self.ondismantlefn = fn end
function PortableStructure:Dismantle(doer)      if self.ondismantlefn ~= nil then self.ondismantlefn(self.inst, doer) end end
```
配套的两处原版挂载点：
- `componentactions.lua:668` —— `portablestructure` 给右键动作
- `actions.lua:4552 / 4571` —— 那个动作的 fn：`act.target.components.portablestructure:Dismantle(act.doer)`

## 固定公式（照抄 portablefirepit / portablecookpot 就行）
1. **结构体 prefab**里：
   ```lua
   inst:AddComponent("portablestructure")
   inst.components.portablestructure:SetOnDismantleFn(ChangeToItem)   -- 或 OnDismantle
   ```
   `ChangeToItem` 里 `SpawnPrefab("xxx_item")` + 把自己 Remove（norse 的写法：第 349 行）
2. **配套一个 `xxx_item` prefab**（背包/地上的那个）：`AddComponent("inventoryitem")` + `AddComponent("deployable")`
   + `ondeploy(inst, pt, deployer)` 里 `SpawnPrefab("xxx")` 摆回结构体（norse 第 723 行）
3. **放置预览**：`MakePlacer("xxx_placer", bank, build, "place")`（结构体和 item 各一个）
4. 想禁止搬走：`inst.components.portablestructure.candismantle = function() return false end`（archive_resonator 的用法）
5. 版本升级/降级时记得 `RemoveComponent("portablestructure")` 再加回来（原版 winona 那批和 portablecookpot 都这么写）

## 原版样板清单（想抄哪个抄哪个）
| 文件 | 用途 | 备注 |
|---|---|---|
| `prefabs/portablefirepit.lua` | **可移动火堆** | 最贴近"便携 + 燃料"，用户之前说"以前设计过的可移动携带的火堆那套"就是这个 ✓ |
| `prefabs/portablecookpot.lua` | 便携锅 | 带 fueled/burnable/stewer，组件最全 |
| `prefabs/portabletent.lua` | 便携帐篷 | 结构最简单 |
| `prefabs/portablespicer.lua` / `portableblender.lua` | 便携调料/料理机 | |
| `prefabs/winona_catapult.lua`、`winona_battery_*.lua`、`winona_spotlight.lua`、`winona_teleport_pad.lua` | 女工那批 | 结构大、带升级，抄升级写法看这批 |
| `prefabs/archive_resonator.lua` | 远古谐振器 | 带 `candismantle` 限制 |
| `prefabs/wx78_drone_delivery.lua` |  drone | |

## 用户给的那个 norse 文件
`references/norse_mythology_portablepot.lua`（27.9 KB，gitee: ZeroCiel/norse_mythology）
- 它 = 原版 portablecookpot 那套 + 包了自家组件 `norse_mythology_portablepot`（锅的烹饪逻辑）
- 结构体的组件：container / burnable / stewer / fueled / workable / portablestructure / lootdropper / storytellingprop
- 还顺手 `AddCookerRecipe` 注册了 portablecookpot 的菜谱
- 🔎 它自家的组件脚本在 `scripts/components/norse_mythology_portablepot.lua`（这次没拉；要的话再说）
- 对我们有什么用：以后要做「可搬运的祭坛 / 便携工作台 / 便携火堆」直接照这套抄；
  和 `musha-dayrewards-plan.md` 里"武器升级机制抄便携火堆那套"是同一批原版代码 ✓
