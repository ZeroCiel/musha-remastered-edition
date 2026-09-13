# DST作物巨大化机制

## 7类压力（farmplantstress）
| Stressor | 判定 | 说明 |
|----------|------|------|
| nutrients | CycleNutrientsAtPoint消耗/归还 | 营养够不够 |
| moisture | CalcPercentTimeHydrated < min_percent | 水分够不够 |
| killjoys | 附近杀植物（杂草）数量 > tolerance | 杂草太多 |
| family | 同种植物数量 < family_min_count | 没种够同族 |
| overcrowding | 同一地块植物 > 4 | 太挤 |
| season | 当前季节 ∉ good_seasons | 不合适的季节 |
| happiness | 是否被主动照料（tend） | 有没有人管 |

## 每个生长阶段的checkpoint
```lua
-- pregrowfn中调用
MakeStressCheckpoint(inst)
  → 检查7个stressor的当前状态
  → SetStressed(name, true/false)
  → MakeCheckpoint() 累计stress_points
```

## 最终判定（final stage pregrowfn）
```lua
MakeStressCheckpoint(inst, true)  -- is_final_stage = true
  → CalcFinalStressState()
  → stress_points ≤ 1 → NONE → 巨大化
  → stress ≤ 6 → LOW → 2种子
  → stress ≤ 11 → MODERATE → 1种子
  → else → HIGH → 无种子

inst.is_oversized = stress == NONE and not no_oversized
```

## 催熟注意事项
1. SetStage跳过pregrowfn → stress不积累 → 永远无法巨大化
2. DoMagicGrowth设no_oversized = true → 禁止巨大化
3. 催熟正确方式：手动调pregrowfn + SetStage + force_oversized
