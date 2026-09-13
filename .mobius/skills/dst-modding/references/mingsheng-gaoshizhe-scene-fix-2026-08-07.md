# 告示者 SCENE 右键修复 (2026-08-07)

## 问题
告示者(mingsheng_gaoshizhe)丢地上后右键无法激活。

## 根因链

1. **GIVE充能自动出仆从+Remove** → 已充能的告示者从不留在地上 → SCENE激活是死代码
2. **SCENE绑了`inventoryitem`官方组件** → 不触发
3. **仆从"休息"SCENE绑了`follower`官方组件** → 不触发
4. **`mingsheng_repairable` marker只放在gaoshizhe上** → GIVE充能(USEITEM)不触发（marker应在手持物品上）

## 修复

### 1. SCENE绑定改专用组件
- 物品SCENE: `mingsheng_gaoshizhe_henshin`（不用inventoryitem）
- 仆从SCENE: `mingsheng_gaoshizhe_minion`（不用follower）

### 2. 充能流程重构
- CHARGE(GIVE梦魇/月华): 只加标签+设finiteuses=1，**不自动出仆从不Remove**
- SCENE右键"激活": 查finiteuses>0 → spawn仆从 → 消耗uses → Remove物品
- craft出来默认finiteuses=1 + gaoshizhe_shadow标签（直接可用）

### 3. marker组件修正
- `mingsheng_repairable` → 加在梦魇/月华/命理prefab上（不在gaoshizhe上）
- USEITEM的inst是手持物品，不是目标

### 4. finiteuses替代纯标签
- 充能状态走finiteuses（网络同步+UI耐久条）
- 类型区分走标签（gaoshizhe_shadow/gaoshizhe_illusion）
- 两套互不干扰

### 5. 动画修复
- `SetMultColour(1,1,1,1)` 强制全色（去Bernie黑影图层）
- `Hide("swap_object")` 默认隐藏武器手持

## 最终流程
1. craft告示者 → finiteuses=1, 默认shadow
2. 丢地上 → 右键"激活" → 直接出暗影仆从
3. 物品栏GIVE梦魇/月华 → 切换shadow/illusion类型
4. 右键仆从"休息" → 变回物品
