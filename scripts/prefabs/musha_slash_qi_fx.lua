-- ============================================================
-- 剑气斩特效（slash_qi）—— 直线飞行 + 命中炸开消散（2026-09-14 v9）
--
--   ★ 机制 = 原版 projectile 组件（直线飞，无重力/无弹道）
--     · 参考：遗迹守卫 mod 的 mecha_x_projectile.lua；原版 blowdart / boomerang 也是它
--     · 它只认**实体**目标（Throw 里会调 target:GetPosition()），所以落点用隐形实体当靶子：
--       prefabs/musha_skill_point.lua（无 health/combat → combat.lua:1122 直接 return，安全）
--     · ⚠️ projectile 和 complexprojectile **互斥**（共用 "projectile" tag），别同时加
--
--   ★ 素材三选一（FX_ART）
--     jimeng   = 自己的剑气图 anim/slash_fx.zip（单帧，动画名 anim）—— 观感偏"刀光/冲击波"
--     crescent = 原版真月牙 anim/crabking_claw_swipe_fx.zip（4 帧一次性动画 atk1）★ 现用这个
--     vanilla  = 原版暗影抛射体 anim/shadow_thrall_projectile_fx.zip（pre/loop/impact）
--   2026-09-14 用户：「冲击波 改月牙」→ FX_ART 从 jimeng 改成 crescent（真月牙形状）。
--   想换成自己画的亮青月牙：先打包 exported/crescent_cyan/crescent_cyan.scml → anim/crescent_cyan.zip，
--   再把下面 FX_ART 改成 "cyan"（一行）。
--
--   ★ 消散 = 动画淡出 + 本地粒子（2026-09-14 v9，用户选的方案②）
--     饥荒没给 mod 通用粒子发射器（AddParticleEmitter 这种引擎 API 不存在），
--     但**原版 FX 的粒子都是"不联网的本地实体"**（看 hitsparks_fx / explode_small：
--     `--[[Non-networked entity]]` + `if not TheNet:IsDedicated() then 本地生成` + animover 自毁）。
--     这套写法零网络开销，12 个粒子对 CPU 完全无压力（对比：把粒子做成联网实体才会卡，
--     这就是某些粒子 mod 吃 CPU 的原因）。
--     触发链：服务端命中 → net_event:push() → 每个客户端各自本地生成粒子（服务端不发一个字节）。
--     粒子素材直接用我们自己的 slash_fx（已经打包好、且 modmain 里全局声明了，客户端一定有）。
-- ============================================================

local FX_ART = "cyan8"     -- ★ 2026-09-14 切到方向图版：8 张（对称光斩）按飞行方向选图、贴图不旋转
                           --   素材链：make_lightslash.py（画对称光弧）→ make_dirs.py（派生 8 方向）→ DST Mod Tool 导 zip
                           --   打包好的：anim/crescent_cyan8.zip（用户 2026-09-14 19:53 导出）
                           -- 备选：cyan（单图+3D旋转，旧；会斜着被压扁） / jimeng（旧刀光图）
                           --       crescent（原版真月牙，蟹王爪击） / vanilla（暗影抛射体）

