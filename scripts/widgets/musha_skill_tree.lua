-- ================================================================
-- musha_skill_tree.lua —— 横排技能树控件（2026-09-20 新写）
--
-- 用户口径（2026-09-18 spec + 2026-09-20 复述）：
--   · 平时只看得到图标（不放说明文字），鼠标移上去才出内容
--   · 左右拖动看目录（按住空白处拖 / 点两侧小箭头 / 滚轮）
--   · 横线+竖线 = 前置：前置没到等级，后面节点是灰的、点不动
--   · 书页风：淡白卡片 + 淡金线 + 深墨字，不放发光/花哨装饰
--
-- 数据来源：面板 md.skills（服务端 GetSkillView 组装）
--   每条 = { id, tree, key, name, icon, cur, max, maxed, can, cost, req,
--            effect, nextfx, tip, book_lock, tree_x, tree_y, pre = {...}, pre_ok }
--
-- 本控件只负责「摆 + 画 + 拖 + 点」；加点/解锁走面板的 RPC（on_add / on_unlock 回调）
-- ================================================================
local Widget      = require "widgets/widget"
local Image       = require "widgets/image"
local Text        = require "widgets/text"
local ImageButton = require "widgets/imagebutton"

local NODE    = 76          -- 图标格边长
local COL_DX  = 132         -- 列距；★ 2026-09-29 用户「（节点之间的）长线太长」：168 → 132
                            --   同行横线长 = COL_DX - NODE：92 → **56**（= 跨行竖线 ROW_DY-NODE 的 56，两向等长）
                            --   想再短就继续减这个数（120 → 44），不用动行距
local ROW_DY = 132          -- 行距（跨行竖线长 = 56）
local PAD    = 44           -- 内容四周留白
local GAP_COL = 1           -- 两棵树之间空几列
local LINE_W = 3            -- 连线粗细
local MARGIN = 16           -- 选中时把节点滚进视野留的边距

-- ★ 2026-09-29 英文第二批：本机语言 + STRINGS.MUSHA_PANEL（modmain 按 Profile 语言加载）
local function UIIsEN()
    local ok, v = pcall(function() return TUNING.MUSHA_UI_LANG end)
    return ok and v ~= nil and v ~= "zh"
end

local function GetGlobalSTRINGS()
    local ok, s = pcall(function() return rawget(_G, "STRINGS") end)
    if ok and s then return s end
    return STRINGS
end

local function MP(key)
    local S = GetGlobalSTRINGS()
    local t = S and S.MUSHA_PANEL
    if type(t) == "table" then return t[key] end
    return nil
end

local function MPS(key, fallback)
    return MP(key) or fallback
end

-- 配色（书页风）
local C_LINE_ON  = { 0.86, 0.64, 0.20, 0.98 }   -- 前置已达标（金）
local C_LINE_OFF = { 0.74, 0.71, 0.66, 0.90 }   -- 前置未达标（灰）
local C_CARD     = { 0.985, 0.975, 0.955, 0.98 }
local C_FRAME    = { 0.80, 0.78, 0.73, 1 }
local C_SEL      = { 0.88, 0.42, 0.10, 1 }      -- 选中：深橙
local C_GOLD     = { 0.86, 0.64, 0.20, 1 }      -- 可加点 / 满级
local C_TXT      = { 0.26, 0.20, 0.13, 1 }
local C_TXT_DIM  = { 0.58, 0.55, 0.51, 1 }
local C_LOCK     = { 0.66, 0.28, 0.22, 1 }
local C_GOLD_TXT = { 0.60, 0.42, 0.08, 1 }

-- 图标注册表：modmain 只把「已经转好 tex/xml」的图标挂到 TUNING.MUSHA_SKILL_ICONS，
-- 没转的这里退回占位（灰块+技能名），绝不崩
local function IconAtlas(id)
    if not id then return nil end
    local ok, T = pcall(function() return TUNING and TUNING.MUSHA_SKILL_ICONS end)
    if ok and T and T[id] then
        return "images/skill_icons/" .. id .. ".xml", id .. ".tex"
    end
    return nil
end

