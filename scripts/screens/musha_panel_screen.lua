-- ====================================
-- musha_panel_screen.lua  (Screen 版 · ScrollingGrid)
-- 2026-09-10 照搬明生神行传送界面架构：
--   真正 Screen（TheFrontEnd:PushScreen）
--   任务区用 TEMPLATES.ScrollingGrid（自带滚动条 / 滚轮滚动 / scissor 裁剪）
--   黑幕点击关 + 关闭按钮 + ESC(CONTROL_CANCEL)
-- ====================================
print("[Musha Panel] 文件开始加载 (Screen 版)")

local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local TEMPLATES = require "widgets/redux/templates"

-- 安全读取全局 STRINGS（绕过 strict 模式）
local function GetGlobalSTRINGS()
    local ok, s = pcall(function() return rawget(_G, "STRINGS") end)
    if ok and s then return s end
    return STRINGS
end

local function JobName(key)
    if not key or key == "" then return "无职业" end
    local S = GetGlobalSTRINGS()
    local name = S["MUSHA_JOB_" .. string.upper(key)]
    if name and name ~= "" then return name end
    return key:gsub("^%l", string.upper)
end

-- 任务名称表（面板不用再查全局 GetQuestName）
local QUEST_NAMES = {
    [1] = "见到龙蝇",
    [2] = "击杀20只蜘蛛",
    [3] = "存活5天",
    [4] = "找到格罗姆",
    [5] = "获得七个噩梦燃料",
    [6] = "收集三色宝石",
    [7] = "制造20个物品",
    [8] = "收获五次烹饪锅",
    [9] = "击败野猪x8",
    [10] = "击败五只火猎犬",
    [11] = "找到海象营地",
    [12] = "使用回复技能达到5次",
    [13] = "建造一个科学机器",
}

local function QuestName(quest_id)
    return QUEST_NAMES[quest_id] or "未知任务"
end

local BG_W = 1232
local BG_H = 832
local PANEL_ZOOM = 0.93

-- ★ 导航位置（2026-09-21 用户拍板：「左边」）
--   原来导航在**右侧**（三角 536 / 列表 458，点开才出现）。现改**左竖排常驻**：
--   · 位置只是把原右侧坐标镜像成负值，按钮仍是 114x40
--   · 实测底图 bookpage_bg.png（1644x1109 → 显示 1232x832）：左侧木框竖线在 content x≈-563，
--     纸面左缘 ≈-519 → 按钮占 -515..-401，压在框带和纸面左边缘上，**不遮挡页内内容**
--     （所以主页任务行 ITEM_W=860 不用缩，之前估的"要缩到 730"是错的）
--   · 竖向居中避开了左上角的木牌装饰（y≈+306 以上）和左下角装饰（y≈-277 以下）
--   想改回右侧：NAV_LEFT = false；想让导航回到"点三角才展开"：NAV_ALWAYS_SHOW = false
local NAV_LEFT = true
local NAV_ALWAYS_SHOW = true

-- 任务行尺寸（ScrollingGrid item）
local ITEM_W = 860          -- 行 widget 宽（含框外扩）
local ITEM_H = 78           -- 行高 = 行距
local VISIBLE_ROWS = 6
local ROW_W = 840           -- 底框宽度（框/白条/红条同步）

-- 技能页行尺寸 + 左对齐文本参数（2026-09-13 从文件下部提前到这里：
--   技能列表改成 ScrollingGrid 后，item_ctor 在构造期就要用到这些常量）
local SKILL_ROW_W   = 780
local SKILL_ROW_H   = 150
local SKILL_ROW_GAP = 20
local SKILL_BTN     = 58
local SKILL_TXT_W   = SKILL_ROW_W - 180          -- 文字区域宽（右侧留给加点按钮）
local SKILL_TXT_X   = -SKILL_ROW_W / 2 + 40      -- 文字左缘 = 卡片左缘 + 40

-- 技能列表滚动网格（2026-09-13 用户：未学习那个要能向下滚动）
--   widget_width 决定"格子宽"（= 裁剪区宽），滚动条就贴在裁剪区右边 →
--   所以格子宽 = 卡宽 + 一点点余量，别把滚动条顶出书页内框（内框半宽 428）
local SKILL_ITEM_W  = SKILL_ROW_W + 24           -- 格子宽（右侧 24px 给滚动条）
local SKILL_ITEM_H  = SKILL_ROW_H + SKILL_ROW_GAP  -- 格子高 = 行高 + 行距
local SKILL_VISIBLE = 2                          -- 可见行数（超出就滚轮向下滚）

local DIRTY_EVENTS = { "gamedata_dirty", "warrior_dirty", "saber_dirty", "guardian_dirty", "mage_dirty" }

-- ================================================================
-- 局内设置页：显示表（默认值/档位要和 components/musha_*_settings.lua 的 SPEC 对齐）
-- ================================================================
local SETTINGS_UI = {
    { scope = "world",  key = "monster_spawn_enabled", label = "怪物生成",   kind = "bool",   default = true },
    { scope = "world",  key = "monster_spawn_mult",    label = "生成倍率",   kind = "choice", default = 1, choices = { 0, 0.5, 1, 2, 3 } },
    { scope = "world",  key = "daily_quest_count",     label = "每日任务数", kind = "number", default = 4, min = 1, max = 10, step = 1 },
    { scope = "world",  key = "exp_mult",              label = "经验倍率",   kind = "choice", default = 1, choices = { 0.5, 1, 2, 3 } },
    -- 生命恢复 hp_regen_mult 已于 2026-09-17 删除（用户：「移除生命恢复」）
    --   原因同 mp_regen_mult：全项目 0 个消费方（class_traits.health_regen 没接过它），纯空转
    --   旧存档里存过的这个键由 OnLoad 按 SPEC 过滤自动丢弃，不会报错
    -- 能量恢复 mp_regen_mult 已于 2026-09-12 删除（用户：没有开放能量恢复的设定就删除）
    --   原因：MP/能量系统整体不存在（全项目无 MP 组件/字段），该设置是纯空转
    { scope = "player", key = "show_debug",            label = "调试信息",   kind = "bool",   default = false },
}

-- ================================================================
-- 信箱页内容（更新日志）—— 2026-09-10
--   内容源：scripts/musha_changelog.lua（require 进来）
--   读不到时用下面的兜底，保证面板不会因为日志文件出问题而炸
-- ================================================================
local MUSHA_CHANGELOG
do
    local ok, data = pcall(require, "musha_changelog")
    if ok and type(data) == "table" then
        MUSHA_CHANGELOG = data
    else
        print("[Musha Panel] 警告：require('musha_changelog') 失败 → " .. tostring(data) .. "，改用内联兜底")
    end
end
if type(MUSHA_CHANGELOG) ~= "table" then
    -- 兜底（内容和 scripts/musha_changelog.lua 保持一致，改内容请改那个文件）
    MUSHA_CHANGELOG = {
        { ver = "0.7.9", date = "2026-09-17", lines = {
            "进阶祭坛改版：坛内取出「转职卷轴」→ 展开才接取转职任务；3 轮考验后回祭坛完成就职仪式。",
            "二转赠礼改为本职业「技能书」（剑士技能书内含剑气斩）；新增通用「技能卷轴」（可制作/可掉落）。",
            "新美术：战士职业书、剑士技能书、转职卷轴。",
            "生命树枝手持显示修复（地上/手上合成一包）并调整大小。",
            "修复：就职仪式发赠礼崩溃、第 3 轮完成没面板提示、祭坛空坛不解释；移除空转的「生命恢复」设置。",
        } },
        { ver = "0.7.7", date = "2026-09-16", lines = {
            "新增武器技能「剑气斩」：剑士专属，右键瞄准、点地释放（月牙改用 8 方向光斩）。",
            "新增礼包系统：游戏时间礼包 + 节日礼包；面板新增「礼包」页（「装备」页暂时收起）。",
            "新增「生命树枝」道具（装备时每秒回 0.2 生命、每 24 秒 +0.1 精神）；便签新增“地上/手中”形态（一卷系绳的纸）。",
            "一转职业书在转职完成后消耗；二转不再额外补发技能书。",
            "修复：剑气斩会穿过敌人；转职任务「存活5天」进度不增长。",
        } },
        { ver = "0.7.6", date = "2026-09-10", lines = {
            "Musha 系统 0.7.6 正式上线。",
            "职业面板改为多页书：主页 / 技能 / 信箱 / 设置 / 图鉴。",
            "新增局内设置：怪物生成、任务数量、经验倍率、生命与能量恢复。",
            "任务系统：每日自动发放 + 雕像接单的转职任务。",
        } },
        { ver = "0.7.5", date = "2026-09-09", lines = {
            "任务系统重构：每日自动发放 + 雕像接单轮转职任务。",
            "修复面板不显示（补回 AddReplicableComponent）。",
            "修复滚轮误关面板。",
        } },
        { ver = "0.7.4", date = "2026-09-08", lines = {
            "面板从 HUD Widget 改为真 Screen + ScrollingGrid。",
            "滚动条外观定制（轨道 / 握把）。",
        } },
        { ver = "0.7.3", date = "2026-09-05", lines = {
            "进阶任务改为雕像接取（单轮 3 轮制）。",
        } },
    }
end

local MAIL_PER_PAGE = 3   -- 每页几条（长度限制由这里定）

-- 图鉴数据（scripts/musha_dex.lua）—— 2026-09-16 新增（原图鉴页是"内容待定"占位）
local MUSHA_DEX
do
    local ok, data = pcall(require, "musha_dex")
    if ok and type(data) == "table" then
        MUSHA_DEX = data
    else
        print("[Musha Panel] 警告：require('musha_dex') 失败 → " .. tostring(data) .. "，图鉴页先留空")
    end
end
if type(MUSHA_DEX) ~= "table" then MUSHA_DEX = {} end

-- 礼包数据（scripts/musha_gifts.lua）—— 2026-09-12 新增
local MUSHA_GIFTS
do
    local ok, data = pcall(require, "musha_gifts")
    if ok and type(data) == "table" then
        MUSHA_GIFTS = data
    end
end
if type(MUSHA_GIFTS) ~= "table" then MUSHA_GIFTS = {} end

local function FmtSetting(def, v)
    if def.kind == "bool" then
        return v and "开" or "关"
    elseif def.kind == "number" then
        return tostring(v)
    end
    return tostring(v) .. "x"
end

-- 算下一档（choice 循环、number 到端点回绕）
local function NextSettingValue(def, cur, dir)
    if def.kind == "choice" then
        local idx = 1
        for i, c in ipairs(def.choices) do
            if c == cur then
                idx = i
                break
            end
        end
        idx = idx + (dir or 1)
        if idx < 1 then idx = #def.choices end
        if idx > #def.choices then idx = 1 end
        return def.choices[idx]
    elseif def.kind == "number" then
        local v = (tonumber(cur) or def.min or 0) + (dir or 1) * (def.step or 1)
        if def.min and v < def.min then v = def.max end
        if def.max and v > def.max then v = def.min end
        return v
    end
    return cur
end

-- 客户端 → 服务端：改一项设置
local function SendSetting(scope, key, value)
    local ok, rpc = pcall(function() return GetModRPC("musha", "musha_set_setting") end)
    if not ok or rpc == nil then return end
    pcall(function() SendModRPCToServer(rpc, scope, key, value) end)
end

-- 客户端 → 服务端：领礼包（2026-09-12）
local function SendClaimGift(gift_id)
    if not gift_id then return end
    local ok, rpc = pcall(function() return GetModRPC("musha", "musha_claim_gift") end)
    if not ok or rpc == nil then return end
    pcall(function() SendModRPCToServer(rpc, gift_id) end)
end

-- 客户端 → 服务端：拉一次最新设置
local function RequestSettings()
    local ok, rpc = pcall(function() return GetModRPC("musha", "musha_request_settings") end)
    if not ok or rpc == nil then return end
    pcall(function() SendModRPCToServer(rpc) end)
end

-- 客户端 → 服务端：技能加点（参数 = "warrior_combat_recovery" 这种 skill_id）
-- 服务端 musha_rpcs.lua 里那个 handler 会自己拆树名/技能名并调 pc:UpgradeSkill
local function SendSkillUpgrade(skill_id)
    if not skill_id then return end
    local ok, rpc = pcall(function() return GetModRPC("musha", "musha_skill_upgrade") end)
    if not ok or rpc == nil then return end
    pcall(function() SendModRPCToServer(rpc, skill_id) end)
end

-- ★ 2026-09-18 客户端 → 服务端：**用背包里的技能书解锁**
--   面板技能页里"点锁"和"点 +"都走这条（用户：「点加点和图片都可以打开的，消耗物品栏里面的技能书」）；
--   另一条等价入口 = 背包里右键那本书（各 prefab 自己的 OnUse，服务端直接调 UnlockSkillWithItem）
local function SendSkillUnlock(skill_id)
    if not skill_id then return end
    local ok, rpc = pcall(function() return GetModRPC("musha", "musha_skill_unlock") end)
    if not ok or rpc == nil then return end
    pcall(function() SendModRPCToServer(rpc, skill_id) end)
end

-- 通用小按钮（用 square.tex 拼，不依赖美术）
local function MakeTextButton(parent, w, h, str, onclick)
    local b = parent:AddChild(ImageButton("images/global.xml", "square.tex"))
    b:ForceImageSize(w, h)
    b:SetImageNormalColour(0.32, 0.27, 0.19, 0.80)
    b:SetImageFocusColour(0.50, 0.42, 0.26, 0.95)
    local t = b:AddChild(Text(UIFONT, 28))
    t:SetString(str)
    t:SetColour(0.96, 0.91, 0.74, 1)
    b._label = t
    if onclick then b:SetOnClick(onclick) end
    return b
end

-- 技能页单行文字（左对齐；2026-09-13 上移到这里，ScrollingGrid 的 item_ctor 在构造期要用）
local function SkillText(row, size, y, str, r, g, b)
    local t = row:AddChild(Text(UIFONT, size))
    t:SetString(str or "")
    t:SetColour(r or 0.30, g or 0.24, b or 0.16, 1)
    t:SetRegionSize(SKILL_TXT_W, size + 14)
    t:SetHAlign(ANCHOR_LEFT)
    t:SetPosition(SKILL_TXT_X + SKILL_TXT_W / 2, y)
    return t
end

-- ★ 2026-09-16 礼包「领取」按钮：橙灰质感 + **弹起感**（用户要求）
--   做法（只用 square.tex 也能做出立体）：
--     · 最底一块深灰棕的"外框"（比面大 6px）= 阴影层，看起来是浮起来的
--     · 面上：上边 + 左边 提亮细条（高光）／下边 + 右边 压暗细条（阴影）→ 立体"凸起"
--     · 悬停：整块放大到 1.06（"弹起来"的手感）；移开缩回
--   ⚠️ 和 MakeTextButton 一样必须关 scale_on_focus，否则 DST 会自己放大 1.2 倍把底色顶出白框
local function MakeGiftButton(parent, w, h, str, onclick)
    local b = parent:AddChild(ImageButton("images/global.xml", "square.tex"))
    b:ForceImageSize(w + 6, h + 6)
    b:SetImageNormalColour(0.38, 0.24, 0.12, 0.92)      -- 外框（深棕）= 立体底（2026-09-16 去灰）
    b:SetImageFocusColour(0.46, 0.30, 0.15, 0.95)
    b.scale_on_focus = false

    local face = b:AddChild(Image("images/global.xml", "square.tex"))
    face:SetSize(w, h)
    face:SetTint(0.90, 0.62, 0.26, 0.99)                 -- 暖橙主色（去灰）

    -- 高光（上 + 左）
    for _, ln in ipairs({ { 0, h / 2 - 2, w, 3 }, { -(w / 2 - 2), 0, 3, h } }) do
        local i = b:AddChild(Image("images/global.xml", "square.tex"))
        i:SetSize(ln[3], ln[4])
        i:SetPosition(ln[1], ln[2])
        i:SetTint(1.00, 0.90, 0.62, 0.98)
    end
    -- 阴影（下 + 右）
    for _, ln in ipairs({ { 0, -(h / 2 - 2), w, 3 }, { (w / 2 - 2), 0, 3, h } }) do
        local i = b:AddChild(Image("images/global.xml", "square.tex"))
        i:SetSize(ln[3], ln[4])
        i:SetPosition(ln[1], ln[2])
        i:SetTint(0.56, 0.33, 0.13, 0.95)
    end

    local t = b:AddChild(Text(UIFONT, 26))
    t:SetString(str)
    t:SetColour(1.00, 0.97, 0.90, 1)
    b._label = t

    b:SetOnGainFocus(function() b:SetScale(1.06, 1.06, 1) end)
    b:SetOnLoseFocus(function() b:SetScale(1, 1, 1) end)

    if onclick then b:SetOnClick(onclick) end
    return b