local ART = ({
    -- jimeng 的 scale 说明：素材画布 512x512，但可见的剑气只占 305x171（约 60%x33%）
    --   · 0.30 → 屏幕上只有 ≈0.9x0.5 世界单位（太小，就是"大小不明"的原因）
    --   · 0.80 → ≈2.4x1.4 世界单位（约 0.6 格宽）★ 现在用这个
    --   · 想更大就往 1.0 走（≈3.0x1.7 单位，接近一格宽）
    jimeng   = { bank = "slash_fx",                  build = "slash_fx",                  pre = "anim",            fly = "anim",            hit = "anim",             scale = 0.80, bloom = false },

    -- ★ 自己画的亮青月牙（2026-09-14，exported/crescent_cyan/）
    --   ★ 2026-09-14 用户："放大到 2 倍" → scale 0.45 → 0.90（可见 487x389 → 约 4.4x3.5 世界单位）
    --   打包：exported/crescent_cyan/crescent_cyan.scml → anim/crescent_cyan.zip，然后把 FX_ART 改成 "cyan"
    --   换 B(厚月牙)/C(双弧)：把 exported/crescent_cyan/crescent_b_thick.png 或 _c_double.png
    --     复制成 crescent_cyan-0.png，重新导一次 scml 即可（代码不用动）
    cyan     = { bank = "crescent_cyan",             build = "crescent_cyan",             pre = "anim",            fly = "anim",            hit = "anim",             scale = 0.90, bloom = true },

    crescent = { bank = "crabking_claw_swipe_fx",    build = "crabking_claw_swipe_fx",    pre = "atk1",            fly = "atk1",            hit = "atk1",             scale = 0.30, bloom = false },

    -- ★ 方向图版（2026-09-14 程序生成，见 `exported/crescent_cyan/make_dirs.py`）——
    --   8 个方向各一张（anim_0..anim_7，世界 +X 起每 45°），按飞行方向选图、贴图不旋转
    --   → 斜着飞不再被"地面投影"压扁（就是用户说的"光和面倾斜"）。
    --   打包：`exported/crescent_cyan/dirs/crescent_cyan8.scml` → `anim/crescent_cyan8.zip`，
    --   然后把最上面的 FX_ART 改成 "cyan8" 即可（表都填好了，不用改别的）。
    cyan8    = { bank = "crescent_cyan8",            build = "crescent_cyan8",            pre = "slash_dir0",      fly = "slash_dir0",      hit = "slash_dir0",           scale = 1.20, bloom = false,
                 -- ★ 2026-09-16：动画名 = slash_dir0..7（**无朝向后缀**，代码按方向点名播；
                 --   带后缀会让编译器写"朝向掩码"、逼引擎自己挑面，实测会挑错，见文件头说明）
                 dirs = { "slash_dir0", "slash_dir1", "slash_dir2", "slash_dir3",
                          "slash_dir4", "slash_dir5", "slash_dir6", "slash_dir7" } },
                 -- ★ 2026-09-14 用户「太大了」→ 0.90 → 0.25（等身）→ 用户「太小」→ **0.50**
                 --   换算口径（本项目实测）：1 世界单位 ≈ 100 贴图像素；月牙本体 ≈966 px 宽
                 --   · 0.90 ≈ 8.7 单位（太大）  · 0.25 ≈ 2.4 单位（太小）
                 --   · **0.50 ≈ 4.8 单位** ≈ 角色身高(1.7) 的 2.8 倍 —— 对齐洛克人 X5 觉醒 Zero
                 --     那个绿月牙的比例（图上月牙 ≈ 角色 3 倍左右）
                 --   要再调就改这一个数，**不用重导素材**
                 -- ★★ 2026-09-16 二调：用户「太小了，几乎成了光斑」→ 63 改 **1.20**，
                 --   同时 **bloom: true → false**（辉光会把白芯糊成一团，这就是「光斑」的主因）
                 --   想再调就动这两个数：scale（大小）/ bloom（要不要发光）——都不用重导素材
                 -- ★ 2026-09-16 用户「太小，一坨 看不清」→ 0.50 → **0.63**
                 --   根因不是 code，是换素材了：09-16 03:47 那版（exported/crescent_moon，
                 --   零辉光干净新月，实物 639x595）比 09-14 那版（exported/crescent_cyan，
                 --   实物 705x809）小 1.266 倍 → 同样 0.50 看着就小一圈、边缘又没辉光过渡 → "一坨"。
                 --   → 0.50 × 809/639 ≈ **0.63** 只是"还原到 09-14 认可的那个大小"。
                 --   想更大就继续加：0.8（≈6.2 单位）/ 1.0（≈7.7 单位）；等比缩放，别非等比（见下面 FX_LEN_MULT）
                 --   想"更清楚"（不是更大）→ 改形状：exported/_tools/crescent_gen.py 顶部 E 减薄（99→60 左右）
                 --   或 XS 拉宽 → 重跑 make_lightslash/make_dirs → 重导 zip
    vanilla  = { bank = "shadow_thrall_projectile_fx", build = "shadow_thrall_projectile_fx", pre = "projectile_pre", fly = "projectile_loop", hit = "projectile_impact", scale = 1, bloom = false },
})[FX_ART]      -- ⚠️ 外面这对括号不能省：Lua 5.1 不许「表构造后面直接跟索引」

-- ===== 飞行手感（想调就动这里）=====
local FX_SPEED      = 22.5                    -- 飞行速度（直线）；★ 2026-09-14 用户"太快"→ 45 减半
local FX_RANGE      = 12                      -- 最远飞多少格（对齐技能的 MAX_RANGE），飞满即消失

-- ★ 2026-09-14 用户：「月牙太大了，可以改一改长度，类似洛克人光剑那样」
--   ⚠️ 2026-09-14 撤回"只压长度"的做法：`SetScale(x<y)` 是**沿屏幕水平方向**压 ——
--      而 8 张方向图是**预先转好角度**的（朝上飞的那张本身就竖着），再压屏幕 x 就等于
--      在不同方向上压不同的部位 → 用户实测"正面侧面不一样、不平均"。
--   → **必须等比缩放**（1.0）。想改"长度"只能**重画底图**（改 make_lightslash.py 的 XS/YS），
--      不能在游戏里拉非等比。
local FX_LEN_MULT   = 1.0

local FX_HIT_DIST   = 1.0                     -- 离落点多近算命中（0.6→1.0：减速后每帧仍走 0.75 单位，
                                              --   太小的判定圈会被"跨帧跳过去"→ 技能空放）
-- ⚠️ 2026-09-17：出手高度/距离的**唯一来源**已挪到 musha_weapon_skill.lua 的 WeaponSkill.LAUNCH_OFFSET
--   （外部评审指出"FX 写 1.0、weapon_skill 又用 0.6"两套参数打架）。这里只留一个**兜底默认值**，
--   仅当 fx 不是由武器技能生成时生效；武器技能每次出手都会覆盖 inst.musha_launch_y。
local FX_DEFAULT_LAUNCH_Y = 1.30
local FX_LIFETIME   = 3                       -- 兜底自毁（秒）
-- ⚠️ 2026-09-16：USE_ENGINE_FACING = true 时**别动这个数**——旋转 = 飞行方向（MotorVel 沿自身旋转），
--    动它会连带偏航。引擎模式下修朝向只能改素材相位（crescent_gen.py 的 PHASE_DEG）或换动画名。
--    只有旧的"代码选图/单图"路径才用它。
local FX_ROT_OFFSET = 0                       -- 贴图朝向补偿（度）——月牙弧口不正就报"转 X 度"改这里

