-- ================================================================
-- musha_tavern_screen.lua —— 酒馆委托板（2026-09-28 新增，同日改 HUD 挂件）
--
-- 用户拍板（2026-09-27 三轮问答）：
--   ① 右键酒馆 → 屏幕**右侧**弹出任务列表（看起来绑定在酒馆上，
--      实际上是这个玩家自己的面板，人人都有）
--   ② 玩法不改：转职卷轴照旧（容器照开，板子不挡它）；
--      **每日获得的任务全部搬到这块板子上**，点「接取」才进"进行中"，
--      不再每日轮询自动发
--   ③ 接取按钮 = 礼包页「领取」（MakeGiftButton 那套 square.tex 立体按钮）
--   ④ 品质四档：普通(灰) / 白 / 银 / 金 —— 分档在服务端算（musha_quest.lua
--      的 QualityOf），这里只按 q 字段上色，不抄数值
--   ⑤ 美术：图片/木框花_350x590.png → images/tavern_frame（publish 已转 tex）
--
-- ★ 2026-09-28 用户拍板（体验点）：**不盖住酒馆容器**。
--   板子从「全屏 Screen（PushScreen 抢输入）」改成 **HUD 挂件**：
--     · 不进屏幕栈（screenstack 之外），ESC/点空白不再由板子接管
--     · 挂在 controls 的右缘（ANCHOR_RIGHT/MIDDLE + SCALEMODE_PROPORTIONAL），
--       和原版容器 containerroot（中央锚点）分属两块，互不遮挡
--     · 非交互部件全部 SetClickable(false)，点击穿透到世界/容器
--     · 关闭方式：× 按钮，或再右键酒馆（toggle）
--   技能面板（Screen）与板子不同层，按用户口径"不会同时打开"，不做互斥检查。
-- ⚠️ tex/xml 变更后必须**完全重启 DST** 才看得到。
-- ================================================================
local Widget     = require "widgets/widget"
local Image      = require "widgets/image"
local Text       = require "widgets/text"
local ImageButton = require "widgets/imagebutton"

local BOARD_W, BOARD_H = 350, 640   -- ★ 09-29 用户「面板拉长 50」：590 → 640（木框图 350x590 等比拉高，行坐标按 BOARD_H 锚点走）
local BOARD_OFFSET     = -441    -- 右缘锚点下的中心 x；09-28「右边的左移 170」：-191-170=-361；★ 09-29 用户「左移 80」：-361-80=-441
local ROW_W            = 310     -- 行底片宽
local ROW_H            = 56
local AVAIL_Y0, AVAIL_DY = 150, 62 -- 可接委托 4 行
local AVAIL_MAX        = 4
local ACT_Y0, ACT_DY   = -130, 38 -- 进行中最多列 3 条
local ACT_MAX          = 3

-- 品质四档（颜色只在客户端上，档位判定在服务端；label 走 STRINGS.MUSHA_PANEL）
local TIER = {
    [1] = { label_key = "Q_COMMON", chip = { 0.55, 0.55, 0.55, 1 }, row = { 0.86, 0.86, 0.86, 0.93 } },
    [2] = { label_key = "Q_WHITE",  chip = { 0.99, 0.99, 0.99, 1 }, row = { 0.99, 0.99, 0.99, 0.93 } },
    [3] = { label_key = "Q_SILVER", chip = { 0.74, 0.78, 0.85, 1 }, row = { 0.88, 0.91, 0.95, 0.93 } },
    [4] = { label_key = "Q_GOLD",   chip = { 0.95, 0.76, 0.22, 1 }, row = { 1.00, 0.94, 0.74, 0.96 } },
}
local function Tier(t)
    return TIER[tonumber(t) or 1] or TIER[1]
end

