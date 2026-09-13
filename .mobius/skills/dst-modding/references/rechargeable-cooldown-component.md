# rechargeable 组件 — 图标冷却遮罩实现

## 基本用法

```lua
inst:AddComponent("rechargeable")
inst.components.rechargeable:SetMaxCharge(COOLDOWN_SECONDS)  -- 总冷却量
inst.components.rechargeable:SetChargeTime(COOLDOWN_SECONDS)  -- 充电速度（秒）
inst.components.rechargeable:SetOnDischargedFn(function(inst)
    -- 开始冷却时触发
end)
inst.components.rechargeable:SetOnChargedFn(function(inst)
    -- 冷却完成时触发
end)
-- 初始已充满
inst.components.rechargeable:SetCharge(COOLDOWN_SECONDS)
```

## 冷却控制

| 操作 | 方法 | 效果 |
|------|------|------|
| 开始冷却 | `Discharge(seconds)` | 设 current=0, chargetime=seconds |
| 进度查询 | `GetPercent()` | 0~1 |
| 是否冷却中 | `not rc:IsCharged()` | current >= total = 已充能 |
| 剩余秒数 | `GetTimeToCharge()` | 冷却剩余时间 |
| 冷却缩短 | `SetCharge(new_value)` | 设新的充电进度（加=延长，减=缩短） |

## 关键陷阱

1. **SetMaxCharge 必须设！** 默认 total=180，如果只 SetChargeTime 不改 total，充电只会充到180秒而不是你期望的值
2. **Discharge 内部调 SetChargeTime** — 传参等于你期望的冷却总时长
3. 图标冷却圈**自动同步**到客户端，不需要额外处理
4. 冷却圈类似绿护符/知天命的图标遮罩效果

## 示例：献祭冷却

```lua
-- 成功献祭后，触发冷却
local rc = target.components.rechargeable
if rc then
    rc:Discharge(COOLDOWN_SECONDS)  -- 开始冷却，图标自动显示遮罩
end

-- 噩梦燃料减冷却
local new_charge = math.min(rc.total, rc:GetCharge() + 480 * (rc.total / COOLDOWN_SECONDS))
rc:SetCharge(new_charge)  -- 减480秒（即当前进度+480）
```