-- ★★ 2026-09-16 官方多面向方案（让引擎挑面，替代"代码算序号选图"）★★
--   原理（拆官方编译器 Don't Starve Mod Tools/mod_tools/tools/scripts/buildanimation.py 得到）：
--     动画名带朝向后缀（_down/_side/_up/_upright/_downright...）时，编译器会把"朝向位掩码"
--     写进 anim 包；游戏里只 PlayAnimation("slash")，引擎按 Transform 的旋转挑对应那一面。
--     官方样板就在眼前：boat_cannon.lua 只写 PlayAnimation("idle") + Transform:SetEightFaced()。
--   ⚠️ 切过来之前**必须**让 Mod Tool 用 exported/crescent_moon/crescent_cyan8.scml 重导
--      anim/crescent_cyan8.zip（新包里动画名才是 slash_right/slash_up/...；旧包还是 anim_0..7）。
--      USE_ENGINE_FACING = false 可一键回退旧的"代码选图"方案（不用重导）。
-- ★★ 2026-09-16 实测定稿：**默认关**（改由代码按方向点名播 slash_dir0..7）★★
--   为什么放弃"引擎挑面"：① 原版 4044 个脚本里没有任何一处用带后缀的名字播动画
--   （后缀只是编译期标记，运行时只能靠引擎按旋转挑面）；② 引擎"旋转 → up/down/right"
--   的映射在本机无法验证 —— 实测两次施法旋转都对（世界 165.5° / 256.4°），但月牙朝向是错的。
--   → 唯一能保证准的：8 条动画我们自己点名播；方向的来源 = **引擎已设好的真实旋转**
--     （DirIndexFromRotation，这才是"方向不准"的真根因：旧代码问的是落点靶子，实测恒为 0 区）。
-- ★★ 2026-09-18 用户实测结论：「**月牙斩方向错位**」→ **切回"代码按方向点名播"（= 本行 false）**
--   · 为什么切回：引擎那层"旋转 → 挑哪一面"的映射在 C++ 里，本机既没有官方样例也验不了；
--     点名播这条路的**方向源是我们自己算的**（DirIndexFromRotation，floor(角/45)），错了也能用数字修。
--   · 已同步换包：`anim/crescent_cyan8.zip` = **点名声版**（动画名 slash_dir0..7，实测确认）
--     8 面版备份 = `anim/_bak_crescent_cyan8_8面_20260918.zip`
--     （8 面版 scml 还留着：`exported/crescent_moon/crescent_cyan8_bak_官方名.scml`）
--   · 想再回 8 面版：① 本行改 true ② 把上面那个 _bak...8面.zip 拷回 anim/crescent_cyan8.zip
--   · ⚠️ 常量与 zip **必须配对**：只改常量不换包 = 月牙看不见（包里没有那个名字的动画）
--   · 若点名播仍整体偏：偏 45° 整数倍 → 改素材相位（crescent_gen.py 的 PHASE_DEG）重出图，
--     别动 Transform 旋转（DST 的飞行方向就是实体旋转，一动就偏航）
local USE_ENGINE_FACING = false   -- true = 引擎按掩码挑面（需要官方后缀名版 scml）
local FACING_ANIM       = "slash" -- 仅 USE_ENGINE_FACING = true 时才用（官方名版 scml 的基础名）
local FACING_DEBUG      = true    -- 实测期打印"旋转角 → 引擎实际选中哪一面"；定稿后改 false

-- 8 个方向名（只给调试用；顺序 = 引擎的朝向位顺序）
local FACING_NAMES = { "slash_right", "slash_upright", "slash_up", "slash_upleft",
                       "slash_left", "slash_downleft", "slash_down", "slash_downright" }

-- Klei 旋转 → 方向序号 k（0 = 世界 +X，每 45° 一格，往 +Z 排）
--   ★ 只用来"同步给客机挑面"，**绝不用来改飞行方向**
--   （DST 的 Physics:SetMotorVel 是沿实体自身旋转飞的：locomotor.lua:723 把旋转换成向量、
--     projectile.lua:458 靠 RotateToTarget 转向、RestoreDelayPos 连 rotation 一起复原）
--   口径：第 k 格覆盖世界角 [45k, 45k+45)，素材按**格中心** 45k+22.5 画
--   （= crescent_gen.py 的 theta = m*45 + 180/count）→ 所以是 floor(b/45)，别加 22.5！
--   2026-09-16 踩过：写成 floor((b+22.5)/45) → 落在每格上半段的朝向整整偏一格（最大 45°）。
local function DirIndexFromRotation(rot)
    local b = (((-rot) % 360) + 360) % 360      -- 朝向的世界角（+X 起往 +Z）
    return math.floor(b / 45) % 8
end

-- 方向序号 k（0 = 世界 +X，每 45° 一个，往 +Z 排）→ Klei 旋转角
--   官方口径（projectile.lua:162 / boat_cannon.lua:170）：朝向向量 = (cos(-rot), sin(-rot))
--   → 朝世界角 b 的旋转 = -b。FX_ROT_OFFSET 用来整圈微调（实测偏了就改它，不用重导素材）。
local function FacingRotationFor(k)
    return ((360 - (k % 8) * 45) % 360) + FX_ROT_OFFSET