local function MakeLine(parent, w, h, colour)
    local img = parent:AddChild(Image("images/global.xml", "square.tex"))
    img:SetSize(w, h)
    img:SetTint(unpack(colour))
    return img
end

local function MakeText(parent, size, str, colour, x, y)
    local t = parent:AddChild(Text(UIFONT, size))
    t:SetString(str or "")
    if colour then t:SetColour(unpack(colour)) end
    if x or y then t:SetPosition(x or 0, y or 0) end
    return t
end

-- 中文按字数折行（DST 的 Text 不自动换行 → 手动插 \n；UTF-8 逐字取）
local function WrapText(str, per)
    str = tostring(str or "")
    local out, line, cnt = {}, "", 0
    for ch in string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
        if ch == "\n" then
            table.insert(out, line); line, cnt = "", 0
        else
            line = line .. ch
            cnt = cnt + 1
            if cnt >= per then
                table.insert(out, line); line, cnt = "", 0
            end
        end
    end
    if line ~= "" then table.insert(out, line) end
    return table.concat(out, "\n")
end

local MushaSkillTree = Class(Widget, function(self, opts)
    Widget._ctor(self, "MushaSkillTree")
    opts = opts or {}

    self.view_w    = opts.w or 620
    self.view_h    = opts.h or 430
    self.on_add    = opts.on_add
    self.on_unlock = opts.on_unlock
    self.on_select = opts.on_select

    self.scroll_x    = 0
    self.content_w   = self.view_w
    self.nodes       = {}     -- id -> 节点 Widget
    self.entries     = {}     -- id -> 数据
    self.selected_id = nil

    -- ① 裁剪窗口
    self.clip = self:AddChild(Widget("tree_clip"))
    self.clip:SetScissor(-self.view_w / 2, -self.view_h / 2, self.view_w, self.view_h)

    -- ② 拖动接盘（垫在节点下面：点空白 = 拖树）
    local grab = self.clip:AddChild(ImageButton("images/global.xml", "square.tex"))
    grab:ForceImageSize(self.view_w, self.view_h)
    grab:SetPosition(0, 0)
    grab.scale_on_focus = false
    grab.move_on_click  = false
    grab.normal_scale   = { 1, 1, 1 }
    grab.focus_scale    = { 1, 1, 1 }
    grab:SetImageNormalColour(0, 0, 0, 0)
    grab:SetImageFocusColour(0, 0, 0, 0)
    if grab.image then grab.image:SetTint(0, 0, 0, 0) end
    grab:SetOnDown(function()
        self._drag_from = self:MouseX()
        self._drag_base = self.scroll_x
    end)
    grab:SetWhileDown(function()
        local mx = self:MouseX()
        if self._drag_from and mx then
            self:SetScrollX(self._drag_base + (mx - self._drag_from) * self:ScreenToLocal())
        end
    end)
    self.grab = grab

    -- ③ 画布（节点 + 连线挂这儿，整体左右平移）
    self.canvas = self.clip:AddChild(Widget("tree_canvas"))
    self.canvas:SetPosition(-self.view_w / 2, self.view_h / 2)

    -- ④ 两侧小箭头
    local function MakeArrow(x, dir)
        local b = self:AddChild(ImageButton("images/global.xml", "square.tex"))
        b:ForceImageSize(30, 52)
        b:SetPosition(x, 0)
        b.scale_on_focus = false
        b.normal_scale = { 1, 1, 1 }
        b.focus_scale  = { 1, 1, 1 }
        b:SetImageNormalColour(0.93, 0.90, 0.84, 0.92)
        b:SetImageFocusColour(1, 0.97, 0.90, 1)
        MakeText(b, 32, dir < 0 and "<" or ">", C_TXT, 0, 2)
        b:SetOnClick(function() self:Scroll(dir * 130) end)
        return b
    end
    self.arrow_l = MakeArrow(-self.view_w / 2 + 16, -1)
    self.arrow_r = MakeArrow( self.view_w / 2 - 16,  1)

    -- ⑤ 底部提示
    self.hint = MakeText(self, 20, MPS("TREE_HINT", "按住空白处左右拖动 · 滚动条两侧小箭头也行"),
        { 0.52, 0.47, 0.40, 1 }, 0, -self.view_h / 2 + 14)

    self:SetScrollX(0)
end)

