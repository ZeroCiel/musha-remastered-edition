# 明生Mod 2026-06-03 修复记录

## Nightmare Amulet NightVision 重装修复
- bug: 脱掉梦魇护符再戴上，夜视不恢复（san还没降到0）
- 修法：客户端侧监听 equip/unequip 事件，紫色护符时 ForceNightVision
- 文件：modmain.lua

## 暗影分身受击问题
- bug: `SGshadow_mingsheng` attacked 事件跳到 "disappear" 状态而不是 "hit"
- 修法：改为跳 "hit"，被打时进受击动画

## 角色死亡后分身上限突破
- bug: 死亡时 follower 关系断开，leader.followers 清空，召唤时以为没有分身
- 修法：`keepdeadleader = true`（官方标准做法，Abigail/宠物都在用）

## 自然消失杂音
- bug: OnRemove 里播音效，实体已在销毁中 → 爆音/杂音
- 修法：音效提前到 Remove() 之前播，OnRemove 只做 KillAllSounds 清理

## Builder Hook 迁移丢失装迷糊逻辑
- 从 `AddComponentPostInit`（modmain）迁移到 `mingsheng.lua` 的 `master_postinit` 时
- 只迁移了 `HasCharacterIngredient` + `RemoveIngredients`
- 漏掉了 `RemoveIngredients` 内部的装迷糊抵消逻辑
- 教训：迁移 builder hook 时必须同时迁移 hook 函数内部的**所有**分支逻辑

## Tianti/Celestial 冷却改为 rechargeable 组件
- 删掉了 `mingsheng_moonphase` 组件
- 改用原版 `rechargeable` 组件提供冷却圈图标显示
- `SetMaxCharge(COOLDOWN_SECONDS)` + `Discharge()` + `GetTimeToCharge()`
- 噩梦燃料冷却中献祭 = 加480秒 current（缩短冷却）
- 月岩冷却中提示不消耗物品

## Sound Cleanup
- 去掉所有分身消失/召唤音效（wx78/charged, shadowtalker_LP）
- 去掉遭遇（zaoyu）的使用音效（moonbase/beam）

## IsCharacterIngredient 注册方式修正
- 旧：直接 `ingredienttype == MINGSHENG_HUNGER` 值比较 — 不生效
- 新：用字符串查表 `MY_CHARACTER_INGREDIENT[ingredienttype]` — 生效
