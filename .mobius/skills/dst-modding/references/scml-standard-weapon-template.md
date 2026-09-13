# 标准武器 SCML 模板（Spriter 导出工作流）

## 场景

画师（或单主自己）在 `exported/` 目录下建了 `BUILD/` 文件夹并放了各帧 png，需要你**写 SCML 文件**把帧串成动画（idle/attack/drop）。

## 标准武器 SCML 结构

DST 武器需要**两个** SCML 项目：

1. **本体** (`book_weapon.scml`) — 放地上/掉落时的样子
2. **手持** (`swap_book_weapon.scml`) — 角色拿在手上时的样子

两者都可以**共用同一个 BUILD 文件夹**里的贴图。

## SCML 文件写法

### book_weapon.scml（本体）

```xml
<?xml version="1.0" encoding="UTF-8"?>
<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="r7">
    <folder id="0" name="BUILD">
        <file id="0" name="BUILD/BUILD-01.png" width="1024" height="1024" pivot_x="0.5" pivot_y="0.5"/>
        <file id="1" name="BUILD/BUILD-02.png" width="1024" height="1024" pivot_x="0.5" pivot_y="0.5"/>
        <file id="2" name="BUILD/BUILD-03.png" width="1024" height="1024" pivot_x="0.5" pivot_y="0.5"/>
    </folder>
    <entity id="0" name="book_weapon">
        <animation id="0" name="idle" length="1000" interval="100">
            <mainline>
                <key id="0">
                    <object_ref id="0" timeline="0" key="0" z_index="0"/>
                </key>
            </mainline>
            <timeline id="0" name="book_weapon">
                <key id="0" spin="0">
                    <object folder="0" file="0" pivot_x="0.5" pivot_y="0.5" angle="0"/>
                </key>
            </timeline>
        </animation>
    </entity>
</spriter_data>
```

### swap_book_weapon.scml（手持）

```xml
<?xml version="1.0" encoding="UTF-8"?>
<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="r7">
    <folder id="0" name="BUILD">
        <file id="0" name="BUILD/BUILD-01.png" width="1024" height="1024" pivot_x="0.5" pivot_y="0.5"/>
        <file id="1" name="BUILD/BUILD-02.png" width="1024" height="1024" pivot_x="0.5" pivot_y="0.5"/>
        <file id="2" name="BUILD/BUILD-03.png" width="1024" height="1024" pivot_x="0.5" pivot_y="0.5"/>
    </folder>
    <entity id="0" name="swap_book_weapon">
        <animation id="0" name="idle" length="1000" interval="100">
            <mainline>
                <key id="0">
                    <object_ref id="0" timeline="0" key="0" z_index="0"/>
                </key>
            </mainline>
            <timeline id="0" name="swap_book_weapon">
                <key id="0" spin="0">
                    <object folder="0" file="0" pivot_x="0.5" pivot_y="0.5" angle="0"/>
                </key>
            </timeline>
        </animation>
        <animation id="1" name="attack" length="1000" interval="100">
            <mainline>
                <key id="0">
                    <object_ref id="0" timeline="0" key="0" z_index="0"/>
                </key>
                <key id="1" time="500">
                    <object_ref id="0" timeline="0" key="1" z_index="0"/>
                </key>
            </mainline>
            <timeline id="0" name="swap_book_weapon">
                <key id="0" spin="0">
                    <object folder="0" file="0" pivot_x="0.5" pivot_y="0.5" angle="0"/>
                </key>
                <key id="1" spin="0">
                    <object folder="0" file="1" pivot_x="0.5" pivot_y="0.5" angle="-30"/>
                </key>
            </timeline>
        </animation>
    </entity>
</spriter_data>
```

## 关键规则

### folder/file 定义

```xml
<folder id="0" name="BUILD">
    <!-- id 从0开始，递增 -->
    <!-- name 是文件夹名（相对scml文件的路径） -->
    <file id="0" name="BUILD/BUILD-01.png" width="1024" height="1024" pivot_x="0.5" pivot_y="0.5"/>
</folder>
```

- `pivot_x` / `pivot_y` — 旋转/缩放的中心点，0.5=中间。武器一般设0.5
- `width` / `height` — png实际尺寸，必须填对

### animation 结构

```xml
<animation id="0" name="idle" length="1000" interval="100">
    <mainline>
        <key id="0">
            <object_ref id="0" timeline="0" key="0" z_index="0"/>
        </key>
    </mainline>
    <timeline id="0" name="xxx">
        <key id="0" spin="0">
            <object folder="0" file="0" pivot_x="0.5" pivot_y="0.5" angle="0"/>
        </key>
    </timeline>
</animation>
```