-- 鼠标屏幕 X（拿不到返回 nil）
function MushaSkillTree:MouseX()
    local ok, p = pcall(function() return TheInput:GetScreenPosition() end)
    if ok and p and p.x then return p.x end
    return nil
end

-- 屏幕像素 → 控件本地单位（面板有 PANEL_ZOOM，不换算拖动会跟手不动）
function MushaSkillTree:ScreenToLocal()
    local ok, sc = pcall(function() return self.canvas:GetWorldScale() end)
    if ok and sc and sc.x and sc.x > 0.001 then return 1 / sc.x end
    return 1
end

function MushaSkillTree:MinScrollX()
    return math.min(0, self.view_w - self.content_w)
end

function MushaSkillTree:MaxScrollX()
    return 0
end

function MushaSkillTree:SetScrollX(x)
    local minx = self:MinScrollX()
    x = math.max(minx, math.min(0, x or 0))
    self.scroll_x = x
    -- ★ 2026-09-28 用户：「技能靠左上去放，不放在屏幕中间」→ 撤掉 09-25 的"不满一屏就挪正中"，
    --   hoff/voff 恒 0：内容一律贴视口**左上角**（画布原点本来就是视口左上）。
    --   滚动范围 / 拖动 / 滚轮行为与从前逐像素一致（MinScrollX 仍看 content_w）。
    self.canvas:SetPosition(-self.view_w / 2 + x, self.view_h / 2)
    if self.arrow_l then
        local on = x < -0.5
        -- ★ 2026-09-28 用户：「不主动显示左边的按钮 <」→ 往左没得滚时整颗藏起来
        --   （原来是 0.20 半透明还挂在那儿）；只有真能往左滚才露出来
        if on then self.arrow_l:Show() else self.arrow_l:Hide() end
        self.arrow_l:SetImageNormalColour(0.93, 0.90, 0.84, on and 0.92 or 0.20)
        self.arrow_l:SetClickable(on)
    end
    if self.arrow_r then
        local on = x > minx + 0.5
        self.arrow_r:SetImageNormalColour(0.93, 0.90, 0.84, on and 0.92 or 0.20)
        self.arrow_r:SetClickable(on)
    end
end

function MushaSkillTree:Scroll(dx)
    self:SetScrollX(self.scroll_x + (dx or 0))
end

-- 滚轮 → 横向翻（纵向留给别处）
function MushaSkillTree:OnControl(control, down)
    if MushaSkillTree._base.OnControl(self, control, down) then
        return true
    end
    if down and control == CONTROL_SCROLLBACK then
        self:Scroll(-90)
        return true
    elseif down and control == CONTROL_SCROLLFWD then
        self:Scroll(90)
        return true
    end
    return false
end

