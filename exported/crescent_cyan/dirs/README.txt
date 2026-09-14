crescent_cyan8 —— 月牙方向图打包说明
=====================================
这里 8 张 crescent_dir0..7.png 是由 make_dirs.py 从 crescent_cyan-0.png 自动派生的
（世界 +X 起，每 45° 一张；画面角度已经做过"地面投影反向补偿"，所以斜飞不会被压扁）。

打包步骤（DST Mod Tool）：
  1. 打开 dirs/crescent_cyan8.scml → 导出 → 得到 crescent_cyan8.zip
  2. 把 zip 放进 mods/musha/anim/crescent_cyan8.zip
  3. 改 scripts/prefabs/musha_slash_qi_fx.lua 的 FX_ART："cyan" → "cyan8"
     （那张表里已经有 cyan8 一项，含 dirs = { anim_0 … anim_7 }）
  4. 进游戏，8 个方向各放一次，看有没有"哪一张歪了/扁了"

校准（改一个数重跑 make_dirs.py 再导一次即可）：
  · 8 张整体偏同一角度 → PHASE_DEG（度）
  · 斜飞的月牙被压扁/拉长 → K（大=更扁，默认 0.5）
  · 方向顺序整体反了（比如朝右的用了朝左的图）→ 代码里 DIR_CCW 取反
