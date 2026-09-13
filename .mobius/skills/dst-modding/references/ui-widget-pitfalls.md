# DST UI Widget 常见坑（报错 "attempt to call method 'X' (a nil value)"）

## SetTint 只有 Image 有
- `SetTint(r,g,b,a)` 只定义在 `widgets/image.lua`（image.lua:142 实测）
- **Widget / Button / ImageButton 都没有 SetTint**
- ImageButton 内部控制颜色靠 `self.image:SetTint(...)`（imagebutton.lua 里全是这么调的）
- 报错现场（2026-08 实测）：`mingsheng_teleportscreen.lua` 第 40 行 `black_overlay` 是 `Image`，`SetTint` 正常；第 46 行 `black_clicker` 是 `ImageButton`，`SetTint` 直接炸
- 修法：`black_clicker:SetTint(...)` → `black_clicker.image:SetTint(...)`
- 注意：ImageButton 获得/失去焦点时会用 focuscolour 重设 image tint，会覆盖你手动设的透明色

## 其他 Widget 方法归属速查（报错排查用）
- `SetColour` → Text 有（button.lua 里 self.text:SetColour）
- `SetTint` → 只有 Image
- 排查套路：先确认控件是什么类（Image / Text / ImageButton / Widget），再 grep 官方 `data/databundles/scripts/widgets/<class>.lua` 看方法存不存在

## 官方 widgets 位置
- 原版代码在 `data/databundles/scripts/widgets/`（不是 data/scripts/）
- 常见类：screen / widget / image / text / button / imagebutton / scrolllist / menu
