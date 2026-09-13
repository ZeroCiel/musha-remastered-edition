# 告示者动画替换 — mengyan占位 → bernie熊玩偶

## 已完成 (2026-08-05)

### 动画编译
- **scml编译修复**: 反编译不全导致缺失 `bernie_ear` 和 `bernie_tail` 文件夹（全是0x0空帧）
  - 创建1x1透明PNG占位 → scml.exe通过 → autocompiler生成 `gaoshizhe.zip`（1.5MB）
- **⚠️ autocompiler输出嵌套**: 生成到 `anim/anim/gaoshizhe.zip`，需手动移到 `anim/`
- **⚠️ 动画名坑**: bernie build没有"idle"动画！小玩偶休眠态叫 `inactive`
  ```
  inst.AnimState:PlayAnimation("inactive")  -- NOT "idle"
  ```

### Prefab最终状态
```lua
-- mingsheng_gaoshizhe.lua
Asset("ANIM", "anim/gaoshizhe.zip")
inst.AnimState:SetBank("gaoshizhe")
inst.AnimState:SetBuild("gaoshizhe")
inst.AnimState:PlayAnimation("inactive")
-- 物品栏图标仍用 mengyan 占位
```

### 代码改动
- **charge action**: 已充能→覆盖切换类型（同类型不浪费），未充能→照旧充能
- **handler**: 去掉 `not target._gaoshi_type` 限制，让已充能物品也能弹出充能菜单
- **deploy from inventory** (2026-08-07): 加 `mingsheng_useitem` 组件，SetFn 里 `DropItem` 丢脚下。`mingsheng_item` tag 不够，必须有同名组件才能触发 INVENTORY 右键。（参考 workshop 2863315795 的 namida_erniu_henshin 组件模式）

## 官方动画名对照（bernie_build）

| 形态 | 动画名 | 说明 |
|------|--------|------|
| 小玩偶 | `inactive` | 地面休眠状态 |
| 变身 | `activate` | 小→大过渡 |
| 大伯尼 | `idle_loop_down/up/side/nodir` | 四方向idle |
| 战斗 | `hit`, `death`, `knockback`, `taunt` | |
| 移动 | `walk_loop_down/up/side`, `walk_pre/post_*` | |
| 收工 | `deactivate` | 大→小过渡 |

⚠️ **没有简单的"idle"动画** — 必须用 `inactive`（小玩偶）或方向性 `idle_loop_*`（大伯尼）。

## scml编译修复流程

### 诊断缺失帧
```python
import re, os
scml = open('exported/name/name.scml').read()
folders_in_scml = set(re.findall(r'<folder id="\d+" name="([^"]+)"', scml))
actual_dirs = set(d for d in os.listdir('exported/name/') if os.path.isdir(...))
missing = folders_in_scml - actual_dirs
```

### 生成0x0占位PNG
缺失帧如果尺寸是 `width="0" height="0"`（空占位），创建1x1透明PNG即可。不需要PIL——用纯二进制构造。
```python
import struct, zlib, os
def minimal_png():
    raw = b'\x00\x00\x00\x00'
    ihdr = struct.pack('>IIBBBBB', 1, 1, 8, 6, 0, 0, 0)
    def chunk(t, d):
        c = t + d
        return struct.pack('>I',len(d)) + c + struct.pack('>I', zlib.crc32(c)&0xffffffff)
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR',ihdr) + chunk(b'IDAT',zlib.compress(b'\x00'+raw)) + chunk(b'IEND',b'')
```

### 编译
```bash
scml.exe exported/name/name.scml mod_dir/anim/
autocompiler.exe mod_dir
mv mod_dir/anim/anim/name.zip mod_dir/anim/
rm -rf mod_dir/anim/anim/
```