end

-- ★ 2026-09-17 技能书锁（用户）：技能书解锁技在 0 级时不显示加号，改显示这把小锁；
--   鼠标悬停 → 提示"需要 N 本技能书才能解锁"（给新手建立认知）。贴图用**官方技能树的挂锁**，不新增素材。
--   ★ 2026-09-18 加 onclick：锁本身也能点（点它 = 用背包里的技能书解锁）
local function MakeLockButton(parent, size, x, y, tipfn, onclick)
    local b = parent:AddChild(ImageButton("images/skilltree.xml", "locked.tex"))
    b:SetSize(size, size)
    b:SetPosition(x, y)
    b.scale_on_focus = false                       -- 别吃 ImageButton 默认的 focus 放大（会爆框）
    b:SetImageNormalColour(0.58, 0.52, 0.44, 0.95)
    b:SetImageFocusColour(0.92, 0.82, 0.56, 1)
    b:SetOnGainFocus(function()
        b:SetScale(1.14, 1.14, 1)
        if tipfn then tipfn(true) end
    end)
    b:SetOnLoseFocus(function()
        b:SetScale(1, 1, 1)
        if tipfn then tipfn(false) end
    end)
    if onclick then b:SetOnClick(onclick) end
    return b
end

-- 把按钮刷成"三角图标那套"外观：蜡黄底 + 白色细框
-- ⚠️ 必须关掉 scale_on_focus：DST 的 ImageButton 默认 scale_on_focus=true、
--    focus_scale={1.2,1.2,1.2}，而"只给一个贴图"的按钮会被判定 image_focus==image_normal，
--    于是鼠标一移上去底图就放大 1.2 倍 → 底色块爆出白框外（imagebutton.lua 源码原话：
--    "Common bug: you probably want scale_on_focus = false or customize scaling."）
local function StyleLikeTriangle(b, w, h)
    b.scale_on_focus = false
    b:SetImageNormalColour(0.70, 0.62, 0.42, 0.95)
    b:SetImageFocusColour(0.78, 0.70, 0.48, 1)   -- 只微亮一点点，别"爆"
    for _, ln in ipairs({
        { 0, h / 2 - 1, w, 2 },
        { 0, -(h / 2 - 1), w, 2 },
        { -(w / 2 - 1), 0, 2, h },
        { (w / 2 - 1), 0, 2, h },
    }) do
        local line = b:AddChild(Image("images/global.xml", "square.tex"))
        line:SetSize(ln[3], ln[4])
        line:SetPosition(ln[1], ln[2])
        line:SetTint(1, 1, 1, 0.9)
    end
    return b
end

-- 画一圈"框线"（4 条边）。inset = 往里缩多少才开始画，thick = 线粗
-- 用来叠多层边框凑"魔兽UI 板甲"那种层次（纯 square.tex，做不到真贴图质感）
local function FrameLines(parent, w, h, inset, thick, r, g, b, a)
    local bw, bh = w - inset * 2, h - inset * 2
    for _, ln in ipairs({
        { 0, bh / 2 - thick / 2, bw, thick },
        { 0, -(bh / 2 - thick / 2), bw, thick },
        { -(bw / 2 - thick / 2), 0, thick, bh },
        { bw / 2 - thick / 2, 0, thick, bh },
    }) do
        local line = parent:AddChild(Image("images/global.xml", "square.tex"))
        line:SetSize(ln[3], ln[4])
        line:SetPosition(ln[1], ln[2])
        line:SetTint(r, g, b, a)
    end
end

-- ================================================================
-- 技能页用的小件（2026-09-12）
-- ================================================================

-- 加点按钮：粉红色框 + 白色加号（纯 square.tex 拼，不依赖美术；用户后续补贴图）
--   2026-09-12 调色：原来底色 (0.99,0.90,0.93) 太白 → 看着像白按钮只描了条粉边，
--   现在底色改成**明确的粉**（0.98,0.72,0.80），框用深一档粉红压边，加号纯白
--   enabled=false → 保留粉色（只是变暗去饱和），不再整颗变灰（灰了看不出是"加点"）
local function MakePlusButton(parent, size, enabled, onclick)
    size = size or 58
    local b = parent:AddChild(ImageButton("images/global.xml", "square.tex"))
    b:ForceImageSize(size, size)
    b.scale_on_focus = false      -- 关掉 1.2 倍 focus 放大，免得底色爆出粉框
    if enabled then
        b:SetImageNormalColour(0.98, 0.72, 0.80, 0.98)   -- 粉色底
        b:SetImageFocusColour(1.00, 0.80, 0.86, 1)
    else
        b:SetImageNormalColour(0.82, 0.81, 0.79, 0.90)   -- 2026-09-13 用户：不能加点 → 灰底
        b:SetImageFocusColour(0.82, 0.81, 0.79, 0.90)
    end

    -- 框（enabled 时深粉，禁用时灰）
    local fr, fg, fb, fa
    if enabled then fr, fg, fb, fa = 0.92, 0.30, 0.45, 1
    else            fr, fg, fb, fa = 0.62, 0.60, 0.58, 0.90 end
    for _, ln in ipairs({
        { 0, size / 2 - 2, size, 4 },
        { 0, -(size / 2 - 2), size, 4 },
        { -(size / 2 - 2), 0, 4, size },
        { (size / 2 - 2), 0, 4, size },
    }) do
        local line = b:AddChild(Image("images/global.xml", "square.tex"))
        line:SetSize(ln[3], ln[4])
        line:SetPosition(ln[1], ln[2])
        line:SetTint(fr, fg, fb, fa)
    end

    -- 白色加号（两根白杠拼，不靠字体里的 "+"）
    local na = enabled and 1 or 0.75
    local v = b:AddChild(Image("images/global.xml", "square.tex"))
    v:SetSize(7, size * 0.50)
    v:SetTint(1, 1, 1, na)
    local h = b:AddChild(Image("images/global.xml", "square.tex"))
    h:SetSize(size * 0.50, 7)
    h:SetTint(1, 1, 1, na)

    -- 无论能不能加都挂点击：加不了时由服务端拒绝并回一句原因（"技能点不足 / 需要等级N"）
    -- （原来禁用就不挂 onclick → 点了一点反应都没有，玩家不知道差在哪）
    if onclick then
        b:SetOnClick(onclick)
    end
    return b
end

-- 金属条带：在同一段 inset/thick 区间里，用 steps 条细分叠出"外亮 → 内暗"的受光渐变
-- 单看是一根有厚度的长条，四条边合起来就是一个有立体感的框
-- （纯 square.tex 能做到的最接近"金属条"的做法：靠多档亮度骗出斜面和受光）
local function MetalBand(parent, w, h, inset, thick, cr, cg, cb, steps, a)
    steps = math.max(1, steps or 3)
    local seg = thick / steps
    for i = 1, steps do
        local k = 1 - (i - 1) / steps * 0.55          -- 亮度系数 1.00 → 0.45（外 → 内）
        FrameLines(parent, w, h, inset + (i - 1) * seg, seg, cr * k, cg * k, cb * k, a or 1)
    end
end

