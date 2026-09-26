# sp_model_tool —— DST Spriter（Sp）模型工具

2026-09-25 夜间按 opencode（`exported/_tools` + hermes `dst-art-pipeline`）的口径重建。
窗口化预览 · 逐帧截图 · 视觉审片任务书 · scml 总成编写 · 官方工具链编译，一条龙。

## 用法

```bash
# 窗口化预览（scml 工程或编译 anim zip 都行）
python sp_model_tool.py 源.scml
python sp_model_tool.py anim\musha_recall_stone.zip

# 无头逐帧截图：frame_XX.png（可 --bg magenta/black/white/game/checker）
#   + _alpha\ 透明底原帧 + 00_总表_洋红底.png + manifest.json + REVIEW_TASK.md（审片任务书）
python sp_model_tool.py 源 --export 出目录 --scale 2 --bg magenta

# 总成演示（编写→scml→scml.exe 编译→解码→逐帧截图 全链路，沙箱目录）
python sp_model_tool.py --demo 出目录

# 窗口自检（真实开窗渲染 + 抓屏存 _tmp/_selftest_window.png）
python sp_model_tool.py 源 --selftest
```

GUI 里有：播放/暂停、逐帧、缩放（0.25x–8x）、棋盘格/洋红/黑/白/游戏绿底、
**📸 逐帧截图导出**、**🔨 编译（scml.exe → anim/）**、打开其他源。

## 两种源

| 模式 | 输入 | 说明 |
|---|---|---|
| scml 工程 | `exported/<name>/<name>.scml` | 按 25ms 网格采样（= scml.exe 落帧口径），台阶保持 |
| 编译 zip | `anim/<name>.zip` | anim.bin + build.bin + atlas-0.tex，所见 = 游戏所见 |

## ⚠️ 重大发现（2026-09-25 夜）：anim 图集是垂直倒序存储的

**anim 图集（KTEX flag `0xfffd…`——scml.exe 编的和官方 anim 包都是）在解码视图里，
每张源图都是上下颠倒存的；引擎加载时自行翻转回来。物品栏图标 tex（flag `0xfffc`）不翻。**

证据（全部 MAE 实测，"上下翻"完胜）：
- 回城石 item.png：图集存储 vs 原图 上下翻 **13.5** / 原图 79.1
- 信差包源图：anim 帧 vs 源图 上下翻 **34.8** / 原图 64.0
- musha 角色 face 符号（游戏内正确）：干净帧 上下翻 **3.4~12.8**
- 官方 wilson `swap_icon`（游戏 UI 人人见过）：解码视图里**发梢朝下**

推论与勘误：
1. **游戏里素材是正的**（引擎负责翻）——别因此去改源图！
2. `dump_anim_frames.py` 的渲染 **placement 正确、像素上下颠倒**（其"v 不翻转"口诀只对
   定位区域成立）；之前的 wilson/回城石预览都是倒的。本工具已补 `FLIP_TOP_BOTTOM`。
3. 顶点数据佐证：build 顶点 `+y ↔ 较小 v`，而图集里"较小 v"一端存的是源图底边。
4. KTEX 头部 flag 高位随宽度变化（128→0x2 … 2048→0x8），`0xfffd/0xfffc` 家族区分 anim/UI。

## scml 房规（工具的 write_scml 已内置，别再手写 scml）

1. `folder` 的 **name = build 里的 symbol 名**（一个 folder 一个 symbol，多 file = 多帧）
2. key 里的 `scale_x/scale_y` **会被 scml.exe 忽略** → 目标尺寸烘进 PNG，声明 1:1
3. key 必须带 `time=`（25ms 网格）+ `curve_type="instant"`，无 time 会塌帧
4. **mainline 每帧一个 key**（object_ref key=i 逐帧指过去），换帧动画的灵魂
5. `pivot 0.5/0.5` 居中；scml 的 `<file width height>` = PNG 实际像素
6. **x/y 位移会被 scml.exe 线性插值**（`instant` 只管换帧，不管坐标）——位移动画里
   需要"停住"的段落必须逐帧钉同值键，否则两键之间自动补间（射箭原型 f6-7 双箭即此）

## scml.exe 调用坑

`scml.exe <file.scml> <outdir>` → 产物在 `<outdir>/anim/<name>.zip`。
**输入必须用相对 cwd 的裸文件名（cwd = scml 所在目录）**，输出目录给绝对路径；
给绝对路径输入时 scml.exe 会把输入拼到输出目录下然后报 Could not open。

## 夜间工作日志（2026-09-25）

1. 调研 opencode 工具链（hermes dst-art-pipeline 76KB SKILL.md + 100+ 篇 reference + 30 脚本；
   `_tools` 的 musha_scml_render / dump_anim_frames / pnglib）
2. 写 `sp_model_tool.py`（tkinter GUI；zip/scml 双引擎；逐帧截图+总表+审片任务书；
   write_scml 编写器；scml.exe 编译封装；--selftest 窗口自检）
3. 双模式对照测试时发现 zip/scml 渲染上下颠倒 → 四路 MAE 取证 → 确认图集倒序存储 +
   引擎自行翻转（见上节）→ 工具修正，zip/scml 逐像素差异 51.6% → 12.5%（余为 BC3 压缩噪声）
4. 官方 wilson idle 渲染验证：修正后输出标准威尔逊（发梢朝上、身体端正）
5. 总成演示 `--demo`：write_scml 生成 8 帧呼吸动画（3 档缩放烘进 PNG + 光晕垫底）→
   scml.exe 编译 → 解码 → 逐帧截图，全链路 ✅（`_test_out/sp_tool_demo/`）
6. GUI 自检：真实开窗 + 渲染 + 抓屏 ✅（`_tmp/_selftest_window.png`）
7. 视觉模型审片：回城石 40 帧 + 演示 8 帧，审查报告见 `夜间报告_20260925.md`

## 已知边界

- scml 采样为台阶保持（instant 语义），不支持补间曲线预览（本 mod 动画全是不补间的换帧/静态）
- zip 模式忽略 anim.bin 元素矩阵的 a/b/c/d（本 mod 的动画矩阵均为单位阵；若以后用
  Spriter 做了旋转/缩放动画需要再补矩阵渲染）
- dump_anim_frames.py 是 opencode 的文件，未改动；其预览颠倒问题本工具已绕开
