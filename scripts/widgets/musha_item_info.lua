-- ==========================================================
-- musha_item_info.lua（2026-09-12 新建，纯客户端）
-- 悬停信息小面板：鼠标指到物品/实体上 → 在光标旁边显示
--   物品名（白）
--   伤害（红字）  ← 用户要求
--   保暖（淡白色）← 用户要求
--   隔热/防暑（淡蓝，顺手加的，不想要就删这行）
--   宝藏值 / 能量回复（以后接了这两套数值自动出现）
--
-- ★ 为什么数值要查表：客户端**读不到** weapon.damage / insulator.insulation
--   （这两个组件没有 replica，服务端专有）→ 用 scripts/musha_item_stats.lua 的静态表
--   （和 Show Me 一个套路；表是扫描 prefabs 自动生成的）
--
-- ★ 左对齐：DST 的 Text 光设 SetHAlign 没用，必须同时 SetRegionSize，
--   且 SetPosition 指的是"区域中心"（左缘 = 位置 - region宽/2）
-- ==========================================================

-- ★★ 2026-09-12 修（用户："musha 原来也不显示"）：
--    日志实测 `[Musha ERROR] 悬停信息面板: ...musha_item_info.lua:34: variable 'Widget' is not declared`
--    根因：在 DST 里 **Widget / Text / Image 不是全局**，它们是模块（widgets/widget.lua 里是 local + return），
--    必须 `require "widgets/widget"` 拿（本 mod 的面板 screen / 明生的 screen / musha_skillui 都是这么写的）。
--    之前直接写 `Class(Widget, ...)` → 加载即报错 → 面板从来没被挂上。
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"

local FONT = "bp50"          -- = UIFONT（写死避免环境差异）
local LINE_H = 26            -- 行高
local PAD = 12               -- 内边距
local W = 340                -- 面板宽（固定宽 → 文字左缘整齐）

-- 2026-09-12 用户问"普通（角色）也可以用吗？" → 做成通用信息工具：
--   true  = 所有角色都能看到悬停信息（像 Show Me 那样，跟职业无关）
--   false = 只有 musha 玩家看得到（原来的行为）
--   注意：谁能看到取决于**谁装了这个 mod**（客机没装就什么都没有）；
--         要"整房人都能看到"得把 modinfo 的 all_clients_require_mod 改成 true。
local SHOW_FOR_ALL = true

-- 配色
local COL = {
    name = { 1.00, 1.00, 1.00 },        -- 物品名 白
    dmg  = { 0.98, 0.62, 0.62 },        -- 伤害 淡红（2026-09-12 用户：淡红给普通伤害）
    planar = { 0.96, 0.28, 0.28 },      -- 位面伤害 正红（2026-09-12 用户：红色专属位面伤害）
    pdef   = { 0.72, 0.68, 0.92 },      -- 位面防御 淡紫
    warm = { 0.95, 0.94, 0.88 },        -- 保暖 淡白
    cool = { 0.62, 0.82, 0.95 },        -- 隔热 淡蓝
    gold = { 0.98, 0.80, 0.35 },        -- 宝藏值 金（以后）
    mp   = { 0.70, 0.90, 1.00 },        -- 能量回复 淡蓝（2026-09-12 用户：由淡青改淡蓝）
                                        -- ⚠️ 和下面 cool「隔热 淡蓝」色系撞了，靠亮度区分（能量更亮更冷）
    dim  = { 0.70, 0.68, 0.64 },        -- 灰
    food = { 0.82, 0.94, 0.74 },        -- 食物（饥饿/理智/生命）淡绿（2026-09-13 追加）
    armor = { 0.72, 0.86, 0.94 },       -- 护甲减伤 淡青（2026-09-13 追加）
}

local MushaItemInfo = Class(Widget, function(self)
    Widget._ctor(self, "MushaItemInfo")

    self.bg = self:AddChild(Image("images/global.xml", "square.tex"))
    self.bg:SetTint(0.05, 0.05, 0.06, 0.86)

    -- 一道细白边，免得压在浅色地上一团黑
    self.frame = self:AddChild(Image("images/global.xml", "square.tex"))
    self.frame:SetTint(1, 1, 1, 0.25)

    self.body = self:AddChild(Widget("body"))
    self.cur_h = 0
    self:Hide()
    self:StartUpdating()
end)