local MushaPanelScreen = Class(Screen, function(self, owner)
    Screen._ctor(self, "MushaPanelScreen")
    self.musha_panel = true          -- 标记：屏幕栈里靠这个认自己（DST Screen 没有 name 字段）
    self.owner = owner
    owner._musha_panel_screen_open = true

    self.root = self:AddChild(Widget("root"))
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetPosition(0, 0)

    -- 黑幕：点击关闭（照搬明生）
    self.black = self.root:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetScale(50, 50)
    self.black:SetTint(0, 0, 0, 0.6)
    self.black_clicker = self.root:AddChild(ImageButton("images/global.xml", "square.tex"))
    self.black_clicker:SetScale(50, 50)
    self.black_clicker.image:SetTint(0, 0, 0, 0)
    self.black_clicker:SetOnClick(function()
        TheFrontEnd:PopScreen()
    end)
    self.black_clicker:MoveToBack()

    -- 面板内容容器（整卡缩放）
    self.content = self.root:AddChild(Widget("panel_content"))
    self.content:SetPosition(0, 0)
    self.content:SetScale(PANEL_ZOOM)

    -- 书页底图 1:1
    self.bg = self.content:AddChild(Image("images/bookpage_bg.xml", "bookpage_bg.tex"))
    self.bg:SetSize(BG_W, BG_H)

    -- 右上角红叉（★ 可见的红叉画在书页底图里；这里是**点击/悬停区**）
    --   ★ 2026-09-14 从 V2 底图 images/bookpage_bg.png（1644x1109，等比显示成 1232x832）
    --     用像素分析量出红色圆盘（红叉）**圆心 = 面板 (523, 360)**：原值 (492,341) 偏左 31、偏下 19。
    --     ⚠️ 口径：图上量的是圆心，点击区按 80x80 居中放这里。
    self.close_btn = self.content:AddChild(ImageButton("images/global.xml", "square.tex"))
    self.close_btn:ForceImageSize(80, 80)
    self.close_btn:SetPosition(523, 360)        -- V2 图实测圆心（原 492,341）
    self.close_btn:SetImageNormalColour(1, 1, 1, 0)
    self.close_btn:SetImageFocusColour(1, 1, 1, 0.15)
    self.close_btn:SetOnClick(function()
        TheFrontEnd:PopScreen()
    end)

    -- 标题：职业名 + Lv 徽标
    self.job_text = self.content:AddChild(Text(UIFONT, 64))
    self.job_text:SetString("")
    self.job_text:SetColour(0.8, 0.6, 0.3, 1)
    self.job_text:SetPosition(-300, 230)
    self.job_text:SetHAlign(ANCHOR_LEFT)

    self.level_badge = self.content:AddChild(Image("images/global.xml", "square.tex"))
    self.level_badge:SetSize(100, 56)
    self.level_badge:SetPosition(264, 250)
    self.level_badge:SetTint(0.5, 0.42, 0.34, 0.8)

    self.level_text = self.content:AddChild(Text(UIFONT, 34))
    self.level_text:SetString("Lv.1")
    self.level_text:SetColour(1, 1, 1, 1)
    self.level_text:SetPosition(264, 250)

    -- 经验条（上面灰条 + 长条填充，整条右移 12 与竖条同步）
    self.exp_bg = self.content:AddChild(Image("images/global.xml", "square.tex"))
    self.exp_bg:SetSize(930, 22)
    self.exp_bg:SetPosition(-3, 150)
    self.exp_bg:SetTint(0.3, 0.3, 0.3, 0.6)

    self.exp_fill = self.content:AddChild(Image("images/global.xml", "square.tex"))
    self.exp_fill:SetSize(0, 22)
    self.exp_fill:SetPosition(-468, 150)
    self.exp_fill:SetTint(0.72, 0.72, 0.72, 0.95)

    self.exp_text = self.content:AddChild(Text(UIFONT, 26))
    self.exp_text:SetString("职业经验 0/100")
    self.exp_text:SetColour(0.55, 0.48, 0.38, 0.95)
    self.exp_text:SetPosition(-130, 205)
    self.exp_text:SetHAlign(ANCHOR_MIDDLE)

    -- 空状态
    self.quest_empty = self.content:AddChild(Text(UIFONT, 48))
    self.quest_empty:SetString("暂无任务")
    self.quest_empty:SetColour(0.62, 0.62, 0.62, 1)
    self.quest_empty:SetPosition(-20, -40)

    self.quest_hint = self.content:AddChild(Text(UIFONT, 26))
    self.quest_hint:SetString("完成转职条件后开启任务")
    self.quest_hint:SetColour(0.45, 0.45, 0.45, 0.5)
    self.quest_hint:SetPosition(-20, -160)

    -- ================================================================
    -- 任务列表：ScrollingGrid（照搬明生架构）
    -- ================================================================
    local FT = 4
    local FOFF = 4

    local function item_ctor_fn(context, index)
        local w = Widget("quest_item")

        -- 底框（背景板）
        w.bg = w:AddChild(Image("images/global.xml", "square.tex"))
        w.bg:SetSize(ROW_W, 64)
        w.bg:SetTint(0.85, 0.68, 0.25, 0.28)

        -- 行框体：4 条描边（外扩 4，线宽 4）
        w.frame = {}
        local frame_lines = {
            { x = 0,                   y = 32 + FOFF,  w = ROW_W + FOFF * 2, h = FT },
            { x = 0,                   y = -32 - FOFF, w = ROW_W + FOFF * 2, h = FT },
            { x = -(ROW_W / 2) - FOFF, y = 0,          w = FT, h = 64 + FOFF * 2 },
            { x = (ROW_W / 2) + FOFF,  y = 0,          w = FT, h = 64 + FOFF * 2 },
        }
        for _, ln in ipairs(frame_lines) do
            local line = w:AddChild(Image("images/global.xml", "square.tex"))
            line:SetSize(ln.w, ln.h)
            line:SetPosition(ln.x, ln.y)
            line:SetTint(0.9, 0.72, 0.3, 0.85)
            table.insert(w.frame, line)
        end

        -- 顶部红条（转职行）
        w.bar = w:AddChild(Image("images/global.xml", "square.tex"))
        w.bar:SetSize(ROW_W, 6)
        w.bar:SetPosition(0, 26)
        w.bar:SetTint(0.85, 0.22, 0.18, 0.95)
        w.bar:Hide()

        -- 顶部白色小横条（每日"普通任务"行）
        w.barw = w:AddChild(Image("images/global.xml", "square.tex"))
        w.barw:SetSize(ROW_W, 4)
        w.barw:SetPosition(0, 26)
        w.barw:SetTint(1, 1, 1, 0.7)

        w.label = w:AddChild(Text(UIFONT, 34))
        w.label:SetString("")
        w.label:SetColour(0.9, 0.9, 0.9, 1)
        w.label:SetPosition(-250, 0)
        w.label:SetHAlign(ANCHOR_LEFT)

        -- ★ 2026-09-16 UI（A 版最小改动）：计数左移 22 —— 原来贴着滚动条，眼睛要跑两边
        w.stat = w:AddChild(Text(UIFONT, 30))
        w.stat:SetString("")
        w.stat:SetColour(0.6, 0.6, 0.6, 1)
        w.stat:SetPosition(228, 0)
        w.stat:SetHAlign(ANCHOR_RIGHT)

        -- ★ 2026-09-16 UI（A）：行底一条浅分隔线 —— 相邻任务行有层次，不再只靠两根细边框
        w.div = w:AddChild(Image("images/global.xml", "square.tex"))
        w.div:SetSize(ROW_W - 60, 2)
        w.div:SetPosition(0, -34)
        w.div:SetTint(0.45, 0.36, 0.24, 0.30)

        return w
    end

    local function apply_fn(context, w, data, index)
        if not data then
            w:Hide()
            return
        end

        local done = data.done == true
        w.label:SetString(data.n or "?")

        -- 描边颜色：每日金 / 转职红 / 完成绿
        local fr, fg, fb, fa
        if done then
            fr, fg, fb, fa = 0.35, 0.8, 0.4, 0.9
        elseif data.adv then
            fr, fg, fb, fa = 0.9, 0.3, 0.25, 0.9
        else
            fr, fg, fb, fa = 0.9, 0.72, 0.3, 0.85
        end
        for _, line in ipairs(w.frame) do
            line:SetTint(fr, fg, fb, fa)
        end

        if data.adv then
            w.bg:SetTint(0.42, 0.40, 0.38, 0.55)
            w.bar:Show()
            w.barw:Hide()
        else
            w.bg:SetTint(0.85, 0.68, 0.25, 0.28)
            w.bar:Hide()
            w.barw:Show()
        end

        w.div:SetTint(done and 0.3 or 0.45, done and 0.5 or 0.36, done and 0.32 or 0.24, 0.30)

        if done then
            w.stat:SetString("✓ 完成")
            w.label:SetColour(0.4, 0.8, 0.4, 1)
            w.stat:SetColour(0.3, 0.8, 0.3, 1)
            w.bg:SetTint(0.25, 0.5, 0.28, 0.32)
        else
            w.stat:SetString((data.p or 0) .. "/" .. (data.t or 1))
            if data.adv then
                w.label:SetColour(0.95, 0.5, 0.4, 1)
                w.stat:SetColour(0.95, 0.6, 0.5, 1)
            else
                w.label:SetColour(0.28, 0.2, 0.1, 1)
                w.stat:SetColour(0.4, 0.3, 0.15, 1)
            end
        end

        w:Show()
    end

    self.list = self.content:AddChild(TEMPLATES.ScrollingGrid({}, {
        context = { screen = self },
        widget_width = ITEM_W,
        widget_height = ITEM_H,
        num_visible_rows = VISIBLE_ROWS,
        num_columns = 1,
        item_ctor_fn = item_ctor_fn,
        apply_fn = apply_fn,
        scrollbar_offset = 30,   -- 2026-09-10：原 10，右移 20
        scrollbar_height_offset = 20,   -- 竖轨上下各突出 10px（居中锚点，两侧均分）
        peek_percent = 0,
        allow_bottom_empty_row = true,
    }))
    -- 位置：首行中心 y=70（旧布局），x=-48（旧 ROW_X 32 + bg -80）
    -- 2026-09-10：上移 6（-125→-119）→ 右移 4（-48→-44）→ 再右移 5、上移 6（-44/-119 → -39/-113）
    self.list:SetPosition(-39, -113)

    -- 2026-09-10 需求：滚动条默认常显（不超过行数也显示）
    -- 原生 RefreshView 在 CanScroll()==false 时 Hide 滚动条；这里覆写强制 Show，
    -- 且在不可滚动(end_pos<=1)时把滑块放顶端，避免 GetPositionScale 除零产生 nan
    local base_refresh = self.list.RefreshView
    self.list.RefreshView = function(list, ...)
        base_refresh(list, ...)
        list.scroll_bar_container:Show()
        if list.end_pos <= 1 then
            list.position_marker:SetPosition(0, list:GetSlideStart())
        end
    end

    -- ================================================================
    -- 滚动条外观定制（2026-09-10）：取消三角、蜡黄竖轨、淡黄握把条(3道白杠)
    -- ================================================================
    do
        local list = self.list
        local SB_W = 12                 -- 竖轨宽度
        local MARK_W, MARK_H = 36, 23   -- 握把条尺寸（宽x高）

        -- 1. 取消上下三角箭头 + 手柄提示
        if list.up_button then list.up_button:Hide() end
        if list.down_button then list.down_button:Hide() end
        if list.up_button_controllerhint then list.up_button_controllerhint:Hide() end
        if list.down_button_controllerhint then list.down_button_controllerhint:Hide() end

        -- 2. 位置微调：累计 +25.3 / +5.3
        --    列表每动一次，这里反向抵消相同数值 → 竖条钉住不动
        --    （历史：+34.3/+11.3 → 列表右4上0 → +30.3/+11.3 → 列表右5上6 → +25.3/+5.3）
        if list.scroll_bar_container then
            local px, py, pz = list.scroll_bar_container:GetPositionXYZ()
            list.scroll_bar_container:SetPosition(px + 25.3, py + 5.3, pz)
        end

        -- 3. 竖条（长条）：淡黄/浅淡黄，柔和（书页底 + 孩童风）
        if list.scroll_bar_line then
            list.scroll_bar_line:ScaleToSize(SB_W, list.scrollbar_height)
            list.scroll_bar_line:SetTint(0.98, 0.91, 0.64, 0.95)
        end

        -- 4. 拉动的显示条（握把）：本体透明(不盖) + 上下两条蜡黄框(等长) + 中间 5 道白杠
        if list.position_marker then
            local m = list.position_marker
            m:SetTextures("images/global.xml", "square.tex")
            m:ForceImageSize(MARK_W, MARK_H)
            m:SetScale(1, 1, 1)   -- 原 BuildScrollBar 设了 0.3，重置
            m:SetImageNormalColour(1, 1, 1, 0)   -- 第三版：本体透明，不盖住下面
            m:SetImageFocusColour(1, 1, 1, 0.15)
            m.scale_on_focus = false
            m.ignore_standard_scaling = true
            m.focus_scale = {1, 1, 1}
            m.normal_scale = {1, 1, 1}
            m.image:SetTint(1, 1, 1, 0)  -- 直接设色兜底

            if not m._grip_built then
                m._grip_built = true

                -- 上下两道外框（等长 = MARK_W），蜡黄不褪色
                local cap_y = MARK_H / 2 - 1.5
                for _, yy in ipairs({ cap_y, -cap_y }) do
                    local cap = m:AddChild(Image("images/global.xml", "square.tex"))
                    cap:SetSize(MARK_W, 3)
                    cap:SetPosition(0, yy)
                    cap:SetTint(0.88, 0.78, 0.48, 1)
                end

                -- 中间 5 道白杠挤在一起（夹心）
                for i = 1, 5 do
                    local bar = m:AddChild(Image("images/global.xml", "square.tex"))
                    bar:SetSize(MARK_W - 14, 1.6)
                    bar:SetPosition(0, (3 - i) * 3)   -- +6/+3/0/-3/-6
                    bar:SetTint(1, 1, 1, 0.9)
                end
            end

            -- 三角取消后，滑块可滑满整条竖轨（原生公式扣了 arrow_button_size）
            list.GetSlideStart = function(l) return l.scrollbar_height / 2 - MARK_H / 2 end
            list.GetSlideRange = function(l) return math.max(1, l.scrollbar_height - MARK_H) end
        end

        -- 5. 轨道空白区点击热区跟着握把宽度
        if list.scroll_bar then
            list.scroll_bar.image:ScaleToSize(MARK_W, list.scrollbar_height)
        end
    end

    -- ================================================================
    -- 【多页 + 导航】2026-09-10
    --   主页 = 复用现有那堆控件（不搬容器，直接成组 Show/Hide）
    --   其它四页各一个容器；右上三角 点开展开 5 项列表
    --   现阶段全文字（导航图标等美术）
    -- ================================================================
    -- 2026-09-13：装备页从"图鉴"里拆出来单独一页（原来页名叫图鉴、内容其实是装备·属性）
    --   现在：equip = 装备·属性（原内容不动），dex = 图鉴（新占位页，内容待定）
    self.page_titles = { home = "主页", skill = "技能", equip = "装备", mail = "信箱", set = "设置", gift = "礼包", dex = "图鉴" }
    -- ★ 2026-09-14 用户：「装备系统拆出来，先隐藏，后面做在右边显示」
    --   → 导航里**先不放** equip（这一版看不到入口）。页面代码（self.pages.equip / RefreshEquip）
    --     全部保留着，以后要做"右边单独显示"时，把 "equip" 加回这个表就能恢复。
    self.page_order  = { "home", "skill", "mail", "set", "gift", "dex" }

    self.pages = {}
    self.pages.home = {
        self.job_text, self.level_badge, self.level_text,
        self.exp_bg, self.exp_fill, self.exp_text,
        self.quest_empty, self.quest_hint, self.list,
    }

    local function NewPage()
        local w = self.content:AddChild(Widget("musha_page"))
        w:Hide()
        return w
    end

    local function PageTip(page, str, size)
        local t = page:AddChild(Text(UIFONT, size or 44))
        t:SetString(str)
        t:SetColour(0.58, 0.52, 0.42, 1)
        t:SetPosition(0, 0)
        return t
    end

    -- 技能页（2026-09-12 建）：外层全白框 + 内层淡白书页底 + 技能行 + 加点按钮（粉框白加号）
    --   美术待补：现在是纯 square.tex 拼的占位（用户晚些时候补图）
    --   只做战士（数据见 musha_profession_component 的 self.warrior / SKILL_UI）
    self.pages.skill = NewPage()
    do
        local PAGE_W, PAGE_H = 890, 600
        local root = self.pages.skill
        root:SetPosition(0, -33)

        -- ① 外层：全白压边
        FrameLines(root, PAGE_W, PAGE_H, 0, 6, 1, 1, 1, 1)

        -- ② 内层：淡白色质感底（占位 = 冷白 tint 的 square.tex，比外框暗一档）
        local inner = root:AddChild(Image("images/global.xml", "square.tex"))
        inner:SetSize(PAGE_W - 34, PAGE_H - 34)
        inner:SetPosition(0, 0)
        inner:SetTint(0.965, 0.960, 0.945, 0.97)

        -- ②b 内圈一道白细线（书页的第二层压边，避免整块死白）
        FrameLines(root, PAGE_W - 26, PAGE_H - 26, 0, 2, 1, 1, 1, 0.85)

        -- ③ 顶部：职业 · 等级 · 可用技能点
        self.skill_head = root:AddChild(Text(UIFONT, 32))
        self.skill_head:SetColour(0.28, 0.22, 0.15, 1)
        self.skill_head:SetString("技能")
        self.skill_head:SetPosition(0, PAGE_H / 2 - 46)

        -- ③b 上方文字项目：未学习 / 已学习（点它切换同一页的两个子页，2026-09-12）
        --   书页风：选中的是白底 + 深墨字 + 一道深橙下划线，未选中的是浅灰底 + 灰字
        self.skill_tabs = {}
        self.skill_tab  = "unlearned"     -- 默认显示"未学习"（= 原来的那一页）
        do
            local TAB_W, TAB_H, TAB_GAP, TAB_Y = 150, 36, 20, 200
            local TABS = {
                { key = "unlearned", label = "未学习" },
                { key = "learned",   label = "已学习" },
            }
            for i, def in ipairs(TABS) do
                local b = root:AddChild(ImageButton("images/global.xml", "square.tex"))
                b:ForceImageSize(TAB_W, TAB_H)
                b.scale_on_focus = false
                b.normal_scale = { 1, 1, 1 }
                b.focus_scale  = { 1, 1, 1 }
                b:SetPosition((i - 1.5) * (TAB_W + TAB_GAP), TAB_Y)
                FrameLines(b, TAB_W, TAB_H, 0, 2, 0.80, 0.78, 0.73, 0.90)

                local t = b:AddChild(Text(UIFONT, 26))
                t:SetString(def.label)

                -- 选中态下划线（未选中时 Hide）
                local ul = b:AddChild(Image("images/global.xml", "square.tex"))
                ul:SetSize(TAB_W - 40, 3)
                ul:SetPosition(0, -TAB_H / 2 + 4)
                ul:SetTint(0.85, 0.30, 0.08, 1)

                b:SetOnClick(function() self:SetSkillTab(def.key) end)
                self.skill_tabs[def.key] = { btn = b, text = t, underline = ul }
            end
        end

        -- ④ 技能列表：ScrollingGrid（2026-09-13 用户：未学习那个照信箱的，要能向下滚动）
        --   item_ctor 只建一次（网格会复用），apply_fn 负责把数据填进去
        local function SKILL_item_ctor(context, index)
            local row = Widget("skill_item")

            -- 卡片底（比整页淡白再亮一档）+ 淡灰细边
            local card = row:AddChild(Image("images/global.xml", "square.tex"))
            card:SetSize(SKILL_ROW_W, SKILL_ROW_H)
            card:SetTint(1.000, 0.995, 0.985, 0.95)
            row.card = card
            FrameLines(row, SKILL_ROW_W, SKILL_ROW_H, 0, 2, 0.80, 0.78, 0.73, 0.90)

            -- 技能名
            row.t_name = SkillText(row, 30, 48, "", 0.22, 0.17, 0.11)
            -- 三行说明（未学习/已学习共用同一批位置，apply_fn 里换字换色）
            row.t_l1 = SkillText(row, 22, 12, "", 0.40, 0.34, 0.26)
            row.t_l2 = SkillText(row, 22, -26, "", 0.30, 0.24, 0.16)
            -- 第三行有两套字号（18 = tip 灰字 / 22 = 下一级粉字），建两个只显示一个
            row.t_l3_tip = SkillText(row, 18, -58, "", 0.52, 0.46, 0.38)
            row.t_l3_next = SkillText(row, 22, -58, "", 0.52, 0.30, 0.36)

            -- ★★ 2026-09-21 用户改口：说明**常显**（原来只在悬停时出现 → 他："恢复鼠标不在上面也可显示"）
            --   → 四行说明一直显示；悬停只把卡片提亮一档（SetHover 只管 tint，不再控制可见性）
            row.hovered = false
            row._l3 = "tip"

            row.SetHover = function(r, on)
                r.hovered = on and true or false
                if r.card then
                    if r.hovered then
                        r.card:SetTint(1.000, 1.000, 0.972, 1)      -- 高亮一档
                    else
                        r.card:SetTint(1.000, 0.995, 0.985, 0.95)
                    end
                end
                -- 第三行两套字号：按 _l3 决定显哪一条（与悬停无关）
                if r._l3 == "next" then
                    r.t_l3_next:Show()
                    r.t_l3_tip:Hide()
                else
                    r.t_l3_tip:Show()
                    r.t_l3_next:Hide()
                end
            end

            -- 悬停接盘：垫在卡片上、加点按钮**下面**（按钮后建 → 在更上层，不会挡住点击）
            local hover = row:AddChild(ImageButton("images/global.xml", "square.tex"))
            hover:ForceImageSize(SKILL_ROW_W, SKILL_ROW_H)
            hover:SetPosition(0, 0)
            hover.scale_on_focus = false
            hover.move_on_click  = false
            hover.normal_scale   = { 1, 1, 1 }
            hover.focus_scale    = { 1, 1, 1 }
            hover:SetImageNormalColour(1, 1, 1, 0)
            hover:SetImageFocusColour(1, 1, 1, 0)       -- 高亮靠卡片 tint，不另画白块
            if hover.image then hover.image:SetTint(1, 1, 1, 0) end
            hover:SetOnGainFocus(function() row:SetHover(true) end)
            hover:SetOnLoseFocus(function() row:SetHover(false) end)

            -- ★ 2026-09-17 技能书锁的悬停提示（默认隐藏，鼠标移到锁上才显示）
            row.t_lock_tip = SkillText(row, 20, -58, "", 0.62, 0.28, 0.24)
            row.t_lock_tip:Hide()

            row.btn = nil          -- 加点按钮：apply_fn 里按数据新建
            row.btn_lock_w = nil   -- 技能书锁图标：apply_fn 里按数据新建
            row.btn_lock = false   -- 当前行是不是"锁"状态（供 diff 判断）
            return row
        end

        local function SKILL_apply_fn(context, row, data, index)
            if not data then
                row:Hide()
                return
            end
            row:Show()

            row.t_name:SetString(data.name or "?")

            local cur = data.cur or 0
            -- ★ 2026-09-21：行首的 [战士]/[剑士] 标签**去掉**（用户口径：技能页不显示职业名）
            local tag = ""

            if cur > 0 then
                -- 已学习：等级 / 当前效果 / 下一级（满级写"已满级"）
                row.t_l1:SetString(string.format("%s等级 %d / %d", tag, cur, data.max or 0))
                row.t_l1:SetColour(0.40, 0.34, 0.26, 1)
                row.t_l2:SetString("当前：" .. (data.effect or ""))
                row.t_l2:SetColour(0.30, 0.24, 0.16, 1)
                row._l3 = "next"                    -- ★ 只记该显哪一行，真显不显看悬停
                row.t_l3_next:SetString(data.maxed and "已满级" or ("下一级：" .. (data.nextfx or "")))
            else
                -- 未学习：需求等级 / 消耗 / 学完后的效果（有 tip 就补一句灰字）
                local parts = {}
                if (data.req or 0) > 0 then
                    table.insert(parts, string.format("需要 Lv.%d", data.req))
                end
                if (data.book_lock or 0) > 0 then
                    -- ★ 2026-09-17 技能书锁：这条不能用技能点买，要书
                    table.insert(parts, string.format("需要 %d 本技能书解锁", data.book_lock))
                else
                    table.insert(parts, string.format("消耗 %d 技能点", data.cost or 1))
                end
                row.t_l1:SetString(tag .. table.concat(parts, "　·　"))
                row.t_l1:SetColour(0.40, 0.34, 0.26, 1)
                row.t_l2:SetString("学完后：" .. (data.nextfx or ""))
                row.t_l2:SetColour(0.30, 0.24, 0.16, 1)
                row._l3 = "tip"                     -- ★ 同上：只记该显哪一行
                row.t_l3_tip:SetString(data.tip or "")
            end

            -- ★ 2026-09-21 说明文字只在悬停时出现 → 填完字同步一次可见性
            --   （悬停中的行立刻显新字；没悬停的行保持只有技能名，干净）
            row:SetHover(row.hovered == true)

            -- 2026-09-13 用户：不能加点的整行按灰色处理（已满级那档不灰，走下面"隐藏加号"）
            local GRAY = (not data.maxed) and not (data.can == true)
            if GRAY then
                row.t_name:SetColour(0.55, 0.52, 0.48, 1)
                row.t_l1:SetColour(0.60, 0.57, 0.53, 1)
                row.t_l2:SetColour(0.60, 0.57, 0.53, 1)
                row.t_l3_tip:SetColour(0.64, 0.61, 0.57, 1)
                row.t_l3_next:SetColour(0.66, 0.62, 0.58, 1)
            end

            -- 加点按钮（2026-09-13 用户：不能加点 = 灰加号；已满级 = 直接隐藏加号）
            -- ★ 2026-09-17 技能书锁：0 级的"技能书解锁技"不画加号，改画小锁（悬停出提示）
            local book_lock = ((data.book_lock or 0) > 0)
            local can_add = (data.can == true) and not data.maxed and not book_lock
            local maxed   = (data.maxed == true)
            if row.btn_skill ~= data.id or row.btn_can ~= can_add or row.btn_maxed ~= maxed
                or row.btn_lock ~= book_lock then
                if row.btn then row.btn:Kill(); row.btn = nil end
                if row.btn_lock_w then row.btn_lock_w:Kill(); row.btn_lock_w = nil end
                if not maxed then
                    if book_lock then
                        local needn = data.book_lock
                        local sid   = data.id
                        -- ★★ 2026-09-18 用户：「点加点和图片都可以打开的」→
                        --   【锁】(图片) 和 【+】两处都能点，两处都走"用背包里的技能书解锁"。
                        --   + 故意画成灰色（不能让玩家以为花技能点也能买 —— 服务端也拦了这道，见 CanUpgradeSkill）
                        row.btn_lock_w = MakeLockButton(row, SKILL_BTN, SKILL_ROW_W / 2 - 56, -6,
                            function(over)
                                if over then
                                    row.t_lock_tip:SetString(string.format(
                                        "点这里（或 +）用背包里的技能书解锁 · 需要 %d 本", needn))
                                    row.t_lock_tip:Show()
                                else
                                    row.t_lock_tip:Hide()
                                end
                            end,
                            function() SendSkillUnlock(sid) end)
                        row.btn = MakePlusButton(row, SKILL_BTN, false, function() SendSkillUnlock(sid) end)
                        row.btn:SetPosition(SKILL_ROW_W / 2 - 56 - SKILL_BTN - 10, -6)
                    else
                        local sid = data.id
                        row.btn = MakePlusButton(row, SKILL_BTN, can_add, function() SendSkillUpgrade(sid) end)
                        row.btn:SetPosition(SKILL_ROW_W / 2 - 56, -6)
                    end
                end
                row.btn_skill = data.id
                row.btn_can   = can_add
                row.btn_maxed = maxed
                row.btn_lock  = book_lock
            end
        end

        self.skill_grid = root:AddChild(TEMPLATES.ScrollingGrid({}, {
            context = { screen = self },
            widget_width = SKILL_ITEM_W,
            widget_height = SKILL_ITEM_H,
            num_visible_rows = SKILL_VISIBLE,
            num_columns = 1,
            item_ctor_fn = SKILL_item_ctor,
            apply_fn = SKILL_apply_fn,
            scrollbar_offset = 24,
            peek_percent = 0,
            allow_bottom_empty_row = true,
        }))
        -- 位置：⚠️ ScrollingGrid 会把"可见行"以自身原点为中心上下分布
        --   （模板里 grid:SetPosition(..., widget_height*(visible-1)/2 + peek/2)）
        --   所以原点不是"第一行中心"：2 行时行中心 = 原点 +85 / 原点 -85
        --   取原点 y=5 → 两行中心 90 / -80，正好落在子页文字(200)和底部(约-240)之间
        self.skill_grid:SetPosition(0, 5)

        -- ⑤ 空状态提示
        self.skill_empty = root:AddChild(Text(UIFONT, 28))
        self.skill_empty:SetColour(0.52, 0.46, 0.38, 1)
        self.skill_empty:SetString("")
        self.skill_empty:SetPosition(0, 0)
        self.skill_empty:Hide()

        -- ⑥ 底部提示
        local foot = root:AddChild(Text(UIFONT, 20))
        foot:SetColour(0.46, 0.40, 0.32, 1)
        foot:SetString("技能书学习的技能 · 后续开放")
        foot:SetPosition(0, -PAGE_H / 2 + 34)
        self.skill_foot = foot

        -- ============================================================
        -- ★★ 2026-09-20 横排技能树（新）—— 见图表 spec：musha-技能树UI-spec.md
        --   · 图标 only + 按住空白左右拖动 + 滚轮/小箭头；横竖线 = 前置（金=已达标 / 灰=未达标）
        --   · 点节点 → 右栏出「技能详情」（加点按钮在右栏，防误点）
        --   · 旧版竖排列表**保留**：右上两颗小按钮切（默认横排）
        -- ============================================================
        self.skill_mode = "tree"            -- "tree" 横排（默认） / "list" 旧版竖排
        do
            local SkillTree = require("widgets/musha_skill_tree")

            -- ① 右栏「技能详情」（默认收起，点节点才出）
            local DW, DH = 232, 380
            self.skill_detail = root:AddChild(Widget("skill_detail"))
            self.skill_detail:SetPosition(298, -14)
            local dbg = self.skill_detail:AddChild(Image("images/global.xml", "square.tex"))
            dbg:SetSize(DW, DH)
            dbg:SetTint(0.995, 0.99, 0.975, 0.99)
            FrameLines(self.skill_detail, DW, DH, 0, 2, 0.80, 0.78, 0.73, 0.95)

            self.skill_detail_title = self.skill_detail:AddChild(Text(UIFONT, 28))
            self.skill_detail_title:SetColour(0.26, 0.20, 0.13, 1)
            self.skill_detail_title:SetPosition(0, DH / 2 - 32)

            self.skill_detail_lines = {}
            for i = 1, 5 do
                local t = self.skill_detail:AddChild(Text(UIFONT, 20))
                t:SetColour(0.36, 0.30, 0.22, 1)
                t:SetPosition(0, DH / 2 - 72 - (i - 1) * 44)
                t:SetString("")
                table.insert(self.skill_detail_lines, t)
            end

            -- 加点 / 用技能书解锁（同一颗按钮，按数据决定干啥；满级直接隐藏）
            self.skill_detail_btn = MakeTextButton(self.skill_detail, 132, 34, "加点", function()
                local e = self.skill_sel
                if not e then return end
                if (e.book_lock or 0) > 0 then
                    SendSkillUnlock(e.id)
                else
                    SendSkillUpgrade(e.id)
                end
            end)
            self.skill_detail_btn:SetPosition(0, -DH / 2 + 34)
            self.skill_detail:Hide()

            -- ② 横排树
            self.skill_tree = root:AddChild(SkillTree({
                w = 596, h = 424,
                on_select = function(e) self:ShowSkillDetail(e) end,
            }))
            self.skill_tree:SetPosition(-124, -26)

            -- ③ 版式切换按钮 —— ★ 2026-09-21 用户拍板「直接横排 不要竖排了」→ **不再创建这两颗按钮**
            --   竖排列表相关的 widget（skill_grid / skill_tabs / skill_foot / skill_empty）仍在，
            --   但永久隐藏（见 SetSkillMode 里强制 tree）；代码留着当退路，将来要加法师大技能树再动。
            self.skill_mode_btns = {}
        end
    end

    -- 礼包页（2026-09-12 用户选 b：面板导航里加一页；节日活动期间发放）
    --   数据源 scripts/musha_gifts.lua；点击「领取」→ RPC musha_claim_gift（服务端校验+发放）
    self.pages.gift = NewPage()
    do
        local PAGE_W, PAGE_H = 890, 600
        local root = self.pages.gift
        root:SetPosition(0, -33)

        FrameLines(root, PAGE_W, PAGE_H, 0, 6, 1, 1, 1, 1)

        local inner = root:AddChild(Image("images/global.xml", "square.tex"))
        inner:SetSize(PAGE_W - 34, PAGE_H - 34)
        inner:SetTint(0.965, 0.960, 0.945, 0.97)

        -- ★ 2026-09-14 用户：① 礼包（标题）左移 220 像素 ② 下面那行提示"跟随"，
        --    但最终定位改成挂在【标题的右下角】再各内缩 15 像素（-15x,-15y）
        -- 2026-09-14 再调：标题再左移 40、上移 12；下面那行在"跟随结果"基础上再加 120 x
        local GIFT_HEAD_X, GIFT_HEAD_Y = -3 - 220 - 40 - 32, PAGE_H / 2 - 46 - 12 + 12   -- (-295, 254) ← 2026-09-14 用户"再往左 -32x"
        local HEAD_HALF_W, HEAD_HALF_H = 32, 16        -- 标题"礼包"=2 个 32 号字 → 半宽≈32、半高≈16
        local HINT_GAP = 15                            -- 右下角内缩量
        local HINT_EXTRA_X = 120                       -- 提示行额外右移（2026-09-14）

        self.gift_head = root:AddChild(Text(UIFONT, 32))
        self.gift_head:SetColour(0.28, 0.22, 0.15, 1)
        self.gift_head:SetString("礼包")
        -- 2026-09-13 用户：先 -12 像素，再左移 3 像素；2026-09-14：再左移 220 → 再左移 40 / 上移 12
        self.gift_head:SetPosition(GIFT_HEAD_X, GIFT_HEAD_Y)

        self.gift_hint = root:AddChild(Text(UIFONT, 20))
        self.gift_hint:SetColour(0.46, 0.40, 0.32, 1)
        self.gift_hint:SetString("节日活动期间发放 · 有活动时礼包会出现在这里")
        -- 2026-09-13 用户：右移 -39（= 左移 39）、上移 15 → 再右移 200 → 净 x = +161
        -- 2026-09-14 用户：跟随标题（右下角 -15,-15），再额外右移 120 → (-263+32-15+120, 254-16-15) = (-126, 223)
        self.gift_hint:SetPosition(GIFT_HEAD_X + HEAD_HALF_W - HINT_GAP + HINT_EXTRA_X,
                                   GIFT_HEAD_Y - HEAD_HALF_H - HINT_GAP)

        -- 礼包行容器（RefreshGift 动态重建）
        --   2026-09-12 用户：初始礼包上移 200（-20 → 180），再下移 10 → 170
        --   2026-09-13 用户：再上移 5 → 175
        --   2026-09-14 用户：「礼包框下移 80 像素」→ 175 - 80 = 95
        --   2026-09-14 用户：「再下 12 像素」→ 95 - 12 = 83
        --   2026-09-14 用户：「再下移 5 像素」→ 83 - 5 = 78
        self.gift_body = root:AddChild(Widget("gift_body"))
        self.gift_body:SetPosition(0, 78)
    end

    -- 信箱页（更新日志）：外圈橙色框条 + 内层橙灰底 + 底部翻页
    self.pages.mail = NewPage()
    do
        -- 第四次调：整体再扩 7/边（876x586 → 890x600）
        local PAGE_W, PAGE_H = 890, 600
        local root = self.pages.mail
        root:SetPosition(0, -33)

        -- ① 外框：条状金属 —— 每层再细分出"外亮→内暗"的受光渐变，做出长条的厚度感
        --    （原来是一条纯色线，太平；现在同一条框由多档亮度的小条拼出来）
        FrameLines(root, PAGE_W, PAGE_H, 0,  5,  0.15, 0.10, 0.06, 1)    -- 最外：深棕黑压边
        MetalBand(root, PAGE_W, PAGE_H, 5,  16, 0.99, 0.63, 0.28, 4, 1)  -- 主条：橙，4 档渐变
        MetalBand(root, PAGE_W, PAGE_H, 21, 3,  1.00, 0.88, 0.50, 2, 1)  -- 内圈：金高光条

        -- 四角铆钉（带顶部受光高光）
        local STUD = 14
        for _, c in ipairs({
            { PAGE_W / 2 - 6, PAGE_H / 2 - 6 },
            { -(PAGE_W / 2 - 6), PAGE_H / 2 - 6 },
            { -(PAGE_W / 2 - 6), -(PAGE_H / 2 - 6) },
            { PAGE_W / 2 - 6, -(PAGE_H / 2 - 6) },
        }) do
            local s = root:AddChild(Image("images/global.xml", "square.tex"))
            s:SetSize(STUD, STUD)
            s:SetPosition(c[1], c[2])
            s:SetTint(0.88, 0.74, 0.40, 1)
            -- 铆钉上半的高光条（受光面）
            local hl = root:AddChild(Image("images/global.xml", "square.tex"))
            hl:SetSize(STUD - 4, 3)
            hl:SetPosition(c[1], c[2] + STUD / 2 - 3)
            hl:SetTint(1.00, 0.94, 0.62, 1)
        end

        -- ② 内层橙灰底（缩到金线以内，别压住边框）
        local inner = root:AddChild(Image("images/global.xml", "square.tex"))
        inner:SetSize(PAGE_W - 50, PAGE_H - 50)
        inner:SetPosition(0, 0)
        inner:SetTint(0.78, 0.68, 0.56, 0.94)

        -- ③ 内容容器（RefreshMail 往里填）；文字整体再上移 3.4
        self.mail_content = root:AddChild(Widget("mail_content"))
        self.mail_content:SetPosition(0, 53.4)

        -- ④ 底部翻页：<  [1 2 3]  >   （数字可点直接跳页；尺寸已缩小）
        --    位置必须完全落在内层橙灰底（±275）之内，否则按钮会压到外框的橙/金描边上 → 颜色发脏
        self.mail_page = 1
        local PY = -PAGE_H / 2 + 46

        self.mail_prev = StyleLikeTriangle(
            MakeTextButton(root, 44, 26, "<", function() self:MailTurn(-1) end), 44, 26)
        self.mail_prev._label:SetSize(20)
        self.mail_prev:SetPosition(-140, PY)

        self.mail_next = StyleLikeTriangle(
            MakeTextButton(root, 44, 26, ">", function() self:MailTurn(1) end), 44, 26)
        self.mail_next._label:SetSize(20)
        self.mail_next:SetPosition(140, PY)

        -- 页码容器（RefreshMail 里按页数重建）
        self.mail_pagenums = root:AddChild(Widget("mail_pagenums"))
        self.mail_pagenums:SetPosition(0, PY)
    end

    -- 装备 · 属性页（2026-09-13 新增；原页名"图鉴"已改成 keys=equip、导航标签"装备"）
    --   左列：头/身/手 三个装备格（图标 + 名字 + 关键数值）
    --   右列：12 行属性（生命/饥饿/理智/能量/攻击力/减伤/移速/保暖/隔热/职业/等级/技能点）
    --   ⚠️ 全走客户端 API：replica.inventory / player_classified / netvar，服务端组件在这里读不到
    self.pages.equip = NewPage()
    do
        local PAGE_W, PAGE_H = 890, 600
        local root = self.pages.equip
        root:SetPosition(0, -33)

        FrameLines(root, PAGE_W, PAGE_H, 0, 6, 1, 1, 1, 1)

        local inner = root:AddChild(Image("images/global.xml", "square.tex"))
        inner:SetSize(PAGE_W - 34, PAGE_H - 34)
        inner:SetTint(0.965, 0.960, 0.945, 0.97)

        self.eq_head = root:AddChild(Text(UIFONT, 32))
        self.eq_head:SetColour(0.28, 0.22, 0.15, 1)
        self.eq_head:SetString("装备 · 属性")
        self.eq_head:SetPosition(-3, PAGE_H / 2 - 46 - 12)

        -- 左列：三个装备格
        self.eq_slots = {}
        local SLOT_DEF = {
            { key = "head",  label = "头部", y =  170 },
            { key = "body",  label = "身体", y =   60 },
            { key = "hands", label = "手部", y =  -50 },
        }
        for _, s in ipairs(SLOT_DEF) do
            local box = root:AddChild(Widget("eq_box_" .. s.key))
            box:SetPosition(-290, s.y)

            local lb = box:AddChild(Text(UIFONT, 18))
            lb:SetColour(0.55, 0.48, 0.38, 1)
            lb:SetString(s.label)
            lb:SetPosition(0, 44)

            local bg = box:AddChild(Image("images/global.xml", "square.tex"))
            bg:SetSize(64, 64)
            bg:SetTint(1, 1, 1, 0.5)

            local ic = box:AddChild(Image("images/global.xml", "square.tex"))
            ic:SetSize(56, 56)
            ic:SetTint(1, 1, 1, 0)          -- 空槽透明；刷新时换图

            local nm = box:AddChild(Text(UIFONT, 20))
            nm:SetColour(0.28, 0.22, 0.15, 1)
            nm:SetString("—")
            nm:SetPosition(0, -44)

            local st = box:AddChild(Text(UIFONT, 18))
            st:SetColour(0.55, 0.48, 0.38, 1)
            st:SetString("")
            st:SetPosition(0, -66)

            self.eq_slots[s.key] = { icon = ic, name = nm, stat = st }
        end

        -- 右列：12 行属性（标签左对齐 + 数值右对齐，都靠 SetRegionSize + SetHAlign）
        self.eq_rows = {}
        -- 标签在建页时就写死（RefreshEquip 只负责填数值）：
        --   万一刷新链路断了，页面至少是可读的标签 + "—"，而不是一片空白
        local ROW_LABELS = {
            "生命", "饥饿", "理智", "能量", "攻击力", "减伤",
            "移速", "保暖", "隔热", "职业", "等级 · 经验", "技能点",
        }
        for i = 1, 12 do
            local y = 200 - (i - 1) * 28

            local lb = root:AddChild(Text(UIFONT, 22))
            lb:SetString(ROW_LABELS[i] or "")
            lb:SetColour(0.55, 0.48, 0.38, 1)
            lb:SetRegionSize(300, 24)
            lb:SetHAlign(ANCHOR_LEFT)
            lb:SetPosition(-10, y)

            local vl = root:AddChild(Text(UIFONT, 22))
            vl:SetString("—")
            vl:SetColour(0.28, 0.22, 0.15, 1)
            vl:SetRegionSize(260, 24)
            vl:SetHAlign(ANCHOR_RIGHT)
            vl:SetPosition(270, y)

            self.eq_rows[i] = { label = lb, value = vl }
        end
    end

    -- 图鉴页（2026-09-13 从装备页里拆出来单独一页）：2026-09-16 起有内容了
    --   内容源 = scripts/musha_dex.lua（数组，卡片式滚动列表；加条目只改那个文件）
    self.pages.dex = NewPage()
    do
        local PAGE_W, PAGE_H = 890, 600
        local root = self.pages.dex
        root:SetPosition(0, -33)

        FrameLines(root, PAGE_W, PAGE_H, 0, 6, 1, 1, 1, 1)

        local inner = root:AddChild(Image("images/global.xml", "square.tex"))
        inner:SetSize(PAGE_W - 34, PAGE_H - 34)
        inner:SetTint(0.965, 0.960, 0.945, 0.97)

        -- ★ 2026-09-16 用户「上面根本没排」：PageTip 自带位置是 (0,0)（= 页面正中），
        --   原来标题被压在卡片后面 → 这里挪到页面上方；列表也跟着上移（见下面 SetPosition）
        local dex_title = PageTip(root, "图鉴", 40)
        dex_title:SetPosition(0, 248)

        -- ★ 2026-09-16 用户「图鉴再改一下 太大」：卡片收窄（840 → 760）、可见行 4 → 3
        --   （高度压不了：标题条 + 3 行说明已经占满 112，再压文字就出框）
        local DEX_W, DEX_H = 760, 112
        local DEX_VISIBLE = 3
        local FT, FOFF = 4, 4

        local function dex_ctor(context, index)
            local w = Widget("dex_item")

            w.bg = w:AddChild(Image("images/global.xml", "square.tex"))
            w.bg:SetSize(DEX_W, DEX_H)
            w.bg:SetTint(0.85, 0.68, 0.25, 0.22)

            w.frame = {}
            local frame_lines = {
                { x = 0,                y = DEX_H / 2 + FOFF,  w = DEX_W + FOFF * 2, h = FT },
                { x = 0,                y = -DEX_H / 2 - FOFF, w = DEX_W + FOFF * 2, h = FT },
                { x = -(DEX_W / 2) - FOFF, y = 0,              w = FT, h = DEX_H + FOFF * 2 },
                { x = (DEX_W / 2) + FOFF,  y = 0,              w = FT, h = DEX_H + FOFF * 2 },
            }
            for _, ln in ipairs(frame_lines) do
                local line = w:AddChild(Image("images/global.xml", "square.tex"))
                line:SetSize(ln.w, ln.h)
                line:SetPosition(ln.x, ln.y)
                line:SetTint(0.9, 0.72, 0.3, 0.85)
                table.insert(w.frame, line)
            end

            -- ★ 2026-09-16 新增：条目图标（贴装备自己的库存图集 images/inventoryimages/<名>.xml）
            --   条目里给了 icon_atlas/icon_tex 才贴，没给就藏起来（不报错）
            --   位置：卡片左侧，文字整体右移 110 让位
            w.icon = w:AddChild(Image("images/global.xml", "square.tex"))
            w.icon:SetSize(64, 64)
            w.icon:SetPosition(-DEX_W / 2 + 46, -12)

            -- 顶部姓名条（同任务列表那套暖黄贴纸感）
            w.chip = w:AddChild(Image("images/global.xml", "square.tex"))
            w.chip:SetSize(320, 36)
            w.chip:SetPosition(-DEX_W / 2 + 292, 34)
            w.chip:SetTint(0.96, 0.91, 0.74, 0.95)

            w.title = w:AddChild(Text(UIFONT, 30))
            w.title:SetString("")
            w.title:SetColour(0.30, 0.24, 0.16, 0.98)
            w.title:SetHAlign(ANCHOR_LEFT)
            w.title:SetPosition(-DEX_W / 2 + 150, 34)

            w.tag = w:AddChild(Text(UIFONT, 24))
            w.tag:SetString("")
            w.tag:SetColour(0.55, 0.42, 0.2, 1)
            w.tag:SetHAlign(ANCHOR_RIGHT)
            w.tag:SetPosition(DEX_W / 2 - 22, 34)

            w.rows = {}
            for i = 1, 3 do
                local t = w:AddChild(Text(UIFONT, 24))
                t:SetString("")
                t:SetColour(0.30, 0.24, 0.17, 1)
                t:SetRegionSize(DEX_W - 170, 26)
                t:SetHAlign(ANCHOR_LEFT)
                t:SetPosition(55, 2 - (i - 1) * 28)
                w.rows[i] = t
            end

            return w
        end

        local function dex_apply(context, w, data, index)
            if not data then w:Hide(); return end

            -- ★ 2026-09-16 图标：条目自带 icon_atlas/icon_tex 就贴（装备的库存图集），否则藏
            if data.icon_atlas ~= nil and data.icon_tex ~= nil then
                w.icon:SetTexture(data.icon_atlas, data.icon_tex, data.icon_tex)
                w.icon:SetSize(64, 64)
                w.icon:Show()
            else
                w.icon:Hide()
            end

            w.title:SetString(tostring(data.name or "?"))
            w.tag:SetString(tostring(data.tag or ""))
            for i = 1, 3 do
                local t = w.rows[i]
                local s = data.lines and data.lines[i]
                if s then
                    t:SetString("· " .. tostring(s))
                    t:Show()
                else
                    t:SetString("")
                    t:Hide()
                end
            end
            w:Show()
        end

        self.dex_list = root:AddChild(TEMPLATES.ScrollingGrid(MUSHA_DEX or {}, {
            context = { screen = self },
            -- ★ 2026-09-16 修「图鉴卡片错位、上下两张叠在一起」：
            --   卡片含外框实际占 DEX_H + 2*FOFF（= 120），原来行高只有 118 → 行与行互相压；
            --   行宽又写的是任务列表的 ITEM_W（860）而卡片是 840 → 左右也偏。按卡片真实尺寸给，留 8px 缝。
            widget_width = DEX_W + 2 * FOFF + 8,
            widget_height = DEX_H + 2 * FOFF + 8,
            num_visible_rows = DEX_VISIBLE,
            num_columns = 1,
            item_ctor_fn = dex_ctor,
            apply_fn = dex_apply,
            -- ★ 2026-09-16 修「框框位置不对」：行宽从 ITEM_W(860) 改成 856 后位置没跟着改，
            --   原来 x=-20 → 卡片外框（848 宽）占 -444..+404：**左框线跑到内页白底外 16px、
            --   右边空 24px**，左右不对称。现 x=0 → 外框 -424..+424，左右各留 4px 对称。
            --   滚动条为了不跟着位移：x 右移了 20，这里 offset 30 → 10（绝对位置不变）。
            scrollbar_offset = 10,
            scrollbar_height_offset = 20,
            peek_percent = 0,
            allow_bottom_empty_row = true,
        }))
        -- ★ 2026-09-16：原来 y=-108（3 行 120 高会掉到白页底边外），现在 3 行 × 128 = 384 高，
        --   取 y=-20 → 占 -212..+172：上方留给标题(+248)、下方留给底部说明(-262)
        self.dex_list:SetPosition(0, -20)

        local tip2 = root:AddChild(Text(UIFONT, 22))
        tip2:SetString("（图鉴按上架顺序排列；新内容会陆续补进来）")
        tip2:SetColour(0.62, 0.56, 0.46, 0.9)
        tip2:SetPosition(0, -262)
    end

    -- 设置页（行数少，直接排，不做滚动）
    self.pages.set = NewPage()
    self.setting_rows = {}
    self.setting_values = {}
    self.settings_can_edit = false

    local ROW_GAP = 62
    local ROW_Y0 = 134      -- 7 行整体上移：80 → 110 → 134

    local function CurrentSetting(def)
        local bag = self.setting_values[def.scope]
        local v = bag and bag[def.key]
        if v == nil then v = def.default end
        return v
    end

    local function CommitSetting(def, value)
        if def.scope == "world" and self.settings_can_edit == false then
            return   -- 没权限，静默忽略（行本身已淡化）
        end
        SendSetting(def.scope, def.key, value)
    end

    -- 底板：橙灰（和信箱内层同色），把设置项从书页底上"抬"出来
    local set_bg = self.pages.set:AddChild(Image("images/global.xml", "square.tex"))
    set_bg:SetSize(780, 500)
    set_bg:SetPosition(0, -52)
    set_bg:SetTint(0.78, 0.68, 0.56, 0.94)

    for i, def in ipairs(SETTINGS_UI) do
        local row = self.pages.set:AddChild(Widget("set_row"))
        row:SetPosition(0, ROW_Y0 - (i - 1) * ROW_GAP)

        local name = row:AddChild(Text(UIFONT, 30))
        name:SetString(def.label)
        name:SetColour(0.30, 0.24, 0.16, 1)        -- 深墨字（压橙灰底 → 4.9:1；原橙字仅 1.9:1）
        name:SetPosition(-330, 0)
        name:SetHAlign(ANCHOR_LEFT)

        local tag_chip = row:AddChild(Widget("set_tag_chip"))
        tag_chip:SetPosition(-95, 0)
        local tag_bg = tag_chip:AddChild(Image("images/global.xml", "square.tex"))
        tag_bg:SetSize(80, 32)
        tag_bg:SetTint(0.96, 0.91, 0.74, 0.95)     -- 暖黄贴纸底
        FrameLines(tag_chip, 80, 32, 1, 2, 1, 1, 1, 0.9)

        local tag = row:AddChild(Text(UIFONT, 22))
        tag:SetString(def.scope == "world" and "世界" or "个人")
        tag:SetColour(0.30, 0.24, 0.16, 0.95)      -- 深墨字（压暖黄底 → 7.6:1）
        tag:SetPosition(-95, 0)

        local entry = { def = def, row = row, name = name }

        if def.kind == "bool" then
            local b = MakeTextButton(row, 100, 42, "关", function()
                CommitSetting(def, CurrentSetting(def) and 0 or 1)
            end)
            b:SetPosition(240, 0)
            entry.btn = b
        else
            local minus = MakeTextButton(row, 46, 42, "<", function()
                CommitSetting(def, NextSettingValue(def, CurrentSetting(def), -1))
            end)
            minus:SetPosition(160, 0)

            local val = row:AddChild(Text(UIFONT, 30))
            val:SetString(FmtSetting(def, def.default))
            val:SetColour(0.30, 0.24, 0.16, 1)     -- 深墨字（同设置项名，保证可读）
            val:SetPosition(240, 0)

            local plus = MakeTextButton(row, 46, 42, ">", function()
                CommitSetting(def, NextSettingValue(def, CurrentSetting(def), 1))
            end)
            plus:SetPosition(320, 0)

            entry.value_text = val
        end

        table.insert(self.setting_rows, entry)
    end

    -- 三角 + 列表（2026-09-21：整体挪到**左侧**并默认展开，见文件顶部 NAV_LEFT / NAV_ALWAYS_SHOW）
    local NAV_TRI_SCALE = 0.7

    self.nav_triangle = self.content:AddChild(ImageButton("images/global.xml", "square.tex"))
    self.nav_triangle:ForceImageSize(46, 46)
    self.nav_triangle:SetPosition(NAV_LEFT and -536 or 536, NAV_LEFT and 154 or 310)

    self.nav_triangle.scale_on_focus = false          -- 否则 hover 会被 focus_scale 拉回 1
    self.nav_triangle.normal_scale = { NAV_TRI_SCALE, NAV_TRI_SCALE, NAV_TRI_SCALE }
    self.nav_triangle.focus_scale  = { NAV_TRI_SCALE, NAV_TRI_SCALE, NAV_TRI_SCALE }
    -- 2026-09-10：灰黑没质感 → 换蜡黄底 + 白色细框（和列表项凑一套）
    self.nav_triangle:SetImageNormalColour(0.70, 0.62, 0.42, 0.95)
    self.nav_triangle:SetImageFocusColour(0.86, 0.78, 0.56, 1)
    for _, ln in ipairs({
        { 0,   22, 46, 2 },
        { 0,  -22, 46, 2 },
        { -22,  0,  2, 46 },
        { 22,   0,  2, 46 },
    }) do
        local line = self.nav_triangle:AddChild(Image("images/global.xml", "square.tex"))
        line:SetSize(ln[3], ln[4])
        line:SetPosition(ln[1], ln[2])
        line:SetTint(1, 1, 1, 0.9)
    end
    self.nav_tri_label = self.nav_triangle:AddChild(Text(UIFONT, 30))
    self.nav_tri_label:SetString(NAV_ALWAYS_SHOW and "v" or ">")
    self.nav_tri_label:SetColour(0.97, 0.92, 0.70, 1)       -- 淡黄符号

    self.nav_list = self.content:AddChild(Widget("musha_nav_list"))
    self.nav_list:SetPosition(NAV_LEFT and -458 or 458, NAV_LEFT and 107 or 266)
    if NAV_ALWAYS_SHOW then
        self.nav_list:Show()          -- 左竖排常驻：开面板就能直接点页
    else
        self.nav_list:Hide()
    end
    self.nav_items = {}

    -- 导航图标（2026-09-13）：清单在 scripts/musha_nav_icons.lua（唯一真源）
    --   哪张 tex 打包好了清单里就有哪一行；缺 tex 时下面的 pcall 会兜住 → 那行只显示文字
    local NAV_ICON = {}
    local ok_nav, NAVICON = pcall(require, "musha_nav_icons")
    if ok_nav and type(NAVICON) == "table" then
        for _, def in ipairs(NAVICON) do
            NAV_ICON[def.key] = { atlas = "images/" .. def.file .. ".xml", elem = def.file .. ".tex" }
        end
    end

    for i, key in ipairs(self.page_order) do
        -- 2026-09-10：横条缩到 76%（150x52 → 114x40），行距 56 → 43；文字字号不缩
        local b = self.nav_list:AddChild(ImageButton("images/global.xml", "square.tex"))
        b:ForceImageSize(114, 40)
        b:SetPosition(0, -(i - 1) * 43)
        b.scale_on_focus = false
        b.normal_scale = { 1, 1, 1 }
        b.focus_scale  = { 1, 1, 1 }
        b:SetImageNormalColour(0.96, 0.90, 0.62, 0.95)   -- 淡黄底
        b:SetImageFocusColour(1.00, 0.97, 0.80, 1)       -- 悬停变亮 = 物质的反馈

        -- 白框：4 条边线（plate 114x40）
        for _, ln in ipairs({
            { 0,   19, 114, 2 },
            { 0,  -19, 114, 2 },
            { -56,  0,   2, 40 },
            { 56,   0,   2, 40 },
        }) do
            local line = b:AddChild(Image("images/global.xml", "square.tex"))
            line:SetSize(ln[3], ln[4])
            line:SetPosition(ln[1], ln[2])
            line:SetTint(1, 1, 1, 0.95)
        end

        local t = b:AddChild(Text(UIFONT, 28))
        t:SetString(self.page_titles[key])
        t:SetColour(0.32, 0.26, 0.18, 1)          -- 淡黄底上用深色字（字号仍 28pt，不缩）

        -- 导航图标（2026-09-13）：图放左边 28x28，文字整体右移 8 让"图+字"看着居中
        --   缺 tex 时 pcall 兜住：只打一行日志，该行保持纯文字
        if NAV_ICON[key] then
            local ok = pcall(function()
                local ic = b:AddChild(Image(NAV_ICON[key].atlas, NAV_ICON[key].elem))
                ic:ScaleToSize(28, 28)
                ic:SetPosition(-41, 0)
                t:SetPosition(8, 0)
            end)
            if not ok then print("[Musha] 导航图标没加载上（tex 打包了吗？）: " .. tostring(key)) end
        end

        b:SetOnClick(function() self:SetActivePage(key) end)
        table.insert(self.nav_items, { key = key, btn = b, text = t })
    end

    self.nav_triangle:SetOnClick(function()
        if self.nav_list.shown then
            self.nav_list:Hide()
            self.nav_tri_label:SetString(">")
        else
            self.nav_list:Show()
            self.nav_tri_label:SetString("v")
        end
    end)

    -- 监听数据刷新
    self._on_dirty = function() self:Refresh() end
    for _, ev in ipairs(DIRTY_EVENTS) do
        owner:ListenForEvent(ev, self._on_dirty)
    end

    self:Refresh()
    self:SetActivePage("home")
    -- 开面板时向服务端拉一次最新设置
    RequestSettings()
    self.default_focus = self.list
end)

