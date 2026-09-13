# DST mod 图片 png → tex/.xml 编译流程（2026-09 实证）

适用：改 Musha/明生等 mod 的 images/*.png 背景图/图标后，游戏里不显示新图。

## 核心机制
- DST 运行**只加载 .tex 纹理 + .xml atlas 元数据**，不认裸 .png。modmain 里
  `Asset("ATLAS","images/xxx.xml")` + `Asset("IMAGE","images/xxx.tex")` 引用的是 tex/xml。
- 换 .png 后**不会自动重编**。DST(dontstarve_steam.exe) 启动加载 mod 时，若发现 png 比 tex 新
  或 tex 缺失，会去调 `..\..\Don't Starve Mod Tools\mod_tools\autocompiler.exe`
  （相对 DST `bin/` 上两级 = **同一个 steamapps\common 库**）。
- **坑（本会话根因）**：DST 从 C 库迁到 D:\SteamLibrary 后，Klei Don't Starve Mod Tools 留在
  C:\Program Files (x86)\Steam → DST 找不到 autocompiler → **静默失效**（不报错，只是 tex 永不更新）。
  修复：把整个 `Don't Starve Mod Tools` 复制到 DST 所在库的 common 下（约 377MB）。
- 症状区分：
  - 图不更新（游戏里还是旧图）→ autocompiler 没跑 / 不在同库。
  - 启动即 LUA ERROR `Could not find an asset matching images/xxx.xml` + assert 崩溃
    （Force aborting）→ tex/xml 被删但 DST 也没编：**xml 必须存在**，别指望 DST 从 png 自造 xml。

## 正确换图步骤
1. 备份旧 tex/xml 到 `images/_bak/`（可随时回滚）。
2. 放入新 png（尺寸随意，非方形也行，autocompiler 会按 bc3 方形 atlas 处理并写 uv 到 xml）。
3. 确认 `Don't Starve Mod Tools` 与 DST 在**同一个** `steamapps/common/` 库
   （现况：已复制到 `D:\SteamLibrary\steamapps\common\Don't Starve Mod Tools`）。
4. 启动 DST 进任意世界让 mod 加载 → 退出后检查 images/ 下 tex/xml 时间戳是否为今天。
5. 手动兜底：`.../Don't Starve Mod Tools/mod_tools/autocompiler.exe` 是 GUI 拖拽式：
   无参运行只注册 compilers.txt 里的编译器(png/scml)就退出（exit 0 无输出）；
   `png.exe` 是内部后端，参数个数不对只报 `ERROR: Invalid number of arguments!`。
   日志在 `<steamapps>\common\temp\autocompiler_log.txt`。

## UI 相关速记（Musha bookpage_bg 横版化 2026-09-03）
- Image `SetScale(单参)` = 等比缩放；`SetScale(w,h)` 双参 = 强拉，横竖图比例不符会变形。
- 图自带边框/红叉/按钮时：别叠代码边框，关闭键用透明 ImageButton 盖图上红叉位
  （坐标按图内元素 px 位置 × 渲染缩放估，需截图微调）。
- Musha 两处界面现状：skillui 卡 592x400、panel 卡 503x340，横版坐标与待办详见
  `mods/musha/musha-backlog.md`「职业面板」段。