-- 设置内容：list = { { text = "...", colour = {r,g,b} }, ... }
function MushaItemInfo:SetLines(list)
    self.body:KillAllChildren()

    local n = #list
    if n <= 0 then
        self:Hide()
        return
    end

    local h = n * LINE_H + PAD * 2
    self.cur_h = h
    self.bg:SetSize(W, h)
    self.frame:SetSize(W + 2, h + 2)

    local region = W - PAD * 2
    for i, e in ipairs(list) do
        local t = self.body:AddChild(Text(FONT, e.size or 22))
        t:SetString(e.text or "")
        local c = e.colour or COL.name
        t:SetColour(c[1], c[2], c[3], c[4] or 1)
        t:SetRegionSize(region, LINE_H)          -- ★ 左对齐必须配 region
        t:SetHAlign(ANCHOR_LEFT)
        local y = h / 2 - PAD - LINE_H / 2 - (i - 1) * LINE_H
        t:SetPosition(-W / 2 + PAD + region / 2, y)   -- 区域中心 = 左缘 + region/2
    end
end

-- 固定钉在屏幕右下角（2026-09-13 用户：不要跟鼠标了，挪到右下角）
--   ☆ 旧版 FollowMouse 保留在下面注释里，想改回"跟鼠标"就把名字换回去
local MARGIN = 24
function MushaItemInfo:PinBottomRight()
    local half_w, half_h = RESOLUTION_X / 2, RESOLUTION_Y / 2
    self:SetPosition(half_w - W / 2 - MARGIN, -half_h + self.cur_h / 2 + MARGIN)
end

--[[ 旧版：跟着鼠标走（贴边时翻到另一侧）
function MushaItemInfo:FollowMouse()
    local pos = TheInput:GetScreenPosition()
    if pos == nil then return end
    local mx, my = pos.x or 0, pos.y or 0

    local half_w, half_h = RESOLUTION_X / 2, RESOLUTION_Y / 2
    local x = mx - half_w + 26 + W / 2
    local y = my - half_h + 18 + self.cur_h / 2
    if x + W / 2 > half_w - 12 then
        x = mx - half_w - 26 - W / 2
    end
    if y + self.cur_h / 2 > half_h - 12 then
        y = my - half_h - 18 - self.cur_h / 2
    end
    self:SetPosition(x, y)
end
]]
--   ★ 2026-09-12 修：`TheInput:GetScreenPosition()` 返回的是 **Vector3**（不是两个返回值！）
--     之前写成 `local mx, my = TheInput:GetScreenPosition()` → mx=Vector3, my=nil
--     → 拿 Vector3 去减数字 → `vector3.lua:14 attempt to index local 'rhs' (a number value)` 每帧刷屏
function MushaItemInfo:FollowMouse()
    local pos = TheInput:GetScreenPosition()
    if pos == nil then return end
    local mx, my = pos.x or 0, pos.y or 0

    local half_w, half_h = RESOLUTION_X / 2, RESOLUTION_Y / 2
    local x = mx - half_w + 26 + W / 2
    local y = my - half_h + 18 + self.cur_h / 2
    if x + W / 2 > half_w - 12 then
        x = mx - half_w - 26 - W / 2
    end
    if y + self.cur_h / 2 > half_h - 12 then
        y = my - half_h - 18 - self.cur_h / 2
    end
    self:SetPosition(x, y)
end

-- 组装某个实体的信息行
local function Num(v)
    if v == nil then return nil end
    if v == math.floor(v) then return string.format("%d", v) end
    return string.format("%.2f", v)
end

