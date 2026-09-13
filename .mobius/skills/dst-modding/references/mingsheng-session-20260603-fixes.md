# 2026-06-03 明生mod修复session

## 夜视修复（梦魇护符重装）
文件：modmain.lua
- 客户端 `AddPlayerPostInit` + 监听 `equip`/`unequip`
- `purpleamulet` 装备时 `ForceNightVision(true)`，卸下 `ForceNightVision(false)`
- 解决：戴护符→脱掉→再戴时夜视不恢复

## 暗影受击修复
文件：SGshadow_mingsheng.lua
- `EventHandler("attacked", ...)` 从 `disappear` 改为 `hit` 状态
- 去掉 `CommonHandlers.OnAttacked()`（与自定义attacked handler冲突）

## 分身突破上限修复
文件：shadow_mingsheng.lua + illusion_mingsheng.lua
- `follower.keepdeadleader = true` → 死亡不断开follower关系
- 这样 `CanSummonMoreShadows`/`CountIllusions` 的 leader.followers 计数正确

## 消除杂音
文件：shadow_mingsheng.lua + illusion_mingsheng.lua
- 从 `OnRemove` 中移除所有 `PlaySound` 调用
- 音效放到 `StartFollowerTimer`/`StartFollowerTimerTicks` 到期回调里（Remove之前）
- `OnRemove` 中加 `SoundEmitter:KillAllSounds()`
- 删除 prefabs 列表中的 `shadow_shield`（不存在）
- 删除 `SpawnPrefab("shadow_shield")` 调用
- 删除 `mingsheng_mengyan.lua` 中的 `shadowtalker_LP` 音效

## 饥饿消耗制造修复
文件：modmain.lua
- `HasCharacterIngredient` 返回值写法修正：先算current再返回两个值
- 问题：`return` 换行 + `freebuildmode and 0` 逻辑错误

## 温度锁定风声修复
文件：temperaturelock.lua
- 去掉 `DoPeriodicTask(0.5, ...)` 循环设体温
- 改为一次性 `SetTemperature(self.target_temp)`，不再频繁触发DST温度音效系统

## 遭遇音效关掉
文件：mingsheng_zaoyu.lua
- 去掉 `PlaySound("dontstarve/common/together/moonbase/beam")`

## ImageButton IsFocused 修复
文件：mingsheng_teleportscreen.lua
- `self:IsFocused()` → `entry:IsSelected()`（ImageButton没有IsFocused方法）

## 天体配方修正
文件：modmain.lua
- `purehorror` → `horrorfuel`