-- ================================================================
-- 建树：list = md.skills（服务端已按 tree 排好）
-- ================================================================
function MushaSkillTree:SetSkills(list)
    self.canvas:KillAllChildren()
    self.nodes       = {}
    self.entries     = {}
    self.selected_id = nil

    if not list or #list == 0 then
        self.content_w = self.view_w
        self.raw_w, self.raw_h = nil, nil          -- 09-25：空表回到"不偏移"状态
        if self.on_select then self.on_select(nil) end
        self:SetScrollX(0)
        return
    end

    -- ① 按 tree 分组（树与树之间空 GAP_COL 列）
    local tree_order, groups = {}, {}
    for _, e in ipairs(list) do
        local t = e.tree or "?"
        if not groups[t] then groups[t] = {}; table.insert(tree_order, t) end
        table.insert(groups[t], e)
    end

    local tree_offx, tree_cols, maxrow = {}, {}, 0
    local cursor = 0
    for _, t in ipairs(tree_order) do
        tree_offx[t] = cursor
        local maxcol = 0
        for _, e in ipairs(groups[t]) do
            maxcol = math.max(maxcol, e.tree_x or 0)
            maxrow = math.max(maxrow, e.tree_y or 0)
        end
        tree_cols[t] = maxcol + 1
        cursor = cursor + maxcol + 1 + GAP_COL
    end
    local total_cols = cursor - GAP_COL
    self.content_w = math.max(self.view_w, PAD * 2 + (total_cols - 1) * COL_DX + NODE)
    self.content_h = math.max(self.view_h, PAD * 2 + maxrow * ROW_DY + NODE)
    -- ★ 09-25「技能栏变动方位」：原始内容尺寸。
    --   ⚠️ 09-28 用户「靠左上放，不放在屏幕中间」→ hoff/voff 居中偏移已撤，
    --     这两个值现在只用来算 content_w/content_h 之外的备份，SetScrollX 不再读它们。
    self.raw_w = PAD * 2 + (total_cols - 1) * COL_DX + NODE
    self.raw_h = PAD * 2 + maxrow * ROW_DY + NODE

    -- 节点中心（画布坐标：x 向右为正，y 向下为负）
    local function Pos(e, t)
        local col = (tree_offx[t] or 0) + (e.tree_x or 0)
        local row = (e.tree_y or 0)
        return PAD + col * COL_DX + NODE / 2, -(PAD + row * ROW_DY + NODE / 2)
    end

    -- ② 每棵树：★★ 2026-09-27 用户「去掉技能书书本外框，只留里面图标」
    --   → 整棵树的淡底块不画了（原来 SetTint(1,1,1,0.5) 的底框 =「书本外框」），
    --     图标/连线直接摆书页上；树与树之间靠 GAP_COL 空列区分。

    -- ③ 连线（画在节点下面）
    for _, t in ipairs(tree_order) do
        for _, e in ipairs(groups[t]) do
            local x2, y2 = Pos(e, t)
            for _, p in ipairs(e.pre or {}) do
                local pe
                for _, cand in ipairs(groups[t]) do
                    if cand.key == p.key then pe = cand; break end
                end
                if pe then
                    local x1, y1 = Pos(pe, t)
                    local on  = (p.cur or 0) >= (p.need or 1)
                    local col = on and C_LINE_ON or C_LINE_OFF
                    if math.abs(y1 - y2) < 1 then
                        -- 同一行：一条横线
                        MakeLine(self.canvas, (x2 - NODE / 2) - (x1 + NODE / 2), LINE_W, col)
                            :SetPosition((x1 + x2) / 2, y1)
                    else
                        -- 不同行：先竖（前置中心 → 目标行），再横到目标左边缘
                        MakeLine(self.canvas, LINE_W, math.abs(y2 - y1) - NODE, col)
                            :SetPosition(x1, (y1 + y2) / 2)
                        MakeLine(self.canvas, (x2 - NODE / 2) - x1, LINE_W, col)
                            :SetPosition((x1 + x2 - NODE / 2) / 2, y2)
                    end
                end
            end
        end
    end

    -- ④ 节点
    for _, t in ipairs(tree_order) do
        for _, e in ipairs(groups[t]) do
            local x, y = Pos(e, t)
            local node = self.canvas:AddChild(Widget("skill_node"))
            node:SetPosition(x, y)

            local card = node:AddChild(Image("images/global.xml", "square.tex"))
            card:SetSize(NODE, NODE)
            card:SetTint(unpack(C_CARD))

            -- 描边：满级/可加点=金，其余=灰
            local frame_c = C_FRAME
            if e.maxed then frame_c = C_GOLD
            elseif e.can then frame_c = C_GOLD end
            for _, d in ipairs({ { 0, 1 }, { 0, -1 }, { -1, 0 }, { 1, 0 } }) do
                local horiz = (d[1] == 0)
                local seg = MakeLine(node, horiz and NODE or 2, horiz and 2 or NODE, frame_c)
                seg:SetPosition(d[1] * NODE / 2, d[2] * NODE / 2)
            end

            -- 图标（没转 tex → 占位灰块 + 技能名前几字）
            local atlas, tex = IconAtlas(e.icon or e.key)
            if atlas then
                local icon = node:AddChild(Image(atlas, tex))
                icon:ScaleToSize(NODE - 12, NODE - 12)
                if not (e.can or e.maxed) then
                    icon:SetTint(0.62, 0.60, 0.56, 1)
                end
            else
                local ph = node:AddChild(Image("images/global.xml", "square.tex"))
                ph:SetSize(NODE - 12, NODE - 12)
                ph:SetTint(0.82, 0.80, 0.76, 1)
                MakeText(node, 20, string.sub(tostring(e.name or e.key or "?"), 1, 5),
                    (e.can or e.maxed) and C_TXT or C_TXT_DIM, 0, 0)
            end

            -- 等级角标 2/3（满级金色）
            if (e.max or 0) > 0 then
                local badge_col = e.maxed and C_GOLD_TXT or C_TXT
                MakeText(node, 20, string.format("%d/%d", e.cur or 0, e.max or 0),
                    badge_col, NODE / 2 - 14, -NODE / 2 + 10)
            end

            -- 状态角标：书=技能书锁 / 锁=前置没到 / 满=满级
            --   ★ 09-29：英文角标更宽（拉丁字母）→ 缩字号 + 短词，保证不出节点左缘
            --     （节点 76 宽、角标中心 x=-25 → 半宽必须 ≤13；18 号 "Max"≈30px 会越界）
            if (e.book_lock or 0) > 0 then
                MakeText(node, UIIsEN() and 14 or 18, MPS("BADGE_BOOK", "书"), C_LOCK, -NODE / 2 + 13, NODE / 2 - 10)
            elseif e.pre_ok == false then
                MakeText(node, UIIsEN() and 14 or 18, MPS("BADGE_LOCK", "锁"), C_TXT_DIM, -NODE / 2 + 13, NODE / 2 - 10)
            elseif e.maxed then
                MakeText(node, UIIsEN() and 14 or 18, MPS("BADGE_MAX", "满"), C_GOLD_TXT, -NODE / 2 + 13, NODE / 2 - 10)
            end

            -- ★ 2026-09-21 用户口径：**鼠标移到图标上 → 用原版 SetHoverText 出信息**
            --   （跟 beta 版 MushaLevel_UI.lua 一个写法：widget 自带方法，widget.lua:708）
            --   内容跟右栏详情同一套：名字/树·等级、当前、下一级、条件、（tip）
            local hl = {}
            -- 第一行：技能名（当前/上限）—— 按用户 2026-09-21 口径：**不显示职业名**
            table.insert(hl, string.format(MPS("HL_NAME_FMT", "%s（%d/%d）"),
                tostring(e.name or e.key or "?"), e.cur or 0, e.max or 0))
            if (e.cur or 0) > 0 then
                table.insert(hl, MPS("LBL_CURRENT", "当前：") .. (((e.effect or "") ~= "") and e.effect or "—"))
            else
                table.insert(hl, MPS("LBL_CURRENT_UNLEARNED", "当前：未学习"))
            end
            if e.maxed then
                table.insert(hl, MPS("LBL_MAXED", "已满级"))
            else
                table.insert(hl, MPS("LBL_NEXT", "下一级：") .. (((e.nextfx or "") ~= "") and e.nextfx or "—"))
            end
            local need = {}
            if (e.req or 0) > 0 then
                table.insert(need, string.format(MPS("REQ_LEVEL_FMT", "角色等级 %d"), e.req))
            end
            if (e.book_lock or 0) > 0 then
                table.insert(need, string.format(MPS("REQ_BOOK_FMT", "%d 本技能书"), e.book_lock))
            elseif not e.maxed then
                table.insert(need, string.format(MPS("REQ_SP_FMT", "%d 技能点"), e.cost or 1))
            end
            if e.pre and #e.pre > 0 then
                local ps = {}
                for _, p in ipairs(e.pre) do
                    table.insert(ps, string.format("%s %d/%d", p.name, p.cur or 0, p.need or 1))
                end
                table.insert(need, MPS("LBL_PREREQ", "前置：") .. table.concat(ps, MPS("LBL_PREREQ_SEP", "、")))
            end
            if #need > 0 then table.insert(hl, MPS("LBL_COND", "条件：") .. table.concat(need, " · ")) end
            if (e.tip or "") ~= "" then table.insert(hl, e.tip) end
            -- ★ 09-29：折行宽度按语言 —— 拉丁字母约半宽，同样像素要放约两倍字符
            local hover_txt = WrapText(table.concat(hl, "\n"), UIIsEN() and 26 or 13)

            -- 点击 = 选中（加点在右栏详情里的按钮上，防误点）
            local btn = node:AddChild(ImageButton("images/global.xml", "square.tex"))
            btn:ForceImageSize(NODE, NODE)
            btn:SetPosition(0, 0)
            btn.scale_on_focus = false
            btn.move_on_click  = false
            btn.normal_scale   = { 1, 1, 1 }
            btn.focus_scale    = { 1, 1, 1 }
            btn:SetImageNormalColour(1, 1, 1, 0)
            btn:SetImageFocusColour(1, 1, 1, 0.08)
            if btn.image then btn.image:SetTint(1, 1, 1, 0) end
            btn:SetOnClick(function() self:Select(e.id, true) end)

            -- 悬停出信息：**原版 SetHoverText**（widget.lua:708）——比 SetTooltip 轻、跟随鼠标位置，
            --   写法跟 beta 版 MushaLevel_UI.lua 一致（那边也是 icon:SetHoverText(text)）
            --   ⚠️ 必须挂在**能获得焦点**的 widget 上（这里是盖住节点的 ImageButton），挂纯 Widget 上不会触发
            btn:SetHoverText(hover_txt, {
                font_size = 20,
                region_w  = 300,
                offset_y  = -NODE / 2 - 10,     -- 默认 +26 会盖住图标 → 往下放到节点外侧
            })

            node._entry = e
            self.nodes[e.id]   = node
            self.entries[e.id] = e
        end
    end

    self:SetScrollX(0)