function MushaItemInfo:BuildLines(inst)
    local prefab = inst.prefab
    local out = {}

    -- 名称
    local nm = prefab or "?"
    pcall(function()
        if inst.GetDisplayName then
            local s = inst:GetDisplayName()
            if s and s ~= "" then nm = s end
        end
    end)
    table.insert(out, { text = nm, colour = COL.name, size = 24 })

    if prefab and MushaItemStat then
        -- 伤害（红）
        --   ★ 预留接口：优先用"运行时算出来的最终伤害"（服务端权威，见 modmain 的 MushaGetLiveWeaponStats）；
        --     没有就走静态表的基础值（客户端读不到 weapon 组件的原因见文件头）
        local live = nil
        pcall(function()
            if MUSHA_LIVE_STATS and MUSHA_LIVE_STATS.get then
                live = MUSHA_LIVE_STATS.get(inst, ThePlayer)
            end
        end)
        if live and live.final then
            local txt = "伤害 " .. Num(live.final)
            if live.base and live.mult and live.mult ~= 1 then
                txt = txt .. string.format("（基础 %s ×%.2f）", Num(live.base), live.mult)
            end
            table.insert(out, { text = txt, colour = COL.dmg })
        else
            local dmg = MushaItemStat(prefab, "dmg")
            if dmg and dmg > 0 then
                table.insert(out, { text = "伤害 " .. Num(dmg), colour = COL.dmg })
            end
        end
        -- 位面伤害（紫）—— 原版裂隙/位面体系那套；weapon:GetDamage 的第二个返回值就是它
        local planar = (live and live.planar) or MushaItemStat(prefab, "planar")
        if planar and planar > 0 then
            table.insert(out, { text = "位面伤害 " .. Num(planar), colour = COL.planar })
        end
        -- 位面防御（淡紫）
        local pdef = MushaItemStat(prefab, "pdef")
        if pdef and pdef > 0 then
            table.insert(out, { text = "位面防御 " .. Num(pdef), colour = COL.pdef })
        end
        -- 保暖（淡白）
        local warm = MushaItemStat(prefab, "warm")
        if warm and warm > 0 then
            table.insert(out, { text = "保暖 " .. Num(warm), colour = COL.warm })
        end
        -- 隔热/防暑（淡蓝）
        local cool = MushaItemStat(prefab, "cool")
        if cool and cool > 0 then
            table.insert(out, { text = "隔热 " .. Num(cool), colour = COL.cool })
        end
        -- 宝藏值 / 能量回复（有就显示，没有就不显示 —— 以后加数据即可）
        local gold = MushaItemStat(prefab, "treasure")
        if gold and gold > 0 then
            table.insert(out, { text = "宝藏值 " .. Num(gold), colour = COL.gold })
        end
        local mp = MushaItemStat(prefab, "mp_regen")
        if mp and mp > 0 then
            table.insert(out, { text = "能量回复 " .. Num(mp), colour = COL.mp })
        end

        -- ── 2026-09-13 追加（对齐 Show Me 的信息面）──
        --   ⚠️ 客户端**没有** finiteuses / perishable / fueled 的 replica（已核实 components/ 里只有
        --      builder/combat/container/equippable/health/hunger/inventory/inventoryitem/stackable 等），
        --      所以下面是**上限/基础值**（静态表），不是"当前还剩多少"；要实时剩余值就得走服务端 RPC。
        -- 减伤（护甲 absorb；≤1 的按比例换算成 %）
        local absorb = MushaItemStat(prefab, "absorb")
        if absorb and absorb > 0 then
            local pct = absorb <= 1 and math.floor(absorb * 100 + 0.5) or math.floor(absorb * 100 + 0.5)
            table.insert(out, { text = "减伤 " .. pct .. "%", colour = COL.armor })
        end
        -- 食物三项
        local fh = MushaItemStat(prefab, "food_hunger")
        local fs = MushaItemStat(prefab, "food_sanity")
        local fl = MushaItemStat(prefab, "food_health")
        if (fh and fh ~= 0) or (fs and fs ~= 0) or (fl and fl ~= 0) then
            local seg = {}
            if fh and fh ~= 0 then table.insert(seg, "饥饿" .. (fh > 0 and "+" or "") .. Num(fh)) end
            if fs and fs ~= 0 then table.insert(seg, "理智" .. (fs > 0 and "+" or "") .. Num(fs)) end
            if fl and fl ~= 0 then table.insert(seg, "生命" .. (fl > 0 and "+" or "") .. Num(fl)) end
            table.insert(out, { text = "食物 " .. table.concat(seg, "  "), colour = COL.food })
        end
        -- 耐久上限
        local uses = MushaItemStat(prefab, "uses_max")
        if uses and uses > 0 then
            table.insert(out, { text = "耐久 最多 " .. Num(uses) .. " 次", colour = COL.dim })
        end
        -- 燃料上限
        local fuel = MushaItemStat(prefab, "fuel_max")
        if fuel and fuel > 0 then
            table.insert(out, { text = "燃料 上限 " .. Num(fuel), colour = COL.dim })
        end
        -- 新鲜时长（表里是秒 → 换算成天：DST 一天 480 秒）
        local perish = MushaItemStat(prefab, "perish_days")
        if perish and perish > 0 then
            table.insert(out, { text = string.format("新鲜 %.1f 天", perish / 480), colour = COL.dim })
        end
        -- 堆叠：这个有 replica，可以读**实时**的
        local st = inst.replica and inst.replica.stackable
        if st then
            local n, mx = nil, nil
            pcall(function() n = st:StackSize() end)
            pcall(function() mx = st:MaxSize() end)
            if n and mx and mx > 1 then
                table.insert(out, { text = string.format("堆叠 %d/%d", n, mx), colour = COL.dim })
            end
        end
    end

    return out
