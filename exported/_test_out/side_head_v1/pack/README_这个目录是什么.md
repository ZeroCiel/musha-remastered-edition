# 这个目录是什么（exported/musha v3/）

**v3 工作区** = 从 `exported/musha v2/` 整份复制的**新工作副本**（2026-09-19 23:2x 建）。
用途：**重置整个衣服套装**（torso / torso_pelvis / skirt）在这里做。
`exported/musha v2/` **保留不动**（留给可能的美术更新 / 回退对照）。

## 里面有什么（非 _bak 的全部）
- 19 个部件目录：arm_lower arm_upper arm_upper_skin cheeks face foot hair hair_hat
  hairfront hairpigtails hand headbase headbase_hat leg **skirt swap_icon tail torso torso_pelvis**
- `musha_v2.scml`（工程文件，1022615 B，与 v2 那份逐字节相同；含 19 folder / 39 key / 156 图）
- `musha_v2.zip`（Spriter/build 源导出件，2178658 B，13:17 那份）
- 本目录**不含** v2 的 `_bak_*` 历史备份（只留在 v2 里）

与 v2 的差异核对：`diff -rq "musha v2" "musha v3"` 排除 `_bak` 后 → **完全一致（0 处不同）**。

## 编译（命令行，不用开 Mod Tool GUI）
```
SCML="/d/SteamLibrary/steamapps/common/Don't Starve Mod Tools/mod_tools/scml.exe"
"$SCML" "$(cygpath -w "<本目录>/musha_v2.scml")" "$(cygpath -w "<出参目录>")"
# → <出参目录>/anim/musha_v2.zip
```
⚠️ **build 名 = scml 文件名**：拿 `musha_v2.scml` 编出来的是 `musha_v2`，游戏里要的是 `musha`。
要出能进游戏的包 → 先拷一份**改名成 `musha.scml`** 再编（r16 就是这么做的）。
⚠️ `scml.exe` 必须吃 **Windows 路径**（bash 里 `cygpath -w`；给 `/d/...` 会报 Could not open）。

## 衣服三件现状（`exported/musha/` 原版与 v3 逐字节相同 → 还没动过）
| 部件 | 帧数 | 实际 PNG 尺寸 | scml 声明 | 备注 |
|---|---|---|---|---|
| torso | 11（-0..-10） | 160x120 ×6（-0,-1,-2,-6,-7,-8）/ 120x120 ×3（-3,-4,-5）/ 90x120 ×1（-9）/ 80x120 ×1（-10） | 与文件一致 | 原版美术 |
| torso_pelvis | 11（-0..-10） | 80x68 ×9（-0..-8，9 张**同一张图**）/ 90x67（-9）/ 90x68（-10） | 与文件一致 | 原版美术 |
| skirt | 5（-0..-4） | **100x100 ×5（全是同一张 579 B 全透明）** | **声明 160x120** ⚠️ 不一致 | 占位透明，要重画 |
| tail | 12 | 100x100（透明占位，与 skirt 同一张图） | 声明 250x100 ⚠️ | 不在本次范围 |
| swap_icon | 1 | 201x244 | — | 物品栏形象 |

⇒ **重置口径**：三件都按上表的**实际尺寸**画（skirt 若要 160x120 就把 scml 声明一起改，别只改图）。

## 铁律（别踩）
- **美术/动画没定稿前不许打包进 `anim/`**（用户 2026-09-18 拍板）；本目录怎么编都行，别覆盖 `mods/musha/anim/*.zip`。
- 改衣服 = **在原有符号的图里改**，别往 scml 里加新符号 / 拆图层（官方动画没引用 → 游戏里不显示，还会占 z_index 撞号）。
- 换完要出「原版 vs 新版」对照图 + 逐像素差异百分比。