end
local FX_COLOUR     = nil                     -- 本体染色 {r,g,b}；nil = 用素材原色
-- ★ 2026-09-16 用户："zero的光什么颜色 我们就改什么"
--   → 洛克人 ZERO（GBA 系列）的 Z 剑光是**青蓝底 + 白芯**，不是 X5 觉醒版那个绿；
--     而新素材本体就是亮青 (0.30,0.86,1.00) → **不再染色**，直接用原色（正是用户要的"青色 青亮色"）。
--   ↩️ 想回到 X5 幻梦零那个绿：把上面那行改回 { 0.45, 1.00, 0.35 }（乘法染色，不用重导素材）

-- ★★ 方向美术（2026-09-14 用户要做：8 面最好、至少 4 面；**左右自动镜像**）——
--   为什么：单图靠"3D 旋转"摆方向 → 斜着飞时贴图被压扁（用户原话"光和面倾斜"）。
--   洛克人 ZERO 那种利落感 = **每个方向各画一张**，按方向选图、贴图不旋转。
--   用法：一张 build 里放多个动画，动画名照下面表写。
--   ★ **左右自动镜像（DIR_MIRROR = true，默认开）**：表里只写**半圈**的图，另半圈由代码把贴图
--     水平镜像（原版 FX 就是这么干的：`AnimState:SetScale(-1, 1)`），所以他画一半就行：
--       8 面 → 只画 4 张：{ "anim_0","anim_45","anim_90","anim_135" }   （每张覆盖 45°）
--       4 面 → 只画 2 张：{ "anim_0","anim_90" }                        （每张覆盖 90°）
--       不想镜像（老老实实每个方向一张）→ DIR_MIRROR = false，表写满 8/4 项
--   · 单项也可以手工标镜像：{ "anim_45", true }（第二项 = 水平翻转）
--   · 表 = nil → 退回现在的"单图 + 3D 旋转"
--   ⚠️ 角度口径：第 1 项 = 世界 **+X**（DST 相机 45° 俯视，+X 在屏幕上偏右下），
--      往 +Z 排；镜像轴 = 第 1 项那条线。整排方向反了就改 DIR_CCW，镜像轴不对就改 DIR_START_DEG。
local FX_DIRS       = ART.dirs                -- 方向图来自 ART 项（FX_ART = "cyan8" 才有；nil = 单图 + 3D 旋转）
local DIR_MIRROR    = ART.mirror == true      -- true = 表只写半圈、另半圈自动左右镜像（cyan8 是 8 张全量 → false）
local DIR_START_DEG = 0                       -- 表里第 1 项对应的世界角度（0 = +X）
local DIR_CCW       = true

-- atan2 自己写（避免依赖 math.atan2 在不在）
local function Atan2(y, x)
    if x > 0 then return math.atan(y / x)
    elseif x < 0 then return math.atan(y / x) + (y >= 0 and math.pi or -math.pi)
    elseif y > 0 then return math.pi / 2
    elseif y < 0 then return -math.pi / 2
    else return 0 end
end

-- 调试：隔一帧问引擎"你现在到底在播哪一面"（IsCurrentAnimation，666 个原版脚本都在用）
local function FacingDebug(inst, k)
    if not FACING_DEBUG then return end
    local rot = 0
    if inst.Transform ~= nil then rot = inst.Transform:GetRotation() end
    inst:DoTaskInTime(0, function(i)
        if i:IsValid() and i.AnimState ~= nil then
            local got = "(没匹配上)"
            for _, nm in ipairs(FACING_NAMES) do
                local ok, cur = pcall(function() return i.AnimState:IsCurrentAnimation(nm) end)
                if ok and cur then got = nm; break end
            end
            if got == "(没匹配上)" then
                -- 官方编译器会把后缀从动画名里去掉 → 包里存的名字就是基础名，
                -- 所以"挑到哪一面"名字上看不出来，但至少能确认引擎有没有挑中动画
                local ok2, cur2 = pcall(function() return i.AnimState:IsCurrentAnimation(FACING_ANIM) end)
                if ok2 and cur2 then got = FACING_ANIM .. "(基础名·引擎已挑到某一面)" end
            end
            print(string.format("[Musha] 剑气斩 引擎挑面：dir%s 旋转=%.1f°（朝向世界角=%.1f°）→ 实际播 %s",
                tostring(k), rot, (((-rot) % 360) + 360) % 360, got))
        end
    end)
end

-- 按飞行方向挑方向图（返回 动画名, 是否水平镜像）；没配方向表就返回 nil
local function PickDirIndex(inst, tx, tz)
    if FX_DIRS == nil or #FX_DIRS == 0 then return nil end
    local x, _, z = inst.Transform:GetWorldPosition()
    local dx, dz = tx - x, tz - z
    if math.abs(dx) < 0.001 and math.abs(dz) < 0.001 then return nil end

    local n = #FX_DIRS                                  -- 表里画了几张
    local total = DIR_MIRROR and n * 2 or n             -- 覆盖多少个方向
    local step = 360 / total
    local deg = math.deg(Atan2(dz, dx)) * (DIR_CCW and 1 or -1) - DIR_START_DEG
    local k = math.floor((((deg % 360) + 360) % 360) / step) % total   -- 0..total-1

    local flip = false
    if DIR_MIRROR and k >= n then
        k = n - (k - n) - 1            -- 镜像轴折回：k=n→n-1, n+1→n-2 … 2n-1→0
        flip = true
    end
    return k, flip
