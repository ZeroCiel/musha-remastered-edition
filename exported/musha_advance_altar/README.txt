祭坛美术草稿（2026-09-13）
=========================

文件
----
  altar_draft_v2_topview.png   ★ **用户认可的版本（2026-09-13，俯视 + 韩风）**，320x280，以这版为基准
  _preview_altar_v2.png        v2 预览：原尺寸 + 50% 缩小并排
  altar_draft_256x320.png      ① v1 正面立柱版 —— 用户否掉了（"不太行"），留档别用
  _preview_altar.png           v1 预览

v2 定下来的方向（用户 2026-09-13："已经行了"）
----------------------------------------------
· 视角：**从上往下看** —— 主体是宽扁椭圆台面（看得到台面 + 侧壁厚度），不是正面立柱
· 风格：**韩风** —— 台面柔和径向渐变（中亮边深）、暖棕描边（不用纯黑）、整体提亮（冷石灰 + 金色点缀）
· 结构：三层阶梯圆台 + 台面一圈金色符文点 + 中心悬浮金色晶体（带光晕）+ 地面投影
· 台座形状保持**圆形**、视角保持**较俯视**、发光照这版（用户没要求改）

这是什么
--------
不是成品美术，是**构图/比例草稿**。照"魔兽3 祭坛"那种构图做了变形改造：
抬高的双层献祭台座 + 方尖碑式立柱 + 碑面符文 + 上方悬浮的暖黄圣物，
配色换成饥荒/musha 这套：深棕描边 + 冷石灰 + 暖黄魔光。

进游戏要准备什么（祭坛是"结构"，不是物品，和武器/物品那套不一样）
------------------------------------------------------------------
1. 一套 build（`anim/musha_advance_altar.zip`）+ 动画
   v1 **只要一条 idle** 就能放进去（祭坛基本是静物）；
   想要有交互反馈再加：interact（交任务/对话）、activate（进阶成功那一下）
2. 放进 `mods/musha/anim/` 后，改 `scripts/prefabs/musha_advance_altar.lua` 文件头：
   · ALTAR_BANK  / ALTAR_BUILD  ← 改成新 zip 里的 bank / build 名
   · assets 表里两行 Asset("ANIM", ...) ← 换成新路径，删掉原版雕像那两行
   （bank/build 名 = 导出时 Spriter 工程名 / anim.bin 里的 build 名；不对会 assert）
3. 现在的占位 = 原版麦斯威尔雕像（statuemaxwell）。

★ 2026-09-13 更新：上面 2、3 两条**已经不用手改了** —— prefab 里改成一个开关了：
     local USE_CUSTOM_MODEL = false  →  打包好之后改成 true 就行
   （bank/build/anim/assets 都会自动跟着换；另有一个 ALTAR_SCALE 用来微调大小）

已经做好、等打包的东西（2026-09-13）
------------------------------------
  musha_advance_altar.scml               Spriter 工程：单帧、动画名 idle、320x320
  musha_advance_altar-0.png              贴图帧
  _preview_altar_frame_320_洋红底.png     洋红底预览（中间黑十字 = 游戏里的原点/落地点）

  打包（只做一次，DST Mod Tool）：
    1) 打开 D:\饥荒开发\tool\DST Mod Tool.exe → 用它的 scml → zip 那个功能
    2) 选 exported/musha_advance_altar/musha_advance_altar.scml → 导出
    3) 会出两个 zip：musha_advance_altar.zip + musha_advance_altar_build.zip
    4) 两个都拷进 mods/musha/anim/  →  然后改 prefab 里那行开关

  为什么帧图平移过（重要，别直接拿草稿图去打包）
    · DST 的贴图原点 = 图片正中心（scml 里 pivot 0.5/0.5）
    · 所以祭坛的"落地点"必须画在图片正中心，否则游戏里会浮空或者沉进地里
    · 草稿原图 320x280 里底面椭圆中心在 (159,193) → 平移成 320x320，让它在 (160,160)

尺寸参考
--------
DST 里麦斯威尔雕像大概 2 个世界单位高。草稿 256x320 是"柱子偏瘦高"的比例，
嫌高就把台座加宽、碑身压矮——比例你定，我按你给的尺寸重画或直接改。
（v2 俯视图：底面椭圆 262 px 宽 ≈ 2.6 世界单位，碰撞半径写的是 1.1，差不多。）