-- ================================================================
-- 数据
-- ================================================================
function MushaPanelScreen:GetUserData()
    local o = self.owner
    if not o or not o:IsValid() then return nil end
    local replica = o.replica and o.replica.musha_profession_component
    local cd = replica and replica.cached_data
    return cd and cd.userdata
end

function MushaPanelScreen:Refresh()
    local md = self:GetUserData()
    if not md then return end

    local has_job = md.carrer_base ~= nil and md.carrer_base ~= ""

    -- 标题 / 等级 / 经验 颜色
    if has_job then
        self.job_text:SetColour(0.8, 0.6, 0.3, 1)
        self.level_text:SetColour(1, 1, 1, 1)
        self.level_badge:SetTint(0.5, 0.42, 0.34, 0.8)
        self.exp_fill:SetTint(0.72, 0.72, 0.72, 0.95)
        self.exp_bg:SetTint(0.3, 0.3, 0.3, 0.6)
    else
        self.job_text:SetColour(0.55, 0.5, 0.42, 0.8)
        self.level_text:SetColour(0.75, 0.75, 0.75, 0.8)
        self.level_badge:SetTint(0.3, 0.3, 0.3, 0.35)
        self.exp_fill:SetTint(0.45, 0.45, 0.45, 0.4)
        self.exp_bg:SetTint(0.35, 0.35, 0.35, 0.4)
    end

    -- ★★ 2026-09-19 修（用户实测：转职后主面板还显示"战士"）：
    --   原来只读 carrer_base → 二转（剑士/近卫…）在面板上完全看不出来。
    --   现在：二转后显示「基础 → 进阶」（例：战士 → 近卫）；没二转只显示基础职业。
    local title = JobName(md.carrer_base)
    if md.carrer_special ~= nil and md.carrer_special ~= "" then
        title = title .. " → " .. JobName(md.carrer_special)
    end
    self.job_text:SetString(title)

    local lv = md.level or 0
    local exp = md.exp or 0
    -- 注意：md.exp_to_next 是"还差多少升级"（服务端 exp_table[level+1] - exp），
    -- 不是"本级总需求"。下一级阈值 = exp + exp_to_next。
    -- 以前直接拿 exp_to_next 当分母，于是显示出 "40/5" 这种怪数字。
    local exp_next = exp + (md.exp_to_next or 0)
    self.level_text:SetString("Lv." .. lv)
    self.exp_text:SetString("职业经验 " .. exp .. "/" .. exp_next)
    local pct = exp_next > 0 and math.min(exp / exp_next, 1) or 0
    self.exp_fill:SetSize(930 * pct, 22)
    self.exp_fill:SetPosition(-468 + 465 * pct, 150)
    if has_job and pct <= 0.001 then
        self.exp_bg:SetTint(0.3, 0.3, 0.3, 0.35)
        self.exp_fill:SetTint(0.72, 0.72, 0.72, 0.35)
        self.exp_text:SetColour(0.55, 0.55, 0.55, 0.6)
    end

    -- 组装任务列表
    local items = {}
    for _, q in ipairs(md.daily_quests or {}) do
        table.insert(items, {
            n = q.n or QuestName(q.id),
            p = q.p or 0, t = q.t or 1, done = q.done, adv = false,
        })
    end
    if md.advance_quest then
        local a = md.advance_quest
        table.insert(items, {
            n = "【转职" .. (md.advance_round or 1) .. "/3】" .. (a.n or QuestName(a.id)),
            p = a.p or 0, t = a.t or 1, done = a.done, adv = true,
        })
    end
    self.list:SetItemsData(items)

    -- 设置页同步（同一份 userdata 里带着 settings 快照）
    self:RefreshSettings(md)
    self:RefreshGift(md)      -- 礼包页（2026-09-12）
    self:RefreshEquip(md)     -- 装备 · 属性页（2026-09-13）

    -- 技能页同步（同一份 userdata 里带着 skills 快照，2026-09-12）
    self:RefreshSkills(md)

    -- 空状态
    if #items > 0 then
        self.quest_empty:Hide()
        self.quest_hint:Hide()
    else
        self.quest_empty:Show()
        self.quest_hint:Show()
        if has_job then
            self.quest_empty:SetString("暂无任务")
            self.quest_hint:SetString("每日任务明日自动发放 · 转职任务去祭坛接取")
        else
            self.quest_empty:SetString("暂无职业")
            self.quest_hint:SetString("使用职业书开启职业之路")
        end
    end