end

-- 序号 → (动画名, 是否镜像)
local function DirAnimFor(k, flip)
    if FX_DIRS == nil or #FX_DIRS == 0 or k == nil then return nil, false end
    local entry = FX_DIRS[k + 1] or FX_DIRS[1]
    if type(entry) == "table" then
        return entry[1], (entry[2] == true) ~= (flip == true)
    end
    return entry, flip == true
end

-- 把对应方向的那张图贴到实体上（任意端都能调；scale 的 x 取负 = 水平镜像）
local function ApplyDirArt(inst, k, flip, fromengine)
    if inst.AnimState == nil then return false end

    if USE_ENGINE_FACING then
        -- ★ 官方做法：贴好 scale + 播基础名，**朝向交给引擎按 Transform 的旋转自己挑**
        --   ⚠️ 服务端（fromengine=true）**一个字都不动旋转**：旋转就是飞行方向！
        --      （引擎已由 projectile:RotateToTarget 设成朝落点，动它就偏航 —— 2026-09-16 踩过）
        --   客机（fromengine=nil）没有飞行责任，用 netvar 传来的 k 摆一个等价旋转，好让引擎挑到同一面。
        --   ★ 想修正"月牙朝向偏了 45° 的整数倍"：不要用 FX_ROT_OFFSET（那会连带偏航），
        --     改素材相位（crescent_gen.py 的 PHASE_DEG）或换动画名（scml 里 slash_* 对调 → 重导）。
        local s = ART.scale
        local ok = pcall(function()
            inst.AnimState:SetScale(s * FX_LEN_MULT, s, s)
            if not fromengine then
                inst.Transform:SetRotation(FacingRotationFor(k or 0))
            end
            inst.AnimState:PlayAnimation(FACING_ANIM)
        end)
        if ok then FacingDebug(inst, k) end
        return ok
    end

    local anim, needflip = DirAnimFor(k, flip)
    if anim == nil then return false end
    local s = ART.scale
    local sx = s * FX_LEN_MULT          -- ★ 只压长度（水平），高度不动
    return pcall(function()
        inst.AnimState:SetScale(needflip and -sx or sx, s, s)
        inst.AnimState:PlayAnimation(anim)
    end)
end

-- 方向序号打包进 net_byte：0 = 还没定；否则 (k+1)，镜像放最高位（+128）—— 最大 136，byte 够放
local function PackDir(k, flip)
    return (k + 1) + (flip and 128 or 0)
end

-- ★ 2026-09-14：方向图必须**每个客户端各自播**（AnimState 不会自动联网！）
--   以前只在服务端 OnThrownFn 里 PlayAnimation → 官方客机看到的永远是 build 的默认动画
--   （就是用户报的"只有一个方向"）。现在服务端只写一个 netvar，各端收到 dirty 自己播。
local function OnDirDirty(inst)
    if TheNet ~= nil and TheNet:IsDedicated() then return end
    local v = inst._qi_dir ~= nil and inst._qi_dir:value() or 0
    if v == 0 then return end
    local flip = v >= 128
    local k = (flip and (v - 128) or v) - 1
    ApplyDirArt(inst, k, flip, false)      -- 客机：只为挑面摆个等价旋转，不动飞行（飞行是服务端的事）
end

-- ===== 命中炸开 FX（联网的那一个，整个命中只发这一个）=====
local FX_BURST        = "hitsparks_fx"        -- 备选：moonstorm_spark / dustmeringue / explode_small
local FX_BURST_SCALE  = 1.2
local FX_BURST_COLOUR = nil                   -- {r,g,b}，nil = 原色

-- ===== 消散：本体淡出 + 本地粒子 =====
local FX_FADE_TIME      = 0.18                -- 本体淡出时长（秒）；0 = 直接消失
local FX_PARTICLE_COUNT = 12                  -- 粒子个数（12 个本地实体完全无压力；想更花别超 24）
local FX_PARTICLE_LIFE  = 0.35                -- 粒子寿命（秒）
local FX_PARTICLE_SPEED = { 3.5, 7.0 }        -- 初速范围（世界单位/秒）
local FX_PARTICLE_UP    = { 1.0, 3.5 }        -- 初始向上速度范围
local FX_PARTICLE_GRAV  = 14                  -- 粒子下落加速度
local FX_PARTICLE_SCALE = { 0.16, 0.02 }      -- 起止大小（相对素材）
local FX_PARTICLE_SPIN  = 260                 -- 自转速度（度/秒）
local FX_PARTICLE_COLOUR = nil                -- 粒子染色 {r,g,b}，nil = 原色

local assets =
{
    Asset("ANIM", "anim/" .. ART.bank .. ".zip"),
}

