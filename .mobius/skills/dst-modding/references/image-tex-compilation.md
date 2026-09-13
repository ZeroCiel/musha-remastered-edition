# DST mod 图片 png→tex 编译链路（2026-09-04 实测）

## 核心机制
- DST UI 图加载的是 `.tex`（+ 单图 atlas `.xml`），**不是 png**。只更新 images/*.png 不改 tex，游戏里显示旧图。
- 编译触发：DST 启动加载 mod 时若检测到图片需要编译，**自动调用 autocompiler**，硬编码路径为 DST `bin` 的 `..\..\Don't Starve Mod Tools\mod_tools\autocompiler.exe`（即与 DST **同一个** `steamapps\common\` 下的 Mod Tools）。
- 库迁移坑：DST 从 C 库迁到 D 库后，若 Don't Starve Mod Tools 留在 C 库 → 自动编译静默失效（不报错，只是 tex 永不更新）。修复：`cp -r "C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Mod Tools" "D:\SteamLibrary\steamapps\common\"`（377MB）。

## 安全操作流程（换封面/换背景图）
1. 备份旧 `images/xxx.tex` + `xxx.xml` 到 `images/_bak/`（保留回滚）。
2. 确认 DST 同库有 Mod Tools（无则按上条复制）。
3. 把旧 tex/xml 移出 images/（**只留新 png**）。
4. 启动 DST 进任意世界 → 游戏自动编译，images/ 生成新 tex/xml（时间戳=启动时刻）。
5. 验证：tex/xml mtime 更新即成功。

## 大坑
- **只删 xml 期望游戏重编 = 启动崩溃**：modmain `Asset("ATLAS","images/xxx.xml")` 找不到文件 → `resolvefilepath` LUA ERROR，游戏直接 abort。旧 tex/xml 必须先备份再删，编译链路未就绪前不要删。
- 手跑 `autocompiler.exe` 不可靠：无参数只"注册编译器"就退出（日志在 `steamapps\common\temp\autocompiler_log.txt`，仅两行 compiler registered）；带 mod 路径参数实测 exit 0 不编译；GUI 在非交互会话起不来。**别手跑，靠 DST 启动自动编译**。
- `mod_tools/png.exe` 直接调用报 `Invalid number of arguments`，参数格式未公开（内部由 autocompiler 调用），别猜。
- 同一张图两份拷贝是常见状态（note_bg.png 与 musha_note_bg.png md5 相同），改图记得同步。

## 附带工具教训（同会话实测）
- 用 patch 工具对**同一文件**做多次 replace_all 修改时，**必须串行**（一次调用完成后等结果再发下一个）。并行发多个 patch 到同一文件，fuzzy matcher 会交叉匹配把行插错位置，文件被改乱（本次 musha_panel_screen.lua 被 4 个并行 patch 打乱，最后整文件重写修复）。
- 大段结构重排（多处删改+结构变化）直接用整文件 write_file 重写，比多个小 patch 稳。
- Lua 结构平衡粗查脚本可复用：剥注释/字符串后数 if/function/for/while 与 end 是否配平（skill 内 `scripts/lua_bracket_check.py` 思路一致）。
