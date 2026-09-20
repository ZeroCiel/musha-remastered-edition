-- ============================================================
-- musha_maillevel.lua —— 收件箱「已解锁格数」的组件 + 网络同步
--   2026-09-21 新建。用户口径：「容器图一旦要改变，必须从组件里改，还得是 replica」
--
--   ★ 为什么必须是"组件 + 网络变量"：
--     · 未解锁格的叉号底图（slotbg）在 containers.lua 里是**静态表**（按初始 3 格写死），
--       客户端不知道"这个人解锁到第几格" → 升级到 5/7/9/12 之后叉号不会跟着退。
--     · DST 的 replica 是**白名单制**（entityreplica.lua 的 REPLICATABLE_COMPONENTS 只认
--       builder/container/health/… 这几个官方名字，第三方组件名进不去）→ 所以这里的做法是：
--       组件**双端都挂**（prefab 的 SetPristine 之前 AddComponent），构造函数里建 net_smallbyte，
--       **只有服务端能 set**，客户端直接读 → 等价于一个自制 replica。
--
--   用法：
--     服务端：inst.components.musha_maillevel:SetUnlocked(7)      -- 升级/建档时
--     客户端：inst.components.musha_maillevel:GetUnlocked()        -- 同步过来的值（读不到时给 3）
--   客户端消费方：modmain 里 AddClassPostConstruct("widgets/containerwidget") 按它重填槽底图
-- ============================================================

local MushaMailLevel = Class(function(self, inst)
    self.inst = inst
    -- 双端都要建（GUID + 名字一致才能同步）；值只有服务端能改
    self.unlocked = net_smallbyte(inst.GUID, "musha_mailbox.unlocked", "musha_mailbox_unlocked_dirty")
end)

function MushaMailLevel:SetUnlocked(n)
    if not TheWorld.ismastersim then return end          -- 只有服务端能改
    n = math.clamp(math.floor(n or 3), 1, 12)
    self.unlocked:set(n)
    self.inst.unlocked = n                               -- 兼容：itemtestfn / 别处还在读 inst.unlocked
    self.inst:PushEvent("musha_maillevel_changed", { unlocked = n })
end

function MushaMailLevel:GetUnlocked()
    local v = self.unlocked:value()
    -- 0 / nil = 还没同步到（客户端首帧）→ 退回初始 3 格
    if v == nil or v <= 0 then return 3 end
    return v
end

function MushaMailLevel:GetDebugString()
    return "unlocked=" .. tostring(self:GetUnlocked())
end

return MushaMailLevel