-- 在指定位置放一下"炸开"（拿不到就悄悄跳过，不影响技能）
local function SpawnBurst(x, y, z)
    if FX_BURST == nil or FX_BURST == "" then return end
    local ok, fx = pcall(SpawnPrefab, FX_BURST)
    if not ok or fx == nil then
        if not SpawnBurst._warned then
            SpawnBurst._warned = true
            print("[Musha] 剑气炸开 FX 取不到：" .. tostring(FX_BURST))
        end
        return
    end
    fx.Transform:SetPosition(x, y or 0, z)
    if FX_BURST_SCALE ~= 1 then
        fx.Transform:SetScale(FX_BURST_SCALE, FX_BURST_SCALE, FX_BURST_SCALE)
    end
    if FX_BURST_COLOUR ~= nil and fx.AnimState ~= nil then
        fx.AnimState:SetMultColour(FX_BURST_COLOUR[1], FX_BURST_COLOUR[2], FX_BURST_COLOUR[3], 1)
    end
end

-- ★ 本地粒子：只在客户端生成、不联网、自毁（照原版 FX 那套写法）
--   纯 Lua 推进（每帧改 Transform）：不做碰撞、不进网络 → 12 个的开销比一个正经实体还低
local function SpawnLocalParticles(x, y, z)
    if TheNet ~= nil and TheNet:IsDedicated() then return end
    local bank = ART.bank
    local dt = 1 / 30
    for _ = 1, FX_PARTICLE_COUNT do
        local p = CreateEntity()                     -- 不 AddNetwork = 本地实体
        p:AddTag("FX")
        p:AddTag("NOCLICK")
        p.entity:AddTransform()
        p.entity:AddAnimState()
        p.entity:SetCanSleep(false)                  -- FX 一律不休眠

        local ok = pcall(function()
            p.AnimState:SetBank(bank)
            p.AnimState:SetBuild(bank)
            p.AnimState:PlayAnimation(ART.fly)
            p.AnimState:SetLightOverride(1)
        end)
        if not ok then p:Remove() else
            p.Transform:SetPosition(x, (y or 0) + 0.4 + math.random() * 0.5, z)
            p.Transform:SetRotation(math.random() * 360)

            local ang = math.random() * 2 * math.pi
            local spd = FX_PARTICLE_SPEED[1] + math.random() * (FX_PARTICLE_SPEED[2] - FX_PARTICLE_SPEED[1])
            local vx, vz = math.cos(ang) * spd, math.sin(ang) * spd
            local vy = FX_PARTICLE_UP[1] + math.random() * (FX_PARTICLE_UP[2] - FX_PARTICLE_UP[1])
            local t = 0
            if FX_PARTICLE_COLOUR ~= nil then
                p.AnimState:SetMultColour(FX_PARTICLE_COLOUR[1], FX_PARTICLE_COLOUR[2], FX_PARTICLE_COLOUR[3], 1)
            end

            p:DoPeriodicTask(dt, function(e)
                if not e:IsValid() then return end
                t = t + dt
                local k = t / FX_PARTICLE_LIFE
                if k >= 1 then
                    e:Remove()
                    return
                end
                local px, py, pz = e.Transform:GetWorldPosition()
                vy = vy - FX_PARTICLE_GRAV * dt
                e.Transform:SetPosition(px + vx * dt, py + vy * dt, pz + vz * dt)
                local s = FX_PARTICLE_SCALE[1] + (FX_PARTICLE_SCALE[2] - FX_PARTICLE_SCALE[1]) * k
                e.AnimState:SetScale(s, s, s)
                e.Transform:SetRotation(e.Transform:GetRotation() + FX_PARTICLE_SPIN * dt)
                e.AnimState:SetMultColour(1, 1, 1, 1 - k)
            end)
        end
    end
end

-- 命中/打空时：每个客户端各自炸开 + 撒粒子（服务端只发一个 net_event）
local function OnBurstDirty(inst)
    if TheNet ~= nil and TheNet:IsDedicated() then return end
    -- 去重：主机上 net_event 的本地回响和小段补发可能撞在一起
    local now = GetTime()
    if inst._lastburst ~= nil and now - inst._lastburst < 2 * FRAMES then return end
    inst._lastburst = now

    local x, y, z = inst.Transform:GetWorldPosition()
    SpawnBurst(x, y, z)
    SpawnLocalParticles(x, y, z)
end

-- 淡出消散（没有粒子发射器，就是 alpha 逐帧往下压）
local function FadeOutAndRemove(inst)
    if FX_FADE_TIME <= 0 then
        inst:Remove()
        return
    end
    local t = 0
    local step = 0.03
    inst:DoPeriodicTask(step, function(i)
        if not i:IsValid() then return end
        t = t + step
        local a = 1 - t / FX_FADE_TIME
        if a <= 0 then
            i:Remove()
        elseif i.AnimState ~= nil then
            -- ⚠️ 别写死 (1,1,1,a)：那会把 FX_COLOUR 的染色冲掉 → 淡出瞬间"绿变青"闪一下
            local c = FX_COLOUR
            if c ~= nil then
                i.AnimState:SetMultColour(c[1], c[2], c[3], a)
            else
                i.AnimState:SetMultColour(1, 1, 1, a)
            end
        end
    end)
end

