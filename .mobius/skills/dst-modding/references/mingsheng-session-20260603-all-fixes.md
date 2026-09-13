# 2026-06-03 Session: Minion Fixes, Hunger Crafting, Nightmare Amulet NightVision, Temperature Sound Bug

## Fixed Bugs

### 1. Shadow minion — no hit reaction (appeared immune)
- SGshadow_mingsheng 的 EventHandler("attacked") 跳到了 "disappear" 状态 → 被打直接消失
- Fix: 改为跳 "hit" 状态

### 2. Shadow minion — strict.lua: PlaySmokeEffects not declared
- PlaySmokeEffects() defined after StartFollowerTimer() which calls it in a callback
- Lua strict mode checks at load time → error
- Fix: move function definition before all callers

### 3. Shadow minion — shadow_shield prefab not found
- prefabs = {"shadow_shield", ...} but no such registered prefab
- Fix: remove from list + delete SpawnPrefab("shadow_shield") call

### 4. Minions — death breakthrough (summon limit exceeded after death)
- Death disconnects follower → leader.followers empty → CanSummonMoreShadows always returns true
- Fix: inst.components.follower.keepdeadleader = true (official pattern: Abigail, Maxwell minions)

### 5. Minion despawn — crackling noise
- OnRemove plays sound during entity destruction → unstable SoundEmitter → noise
- Fix: play sound before Remove(), add KillAllSounds() in OnRemove

### 6. Nightmare amulet — nightvision lost on re-equip
- SetInducedInsanity(true) needs time to drop sanity → nightvision not immediate
- Fix: client-side ListenForEvent("equip") → ForceNightVision(true)

### 7. Temperature lock — wind sound persists
- DoPeriodicTask(0.5, SetTemperature(24)) repeatedly crossing threshold → wind sounds fire continuously
- Fix: removed periodic task, set temperature ONCE at lock start

### 8. Hunger crafting — "材料不足" when hunger is full
- Client builder_replica hook: classified nil guard defect → math.ceil(0) = 0
- Fix: removed client-side hook entirely (Elaina/Setsuro mod pattern)

### 9. ImageButton crash — IsFocused() doesn't exist
- Fix: use entry:IsSelected() instead

## Sources
- Huohuo mod (3348667263): same pattern with client + server hooks
- Elaina mod (2578692071): server-only hook (the correct pattern)
- Setsuro (3660903728): uses AddNewCharacterIngredient(Builder) pattern

## Builder Ingredient Pattern (Correct)
- Server: hook inst.components.builder.HasCharacterIngredient + RemoveIngredients
- Client: do NOT hook builder_replica — DST syncs automatically
- Register: CHARACTER_INGREDIENT.MINGSHENG_HUNGER = "MINGSHENG_HUNGER"
- Override: IsCharacterIngredient() globally
- Recipe: Ingredient(CHARACTER_INGREDIENT.MINGSHENG_HUNGER, amount)
