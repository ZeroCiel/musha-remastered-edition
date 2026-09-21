-- ============================================================
-- musha_maillevel.lua —— 收件箱「已解锁格数」的组件 + 网络同步 + 换容器档位
--   2026-09-21 新建（同日晚按崩溃日志重做一版）。用户口径：
--     「容器图一旦要改变，必须从组件里改，还得是 replica」
--
--   ★ 这组件干三件事：
--     1) 存"解锁到第几格"（netvar 同步给客机）
--     2) 服务端：换档时 `container:WidgetSetup("musha_mailbox_shadow_u7")`
--        —— params 里按 prefab 名 + 档位生成了 5 张表（见 scripts/musha_containers.lua）
--           widget 一换，slotbg（叉号底图）自动跟着变，不需要自己去改格子
--     3) 客机：档位同步过来后，对 `inst.replica.container` 做同样的 WidgetSetup
--        （= 原版 firepit.lua:131「prefaboverride」那套写法：
--           netvar 变化 → replica.container:WidgetSetup(名字)）
--
--   ⚠️ 为什么不用官方 replica 名：
--      DST 的 replica 是**白名单制**（entityreplica.lua 的 REPLICATABLE_COMPONENTS 只认
--      builder/container/health/… 官方名）→ 第三方组件名进不去。所以本组件**双端都挂**
--      （prefab 的 SetPristine 之前 AddComponent），构造函数里建 net_smallbyte：
--      只有服务端 set，客机直接读 —— 等价于一个自制 replica。
--      （实例证据：崩溃日志里客机上构造的实体 `GUID = 100116 / Network = ...` 都是齐的，
--        说明 pristine 阶段 GUID 已可用，netvar 建得出来。）
-- ============================================================

-- 档位 → 容器参数表名（= musha_containers.lua 里的 key，必须一字不差）
local TIER_WIDGET = {
    [3]  = "musha_mailbox_shadow",
    [5]  = "musha_mailbox_shadow_u5",
    [7]  = "musha_mailbox_shadow_u7",
    [9]  = "musha_mailbox_shadow_u9",
    [12] = "musha_mailbox_shadow_u12",
}

-- 取"不大于 n 的最大档"（万一存档里是 11 这种非标准值，也要能落到 9 档而不是报 nil）
local function WidgetNameFor(n)
    n = n or 3
    local best, bestn = TIER_WIDGET[3], -1
    for k, v in pairs(TIER_WIDGET) do
        if k <= n and k > bestn then
            best, bestn = v, k
        end
    end
    return best
end

local MushaMailLevel = Class(function(self, inst)
    self.inst = inst
    -- 双端都要建（GUID + 名字一致才能同步）；值只有服务端能改
    self.unlocked = net_smallbyte(inst.GUID, "musha_mailbox.unlocked", "musha_mailbox_unlocked_dirty")

    if not TheWorld.ismastersim then
        -- 客机：档位一变就把 replica 的容器参数换到对应档（叉号格才对）
        --   ⚠️ 首帧 netvar 可能还没同步到（读出来是 0 → 会先套 3 格那套）
        --   → 除了监听 dirty，还在 0 / 1 / 3 秒各补一次（幂等，多调无害）
        local function try_apply(i)
            if i ~= nil and i:IsValid() and i.components.musha_maillevel ~= nil then
                i.components.musha_maillevel:ApplyWidget()
            end
        end
        inst:ListenForEvent("musha_mailbox_unlocked_dirty", function() inst:DoTaskInTime(0, try_apply) end)
        for _, t in ipairs({ 0, 1, 3 }) do
            inst:DoTaskInTime(t, try_apply)
        end
    end
end)

-- 把当前档位对应的容器参数套上去（服务端换 container / 客机换 replica）
function MushaMailLevel:ApplyWidget()
    local name = WidgetNameFor(self:GetUnlocked())
    local inst = self.inst
    if TheWorld.ismastersim then
        if inst.components.container ~= nil then
            inst.components.container:WidgetSetup(name)
        end
    elseif inst.replica ~= nil and inst.replica.container ~= nil then
        inst.replica.container:WidgetSetup(name)
    end
end

function MushaMailLevel:SetUnlocked(n)
    if not TheWorld.ismastersim then return end          -- 只有服务端能改
    n = math.clamp(math.floor(n or 3), 1, 12)
    self.unlocked:set(n)
    self.inst.unlocked = n                               -- 兼容：itemtestfn / 别处还在读 inst.unlocked
    self:ApplyWidget()                                   -- 顺带把容器档位换成对应那张表
    self.inst:PushEvent("musha_maillevel_changed", { unlocked = n })
end

function MushaMailLevel:GetUnlocked()
    local v = self.unlocked:value()
    -- 0 / nil = 还没同步到（客机首帧）→ 退回初始 3 格
    if v == nil or v <= 0 then return 3 end
    return v
end

function MushaMailLevel:GetDebugString()
    return "unlocked=" .. tostring(self:GetUnlocked())
end

return MushaMailLevel