-- 收尾：清掉落点靶子 + 自己
local function Cleanup(inst, playimpact)
    if inst.musha_marker ~= nil and inst.musha_marker:IsValid() then
        inst.musha_marker:Remove()
        inst.musha_marker = nil
    end
    if not inst:IsValid() then return end
    if playimpact and ART.hit ~= ART.fly and FX_DIRS == nil then
        inst.AnimState:PlayAnimation(ART.hit)
        inst:ListenForEvent("animover", function(i) FadeOutAndRemove(i) end)
    else
        FadeOutAndRemove(inst)
    end
end

-- 命中（原版 projectile 回调签名 = inst, attacker, target）
local function OnHit(inst, attacker, target)
    if inst.SoundEmitter then
        inst.SoundEmitter:PlaySound("rifts2/thrall_wings/projectile")
    end
    if inst.cast_hit then          -- 伤害结算在武器技能那边（musha_weapon_skill.OnFxHit）
        inst.cast_hit(inst)
    end
    if inst._qi_burst ~= nil then
        inst._qi_burst:push()      -- ★ 通知所有客户端：炸开 + 撒粒子
    end
    Cleanup(inst, true)
end

-- 打空（飞满射程）：也炸一下再消散，只是不结算伤害
local function OnMiss(inst, attacker, target)
    if inst._qi_burst ~= nil then
        inst._qi_burst:push()
    end
    Cleanup(inst, false)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddPhysics()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)     -- 不跟地形/建筑碰撞（代价：也会穿墙）

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("projectile")        -- 原版 projectile 组件要求
    -- ⚠️ 千万别加 "complexprojectile"：跟 projectile 互斥

    -- ★ 2026-09-14 朝向统一（用户报"发出去方向会不同变换"）——
    --   原来只有 SetFourFaced()、出手时又没给角度 → 不同飞行方向看起来朝向不一致。
    --   照原版样板改（"会飞的贴图"的标准做法）：prefabs/blowdart.lua:44 = OnGround 平铺地面
    --   ★ 2026-09-16 更新：crabking_claw 那行 SetEightFaced 是注释掉的，原因是**它只有单帧**；
    --     我们现在是"8 条动画各管一面"→ 反而**必须**开 SetEightFaced（见下面 fn 里那两行，
    --     官方 boat_cannon 就是这么干的）。别再把这条当"不能开"的理由。
    --   OnGround = 把贴图平铺在**地面平面**上 → 之后 Transform:SetRotation(角度) 才是
    --   "在地面上转"（不会随镜头/方向被压扁成别的样子）。
    -- ★★ 2026-09-14 v10b：SetOrientation 这行**故意不调** ★★
    --   起因：原来 = OnGround（贴图平铺地面）→ 用户报「剑气看起来像从地上发出去」。
    --   改 Billboard 时踩坑：**本版本 ANIM_ORIENTATION.Billboard 是 nil**，写了直接崩
    --   （calling 'SetOrientation' on bad self (number expected, got nil)）。
    --   结论：**不调这个方法** = 用引擎默认朝向 —— DST 的 AnimState 默认就是"面向摄像机"
    --   （billboard），正是我们要的"月牙立着飞"。
    --   · 想改回贴地：把下面一行换成 inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    --   · 要写成版本兼容：ANIM_ORIENTATION and (ANIM_ORIENTATION.Billboard or ANIM_ORIENTATION.Default)
    --   ⚠️ 连带：默认朝向的贴图**不吃 Transform:SetRotation**（不像贴地时"在地上转"会真的转），
    --     所以"月牙朝着飞行方向"完全靠方向图（FX_DIRS 一张一个方向），单图指望不上了。
    inst.AnimState:SetLayer(LAYER_BACKGROUND)     -- 仍然画在角色下面（别挡住人）
    inst.AnimState:SetSortOrder(3)

    inst.AnimState:SetBank(ART.bank)
    inst.AnimState:SetBuild(ART.build)
    if USE_ENGINE_FACING and inst.Transform.SetEightFaced ~= nil then
        -- ★ 官方样板同款（boat_cannon.lua:290）：「八面向」= 引擎按 Transform 的旋转挑面
        --   不设的话引擎只认"没后缀"的默认面（我们 8 条动画各管一面，就必须开这个）
        inst.Transform:SetEightFaced()
    end
    if FX_DIRS == nil then
        inst.AnimState:PlayAnimation(ART.pre)     -- 配了方向表就等出手时按方向播（见 OnThrownFn）
    end
    inst.AnimState:SetLightOverride(1)
    if ART.scale ~= 1 then
        inst.AnimState:SetScale(ART.scale * FX_LEN_MULT, ART.scale, ART.scale)
    end
    if ART.bloom then
        -- 亮部辉光：亮青月牙靠它才有"在发光"的感觉（原版 FX 常用这招）
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    end
    if FX_COLOUR ~= nil then
        inst.AnimState:SetMultColour(FX_COLOUR[1], FX_COLOUR[2], FX_COLOUR[3], 1)
    end

    -- ★ 命中信号（必须建在 SetPristine 之前）：服务端 push，各客户端各自本地出特效
    inst._qi_burst = net_event(inst.GUID, "musha_qi.burst", "musha_qi_burstdirty")
    inst:ListenForEvent("musha_qi_burstdirty", OnBurstDirty)

    -- ★ 方向图信号（同样建在 SetPristine 之前）：服务端只写方向序号，各客户端各自播那张图
    --   （AnimState 不会自动联网 —— 少了这一步客机永远只看到 build 的默认动画）
    --   ⚠️ 数值类型只能用原版有的：net_bool / net_smallbyte[0..63] / **net_byte[0..255]** / net_int …
    --      （没有 net_smallint！写了会 "variable 'net_smallint' is not declared" 直接崩）
    inst._qi_dir = net_byte(inst.GUID, "musha_qi.dir", "musha_qi.dirdirty")
    inst:ListenForEvent("musha_qi.dirdirty", OnDirDirty)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    if FX_DIRS == nil then
        inst.AnimState:PushAnimation(ART.fly)      -- 方向图模式在出手时按方向播（见 OnThrownFn）
    end

    inst:AddComponent("projectile")
    local p = inst.components.projectile
    p:SetSpeed(FX_SPEED)
    p:SetHoming(false)              -- ★ 直线：出手朝向落点，之后不再转向
    p:SetRange(FX_RANGE)            -- 飞满就 Miss
    p:SetHitDist(FX_HIT_DIST)
    p:SetLaunchOffset(Vector3(0, 0, 0))
    -- ★ 2026-09-16：原来这里写 Vector3(1.0, 1.25, 0)，而 musha_weapon_skill.DoCast 又手动设了一次
    --   位置（径向按瞄点方向、y 给的是脚下）→ **径向叠了两份、高度口径不一致**
    --   （projectile.lua:159-162 的 Throw 会自动 y+launchoffset.y）→ 客户端看就是"出门那下往下掉一下"。
    --   现在统一由 musha_weapon_skill 一处算（径向 + 高度），这里归零，起点高度 == 落点靶子高度 = 直线平飞。
    -- ★ 2026-09-17 兜底默认值；武器技能出手时会覆盖成 WeaponSkill.LAUNCH_OFFSET.y
    inst.musha_launch_y = FX_DEFAULT_LAUNCH_Y
    p:SetOnHitFn(OnHit)
    p:SetOnMissFn(OnMiss)
    p:SetOnThrownFn(function(i, owner)
        i.owner = owner
        local m = i.musha_marker
        local mx, mz
        if m ~= nil and m:IsValid() then
            local a, b, c = m.Transform:GetWorldPosition()
            mx, mz = a, c
        end

        if FX_DIRS ~= nil then
            -- ★ 方向美术：按方向选动画，**贴图不旋转**（斜飞的压扁/光面倾斜就是这么消掉的）
            --   ★ 2026-09-14 修"只有一个方向"：改成写 netvar，让**每个客户端各自播**对应方向图
            --     （AnimState 不联网；只在服务端 PlayAnimation 的话，客机永远看 build 默认动画）
            -- ★ 方向来源（2026-09-16 定稿）：**引擎已设好的真实旋转**
            --   （projectile:RotateToTarget 出手时已朝向落点；且 MotorVel 沿自身旋转飞 → 旋转就是方向）
            --   旧的"落点靶子"口径实测恒落在 0 区（就是用户报"方向不准"的根因），只留作兜底。
            local k, flip = nil, false
            if i.Transform ~= nil then
                k = DirIndexFromRotation(i.Transform:GetRotation())
            end
            if k == nil and mx ~= nil then
                k, flip = PickDirIndex(i, mx, mz)
            end
            if k ~= nil and i._qi_dir ~= nil then
                i._qi_dir:set(PackDir(k, flip))
            end
            -- 日志：实测时一眼看出选的是哪张方向图（k=0 起，对应 anim_0..7）
            if k ~= nil and not USE_ENGINE_FACING then
                local an = DirAnimFor(k, flip)
                print("[Musha] 剑气斩 方向图 → " .. tostring(an) .. "（k=" .. tostring(k) .. "）")
            end
            -- 兜底①：netvar 写不进去 → 本端自己贴一张；兜底②：方向表取不到 → 退回"单图 + 旋转"
            if not ApplyDirArt(i, k, flip, USE_ENGINE_FACING) and mx ~= nil then
                i.AnimState:SetScale(ART.scale, ART.scale, ART.scale)
                i:FacePoint(mx, 0, mz)
                if FX_ROT_OFFSET ~= 0 then
                    i.Transform:SetRotation(i.Transform:GetRotation() + FX_ROT_OFFSET)
                end
            end
            return
        end

        -- ★ 2026-09-14：单图时出手把月牙摆成"朝着落点"（引擎自己算朝向，不自己凑角度）
        --   靶子就在落点上 → FacePoint(靶子) = 沿飞行方向。弧口不正再叠 FX_ROT_OFFSET 微调。
        if mx ~= nil then
            i:FacePoint(mx, 0, mz)
        end
        if FX_ROT_OFFSET ~= 0 then
            i.Transform:SetRotation(i.Transform:GetRotation() + FX_ROT_OFFSET)
        end
    end)

    -- 兜底：既没命中也没 Miss 也自己收尾
    inst:DoTaskInTime(FX_LIFETIME, function(i)
        if i:IsValid() then Cleanup(i, false) end
    end)

    return inst
end

return Prefab("musha_slash_qi_fx", fn, assets)
