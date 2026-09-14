生命树枝（武器）— 美术 + 接线（2026-09-14）
=============================================

做了什么
--------
用户给的那张树枝线条画（原始文件：C:\Users\Administrator\musha-backups\images_src_20260913\技能.png，
200x200 白底细线稿）→ 转成透明底，做了下面三样东西：

  1) 手持图（swap）   swap_lifebranch.png     512x512，握把在图片正中心
     - variants/swap_lifebranch_b.png   B 立起来（52°）
     - variants/swap_lifebranch_c.png   C 压平（16°）
     默认用的 A（原角度 34°）。
     _preview_swap_3角度_洋红底.png  = 三版并排预览（洋红底，青蓝十字 = 游戏里手的位置）

  2) 物品自体         musha_lifebranch-0.png  256x256（掉地上/背包里显示的那个）
  3) 背包图标         icon_musha_lifebranch.png  64x64 透明底
     → 要拷成 mods/musha/images/inventoryimages/musha_lifebranch.png 再打 tex/xml

为什么握把必须落在图正中心
--------------------------
DST 的贴图原点是图片正中心（scml 里 pivot 0.5/0.5）。角色手部的 swap_object 符号
按"图片中心 = 手握的位置"来贴，所以树枝的握把（主干底那个断面）必须画在正中心，
否则树枝会整根偏出去 / 像浮在手外面。
本图已按这个对齐：握把点 = (256,256)。

打包（DST Mod Tool，一次两个）
------------------------------
  1) exported/musha_lifebranch/swap_lifebranch.scml      → anim/swap_lifebranch.zip
  2) exported/musha_lifebranch/musha_lifebranch.scml     → anim/musha_lifebranch.zip
  3) icon_musha_lifebranch.png → images/inventoryimages/musha_lifebranch.png
     （然后照旧打 images/inventoryimages/musha_lifebranch.tex + .xml）

  ⚠️ zip 名 / entity 名 / 代码里的名字必须一致（本项目惯例，跟 musha_jobbook_warrior 一样）：
     swap_lifebranch.zip 里的 build 名 = "swap_lifebranch"
     musha_lifebranch.zip 里的 bank/build 名 = "musha_lifebranch"

想换角度（B 或 C）
------------------
  把 variants/swap_lifebranch_b.png（或 _c）复制成 swap_lifebranch.png 覆盖，
  重新导一次 swap_lifebranch.scml 就行，代码不用动。

嫌大 / 嫌小
-----------
  现在树枝在手里长度 ≈ 161 px（≈1.6 世界单位，跟原版矛差不多）。
  要改说一句"长一点/短一点"，我重生成（改一个数，10 秒）。

代码那边
--------
  scripts/prefabs/musha_lifebranch.lua   新建（照 musha_sword.lua 写的）
    · 攻击 12（LIFE_DAMAGE）、距离 0.4、tag musha_weapon
    · on_equip: OverrideSymbol("swap_object", "swap_lifebranch", "swap_lifebranch") + 手臂切换
    · ★ 升级机制（满级 18~24）按计划延后，没做
  modmain.lua  PrefabFiles 里加了 "musha_lifebranch"

怎么测
------
  控制台：c_spawn("musha_lifebranch")  → 捡起来装上 → 看手上有没有树枝
  （天数奖励系统本身还没做，所以现在只能控制台刷）
