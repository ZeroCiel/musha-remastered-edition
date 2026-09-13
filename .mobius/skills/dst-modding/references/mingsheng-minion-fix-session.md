# 2026-06-03 暗影/虚影仆从修复 Session

## 修复内容

### 1. 暗影分身没有受击判定
- SGshadow_mingsheng 的 `events` 里 `EventHandler("attacked")` 跳 `"disappear"` → 改为跳 `"hit"` 状态
- 去掉重复注册的 `CommonHandlers.OnAttacked()`（和自定义 handler 冲突）

### 2. 角色死亡后分身突破上限
- modmain 里加 `AddPlayerPostInit` 监听 `death` 事件，死亡时收集所有 `shadow_mingsheng`/`illusion_mingsheng` 标签的 follower 并 Remove
- 收集后再移除，避免遍历时修改表
- `inst:HasTag("mingsheng")` 在回调内判断，不在 postinit 时机判断

### 3. 暗影自然消失后杂音
- 音效从 `OnRemove` 提前到 `StartFollowerTimer`/`StartFollowerTimerTicks`/`ondeath` 的回调里播放
- `OnRemove` 里只播特效 + `KillAllSounds()` 清空残留音效
- `KillAllSounds()` 是 SoundEmitter 组件的官方方法（bee.lua 也这样用）

### 4. strict.lua 声明顺序错误
- `PlaySmokeEffects` 的定义放到了调用它的 `StartFollowerTimer` 之前
- `shadow_shield` prefab 不存在 → 从 prefabs 列表和召唤代码中删掉

### 5. 梦魇护符夜视重装不恢复
- `playervision` 是客户端组件，服务端无法访问
- 客户端侧监听 `equip`/`unequip` 事件，紫色护符时调 `ForceNightVision`
- `inst:HasTag("mingsheng")` 在回调内判断
- `ForceNightVision` 当 `nightvision` 已是 true 时会跳过更新（注意陷阱）

### 6. Builder饥饿消耗制造不了
- `HasCharacterIngredient` 返回两个值：has_ingredient, current_amount
- 原写法用 `self.freebuildmode and 0` 在 freebuild 模式返回 0（falsy），导致条件判断错
- 改为 `self.freebuildmode or current >= ingredient.amount`