- `length` — 动画总时长（毫秒），1000=1秒
- `interval` — 每帧间隔（毫秒），100=10fps
- `object_ref` 的 `timeline` — 指向 timeline 的 id
- `object` 的 `folder` / `file` — 指向 folder 和 file 的 id
- `angle` — 旋转角度，正=顺时针

### 多帧 attack 动画

多帧 = 多个 `key`：

```xml
<animation id="1" name="attack" length="1000" interval="100">
    <mainline>
        <key id="0">                          <!-- 第0ms -->
            <object_ref id="0" timeline="0" key="0" z_index="0"/>
        </key>
        <key id="1" time="500">               <!-- 第500ms -->
            <object_ref id="0" timeline="0" key="1" z_index="0"/>
        </key>
    </mainline>
    <timeline id="0" name="swap_book_weapon">
        <key id="0" spin="0">                 <!-- 对应object_ref key=0 -->
            <object folder="0" file="0" pivot_x="0.5" pivot_y="0.5" angle="0"/>
        </key>
        <key id="1" spin="0">                 <!-- 对应object_ref key=1 -->
            <object folder="0" file="1" pivot_x="0.5" pivot_y="0.5" angle="-30"/>
        </key>
    </timeline>
</animation>
```

### entity 名字必须匹配

- `entity name` — 必须等于 build 名（即 .zip 文件去掉拓展名）
- 本体: `name="book_weapon"` → 编译为 `book_weapon.zip`
- 手持: `name="swap_book_weapon"` → 编译为 `swap_book_weapon.zip`
- DST 代码里：`SetBank("book_weapon")` / `OverrideSymbol("swap_object", "swap_book_weapon", "swap_book_weapon")`

## 最终目录结构

```
exported/book_weapon/
├── BUILD/
│   ├── BUILD-01.png        ← idle 帧（书闭合待机）
│   ├── BUILD-02.png        ← attack 帧1（书举起）
│   └── BUILD-03.png        ← attack 帧2（书砸下）
├── book_weapon.scml         ← 本体Spriter项目
└── swap_book_weapon.scml    ← 手持Spriter项目
```

## 编译（exported → anim）

画师做完 scml + png 后，需要编译成 DST 能读的 zip。两种方式：

### 方式1：Krane（推荐）

```bash
krane exported/book_weapon/ anim/
```

### 方式2：Autocompiler

把 scml 拖进 Autocompiler 窗口即可。

## 常见陷阱

### 1. png 路径错误

```xml
<!-- ❌ 错误：路径不对 -->
<file name="BUILD-01.png" .../>

<!-- ✅ 正确：要包含文件夹名 -->
<file name="BUILD/BUILD-01.png" .../>
```

### 2. pivot 不对导致动画偏移

武器类的 pivot：`pivot_x="0.5", pivot_y="0.5"`（中心）。如果设成 0 则左上角为锚点，看起来会飘。

### 3. entity 名字不匹配 build

```xml
<!-- ❌ entity name 是 "my_weapon"，但代码里 SetBank("book_weapon") → 找不到 -->
<entity id="0" name="my_weapon">

<!-- ✅ entity name 必须等于 build 名 -->
<entity id="0" name="book_weapon">
```

### 4. Bug: 拷贝 scml 时没看到内容

大部分 mod 的 scml 是空文件（0 KB），只是占位。真正的动画定义在 zip 里。所以**不要直接从其他 mod 拷贝 scml 来用**，要自己写。

但如果找不到手写 scml 的参考，可以看 Musha mod 的 `musha_jobbook_warrior.scml` — 它有真实的 xml 内容。

### 5. png 文件太大（> 500KB）可能导致性能问题

BUILD 里的 png 一般是每个图层分开的小图（几KB~几十KB），不是整张大图。如果用户放的是大图（~1MB），需要切成子图层小图。

## 给单主的话术

> exported/book_weapon/ 下 BUILD/ 里你的png已经有了，我补了 book_weapon.scml 和 swap_book_weapon.scml。
>
> 当前结构：
> - BUILD-01.png → idle 动画
> - BUILD-02.png → attack 第一帧（举起）
> - BUILD-03.png → attack 第二帧（砸下，角度-30°）
>
> 你用Spriter打开 scml 就能看到动画了。要改帧数、角度、pivot，直接编辑scml或用Spriter改都行。
>
> 改完后用krane编译：
>   krane exported/book_weapon/ anim/
> 就能进游戏测了。
