# DST：界面/按键"没反应"排查（Screen 入口 + 日志）

适用症状：**"打不开界面了"、"按 B 没反应"、面板/技能书点了没动静**，
游戏不报错、屏幕不弹红字、日志里也找不到 traceback。

---

## 1. 日志位置（本机）

- 客户端日志：`D:\Backup\Documents\Klei\DoNotStarveTogether\client_log.txt`
  （Windows "文档"目录被重定向到 `D:\Backup\Documents`；
  `C:\Users\Administrator\Documents\Klei` **不存在**，别去那儿找）
- 本地开世界（当主机）时，服务端输出也写进**同一个** client_log.txt
- cluster 侧文件：`...\DoNotStarveTogether\<clusterid>\Cluster_1\Master\`
  里的 `cluster.ini / server.ini / modoverrides.lua / leveldataoverride.lua`
  的 mtime ≈ **最近一次开局的真实时刻**，可用来给日志里那些错位的时间戳对表

## 2. 读日志的正确姿势（三个坑）

1. **行内时间戳和系统时间对不上**（实测差 2 小时以上）。
   别用时戳判断"这是不是最新一局"——看**文件末尾内容**判断。
2. **游戏运行期间日志还在增长**。第一次 `wc -l` + `tail` 读到的可能不是最新一局，
   必须隔几秒重新 `wc -l` 再 `tail`（必要时 `sleep 10`）。
3. **DST 的 Lua 错误不一定写进 client_log**，界面上的红色错误弹窗可能只存在于屏幕。
   → 日志没有 traceback ≠ 没报错；反之日志干净也不代表逻辑走通了。

分"上一局 / 这一局"最好用的手法：

```bash
wc -l client_log.txt
tail -50 client_log.txt
# 按行号切段，只 grep 本次启动之后的部分
grep -n "pattern" client_log.txt | awk -F: '$1>11500'
```

## 3. "按键没反应"定位法（本次实战）

1. 先找出入口模块的**模块级 print**（模块被 require 时就会打印）。
   例：`scripts/screens/musha_panel_screen.lua` 第 8 行
   `print("[Musha Panel] 文件开始加载 (Screen 版)")`。
2. 对比"能开的那局"和"不能开的那局"：
   - 有 `文件开始加载` → require 确实走到了，问题在构造/后续
   - **一条都没有 → 打开函数在 require 之前就静默 return 了**（或入口压根没被调用）
3. 如果入口代码里有**不打日志的提前 `return`**，那就是黑洞。
   给每个分支加一句 print，跑一次就能精确定位卡在哪一步——
   这比反复猜"是不是 API 不存在"快得多。

## 4. 坑：Screen 入口的"标志残留死锁"（本次根因）

反面教材（真实代码形态）：

```lua
local function OpenMushaPanel(owner)
    if not owner or not owner:IsValid() then return end
    if not TheFrontEnd then return end
    if owner._musha_panel_screen_open then return end   -- ← 静默黑洞
    local ok, mod = pcall(require, "screens/xxx")
    if ok and mod then
        TheFrontEnd:PushScreen(mod(owner))   -- ← 构造没 pcall：中途报错就永久废掉
    else
        print("[X] 打开失败: " .. tostring(mod))
    end
end
```

而 Screen 构造函数**开头第一行**就 `owner._musha_panel_screen_open = true`。

后果：只要构造中途报错一次 →
Screen 没入栈 → `OnDestroy` 不执行 → **标志永久 true** →
之后每次打开都在第一行静默 return，而且 B 键还会反过来去 `PopScreen()` 关掉别的窗口。
表现为"完全没有反应、也没有任何日志"。

正解（三件事一起做）：

```lua
-- ① 认屏幕：DST Screen 没有 name 字段！用自己打的标记
local function PanelIsOnTop()
    local fe = TheFrontEnd
    local stack = fe and fe.screenstack
    if not stack then return false end
    local top = stack[#stack]
    return top ~= nil and top.musha_panel == true   -- 构造函数里 self.musha_panel = true
end

-- ② 打开：残留标志清掉 + 构造也 pcall + 每步打日志
if PanelIsOnTop() then print("[X] 已在栈顶"); return end
if owner._musha_panel_screen_open then
    print("[X] 残留标志，已清除")
    owner._musha_panel_screen_open = nil
end
local ok, mod = pcall(require, "screens/xxx")
if not ok or not mod then print("[X] require 失败: " .. tostring(mod)); return end
local ok2, inst = pcall(mod, owner)
if not ok2 or not inst then
    print("[X] 构造失败: " .. tostring(inst))
    owner._musha_panel_screen_open = nil     -- ③ 出错也不留脏标志
    return
end
TheFrontEnd:PushScreen(inst)
```

> 通用教训：**"已打开"这类互斥标志，只能在成功入栈之后才有资格拦住下次打开；
> 构造失败必须能自愈。** 任何"设了 true 却只在 OnDestroy 里清"的标志都是定时炸弹。

## 5. DST Screen / 屏幕栈 API 事实

- `Screen` 类在 `data/databundles/scripts/widgets/screen.lua`
  （**不是** `screens/screen.lua`，找文件别找错目录）
- **`Screen` 没有 `self.name` 字段**：`Screen._ctor(self, "XxxScreen")` 传的字符串
  不会存到 `self.name`。想识别栈里的屏幕，自己在构造函数里打标记字段。
- 屏幕栈：`TheFrontEnd.screenstack`（`frontend.lua:43` 初始化为 `{}`），
  栈顶 = `screenstack[#screenstack]`；`#self.screenstack` 在 frontend.lua 里被大量用来判空。
- mod 环境 `require "widgets/screen"` 会回退到 DST 自带脚本（mod 目录里没有该文件），正常。

## 6. 提醒用户的话（别省这一句）

改完 mod 的 lua **必须完全退出并重启游戏客户端**。只回主菜单重进不一定重新编译 mod 脚本，
否则用户测的还是旧代码，白折腾一轮。