-- 中文按字数截断（按字节截会切坏 UTF-8 → 乱码）
local function TrimCN(s, maxchars)
    s = tostring(s or "")
    local out, n = {}, 0
    for ch in string.gmatch(s, "[%z\1-\127\194-\244][\128-\191]*") do
        n = n + 1
        if n > maxchars then
            out[#out + 1] = "…"
            break
        end
        out[#out + 1] = ch
    end
    return table.concat(out)
end

-- ★ 2026-09-29 英文第二批：本机语言（同面板屏，modmain 按 Profile 语言加载语言文件）
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

-- 任务名：**客户端本地表优先**（语言跟人走）；服务端 q.n 只作未知 id 的回退。
-- （服务端模板 quest_id 1~13 与 STRINGS.MUSHA_PANEL.QUEST_NAMES 同源同 id）
local function QuestNameOf(q)
    if type(q) ~= "table" then return nil end
    local t = MP("QUEST_NAMES")
    local n = t and t[q.id]
    if n and n ~= "" then return n end
    return q.n
end

-- 英文是拉丁字母，同样像素宽度下能塞下约两倍字符数 → 截断上限按语言放一倍
local function TrimQ(s, zh_max)
    return TrimCN(s, UIIsEN() and (zh_max * 2) or zh_max)
end

-- 「接取」按钮：照礼包页 MakeGiftButton 的做法（square.tex 分层做立体，不依赖美术）
local function MakeGiftButton(parent, w, h, str, onclick)
    local b = parent:AddChild(ImageButton("images/global.xml", "square.tex"))
    b:ForceImageSize(w + 6, h + 6)
    b:SetImageNormalColour(0.38, 0.24, 0.12, 0.92)      -- 外框（深棕）= 立体底
    b:SetImageFocusColour(0.46, 0.30, 0.15, 0.95)
    b.scale_on_focus = false

    local face = b:AddChild(Image("images/global.xml", "square.tex"))
    face:SetSize(w, h)
    face:SetTint(0.90, 0.62, 0.26, 0.99)                -- 暖橙主色

    for _, ln in ipairs({ { 0, h / 2 - 2, w, 3 }, { -(w / 2 - 2), 0, 3, h } }) do
        local i = b:AddChild(Image("images/global.xml", "square.tex"))
        i:SetSize(ln[3], ln[4])
        i:SetPosition(ln[1], ln[2])
        i:SetTint(1.00, 0.90, 0.62, 0.98)
    end
    for _, ln in ipairs({ { 0, -(h / 2 - 2), w, 3 }, { (w / 2 - 2), 0, 3, h } }) do
        local i = b:AddChild(Image("images/global.xml", "square.tex"))
        i:SetSize(ln[3], ln[4])
        i:SetPosition(ln[1], ln[2])
        i:SetTint(0.56, 0.33, 0.13, 0.95)
    end

    local t = b:AddChild(Text(UIFONT, 22))
    t:SetString(str)
    t:SetColour(1.00, 0.97, 0.90, 1)
    b._label = t

    b:SetOnGainFocus(function() b:SetScale(1.06, 1.06, 1) end)
    b:SetOnLoseFocus(function() b:SetScale(1, 1, 1) end)
    if onclick then b:SetOnClick(onclick) end
    return b
end

local function GetUserData(owner)
    if not owner or not owner:IsValid() then return nil end
    local replica = owner.replica and owner.replica.musha_profession_component
    local cd = replica and replica.cached_data
    return cd and cd.userdata
end

-- 客户端 → 服务端：拉一次最新任务数据（开板时先要一次）
local function RequestSettings()
    local ok, rpc = pcall(function() return GetModRPC("musha", "musha_request_settings") end)
    if not ok or rpc == nil then return end
    pcall(function() SendModRPCToServer(rpc) end)
end

-- 客户端 → 服务端：接取委托
local function SendAcceptQuest(quest_id)
    if not quest_id then return end
    local ok, rpc = pcall(function() return GetModRPC("musha", "musha_accept_quest") end)
    if not ok or rpc == nil then return end
    pcall(function() SendModRPCToServer(rpc, quest_id) end)
end

local MushaTavernBoard = Class(Widget, function(self, owner)
    Widget._ctor(self, "MushaTavernBoard")
    self.musha_tavern = true         -- 打开入口用来认自己（防重入标记）
    self.owner = owner

    -- 位置由挂在根节点（ANCHOR_RIGHT/MIDDLE + SCALEMODE_PROPORTIONAL，
    -- 照原版 containerroot 的挂法）决定，这里只写相对右缘的偏移：
    -- 中心 x = -(350/2 + 16) → 板子右缘离屏幕右边 16px（09-28 起左移 170 → 边距 186px）。
    -- 坐标按 1280x720 虚拟分辨率等比缩放，随玩家 HUD 大小设置一起走。
    -- ★ 09-28 用户「上移动 7 像素」：y 0 → +7。
    self:SetPosition(BOARD_OFFSET, 7)

    -- 木框花 350x590（原尺寸，不拉伸 → 不变形）
    local frame = self:AddChild(Image("images/tavern_frame.xml", "tavern_frame.tex"))
    frame:SetSize(BOARD_W, BOARD_H)
    frame:SetTint(1, 1, 1, 1)
    frame:SetClickable(false)        -- 框不吃点击 → 不挡世界/容器
    self.frame = frame

    -- 关闭按钮（右上角）
    local xb = self:AddChild(ImageButton("images/global.xml", "square.tex"))
    xb:ForceImageSize(30, 30)
    xb:SetPosition(BOARD_W / 2 - 26, BOARD_H / 2 - 24)
    xb:SetImageNormalColour(0.32, 0.20, 0.14, 0.90)
    xb:SetImageFocusColour(0.62, 0.24, 0.16, 0.98)
    xb.scale_on_focus = false
    local xt = xb:AddChild(Text(UIFONT, 26))
    xt:SetString("×")
    xt:SetColour(1, 0.94, 0.86, 1)
    xb:SetOnClick(function() self:SetBoardVisible(false) end)

    -- 标题
    self.title = self:AddChild(Text(UIFONT, 30))
    self.title:SetString(MP("TAVERN_TITLE") or "酒馆委托")
    self.title:SetColour(0.30, 0.22, 0.13, 1)
    self.title:SetPosition(0, BOARD_H / 2 - 56)
    self.title:SetClickable(false)

    self.sub = self:AddChild(Text(UIFONT, 16))
    self.sub:SetString(MP("TAVERN_SUB") or "点「接取」才开始计进度")
    self.sub:SetColour(0.46, 0.40, 0.32, 1)
    self.sub:SetPosition(0, BOARD_H / 2 - 84)
    self.sub:SetClickable(false)

    -- 分区标题
    self.head_avail = self:AddChild(Text(UIFONT, 20))
    self.head_avail:SetString(MP("TAVERN_HEAD_AVAIL") or "可接委托")
    self.head_avail:SetColour(0.60, 0.42, 0.08, 1)
    self.head_avail:SetPosition(0, AVAIL_Y0 + 36)
    self.head_avail:SetClickable(false)

    self.head_act = self:AddChild(Text(UIFONT, 20))
    self.head_act:SetString(MP("TAVERN_HEAD_ACT") or "进行中")
    self.head_act:SetColour(0.60, 0.42, 0.08, 1)
    self.head_act:SetPosition(0, ACT_Y0 + 30)
    self.head_act:SetClickable(false)

    -- 行容器（每次刷新清空重建）
    self.rows = self:AddChild(Widget("tavern_rows"))
    self.rows:SetPosition(0, 0)

    self.foot = self:AddChild(Text(UIFONT, 14))
    self.foot:SetString(MP("TAVERN_FOOT") or "再右键酒馆或点 × 关闭")
    self.foot:SetColour(0.50, 0.45, 0.38, 1)
    self.foot:SetPosition(0, -BOARD_H / 2 + 26)
    self.foot:SetClickable(false)

    -- 数据变更 → 重画（接取成功后服务端会 SyncToPanel → gamedata_dirty）
    self._on_dirty = function() self:Rebuild() end
    if owner then owner:ListenForEvent("gamedata_dirty", self._on_dirty) end

    self:Hide()                      -- 构造完先藏着，由打开入口决定是否显示
end)

-- ================================================================
-- 开 / 关（toggle 由 musha_panel_registered.lua 调）
-- ================================================================
function MushaTavernBoard:SetBoardVisible(vis)
    if vis then
        self:Show()
        if self.owner then self.owner._musha_tavern_screen_open = true end
        RequestSettings()            -- 开板先拉一次最新数据
        self:Rebuild()
    else
        self:Hide()
        if self.owner then self.owner._musha_tavern_screen_open = nil end
    end
end

-- ================================================================
-- 画板子：可接委托（带品质色 + 接取按钮）/ 进行中（只读）
-- ================================================================
function MushaTavernBoard:Rebuild()
    if not self.rows or not self.parent then return end   -- 已从 HUD 摘下就不画
    if not self:IsVisible() then return end              -- 隐藏时跳过，省一次重建
    self.rows:KillAllChildren()

    local md = GetUserData(self.owner) or {}
    local avail = md.available_quests or {}
    local active = md.daily_quests or {}

    if #avail == 0 then
        local t = self.rows:AddChild(Text(UIFONT, 17))
        t:SetString(MP("TAVERN_EMPTY_AVAIL") or "今天的委托都接完了")
        t:SetColour(0.52, 0.46, 0.38, 1)
        t:SetPosition(0, AVAIL_Y0 - 10)
        t:SetClickable(false)
    end

    for i = 1, math.min(#avail, AVAIL_MAX) do
        local q = avail[i]
        local y = AVAIL_Y0 - (i - 1) * AVAIL_DY
        local tr = Tier(q.q)

        -- 行底片（按品质上一层淡色，一眼分档）
        local bg = self.rows:AddChild(Image("images/global.xml", "square.tex"))
        bg:SetSize(ROW_W, ROW_H)
        bg:SetPosition(0, y)
        bg:SetTint(unpack(tr.row))
        bg:SetClickable(false)

        -- 品质色块（深色描边 + 中间色块）
        local edge = self.rows:AddChild(Image("images/global.xml", "square.tex"))
        edge:SetSize(20, 20)
        edge:SetPosition(-145, y)
        edge:SetTint(0.25, 0.22, 0.18, 1)
        edge:SetClickable(false)
        local chip = self.rows:AddChild(Image("images/global.xml", "square.tex"))
        chip:SetSize(14, 14)
        chip:SetPosition(-145, y)
        chip:SetTint(unpack(tr.chip))
        chip:SetClickable(false)

        -- 名称（深墨字，白色档也能看清）
        local name = self.rows:AddChild(Text(UIFONT, 16))
        name:SetString(TrimQ(QuestNameOf(q)
                or string.format(MP("QUEST_DEFAULT_FMT") or "任务%s", tostring(q.id)), 10))
        name:SetColour(0.24, 0.19, 0.13, 1)
        name:SetPosition(-45, y + 9)
        name:SetClickable(false)

        -- 奖励预览（"现在发不起奖励" → 只写职业经验，数值走服务端 q.exp，不改）
        --   ★ 0.7.13 批：行尾带 "n/3"（服务端 q.tk = 该委托已同时接取人数，上限 3）
        local rw = self.rows:AddChild(Text(UIFONT, 13))
        local expn = tonumber(q.exp) or 0
        local tk = tonumber(q.tk) or 0
        rw:SetString(string.format(MP("REWARD_ROW_FMT") or "%s · 经验 +%s · %s/3",
                MP(tr.label_key) or "?", tostring(expn), tostring(tk)))
        rw:SetColour(0.55, 0.42, 0.14, 1)
        rw:SetPosition(-45, y - 13)
        rw:SetClickable(false)

        -- 接取（礼包页「领取」同款）
        local qid = q.id
        local btn = MakeGiftButton(self.rows, 74, 30, MP("ACCEPT") or "接取", function()
            SendAcceptQuest(qid)
        end)
        btn:SetPosition(100, y)
    end

    -- 进行中（只读：接取后才出现）
    if #active == 0 then
        local t = self.rows:AddChild(Text(UIFONT, 16))
        t:SetString(MP("TAVERN_EMPTY_ACT") or "还没有接取的委托")
        t:SetColour(0.52, 0.46, 0.38, 1)
        t:SetPosition(0, ACT_Y0)
        t:SetClickable(false)
    else
        for i = 1, math.min(#active, ACT_MAX) do
            local q = active[i]
            local y = ACT_Y0 - (i - 1) * ACT_DY
            local bg = self.rows:AddChild(Image("images/global.xml", "square.tex"))
            bg:SetSize(ROW_W - 20, 32)
            bg:SetPosition(0, y)
            bg:SetTint(1, 1, 1, 0.55)
            bg:SetClickable(false)

            local t = self.rows:AddChild(Text(UIFONT, 15))
            local flag = q.done and "✓ " or ""
            t:SetString(string.format("%s%s [%d/%d]", flag, TrimQ(QuestNameOf(q) or "?", 9),
                tonumber(q.p) or 0, tonumber(q.t) or 1))
            t:SetColour(q.done and 0.30 or 0.26, q.done and 0.55 or 0.21,
                        q.done and 0.30 or 0.15, 1)
            t:SetPosition(0, y)
            t:SetClickable(false)
        end
        if #active > ACT_MAX then
            local t = self.rows:AddChild(Text(UIFONT, 14))
            t:SetString(string.format(MP("TAVERN_MORE_FMT") or "…还有 %d 个", #active - ACT_MAX))
            t:SetColour(0.50, 0.45, 0.38, 1)
            t:SetPosition(0, ACT_Y0 - ACT_MAX * ACT_DY + 6)
            t:SetClickable(false)
        end
    end
end

-- ================================================================
-- 关闭时解监听（板子是 HUD 挂件，正常只 Hide 不销毁；
-- 只有 controls 整体重建/世界切换才需要显式调 Detach ——
-- Widget 没有 OnDestroy，Screen 的那套生命周期在挂件上不会触发）
-- ================================================================
function MushaTavernBoard:Detach()
    if self.owner and self.owner._musha_tavern_screen_open then
        self.owner._musha_tavern_screen_open = nil
    end
    if self.owner and self._on_dirty then
        self.owner:RemoveEventCallback("gamedata_dirty", self._on_dirty)
    end
    self._on_dirty = nil
end

print("[Musha] 返回 MushaTavernBoard(HUD 挂件)")
return MushaTavernBoard
