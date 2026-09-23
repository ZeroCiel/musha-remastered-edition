# musha_cloth_v01 —— 皮肤模板（自动生成）

生成工具：`exported/_tools/make_skin_template.py`（源 = `build.xml` + `animation.xml` + 贴图）

## 这个工程是什么

- Spriter 工程（`.scml`）+ 每符号一个子文件夹的贴图槽，可直接用 Mod Tool / `scml.exe` 编译成
  `anim/musha_cloth_v01.zip`（包内 build 名 = `musha_cloth_v01`，动画名 = `BUILD_PLAYER`）

- 19 个符号、156 张图、39 个 key（`BUILD_PLAYER` 长度 975）。**实测：源数据里这 39 帧完全相同**
  （DST 角色 build 的惯例 = 单姿态模板，游戏动作由 bank 提供），每个 key 里排着 3 列朝向部件（x≈-325 / 0 / +352）
- 坐标系：Spriter 的 y 向上为正；pivot 就是每帧贴图的「锚点」，**改图不要改 pivot**，
  画布尺寸（每帧的 w×h）也**必须保持**，否则会错位

## 画皮肤怎么用（推荐流程）

1. `参考图/` 里每个符号都有帧表（红十字符号 = pivot 位置）→ 交给画师/ChatGPT 当参考
2. 按「符号 > 帧号」逐张替换 `<符号>/<符号>-N.png`，**尺寸必须等于帧表里标的 w×h**
3. 编译：`scml.exe <本目录>/musha_cloth_v01.scml <输出目录>` → `<输出目录>/anim/musha_cloth_v01.zip`
4. 把 zip 放进 `mods/musha/anim/`，代码里 `SetBuild("musha_cloth_v01")`（或做皮肤切换）

## 符号表

| 符号 | 帧数 | 画布尺寸（各帧） | 说明 | 占位/缺图 |
|---|---|---|---|---|
| `headbase_hat` | 5 | 206x187, 225x225, 225x263 | 头（戴帽版本，配合帽子遮挡） |  |
| `torso_pelvis` | 11 | 120x90, 80x90 | 腰胯/下摆 |  |
| `cheeks` | 2 | 64x60 | 腮红 |  |
| `hair` | 4 | 75x100, 75x75 | 头发（后发/发束） |  |
| `arm_upper_skin` | 3 | 40x40, 40x80 | 上臂露肤部分 |  |
| `skirt` | 5 | 160x120 | 裙子（当前是空白占位，要画） | ⚠ 源里是空图/被缩放：skirt-0, skirt-1, skirt-2, skirt-3, skirt-4 |
| `foot` | 8 | 50x50 | 脚（鞋子，8 帧朝向） |  |
| `torso` | 11 | 120x120, 160x120, 80x120 | 上衣/躯干（衣服正面背面分帧） |  |
| `swap_icon` | 1 | 201x244 | 手持物品时的替换图标（单帧） |  |
| `hairfront` | 2 | 400x400 | 前刘海 | ⚠ 源里是空图/被缩放：hairfront-0, hairfront-1 |
| `leg` | 11 | 60x60, 60x80 | 腿（裤子） |  |
| `face` | 33 | 100x75, 125x100, 125x125, 125x150, 150x100, 150x125, 150x75, 50x75 | 表情（33 帧，正面/侧面/背面 + 各种表情） |  |
| `hair_hat` | 4 | 400x400 | 帽子压住的头发 | ⚠ 源里是空图/被缩放：hair_hat-0, hair_hat-1, hair_hat-2, hair_hat-3 |
| `hand` | 20 | 50x50, 50x75, 75x100, 75x50, 75x75, 75x78 | 手（20 帧：张手/握拳/持物/不同朝向） |  |
| `tail` | 12 | 250x100 | 尾巴（12 帧，狐狸尾巴分段） | ⚠ 源里是空图/被缩放：tail-0, tail-1, tail-2, tail-3, tail-4, tail-5… |
| `hairpigtails` | 5 | 125x187, 156x187, 93x187, 94x225 | 双马尾 |  |
| `headbase` | 5 | 206x187, 225x225, 225x263 | 头（基础头型，多帧=正/侧/背等朝向） |  |
| `arm_upper` | 7 | 60x80, 80x80 | 上臂（衣服袖子） |  |
| `arm_lower` | 7 | 50x50, 50x80, 60x60, 80x50 | 小臂（衣服） |  |

## 编译检查（照抄）

```bash
"D:\SteamLibrary\steamapps\common\Don't Starve Mod Tools/mod_tools/scml.exe" "<本目录>/musha_cloth_v01.scml" "<输出目录>"
```

## 已知注意

- 源包里 `tail` / `hairfront` / `hair_hat` / `skirt` 是 100x100 全透明占位（真实画布更大，见上表）：
  这几个槽位在游戏里本来就看不见，**要显示就得按表里的尺寸重画**。
- 包内图层名与原工程的重名编号可能不同（只影响 `AnimState:Hide(图层名)` 这类按名字隐藏的代码，不影响显示）。
