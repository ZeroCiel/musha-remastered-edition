# 面板打不开：`io.open` 非法路径抛 `invalid filepath` 炸掉整个构造

musha 0.7.9，2026-09-24 实测。当时连查两三天无果，根因是**三层叠加**，缺一层都复现不出来。

## 1. 症状（务必对照，别再从头猜）

技能书右键 / （当时还有）B 键 / `musha_open_skill_panel` 事件**全都触发了**，UI 却完全不出现。
`client_log.txt` 里这一串是稳定的（连续十几场一模一样）：

```
[Musha Panel Register] 面板入口(Screen)已注册        ← 注册 OK
[Musha Panel] 打开请求 from=event owner=xxxx - musha   ← 事件 OK
[Musha Panel] 文件开始加载 (Screen 版)
[Musha Panel] 返回 MushaPanelScreen                   ← require OK
[Musha Edit] starting init
[Musha Panel] 构造失败: [string "../mods/musha/scripts/screens/musha_edit_mo..."]:150: invalid filepath
```

★ **`构造失败:` 后面那串 `[string "..."]:NNN: <msg>` 就是精确的 `文件:行号:原因`，直接照它改，不要猜。**

## 2. 根因：三层叠加

### ① DST 魔改 Lua 的 `io.open` 对非法路径是 **`error()`，不是返回 `nil + errmsg`**
- 错误串 `invalid filepath` 在 exe 的 **Lua 错误串表**里（紧挨 `file is already closed` /
  `invalid format`），所以是 C++ 侧抛的，**在全部 Lua 脚本里搜不到出处**（已全量搜过 `scripts.zip`，零命中）。
- 实测**非法**：以 `/` 开头的根路径，如 `"/musha_edit_log.json"`。
- 实测**合法**：裸文件名（原版 `scripts/debugcommands.lua:4536` `local SCANLAYOUT_SAVE_DIR = ""`
  → `save_path = filename..".tmx"`；还有 `"profile.txt"` / `"MISSINGSTRINGS.lua"`）、
  子目录相对路径（`"databundles/hashes.txt"`、`"scripts/screens/redux/scrapbookdata.lua"`）。
- 结论：**判路径可用性只能靠 `pcall(io.open, p, "r")`** —— 不抛 = 合法；
  文件不存在只是返回 `nil`，**不算非法**。这两种失败形态必须区分开。

### ② 路径拼接拿到了 `nil`
`_G.ModPath` 只存在于 mod env —— `scripts/mods.lua:330` 只注入了 `MODROOT`（以及 `modname`/`GLOBAL`）。
经 `pcall(require, "screens/xxx")` 进来的文件跑在**全局 env**，取不到 → `""` →
`(EditMode._dir or ".")` 之外的拼法直接得到根路径。

> 注意：全局 env 读未声明全局会被 **strict.lua** 拦下报
> `variable 'ModPath' is not declared` —— 这就是该 bug 的**上一个版本**的日志形态。
> 所以"先 `_G.` 包 pcall 取"是必要的，但取到 nil 后**不能拿去拼路径**。

### ③ 这一行没包 `pcall`
错误穿透模块、被 `OpenMushaPanel` 的 `pcall(mod, owner)` 兜住 → 打印"构造失败" → **直接 return** →
面板**从来没执行 `TheFrontEnd:PushScreen`**。所以症状是"完全没反应"，而不是"报错红字"。

## 3. 通用规则（照抄）

- ★ **任何辅助子系统（编辑模式 / 日志 / 持久化 / 统计）在 Screen 构造函数里跑时，
  必须整体 `pcall(function() ... end)`，它挂了不能拖累主功能。**
  同款规则见 `panel-content-pages.md` 第 37 行（"必须 pcall + 内联兜底"）。
- ★ **`io.open` 在 DST 里路径非法会抛错**，别假设它一定返回 `nil`。
- ★ **别猜路径**：列候选 → 逐个 `pcall` 探测 → 全失败就退回
  `TheSim:SetPersistentString(name, data, encode)`（官方 API，**不做路径校验**，
  落点 `<Klei>\DoNotStarveTogether\mod_config_data\<name>`，真实文件，外部工具可直接读）。
  冒号调用签名按 `scripts/mainfunctions.lua:27`：`TheSim:SetPersistentString(name, data, encode[, cb])`。

## 4. 现行实现（`scripts/screens/musha_edit_mode.lua`）

- `EditMode.PERSIST_KEY = "mod_config_data/musha_edit_log"`
- `EditMode._io_path()`：探测结果缓存在 `_resolved`；候选顺序
  `../mods/musha/musha_edit_log.json` → `mods/musha/...` → `musha_edit_log.json`；全失败返回 `nil`。
- `EditMode._path()`：给日志打印用，**永远返回字符串**（拿不到 io 路径就回退 `PERSIST_KEY`），
  避免调用方 `.. _path()` 拼接时又炸一次。
- `load()` / `save()`：所有 `io.open` 都包 `pcall`，本模块保证**永不向上抛错**。
- `save()` 开头 `if next(EditMode.buffer) == nil then EditMode.init() end`
  —— 防静默丢数据：`buffer` 只有 `init()` 会填，若 `save()` 先于 `load()` 被调到，
  会写出一个 `elements` 为空的 JSON，**Hermes 读到空表且日志毫无报错**。
- 面板侧（`musha_panel_screen.lua`）：整段编辑模式收进 `local _eok, _eerr = pcall(function() ... end)`，
  失败只 `print("[Musha Edit] 初始化失败（面板不受影响）: ...")`，面板照常打开。

## 5. 验证方式（这次用的，下次照用）

- **语法**：`pip install lupa` → `lupa.luajit20`（LuaJIT = Lua 5.1，与 DST 同代）
  → `lua.compile(src)`，全 mod 75 个 lua 一次性扫，0 失败。**别靠肉眼数 `end`。**
- **行为**：在 LuaJIT 里把 `io.open` 换成桩 —— 路径以 `/` 开头就 `error("...: invalid filepath")`
  —— 于是能在**不启动游戏**的情况下复现原 bug 并验证候选探测 / 持久化兜底两条分支。
  （`TheSim:SetPersistentString` 是冒号调用，桩签名必须是 `function(self, name, data, encode)`。）
- **日志锚点**：备份日志在 `<Klei>\DoNotStarveTogether\backup\client_log\*.txt`，
  可按 `构造失败` 拉时间线看 bug 是哪一版引入的。
