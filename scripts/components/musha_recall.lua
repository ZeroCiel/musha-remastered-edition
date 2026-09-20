-- ============================================================
-- musha_recall.lua（组件）— 回城石：绑定 / 回家 / 次数 / 冷却
--   2026-09-20 新建。用户需求原文：
--     "做一个回城石，绑定于任何单位之上，只要这个东西还存在，
--      我就可以通过右键石头回家。冷却 360 秒，可以使用 3 次，
--      3 次之后自动移除。配方 红宝石/绿宝石 + 2 个金子。"
--
--   ★★ 为什么逻辑必须写在「组件」里：
--      DST **不保存物品上的裸字段**（inst.xxx = ... 掉线重进就丢），
--      物品级的持久化只有一条路 = 组件 OnSave/OnLoad（原版 linkeditem 就是这么干的）。
--   ★★ 绑定目标是「实体」→ 存 GUID：
--      · 读档时靠 组件 LoadPostPass(newents) 把 GUID 换回实体
--      · 传送时取目标的**当前位置** → 目标会动（比如绑的是玩家/牛）就跟着动
--   ★ 服务器上所有实体都在 Ents 里（不受 15 格加载范围限制）→ 可做兜底查找
-- ============================================================

local COOLDOWN  = 360      -- 冷却（秒）
local MAX_USES  = 3        -- 可用次数；用完石头自毁

-- ★ 冷却的「表现」交给原版 rechargeable 组件（prefab 里挂上）：
--     · 物品栏 / 背包 / 快捷栏图标自动出现深蓝扇形遮罩，360 秒慢慢转满，转满播 frame_pst
--     · 跟沃尔特回旋镖、沃尔特盾、旺达怀表同一套（客机也能看到，不需要自己做动画）
--   本文件只负责「能不能用」的判断；rechargeable 自己存档，所以旧的 cooldown_end 字段
--   只作为「组件没挂上」时的兜底 + 老档迁移用。
local function RC(inst)
    return inst ~= nil and inst.components.rechargeable or nil
end

local function StartCooldown(self)
    local r = RC(self.inst)
    if r ~= nil then
        r:Discharge(COOLDOWN)     -- current 归 0，并按 COOLDOWN 秒自动回充
        self.cooldown_end = nil   -- 不留双份计时（省得两份数据打架）
    else
        self.cooldown_end = GetTime() + COOLDOWN
    end
end

local MushaRecall = Class(function(self, inst)
    self.inst = inst

    -- 存档字段（OnSave 写、OnLoad 读）
    self.bound_guid  = nil     -- 绑定目标 GUID
    self.bound_name  = nil     -- 绑定时记下的名字（提示用）
    self.bound_x     = nil     -- 最后一次已知坐标（目标丢了也还能提示在哪儿）
    self.bound_y     = nil
    self.bound_z     = nil
    self.bound_shard = nil     -- 绑定时所在分片（地面/洞穴）
    self.uses_left   = MAX_USES
    self.cooldown_end = 0

    -- 运行时（不存档）
    self.bound_inst  = nil     -- LoadPostPass / 兜底查找到的实体
end)

function MushaRecall:IsServer()
    return TheWorld ~= nil and TheWorld.ismastersim
end

local function Say(doer, s)
    if doer ~= nil and doer:IsValid() and doer.components.talker ~= nil then
        doer.components.talker:Say(s, 4)
    end
end

-- 按 GUID 找实体（服务器上 Ents 装着全部实体，不受加载范围限制）
local function FindEntityByGUID(guid)
    if guid == nil then return nil end
    local ents = Ents                          -- 原版全局（mainfunctions.lua 也用这个）
    local e = ents ~= nil and ents[guid] or nil
    if e ~= nil and e:IsValid() then return e end
    return nil
end

local function ShardID()
    local s = TheShard
    if s == nil or s.GetShardId == nil then return nil end
    local ok, id = pcall(function() return s:GetShardId() end)
    return ok and id or nil
end

-- ---------- 查询 ----------

function MushaRecall:GetCooldownLeft()
    local r = RC(self.inst)
    if r ~= nil then
        return r:GetTimeToCharge()          -- 0 = 冷却好了
    end
    local left = (self.cooldown_end or 0) - GetTime()
    return left > 0 and left or 0
end

-- 绑定的那个东西现在还找得到吗？找得到就返回实体，找不到返回 nil
function MushaRecall:GetTarget()
    local t = self.bound_inst
    if t ~= nil and t:IsValid() and not t:IsInLimbo() then
        return t
    end
    t = FindEntityByGUID(self.bound_guid)
    if t ~= nil and not t:IsInLimbo() then
        self.bound_inst = t
        return t
    end
    return nil
end

function MushaRecall:GetStatusText()
    local t = self:GetTarget()
    local s = (t ~= nil) and ("绑定：" .. tostring(self.bound_name or "?")) or "未绑定"
    return string.format("%s 次数=%d 冷却=%.0f", s, self.uses_left or 0, self:GetCooldownLeft())
end