end

-- ================================================================
-- 设置页：把服务端推来的 settings 快照刷到 UI
-- （settings 跟着 userdata 一起来，见 musha_profession_component:PushSettings）
-- ================================================================
function MushaPanelScreen:RefreshSettings(md)
    local st = md and md.settings
    self.setting_values = {
        world  = (st and st.world) or {},
        player = (st and st.player) or {},
    }
    self.settings_can_edit = (st and st.can_edit) == true

    for _, entry in ipairs(self.setting_rows or {}) do
        local def = entry.def
        local bag = self.setting_values[def.scope]
        local v = bag[def.key]
        if v == nil then v = def.default end
        entry.value = v

        if def.kind == "bool" then
            if entry.btn and entry.btn._label then
                entry.btn._label:SetString(v and "开" or "关")
            end
        elseif entry.value_text then
            entry.value_text:SetString(FmtSetting(def, v))
        end

        -- 没权限改世界设置 → 行名淡化
        local locked = (def.scope == "world") and (not self.settings_can_edit)
        if entry.name then
            if locked then
                entry.name:SetColour(0.55, 0.50, 0.44, 0.6)
            else
                entry.name:SetColour(0.30, 0.24, 0.16, 1)
            end
        end
    end
end

-- ================================================================
-- 技能页：把服务端推来的 skills 快照刷成一行行技能（2026-09-12）
--   数据来源：pc:GetSkillView()（服务端组装）→ PushSettings → DoUpdata → md.skills
--   行 = 名字 / 等级·需求·消耗 / 当前效果 / 下一级效果 / 加点按钮（粉框白加号）
--   加分请求走 RPC musha_skill_upgrade → 服务端 UpgradeSkill → 再推一次
-- ================================================================