end

-- 鼠标下拿到"真实的物品实体"（背包格子里的 / 世界里的）
-- 目标必须是"实体"（有 IsValid 方法的 table）—— 2026-09-12：
--   日志实测 `:234: attempt to call method 'IsValid' (a nil value)`：
--   `TheInput:GetWorldEntityUnderMouse()` / HUD widget 链拿到的**不一定是实体**（可能是普通 table / nil）
--   → 直接 `target:IsValid()` 就炸，而且是每帧炸 → 面板永远 Show 不出来
local function IsEntity(t)
    return t ~= nil and type(t) == "table" and t.IsValid ~= nil
end

local function GetMouseTarget()
    -- 1) 先看 HUD（背包/装备栏格子里的物品）
    local t = nil
    pcall(function() t = TheInput:GetHUDEntityUnderMouse() end)
    if t ~= nil then
        local item = nil
        pcall(function()
            -- 沿 parent 链往上找 .item —— 背包格（ItemTile）和**装备栏格子**层次不同，
            -- 只认 widget.parent.item 会漏掉装备栏/手部格子里的物品（照 Show Me 那套的坑）
            local w = t.widget
            for _ = 1, 5 do
                if w == nil then break end
                if w.item ~= nil then
                    item = w.item
                    break
                end
                w = w.parent
            end
        end)
        if IsEntity(item) then return item end
    end
    -- 2) 再看世界里鼠标指着的东西
    t = nil
    pcall(function() t = TheInput:GetWorldEntityUnderMouse() end)
    if IsEntity(t) then return t end
    return nil
end

function MushaItemInfo:OnUpdate(dt)
    -- ★ 2026-09-12：整体套一层 pcall —— 悬停目标千奇百怪（HUD widget / 非实体 table / 已销毁实体），
    --   任何一处出错都只记一次日志，绝不让它每帧刷屏（上一版就是 target:IsValid() 炸成满屏）
    local ok, err = pcall(function() self:UpdateInfo() end)
    if not ok then
        if self.shown then self:Hide() self.shown = false end
        if not self._warn_once then
            self._warn_once = true
            print("[Musha] 悬停信息面板 OnUpdate 出错（只报一次）: " .. tostring(err))
        end
    end
end

function MushaItemInfo:UpdateInfo()
    -- 玩家有效性（原版客户端才有 HUD）
    local p = ThePlayer
    if not p or not p:IsValid() then
        if self.shown then self:Hide() self.shown = false end
        return
    end
    -- 是否限定 musha（见文件头 SHOW_FOR_ALL）
    if not SHOW_FOR_ALL and not p:HasTag("musha") then
        if self.shown then self:Hide() self.shown = false end
        return
    end

    -- 有别的界面开着就不显示（别挡着面板/箱子 UI）
    local scr = TheFrontEnd and TheFrontEnd:GetActiveScreen()
    if scr and scr.name ~= "HUD" then
        if self.shown then self:Hide() self.shown = false end
        return
    end

    local target = GetMouseTarget()
    if not IsEntity(target) or not target:IsValid() then
        if self.shown then self:Hide() self.shown = false end
        return
    end

    local lines = self:BuildLines(target)
    if #lines <= 1 then          -- 只有名字 → 没信息，不显示
        if self.shown then self:Hide() self.shown = false end
        return
    end

    self:SetLines(lines)
    self:PinBottomRight()
    self:Show()
    self.shown = true
end

return MushaItemInfo