-- ---------- 绑定（拿在手上，对着任何东西用）----------
--   · 可以换绑（覆盖旧的）
--   · **不重置**次数与冷却（防刷）
function MushaRecall:Bind(doer, target)
    if not self:IsServer() then return false end
    if target == nil or not target:IsValid() then
        Say(doer, "（这里没有可绑的东西）")
        return false
    end
    if target == self.inst then return false end          -- 别绑自己

    local x, y, z = target.Transform:GetWorldPosition()
    local name = nil
    pcall(function() name = target:GetDisplayName() end)
    if name == nil or name == "" then
        name = STRINGS.NAMES[string.upper(target.prefab or "")] or target.prefab or "那个东西"
    end

    self.bound_guid  = target.GUID
    self.bound_inst  = target
    self.bound_name  = name
    self.bound_x, self.bound_y, self.bound_z = x, y, z
    self.bound_shard = ShardID()

    Say(doer, "（记住了 —— 家就在「" .. name .. "」那儿。之后右键这块石头就能回去）")
    print("[Musha] 回城石绑定：" .. tostring(name) .. " (" .. tostring(target.prefab)
        .. " / GUID=" .. tostring(target.GUID) .. ")")
    return true
end

-- ---------- 回家（背包里右键石头）----------

function MushaRecall:Recall(doer)
    if not self:IsServer() then return false end
    local inst = self.inst
    if doer == nil or not doer:IsValid() then return false end

    if (self.uses_left or 0) <= 0 then
        Say(doer, "（这块石头已经没劲了）")
        return false
    end

    local cd = self:GetCooldownLeft()
    if cd > 0 then
        Say(doer, "（石头还烫着……还要 " .. math.ceil(cd) .. " 秒）")
        return false
    end

    if self.bound_guid == nil then
        Say(doer, "（还没绑过 —— 手上拿着它，对着想回去的地方用一下）")
        return false
    end

    local target = self:GetTarget()
    if target == nil then
        local where = ""
        if self.bound_shard ~= nil and ShardID() ~= self.bound_shard then
            where = "（它好像不在这个世界了）"
        end
        Say(doer, "（绑的「" .. tostring(self.bound_name or "那个东西") .. "」已经不在了）" .. where)
        return false
    end

    -- 落点：优先目标身边能站人的地（找不到就落它脚下）
    --   ⚠️ FindWalkableOffset 签名（simutil.lua:329）：
    --      (position, start_angle, radius, attempts, check_los, ignore_walls, ...)
    --      原版都是 (pos, 随机角, 半径, 8, true, false) → 视线要通、不穿墙
    local x, y, z = target.Transform:GetWorldPosition()
    local pt = Vector3(x, y, z)
    pcall(function()
        local offset = FindWalkableOffset(pt, math.random() * TWOPI, 3, 12, true, false)
        if offset ~= nil then pt = pt + offset end
    end)

    if doer.components.locomotor ~= nil then
        doer.components.locomotor:StopMoving()
    end
    if doer.components.rider ~= nil and doer.components.rider:IsRiding() then
        doer.components.rider:ActualDismount()
    end

    local ex, ey, ez = pt:Get()
    doer.Transform:SetPosition(ex, ey, ez)

    self.uses_left = (self.uses_left or MAX_USES) - 1
    StartCooldown(self)

    if self.uses_left <= 0 then
        Say(doer, "（到家了……石头也跟着碎了）")
        print("[Musha] 回城石：次数用尽，自动移除")
        inst:Remove()
    else
        Say(doer, "（到家了 —— 这块石头还能用 " .. self.uses_left .. " 次）")
        print("[Musha] 回城石回家成功（剩余 " .. self.uses_left .. " 次，冷却 " .. COOLDOWN .. "s）")
    end
    return true
end

-- ---------- 存档 ----------

function MushaRecall:OnSave()
    -- 全新石头且没绑过 → 不写存档（保持存档干净）
    if self.bound_guid == nil and (self.uses_left or MAX_USES) >= MAX_USES
        and (self.cooldown_end or 0) <= GetTime() then
        return nil
    end
    return {
        bound_guid  = self.bound_guid,
        bound_name  = self.bound_name,
        bound_x     = self.bound_x,
        bound_y     = self.bound_y,
        bound_z     = self.bound_z,
        bound_shard = self.bound_shard,
        uses_left   = self.uses_left,
        cooldown_end = self.cooldown_end,
    }
end

function MushaRecall:OnLoad(data)
    if data == nil then return end
    self.bound_guid  = data.bound_guid
    self.bound_name  = data.bound_name
    self.bound_x     = data.bound_x
    self.bound_y     = data.bound_y
    self.bound_z     = data.bound_z
    self.bound_shard = data.bound_shard
    self.uses_left   = data.uses_left or MAX_USES
    self.cooldown_end = data.cooldown_end or 0

    -- 老档迁移：以前冷却记在自研字段里 → 换算成 rechargeable 的剩余回充时间
    local r = RC(self.inst)
    if r ~= nil then
        local left = (self.cooldown_end or 0) - GetTime()
        if left > 0 then
            r:Discharge(math.max(1, math.ceil(left)))
        end
        self.cooldown_end = nil
    end
end

-- 读档后所有实体都在了 → 把绑定的 GUID 换回实体
function MushaRecall:LoadPostPass(newents, data)
    if data == nil or data.bound_guid == nil or newents == nil then return end
    local rec = newents[data.bound_guid]
    self.bound_inst = rec ~= nil and rec.entity or nil
end

function MushaRecall:GetDebugString()
    return self:GetStatusText()
end

return MushaRecall
