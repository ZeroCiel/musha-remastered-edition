# 美术贴图更新接口（art_update.py）

给 agent / 人工用的统一入口：**PNG 源图 → 游戏可读的 .tex/.xml**。
游戏只认 `.tex`+`.xml`，光换 `images\xxx.png` 不生效——必须过这个接口。

## 三条命令

```bat
python exported\_tools\art_update.py status
    列出 images\ 里 png 比 tex 新（没转）或缺 tex 的文件。
    全绿示例：images/ atlases: 27 up-to-date, 0 STALE, 0 MISSING tex

python exported\_tools\art_update.py convert <png路径> [--out <xx.tex>]
    原地转换：给任意 png 生成旁边的 .tex/.xml（不动 images\）。
    用于先验证、或转非 images\ 目录的图。

python exported\_tools\art_update.py publish <png路径> <图名>
    正式发布：旧图先备份 → 复制进 images\<图名>.png → 转 .tex/.xml。
    例：python exported\_tools\art_update.py publish exported\_tools\_panel_probe\merged_full.png panel_bg
```

- 图名可带/不带 `.png` 后缀；输出名以图名为准（xml 里的 `filename` 自动对应）。
- 转换器默认 `D:\SteamLibrary\steamapps\common\Don't Starve Mod Tools\mod_tools\png.exe`，
  可用 `--png-exe` 或环境变量 `MUSHA_PNG_EXE` 覆盖。
- 备份落在 `exported\_tools\_art_backup\<图名>_<时间戳>\`（png+tex+xml 三件），回滚=拷回去。
- 控制台输出**故意用英文**（GBK 控制台显示中文 UTF-8 会乱码），文档看本文件。

## 硬规则

1. **先过目再 publish**：覆盖 images\ 是单向操作（对游戏而言），改图先出预览给用户看。
2. **改完必须完全重启游戏**才生效（包括只 convert 后手动拷贝的情况）。
3. `status` 必须全绿再交付；有 STALE/MISSING 说明 tex 没跟上，游戏跑的是旧图。
4. 只动 musha\ 自己的图；不碰其他 mod / 原皮资源。

## 本目录工具清单

| 文件 | 用途 |
|---|---|
| `art_update.py` | **统一接口（上面三条命令）** |
| `art_manager.exe` | **管理窗口（用户用）**：列状态/发布 PNG/打开目录；源码 `art_manager.cs`（系统 csc 离线编译，须 UTF-8 带 BOM），自检 `--dump <file>`、`--publish <png> <图名>`，`art_manager.cfg` 首行可覆盖 png.exe 路径 |
| `pnglib.py` | 纯标准库 PNG 读写（无 PIL 环境用） |
| `panel_merge_frames.py` | panel_bg 两框合并手术（生成 `_panel_probe\merged_full.png`） |
| `panel_merge_probe*.py / _cmp / _residue / _verify` | 合并手术的探针与校验（改手术逻辑时配套跑） |
| `_panel_probe\` | 合并产物与对比裁片（merged_full.png / merged_side_by_side.png 等） |
| `_art_backup\` | publish 自动备份（按时间戳一图一夹） |

panel_bg 合并工作流（2026-09-25 状态：**已发布、页框已接线，等完全重启进游戏验证**）：
```
panel_merge_frames.py   -> _panel_probe\merged_full.png     （手术+校验，重跑即再生成）
art_update.py publish exported\_tools\_panel_probe\merged_full.png panel_bg
musha_panel_screen.lua 页框接线（五页 frame 挂 (61,4)、932x638 —— 算法见该文件注释）
完全重启游戏
```

## png.exe 底层用法（接口已封装，备用）

```
png.exe <输入.png> <输出.tex>     （在输出目录下执行；同名 .xml 自动生成）
```
验证过：同图转换 MD5 逐字节一致（确定性转换）。
