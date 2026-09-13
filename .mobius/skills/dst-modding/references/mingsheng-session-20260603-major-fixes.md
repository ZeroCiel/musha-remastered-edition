# 2026-06-03 Major Fix Session

## 1. 梦魇护符重装夜视不恢复
Fix: 客户端监听 equip/unequip → ForceNightVision

## 2. 暗影分身没有受击判定
- SGshadow 被攻击跳 disappear → 改为跳 hit
- 加 CommonHandlers.OnAttacked()（后来删掉，因为和自定义attacked handler冲突）
- shadow_shield prefab 不存在 → 从列表删除

## 3. 角色死亡后分身突破上限 → keepdeadleader = true
原方案：死亡时遍历 finds 重新绑定follower
最终方案：设 `keepdeadleader = true`（Abigail/宠物模式）
shadow_mingsheng.lua 和 illusion_mingsheng.lua 的 follower 组件都加了

## 4. 分身自然消失杂音
- 音效从 OnRemove 提前到 StartFollowerTimer 到期回调
- OnRemove 里加 KillAllSounds() 兜底
- 虚影同理
- 梦魇召唤暗影时去掉 shadowtalker_LP 音效

## 5. 饥饿值制造不满足
- 原代码: `builder_replica` hook 读 `classified` 方式不对（可能读到0）
- 修法: 删掉 builder_replica hook，改用雪露mod的单函数模式
- `IsCharacterIngredient` 注册去掉 nil guard
- `HasCharacterIngredient` 一个函数同时处理服务端和客户端

## 6. 遭遇风声
- temperaturelock 的 DoPeriodicTask 每0.5s设体温 → 触发DST风声系统
- 改为一次性设体温，去掉循环
- 最后用户选择恢复锁体温但关掉所有音效

## 7. 卜算天体冷却圈
- 用 rechargeable 组件（同知天命）
- SetCharged 不存在（rechargeable 默认 current=total=180）
- 献祭时 Discharge(COOLDOWN_SECONDS)

## 8. irreplaceable tag 导致下线掉落
用户手动删掉了 mingsheng_tianti 的 `irreplaceable` tag

## 9. 卜算天体配方写错
purehorror → horrorfuel