-- ================================================================
-- 技能行尺寸 + 左对齐文本（要挪位置改这里一处，整页跟着变）
-- ⚠️ DST 的 Text 一旦设了 region，**SetPosition 指的是"区域中心"，不是文字左缘**！
--    原版 morguescreen 的列头、consolescreen 的遥控标签都是 position ± region_w/2 这么算的，
--    HAlign 只负责把文字摆在区域内 → 要让文字左缘落在 left_x，必须 SetPosition(left_x + w/2)
--    （踩过的坑：按"文字左缘 = position"写 → 文字被算到卡片左外侧 210px 去了）
-- ================================================================
-- 技能行尺寸常量已上移到文件顶部（2026-09-13，ScrollingGrid 的 item_ctor 要用）

-- 技能页两个子页的标题项配色（选中 / 未选中）
local SKILL_TAB_ON  = { text = { 0.24, 0.19, 0.13 }, bg = { 1.00, 1.00, 0.99, 0.98 }, focus = { 1.00, 1.00, 1.00, 1.00 } }
local SKILL_TAB_OFF = { text = { 0.52, 0.46, 0.38 }, bg = { 0.92, 0.90, 0.85, 0.55 }, focus = { 0.96, 0.94, 0.90, 0.80 } }

local function SkillText(row, size, y, str, r, g, b)
    local t = row:AddChild(Text(UIFONT, size))
    t:SetString(str or "")
    t:SetColour(r or 0.30, g or 0.24, b or 0.16, 1)
    t:SetRegionSize(SKILL_TXT_W, size + 14)
    t:SetHAlign(ANCHOR_LEFT)
    t:SetPosition(SKILL_TXT_X + SKILL_TXT_W / 2, y)
    return t
end

-- 切换技能页的两个子页：未学习 / 已学习（2026-09-12）
function MushaPanelScreen:SetSkillTab(key)
    key = (key == "learned") and "learned" or "unlearned"
    if self.skill_tab == key then return end
    self.skill_tab = key
    self:RefreshSkills(nil)      -- 用上一次的数据重排（不改数据，只换筛选）
end

-- 刷新两个标题项的外观（选中：白底 + 深墨字 + 橙下划线）
function MushaPanelScreen:RefreshSkillTabs()
    local cur = self.skill_tab or "unlearned"
    for key, e in pairs(self.skill_tabs or {}) do
        local on = (key == cur)
        local c = on and SKILL_TAB_ON or SKILL_TAB_OFF
        if e.underline then
            if on then e.underline:Show() else e.underline:Hide() end
        end
        if e.text then
            e.text:SetColour(c.text[1], c.text[2], c.text[3], 1)
        end
        if e.btn then
            e.btn:SetImageNormalColour(c.bg[1], c.bg[2], c.bg[3], c.bg[4])
            e.btn:SetImageFocusColour(c.focus[1], c.focus[2], c.focus[3], c.focus[4])
        end
    end
end