end

-- 把某个画布 x 滚进视野（留 MARGIN 边距），返回新的 scroll_x
function MushaSkillTree:ScrollToShow(canvas_x)
    -- 可见条件：-scroll_x + MARGIN <= canvas_x <= view_w - scroll_x - MARGIN
    local lo = MARGIN - canvas_x                    -- scroll_x 下限
    local hi = self.view_w - MARGIN - canvas_x      -- scroll_x 上限
    if lo > hi then lo, hi = hi, lo end
    local x = self.scroll_x
    if x < lo then x = lo elseif x > hi then x = hi end
    return x
end

-- 选中节点（id 为空 = 取消）；notify = 是否回调面板画详情
function MushaSkillTree:Select(id, notify)
    if self.selected_id and self.nodes[self.selected_id] then
        local old = self.nodes[self.selected_id]
        for _, m in ipairs(old._sel_marks or {}) do m:Kill() end
        old._sel_marks = nil
    end
    self.selected_id = id

    local node = id and self.nodes[id] or nil
    if node then
        local marks = {}
        local function put(w, h, px, py)
            local s = MakeLine(node, w, h, C_SEL)
            s:SetPosition(px, py)
            table.insert(marks, s)
        end
        put(NODE + 8, 2,  0,  NODE / 2 + 4)
        put(NODE + 8, 2,  0, -NODE / 2 - 4)
        put(2, NODE + 8,  NODE / 2 + 4, 0)
        put(2, NODE + 8, -NODE / 2 - 4, 0)
        node._sel_marks = marks

        -- ⚠️ Widget:GetPosition() 返回的是 Vector3（不是 x,y 两个数）
        local pos = node:GetPosition()
        local px  = pos and pos.x
        if px then
            self:SetScrollX(self:ScrollToShow(px))
        end
    end

    if notify and self.on_select then
        self.on_select(id and self.entries[id] or nil)
    end
end

function MushaSkillTree:GetSelected()
    return self.selected_id and self.entries[self.selected_id] or nil
end

-- 服务端推了新数据 → 重建，尽量保住选中项
function MushaSkillTree:RefreshKeepSelection(list)
    local keep = self.selected_id
    self:SetSkills(list)
    if keep and self.entries[keep] then
        self:Select(keep, true)
    end
end

function MushaSkillTree:SetHint(str)
    if self.hint then self.hint:SetString(str or "") end
end

return MushaSkillTree