function MushaPanelScreen:RefreshSkills(md)
    if not self.skill_grid then return end

    -- md 只在数据刷新时传进来；切子页时传 nil → 复用上一次的数据
    if md then self.skill_md = md end
    -- ★ 2026-09-21 兜底（用户报"切回去全部不显示"）：如果一次数据都还没收到（skill_md 为 nil），
    --   切版式/切子页就会拿 nil 重画 → 树空、列表空、连空状态字样都不出现 = 整页空白。
    --   这里现取一次 userdata（跟 Refresh() 用的是同一个源）。
    if self.skill_md == nil then
        local ok, d = pcall(function() return self:GetUserData() end)
        self.skill_md = ok and d or nil
    end
    local data = self.skill_md

    -- 重建：现在由 ScrollingGrid 管（SetItemsData 会重排/复用 item，不用手动 KillAllChildren）
    self:RefreshSkillTabs()

    -- ★ 2026-09-20 横排技能树：喂**全量**技能（树本来就是整棵，不分「未学习/已学习」子页）
    --   放在这里（下面的空列表提前 return 之前），否则子页空的时候树会被漏刷
    if self.skill_tree then
        local full = {}
        for _, s in ipairs((data and data.skills) or {}) do
            table.insert(full, s)
        end
        self.skill_tree:RefreshKeepSelection(full)
    end

    local job  = data and data.carrer_base
    local spec = data and data.carrer_special
    local lv   = (data and data.level) or 0
    local sp   = (data and data.skill_points) or 0

    if self.skill_head then
        if job then
            -- ★ 2026-09-12：二转后标题写成「战士 → 剑士 · 等级 N · 可用技能点 M」
            local title = JobName(job)
            if spec and spec ~= "" then
                title = title .. " → " .. JobName(spec)
            end
            self.skill_head:SetString(string.format("%s · 等级 %d · 可用技能点 %d", title, lv, sp))
        else
            self.skill_head:SetString("技能")
        end
    end

    -- 按子页筛选：未学习 = 等级 0；已学习 = 等级 ≥ 1
    local tab = self.skill_tab or "unlearned"
    local list = {}
    for _, s in ipairs((data and data.skills) or {}) do
        local cur = s.cur or 0
        if (tab == "learned" and cur > 0) or (tab == "unlearned" and cur == 0) then
            table.insert(list, s)
        end
    end

    if #list == 0 then
        if self.skill_empty then
            if not job then
                self.skill_empty:SetString("还没有职业")
            elseif tab == "learned" then
                self.skill_empty:SetString("还没有学习任何技能")
            else
                self.skill_empty:SetString("该职业的技能已全部学习")
            end
            self.skill_empty:Show()
        end
        self.skill_grid:SetItemsData({})
        return
    end
    if self.skill_empty then self.skill_empty:Hide() end

    -- 交给滚动网格渲染（行内容在 SKILL_apply_fn 里填；网格自己管滚动条/滚轮）
    self.skill_grid:SetItemsData(list)
end

-- ================================================================
-- ★ 2026-09-20 技能页两套版式：tree = 横排技能树（默认） / list = 旧版竖排列表
--   用户口径：新版先上，旧版留一个一键切回的退路（法师版验证过再拆掉旧版＋这两颗按钮）
-- ================================================================
function MushaPanelScreen:SetSkillMode(mode)
    -- ★★ 2026-09-21 用户拍板：「直接横排 不要竖排了」→ 传什么进来都强制 tree
    --   （竖排列表的代码/控件先留着当退路，但入口没了、永远隐藏）
    mode = "tree"
    self.skill_mode = mode
    local tree_mode = (mode == "tree")

    if self.skill_tree then
        if tree_mode then self.skill_tree:Show() else self.skill_tree:Hide() end
    end
    if self.skill_detail then self.skill_detail:Hide() end      -- 详情每次切换都收起，点节点才出
    if self.skill_grid then
        if tree_mode then self.skill_grid:Hide() else self.skill_grid:Show() end
    end
    -- ★ 2026-09-21 修：原来只写了 Hide 分支 → 切回竖排后这两行再也显不回来
    if self.skill_empty then
        if tree_mode then self.skill_empty:Hide() else self.skill_empty:Show() end
    end
    if self.skill_foot then
        if tree_mode then self.skill_foot:Hide() else self.skill_foot:Show() end
    end

    for _, key in ipairs({ "unlearned", "learned" }) do
        local tb = self.skill_tabs and self.skill_tabs[key]
        if tb and tb.btn then
            if tree_mode then tb.btn:Hide() else tb.btn:Show() end
        end
    end

    for key, e in pairs(self.skill_mode_btns or {}) do
        local on = (key == mode)
        e.text:SetColour(on and 0.86 or 0.44, on and 0.30 or 0.41, on and 0.08 or 0.33, 1)
        e.btn:SetImageNormalColour(on and 1.00 or 0.94, on and 0.96 or 0.92, on and 0.90 or 0.88, 1)
    end

    self:RefreshSkills(nil)        -- 用最近一次 md 重画（树 + 旧列表一起刷）
end

-- ================================================================
-- ★ 2026-09-20 右栏「技能详情」：点树上的节点才填内容 + 显示
--   e = nil 时收起（取消选中）
-- ================================================================
function MushaPanelScreen:ShowSkillDetail(e)
    if not self.skill_detail then return end
    self.skill_sel = e
    if not e then
        self.skill_detail:Hide()
        return
    end
    self.skill_detail:Show()

    -- 中文按字数折行（DST 的 Text 不会自动换行，手动插 \n；UTF-8 逐字取）
    local function Wrap(str, n)
        str = tostring(str or "")
        local out, line, cnt = {}, "", 0
        for ch in string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
            if ch == "\n" then
                table.insert(out, line); line, cnt = "", 0
            else
                line = line .. ch
                cnt = cnt + 1
                if cnt >= n then
                    table.insert(out, line); line, cnt = "", 0
                end
            end
        end
        if line ~= "" then table.insert(out, line) end
        return table.concat(out, "\n")
    end

    self.skill_detail_title:SetString(Wrap(e.name or e.key or "?", 6))

    local L = self.skill_detail_lines
    -- ★ 2026-09-21 用户两条口径：技能页**不显示职业名**（"战士/剑士"这种字都不要）
    --   → 详情框等级行、竖排行首的 [战士] 标签，全部去掉，只留等级数字
    L[1]:SetString(string.format("等级 %d / %d", e.cur or 0, e.max or 0))

    if (e.cur or 0) > 0 then
        L[2]:SetString(Wrap("当前：" .. ((e.effect or "") ~= "" and e.effect or "—"), 12))
    else
        L[2]:SetString(Wrap("当前：未学习", 12))
    end

    if e.maxed then
        L[3]:SetString("已满级")
    else
        L[3]:SetString(Wrap("下一级：" .. ((e.nextfx or "") ~= "" and e.nextfx or "—"), 12))
    end

    -- 条件（角色等级 / 技能点 / 技能书 / 前置）
    local need = {}
    if (e.req or 0) > 0 then table.insert(need, string.format("角色等级 %d", e.req)) end
    if (e.book_lock or 0) > 0 then
        table.insert(need, string.format("%d 本技能书", e.book_lock))
    elseif not e.maxed then
        table.insert(need, string.format("%d 技能点", e.cost or 1))
    end
    if e.pre and #e.pre > 0 then
        local ps = {}
        for _, p in ipairs(e.pre) do
            table.insert(ps, string.format("%s %d/%d", p.name, p.cur or 0, p.need or 1))
        end
        table.insert(need, "前置：" .. table.concat(ps, "、"))
    end
    L[4]:SetString(Wrap("条件：" .. table.concat(need, " · "), 12))
    L[5]:SetString(Wrap((e.tip or "") ~= "" and e.tip or "", 13))

    -- 按钮：满级直接隐藏（用户口径：满级不留按钮）；不可用的灰掉 + 不可点
    local unlock = ((e.book_lock or 0) > 0)
    local usable = unlock or (e.can == true and not e.maxed)
    if e.maxed then
        self.skill_detail_btn:Hide()
    else
        self.skill_detail_btn:Show()
        if self.skill_detail_btn._label then
            self.skill_detail_btn._label:SetString(unlock and "用技能书解锁" or "加点")
        end
        if usable then
            self.skill_detail_btn:SetImageNormalColour(0.62, 0.34, 0.14, 1)
            self.skill_detail_btn:SetImageFocusColour(0.72, 0.42, 0.18, 1)
        else
            self.skill_detail_btn:SetImageNormalColour(0.72, 0.69, 0.65, 1)
            self.skill_detail_btn:SetImageFocusColour(0.72, 0.69, 0.65, 1)
        end
        self.skill_detail_btn:SetClickable(usable)
    end
end

-- ================================================================
-- ================================================================
-- 装备 · 属性页（2026-09-13，照 Show Me 的读法移植到我们自己的面板格式）
--   数值来源（**全是客户端能读到的**，服务端组件在这个 Screen 里是 nil）：
--     · 装备格 → p.replica.inventory:GetEquippedItem("head"/"body"/"hands")
--       （⚠️ `components.inventory:GetEquippedItem` 是服务端的；客户端走 replica）
--     · 图标   → item.replica.inventoryitem:GetAtlas() / :GetImage()
--     · 生命/饥饿/理智 → p.player_classified.currenthealth / maxhealth 等同名 netvar
--     · 能量 MP → p.Musha_MP / p.Musha_MP_MAX（本 mod 的 net_float，prefabs/musha.lua:75）
--     · 职业/等级/经验/技能点 → 面板自己的 md（服务端 PushSettings 推来）
--     · 装备数值 → musha_item_stats 静态表
--       （⚠️ item.components.armor / .weapon / .insulator 客户端**全是 nil**：
--          armor 这些组件写在 prefab 的 master_postinit 里，客户端只跑 common_postinit，
--          所以只能读那张静态表 —— Show Me 能显示减伤靠的就是同一套路）
-- ================================================================
-- 注意：这一堆放一个 table 里，避免在文件顶层再加 chunk 局部变量
--   （这个文件已经很长的顶层 locals 列表了，逼近 Lua 200 个上限）
local EQ = {}

EQ.DEBUG = true     -- 装备页诊断打印（验完改回 false）

EQ.SLOT_ORDER = { "head", "body", "hands" }

function EQ.Num(v)
    if type(v) ~= "number" then return nil end
    return string.format("%d", math.floor(v + 0.5))
end

function EQ.Pct(v)
    if type(v) ~= "number" then return nil end
    return string.format("%d%%", math.floor(v * 100 + 0.5))
end

function EQ.ItemStat(prefab, field)
    if prefab == nil or MushaItemStat == nil then return nil end
    local ok, v = pcall(MushaItemStat, prefab, field)
    if ok and type(v) == "number" then return v end
    return nil
end

function EQ.NetVar(p, name)
    if p == nil then return nil end
    local ok, v = pcall(function()
        local nv = p.player_classified and p.player_classified[name]
        return nv and nv:value() or nil
    end)
    if ok and type(v) == "number" then return v end
    return nil
end

function MushaPanelScreen:RefreshEquip(md)
    if not self.eq_rows then return end
    md = md or self:GetUserData()

    local p = self.owner
    if not p or not p:IsValid() then return end

    local inv = p.replica and p.replica.inventory
    -- 装备读取：三条路依次试（客户端拿装备只有这几条路，任何一条 nil 都要能兜住）
    --   ① replica.inventory:GetEquippedItem(slot)   ← 标准路径
    --   ② player_classified:GetEquips()[slot]        ← 底层装备表
    --   ③ replica.inventory:GetEquips()[slot]        ← 同上的封装
    local function GetEquip(slot)
        if inv and inv.GetEquippedItem then
            local ok, item = pcall(function() return inv:GetEquippedItem(slot) end)
            if ok and item and item.IsValid and item:IsValid() then return item end
        end
        local ok2, item2 = pcall(function()
            local cl = p.player_classified
            local e = cl and cl.GetEquips and cl:GetEquips() or nil
            return e and e[slot] or nil
        end)
        if ok2 and item2 and item2.IsValid and item2:IsValid() then return item2 end
        local ok3, item3 = pcall(function()
            local e = inv and inv.GetEquips and inv:GetEquips() or nil
            return e and e[slot] or nil
        end)
        if ok3 and item3 and item3.IsValid and item3:IsValid() then return item3 end
        return nil
    end

    -- 诊断（验完把 EQ.DEBUG 改回 false）：一行说清「刷新跑了没 / 数值表在不在 / 三个格子读到什么」
    if EQ.DEBUG then
        local names = {}
        for _, key in ipairs(EQ.SLOT_ORDER) do
            local it = GetEquip(key)
            names[#names + 1] = key .. "=" .. tostring(it and it.prefab)
        end
        print("[Musha Equip] md=" .. tostring(md ~= nil)
            .. " 数值表=" .. tostring(MushaItemStat ~= nil)
            .. " 装备 " .. table.concat(names, " "))
    end

    -- ---------- 左列：装备格 ----------
    local absorb_left, speed_mult = 1, 1
    local warm_sum, cool_sum = 0, 0
    local hand_dmg = nil

    for _, key in ipairs(EQ.SLOT_ORDER) do
        local meta = self.eq_slots[key]
        local item = GetEquip(key)
        if meta then
            if item then
                local pf = item.prefab
                -- 名字：GetDisplayName 走 pcall（某些实体没这个方法 → 原来会整页炸掉）
                local disp = pf or "?"
                pcall(function()
                    if item.GetDisplayName then
                        local s = item:GetDisplayName()
                        if s and s ~= "" then disp = s end
                    end
                end)
                meta.name:SetString(disp)

                local atlas, image = nil, nil
                pcall(function()
                    local ri = item.replica and item.replica.inventoryitem
                    if ri and ri.GetAtlas then atlas = ri:GetAtlas() end
                    if ri and ri.GetImage then image = ri:GetImage() end
                end)
                if atlas and image then
                    meta.icon:SetTexture(atlas, image)
                    meta.icon:SetTint(1, 1, 1, 1)
                else
                    meta.icon:SetTint(1, 1, 1, 0)
                end

                local absorb = EQ.ItemStat(pf, "absorb")
                local warm   = EQ.ItemStat(pf, "warm") or 0
                local cool   = EQ.ItemStat(pf, "cool") or 0
                local dmg    = EQ.ItemStat(pf, "dmg")
                local planar = EQ.ItemStat(pf, "planar")
                local speed  = EQ.ItemStat(pf, "speed")

                local txt = {}
                if key == "hands" then
                    if dmg then
                        hand_dmg = dmg
                        table.insert(txt, "伤害 " .. EQ.Num(dmg))
                    end
                    if planar then table.insert(txt, "位面 " .. EQ.Num(planar)) end
                    if #txt == 0 then table.insert(txt, "武器") end
                else
                    if absorb then table.insert(txt, "减伤 " .. EQ.Pct(absorb)) end
                    if warm ~= 0 then table.insert(txt, "保暖 " .. EQ.Num(warm)) end
                    if cool ~= 0 then table.insert(txt, "隔热 " .. EQ.Num(cool)) end
                    if #txt == 0 then table.insert(txt, "护甲") end
                end
                if speed and speed ~= 1 then
                    table.insert(txt, "移速 " .. EQ.Pct(speed - 1))
                end
                meta.stat:SetString(table.concat(txt, " · "))

                if absorb then absorb_left = absorb_left * (1 - absorb) end
                if speed then speed_mult = speed_mult * speed end
                warm_sum = warm_sum + warm
                cool_sum = cool_sum + cool
            else
                meta.name:SetString("—")
                meta.stat:SetString("")
                meta.icon:SetTint(1, 1, 1, 0)
            end
        end
    end

    -- ---------- 右列：12 行属性 ----------
    local function Row(i, label, value)
        local r = self.eq_rows[i]
        if r == nil then return end
        if r.label:GetString() ~= label then r.label:SetString(label) end
        if r.value:GetString() ~= value then r.value:SetString(value) end
    end

    local function CurMax(cur, mx)
        if cur == nil and mx == nil then return "-" end
        return (EQ.Num(cur) or "?") .. " / " .. (EQ.Num(mx) or "?")
    end

    Row(1, "生命", CurMax(EQ.NetVar(p, "currenthealth"), EQ.NetVar(p, "maxhealth")))
    Row(2, "饥饿", CurMax(EQ.NetVar(p, "currenthunger"), EQ.NetVar(p, "maxhunger")))
    Row(3, "理智", CurMax(EQ.NetVar(p, "currentsanity"), EQ.NetVar(p, "maxsanity")))

    local mp_cur, mp_max = 0, 0
    pcall(function()
        if p.Musha_MP then mp_cur = p.Musha_MP:value() or 0 end
        if p.Musha_MP_MAX then mp_max = p.Musha_MP_MAX:value() or 0 end
    end)
    Row(4, "能量", (EQ.Num(mp_cur) or "0") .. " / " .. (EQ.Num(mp_max) or "0"))

    -- 攻击力：V1 = 手持武器的静态伤害值
    --   （人物基础伤害/职业加成是服务端算的，客户端拿不到 → 想显示最终伤害要 RPC，排 V3）
    Row(5, "攻击力", EQ.Num(hand_dmg) or "0")

    Row(6, "减伤", EQ.Pct(1 - absorb_left) or "0%")
    local sp = speed_mult - 1
    Row(7, "移速", (sp >= 0 and "+" or "") .. (EQ.Pct(sp) or "0%"))
    Row(8, "保暖", EQ.Num(warm_sum) or "0")
    Row(9, "隔热", EQ.Num(cool_sum) or "0")

    local job = JobName(md and md.carrer_base)
    if md and md.carrer_special then
        job = job .. " → " .. JobName(md.carrer_special)
    end
    Row(10, "职业", job)

    local lv  = (md and md.level) or 0
    local exp = (md and md.exp) or 0
    local exp_next = exp + ((md and md.exp_to_next) or 0)
    Row(11, "等级 · 经验", "Lv." .. lv .. " · " .. exp .. "/" .. exp_next)
    Row(12, "技能点", EQ.Num((md and md.skill_points) or 0) or "0")
end

-- 礼包页：按 md.gifts（服务端推来的"已领过"表）重建行
--   2026-09-12 新增；2026-09-14 改双轨：
--     · 游戏时间礼包（kind="cycle"）→ **常显**；没到天数 → 按钮位显示"第 X 天可领（还差 N 天）"，点不了
--     · 节日礼包（kind="festival"）→ 只在现实日期窗口内**出现**，窗口外连行都没有
--   口径跟服务端 RPC 一致：天数 = TheWorld.state.cycles；日期 = 本机时间 YYYY-MM-DD
-- ================================================================
local GIFT_ROW_W   = 780
local GIFT_ROW_H   = 76
local GIFT_ROW_GAP = 18

-- 今天（本机时间）"YYYY-MM-DD" —— 字符串大小比较 == 时间先后（跨年也对）
local function TodayStr()
    local ok, s = pcall(os.date, "%Y-%m-%d")
    return (ok and type(s) == "string") and s or nil
end

-- 这行现在该不该出现在礼包页
local function GiftVisible(g)
    if g.enabled == false then return false end
    if g.kind == "festival" then
        local today = TodayStr()
        if today ~= nil then
            if g.from ~= nil and today < g.from then return false end
            if g.to   ~= nil and today > g.to   then return false end
        end
    end
    return true
end

-- 游戏内天数（客户端直接读 world state 的同步值；拿不到当 0）
local function CurrentCycles()
    local st = TheWorld ~= nil and TheWorld.state or nil
    return (st and st.cycles) or 0
end

-- 没到天数 → 返回锁态文字；能领 → nil
local function GiftLockText(g)
    if g.kind == "cycle" then
        local need = g.day or 0
        local cy = CurrentCycles()
        if cy < need then
            return string.format("第 %d 天可领（还差 %d 天）", need, need - cy)
        end
    end
    return nil
end

function MushaPanelScreen:RefreshGift(md)
    if not self.gift_body then return end
    self.gift_body:KillAllChildren()

    local claimed = (md and md.gifts) or {}
    local rows, has_cycle = {}, false
    for _, g in ipairs(MUSHA_GIFTS or {}) do
        if GiftVisible(g) then
            table.insert(rows, g)
            if g.kind == "cycle" then has_cycle = true end
        end
    end

    if self.gift_hint then
        if #rows == 0 then
            self.gift_hint:SetString("当前没有可领取的礼包 · 节日活动期间会出现在这里")
        elseif has_cycle then
            self.gift_hint:SetString("按游戏内天数开放 · 每个只能领一次")
        else
            self.gift_hint:SetString("活动礼包 · 每个只能领一次")
        end
    end
    if #rows == 0 then return end

    local total = #rows * GIFT_ROW_H + (#rows - 1) * GIFT_ROW_GAP
    local y = total / 2 - GIFT_ROW_H / 2

    for _, g in ipairs(rows) do
        local row = self.gift_body:AddChild(Widget("gift_row"))
        row:SetPosition(0, y)
        y = y - (GIFT_ROW_H + GIFT_ROW_GAP)

        local card = row:AddChild(Image("images/global.xml", "square.tex"))
        card:SetSize(GIFT_ROW_W, GIFT_ROW_H)
        card:SetTint(1.000, 0.995, 0.985, 0.95)
        FrameLines(row, GIFT_ROW_W, GIFT_ROW_H, 0, 2, 0.80, 0.78, 0.73, 0.90)

        -- 名字（左对齐：SetRegionSize + ANCHOR_LEFT，位置 = 区域中心）
        local TXT_W = GIFT_ROW_W - 320
        local nm = row:AddChild(Text(UIFONT, 26))
        nm:SetString(g.name or g.id or "礼包")
        nm:SetColour(0.22, 0.17, 0.11, 1)
        nm:SetRegionSize(TXT_W, 30)
        nm:SetHAlign(ANCHOR_LEFT)
        nm:SetPosition(-GIFT_ROW_W / 2 + 30 + TXT_W / 2, 12)

        -- 说明（左对齐、灰）
        local ds = row:AddChild(Text(UIFONT, 18))
        ds:SetString(g.desc or "")
        ds:SetColour(0.46, 0.40, 0.32, 1)
        ds:SetRegionSize(TXT_W, 24)
        ds:SetHAlign(ANCHOR_LEFT)
        ds:SetPosition(-GIFT_ROW_W / 2 + 30 + TXT_W / 2, -18)

        -- 状态 / 领取按钮（2026-09-14：多一档「没到时间」的锁态）
        if claimed[g.id] ~= nil then
            local done = row:AddChild(Text(UIFONT, 22))
            done:SetString("已领取")
            done:SetColour(0.52, 0.46, 0.38, 1)
            done:SetPosition(GIFT_ROW_W / 2 - 80, 0)
        else
            local lock = GiftLockText(g)
            if lock ~= nil then
                -- 游戏时间礼包：没到天数 → 灰字，点不了
                local lk = row:AddChild(Text(UIFONT, 20))
                lk:SetString(lock)
                lk:SetColour(0.58, 0.52, 0.44, 1)
                lk:SetRegionSize(220, 26)
                lk:SetHAlign(ANCHOR_MIDDLE)
                lk:SetPosition(GIFT_ROW_W / 2 - 120, 0)
            else
                local b = MakeGiftButton(row, 120, 44, "领取", function()
                    SendClaimGift(g.id)
                end)
                b:SetPosition(GIFT_ROW_W / 2 - 80, 0)
            end
        end
    end
end

-- ================================================================
-- 切页：只 Show/Hide，不重建 Screen
-- ================================================================
function MushaPanelScreen:SetActivePage(name)
    if not self.pages then return end
    if self.pages[name] == nil then name = "home" end

    for key, group in pairs(self.pages) do
        local show = (key == name)
        -- ⚠️ 主页是"一组 widget 的数组表"，其它页是"单个容器 Widget"。
        -- 之前一律 ipairs(group) → 对 Widget 一个都遍历不到 → 那些页永远 Show 不出来。
        -- 用 group.Show 是否存在来区分两种情况。
        if type(group) == "table" and group.Show == nil then
            for _, w in ipairs(group) do
                if w and w.Show and w.Hide then
                    if show then w:Show() else w:Hide() end
                end
            end
        elseif group and group.Show and group.Hide then
            if show then group:Show() else group:Hide() end
        end
    end
    self.active_page = name

    -- 导航项高亮（淡黄底 + 深色字，当前页用深橙）
    for _, it in ipairs(self.nav_items or {}) do
        if it.key == name then
            it.text:SetColour(0.85, 0.30, 0.08, 1)   -- 当前页
        else
            it.text:SetColour(0.32, 0.26, 0.18, 1)   -- 其余
        end
    end

    -- 选完自动收起（★ 左竖排常驻时**不**收：见文件顶部 NAV_ALWAYS_SHOW）
    if not NAV_ALWAYS_SHOW then
        if self.nav_list then
            self.nav_list:Hide()
        end
        if self.nav_tri_label then
            self.nav_tri_label:SetString(">")
        end
    end

    if name == "home" then
        self.default_focus = self.list
        -- 空状态字样由 Refresh 管可见性；切回来时补刷一次，免得被 Show 出来
        self:Refresh()
    elseif name == "skill" then
        -- ★ 2026-09-20 技能树页：默认横排（导航上一步已经自动收起，树可以往右伸展）
        self:SetSkillMode(self.skill_mode or "tree")
        if self.skill_mode == "tree" and self.skill_tree then
            self.default_focus = self.skill_tree
            self.skill_tree:SetFocus()
        else
            self.default_focus = self.skill_grid or self.nav_triangle
        end
    elseif name == "mail" then
        self.default_focus = self.nav_triangle
        self:RefreshMail()
    elseif name == "gift" then
        self.default_focus = self.nav_triangle
        self:RefreshGift(self:GetUserData())
    elseif name == "equip" then
        self.default_focus = self.nav_triangle
        self:RefreshEquip(self:GetUserData())    -- 装备 · 属性页（2026-09-13 从"图鉴"改名拆出）
    elseif name == "dex" then
        self.default_focus = self.dex_list or self.nav_triangle
        self:RefreshDex()                        -- 图鉴页（2026-09-16 起有内容，源 = scripts/musha_dex.lua）
    else
        self.default_focus = self.nav_triangle
    end
end

-- ================================================================
-- 图鉴页：内容源 = scripts/musha_dex.lua（静态表；以后要按收集进度动态显示，在这里改）
-- ================================================================
function MushaPanelScreen:RefreshDex()
    if self.dex_list and MUSHA_DEX then
        self.dex_list:SetItemsData(MUSHA_DEX)
    end
end

-- ================================================================
-- 信箱页：翻页 + 重绘（内容来自本文件顶部 MUSHA_CHANGELOG）
-- ================================================================
function MushaPanelScreen:RefreshMail()
    if not self.mail_content then return end

    local total = #MUSHA_CHANGELOG
    local maxpage = math.max(1, math.ceil(total / MAIL_PER_PAGE))
    if (self.mail_page or 1) > maxpage then self.mail_page = maxpage end
    if (self.mail_page or 1) < 1 then self.mail_page = 1 end

    -- 页码：点数字直接跳页（原来的 "1/1" 文字已去掉）
    if self.mail_pagenums then
        self.mail_pagenums:KillAllChildren()
        local bw, gap = 28, 8
        local totalw = maxpage * bw + (maxpage - 1) * gap
        local x0 = -totalw / 2 + bw / 2
        for p = 1, maxpage do
            local b = StyleLikeTriangle(
                MakeTextButton(self.mail_pagenums, bw, 22, tostring(p), function() self:MailGoto(p) end), bw, 22)
            if b._label then
                b._label:SetSize(16)
            end
            b:SetPosition(x0 + (p - 1) * (bw + gap), 0)
            if p == self.mail_page and b._label then
                b._label:SetColour(0.85, 0.30, 0.08, 1)   -- 当前页
            end
        end
    end

    -- 正文
    self.mail_content:KillAllChildren()

    -- 左对齐：DST 的 Text 必须配 SetRegionSize 才能左对齐（光 SetHAlign 是无效的，
    -- 会变成"整行绕着自己的中心点摆" → 看着就是居中）。
    -- 左边缘 = x - regionW/2，所以想要左边距就得把 x 往右挪 regionW/2。
    local REGION_W = 800
    local TX = -2                     -- → 文字左边缘 = -402（框内半宽 432，留 30 边距）

    local startidx = (self.mail_page - 1) * MAIL_PER_PAGE + 1
    local y = 175
    for i = startidx, math.min(startidx + MAIL_PER_PAGE - 1, total) do
        local e = MUSHA_CHANGELOG[i]
        if e then
            -- 2026-09-12 C 方案：标题行 = 暖黄贴纸块 + 深墨字
            -- 原橙字 #D16B1F 压橙灰底 #C7AD8F 只有 1.68:1（全 UI 最差的一处），发闷看不清
            local head_chip = self.mail_content:AddChild(Widget("mail_head_chip"))
            head_chip:SetPosition(TX - REGION_W / 2 + 150, y)   -- 左边缘对齐文字起点（chip 宽 300）
            local head_bg = head_chip:AddChild(Image("images/global.xml", "square.tex"))
            head_bg:SetSize(300, 38)
            head_bg:SetTint(0.96, 0.91, 0.74, 0.95)             -- 暖黄贴纸底
            FrameLines(head_chip, 300, 38, 1, 2, 1, 1, 1, 0.9)

            local head = self.mail_content:AddChild(Text(UIFONT, 28))
            head:SetString("v" .. tostring(e.ver or "?") .. "    " .. tostring(e.date or ""))
            head:SetColour(0.30, 0.24, 0.16, 0.95)             -- 深墨字（压暖黄底 → 7.6:1）
            head:SetRegionSize(REGION_W, 40)
            head:SetHAlign(ANCHOR_LEFT)
            head:SetPosition(TX, y)
            y = y - 36

            for _, line in ipairs(e.lines or {}) do
                local t = self.mail_content:AddChild(Text(UIFONT, 22))
                t:SetString("· " .. tostring(line))
                t:SetColour(0.30, 0.24, 0.17, 1)
                t:SetRegionSize(REGION_W, 28)
                t:SetHAlign(ANCHOR_LEFT)
                t:SetPosition(TX, y)
                y = y - 28
            end
            y = y - 14
        end
    end
end

-- 跳到第 p 页
function MushaPanelScreen:MailGoto(p)
    local total = #MUSHA_CHANGELOG
    local maxpage = math.max(1, math.ceil(total / MAIL_PER_PAGE))
    self.mail_page = math.max(1, math.min(maxpage, p or 1))
    self:RefreshMail()
end

-- 左右翻页
function MushaPanelScreen:MailTurn(dir)
    self:MailGoto((self.mail_page or 1) + (dir or 1))
end

-- ================================================================
-- 控制 / 清理
-- ================================================================
function MushaPanelScreen:OnControl(control, down)
    if MushaPanelScreen._base.OnControl(self, control, down) then
        return true
    end
    if not down then return false end
    if control == CONTROL_CANCEL then
        TheFrontEnd:PopScreen()
        return true
    end
    return false
end

function MushaPanelScreen:OnDestroy()
    if self.owner and self.owner._musha_panel_screen_open then
        self.owner._musha_panel_screen_open = nil
    end
    if self.owner and self._on_dirty then
        for _, ev in ipairs(DIRTY_EVENTS) do
            self.owner:RemoveEventCallback(ev, self._on_dirty)
        end
    end
    Screen.OnDestroy(self)
end

print("[Musha Panel] 返回 MushaPanelScreen")
return MushaPanelScreen
