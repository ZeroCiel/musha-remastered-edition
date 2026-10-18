-- =============================================
-- musha_actions.lua
-- 自定义动作注册 + ComponentAction + Stategraph 处理器
-- =============================================

-- =============================================
-- 第12步：注册自定义动作
-- =============================================

print("[Musha Actions] 开始注册 AddAction...")
-- 动作1：使用职业书（INVENTORY 右键）
AddAction("MUSHA_USE_JOBBOOK", STRINGS.ACTIONS.MUSHA_USE_JOBBOOK, function(act)
    if act.invobject and act.invobject.components.musha_action then
        act.invobject.components.musha_action:UseItem(act.doer)
    end
    return true
end)

ACTIONS.MUSHA_USE_JOBBOOK.strfn = function(act)
    if act.doer and act.doer:HasTag("musha") then
        local career = act.doer.replica.musha_profession_component
            and act.doer.replica.musha_profession_component.cached_data
            and act.doer.replica.musha_profession_component.cached_data.mydata
            and act.doer.replica.musha_profession_component.cached_data.mydata.career_base
        if career then
            return STRINGS.ACTIONS.MUSHA_USE_JOBBOOK_STR["使用"]
        else
            return STRINGS.ACTIONS.MUSHA_USE_JOBBOOK
        end
    end
    return STRINGS.ACTIONS.MUSHA_USE_JOBBOOK
end
ACTIONS.MUSHA_USE_JOBBOOK.priority = 5
print("[Musha Actions] + AddAction MUSHA_USE_JOBBOOK")

-- 动作2：打开祭坛（SCENE 右键点击建筑）
--   ★ 2026-09-17 改名：原来叫 MUSHA_QUEST_INTERACT（"查看任务"），那时右键祭坛 = 直接接任务。
--     现在祭坛是【容器】：右键 = 打开祭坛 → 里面躺着转职卷轴 → 取出来再"展开卷轴"接任务。
AddAction("MUSHA_OPEN_ALTAR", STRINGS.ACTIONS.MUSHA_OPEN_ALTAR, function(act)
    if act.target and act.target.components.musha_action then
        act.target.components.musha_action:InteractScene(act.doer)
    end
    return true
end)
print("[Musha Actions] + AddAction MUSHA_OPEN_ALTAR")

-- 动作3：学习技能书（INVENTORY 右键）
AddAction("MUSHA_LEARN_SKILL", STRINGS.ACTIONS.MUSHA_LEARN_SKILL, function(act)
    if act.invobject and act.invobject.components.musha_action then
        act.invobject.components.musha_action:UseItem(act.doer)
    end
    return true
end)
print("[Musha Actions] + AddAction MUSHA_LEARN_SKILL")

-- 动作4：休息（INVENTORY 右键）
AddAction("MUSHA_REST", STRINGS.ACTIONS.MUSHA_REST, function(act)
    if act.invobject and act.invobject.components.musha_action then
        act.invobject.components.musha_action:UseItem(act.doer)
    end
    return true
end)
print("[Musha Actions] + AddAction MUSHA_REST")

-- 动作6：打开职业面板（INVENTORY 右键 — 转职后代替学习技能）
AddAction("MUSHA_OPEN_PANEL", STRINGS.ACTIONS.MUSHA_OPEN_PANEL, function(act)
    if act.invobject and act.invobject.components.musha_action then
        act.invobject.components.musha_action:UseItem(act.doer)
    end
    return true
end)
print("[Musha Actions] + AddAction MUSHA_OPEN_PANEL")

-- 动作5：阅读便签（INVENTORY 右键）
AddAction("MUSHA_READ_NOTE", STRINGS.ACTIONS.MUSHA_READ_NOTE, function(act)
    if act.invobject and act.invobject.components.musha_action then
        act.invobject.components.musha_action:UseItem(act.doer)
    end
    return true
end)
print("[Musha Actions] + AddAction MUSHA_READ_NOTE")

-- 动作7：展开卷轴（INVENTORY 右键 — 进阶祭坛里取出的【转职卷轴】）
--   ★ 2026-09-17 新增：祭坛改成"打开取卷轴"流程后，接任务这一步落在卷轴身上
AddAction("MUSHA_UNROLL_SCROLL", STRINGS.ACTIONS.MUSHA_UNROLL_SCROLL, function(act)
    if act.invobject and act.invobject.components.musha_action then
        act.invobject.components.musha_action:UseItem(act.doer)
    end
    return true
end)
print("[Musha Actions] + AddAction MUSHA_UNROLL_SCROLL")

-- 动作8：使用方向徽记（INVENTORY 右键 — 就职仪式发下来的【剑士徽记 / 近卫徽记】）
--   ★ 2026-09-18 新增：用掉一枚 = 选定进阶方向（不可逆），另一枚自动作废
--   逻辑全在 musha_profession_component:UseAdvanceCrest()（服务端权威）
AddAction("MUSHA_USE_CREST", STRINGS.ACTIONS.MUSHA_USE_CREST, function(act)
    if act.invobject and act.invobject.components.musha_action then
        act.invobject.components.musha_action:UseItem(act.doer)
    end
    return true
end)
print("[Musha Actions] + AddAction MUSHA_USE_CREST")

-- 动作9：摸信箱（SCENE 右键 — 第一次摸 = 绑定收件箱；之后 = 开/关自己的收件箱）
--   ★ 2026-09-19 新增（信箱 + 信差包）。逻辑在玩家身上的 components.musha_mail:UseMailbox()
AddAction("MUSHA_OPEN_MAILBOX", STRINGS.ACTIONS.MUSHA_OPEN_MAILBOX, function(act)
    if act.target and act.target.components.musha_action then
        act.target.components.musha_action:InteractScene(act.doer)
    end
    return true
end)
-- 动作2：右键物品自动放入信箱（INVENTORY 右键）
AddAction("MUSHA_PUT_MAILBOX", STRINGS.ACTIONS.MUSHA_PUT_MAILBOX, function(act)
    if act.invobject and act.doer and act.target then
        -- 检查目标是不是信箱
        if act.target:HasTag("musha_mailbox") or act.target.prefab == "musha_mailbox_shadow" then
            -- 检查物品能不能放进信箱
            local container = act.target.components.container
            if container and container:IsOpenedBy(act.doer) then
                -- 尝试把物品放进信箱：找第一个已解锁的空格（2026-10-18 收尾批）
                --   原 GetOpenSlotForItem 原版不存在（nil 调用报错）；与 musha_mail.lua
                --   PutItemToMailbox 同一修法：逐格 1..unlocked 找空格，GiveItem 显式带槽
                --   （itemtestfn 锁格照常；首个空格都放不进 = 这物品哪格都进不去）。
                local unlocked = math.min((act.target.unlocked or 3), container:GetNumSlots())
                for i = 1, unlocked do
                    if container:GetItemInSlot(i) == nil then
                        if container:GiveItem(act.invobject, i) then
                            return true
                        end
                        return false
                    end
                end
            end
        end
    end
    return false
end)

ACTIONS.MUSHA_PUT_MAILBOX.strfn = function(act)
    return STRINGS.ACTIONS.MUSHA_PUT_MAILBOX
end

print("[Musha Actions] + AddAction MUSHA_PUT_MAILBOX")

-- ★ 动作名动态化（照 MUSHA_USE_JOBBOOK 的 strfn 写法）：
--   ① 背包里带着【邮包升级套件】        → 「升级」
--   ② 已经绑定过收件箱                  → 「触摸（打开）」
--   ③ 还没绑定                          → 「触摸（绑定）」
--
-- ⚠️ ②③ 靠的是**职业组件已有的推送通道**：服务端在 PushSettings 里多塞了一个 d.mail.bound。
--    代价（用户 2026-09-19 拍板接受）：只有 musha 玩家有职业组件 → 其他角色的动作名退回纯「触摸」。
--    客户端读不到职业数据时也退回纯「触摸」，不会显示错的状态。
ACTIONS.MUSHA_OPEN_MAILBOX.strfn = function(act)
    local doer = act.doer
    local t = STRINGS.ACTIONS.MUSHA_OPEN_MAILBOX_STR
    local function S(key, dflt)
        return (t ~= nil and t[key]) or dflt
    end

    -- ⓪ 已经开着这块收件箱 → 显示「关闭」（用户 09-21：右键关闭的时候没有"关闭"这个字）
    local invr = doer ~= nil and doer.replica ~= nil and doer.replica.inventory or nil
    if invr ~= nil and invr.GetOpenContainers ~= nil then
        local ok, cs = pcall(function() return invr:GetOpenContainers() end)
        if ok and type(cs) == "table" then
            for container, _ in pairs(cs) do
                local ci = container ~= nil and container.inst or nil
                if ci ~= nil and ci:HasTag("musha_mail_shadow") then
                    return S("CLOSE", "触摸（关闭）")
                end
            end
        end
    end

    -- ① 带着升级套件
    local rep = doer ~= nil and doer.replica ~= nil and doer.replica.inventory or nil
    if rep ~= nil then
        for _, item in ipairs(rep:GetItems() or {}) do
            if item:HasTag("musha_mailkit") then
                return S("UPGRADE", "升级")
            end
        end
    end

    -- ②③ 绑定状态（从职业组件的推送数据里读）
    local pc = doer ~= nil and doer.replica ~= nil and doer.replica.musha_profession_component or nil
    local cd = pc ~= nil and pc.cached_data or nil
    local md = cd ~= nil and (cd.mydata or cd.userdata) or nil
    if md == nil then
        return STRINGS.ACTIONS.MUSHA_OPEN_MAILBOX          -- 读不到（非 musha 角色）→ 纯「触摸」
    end
    if md.mail ~= nil and md.mail.bound then
        return S("OPEN", "触摸（打开）")
    end
    return S("BIND", "触摸（绑定）")
end

-- 动作10：开/关 信差包（INVENTORY 右键）
--   ★ 2026-09-19 新增。关包那一刻由 container.onclosefn 触发寄件
AddAction("MUSHA_OPEN_MAILBAG", STRINGS.ACTIONS.MUSHA_OPEN_MAILBAG, function(act)
    if act.invobject and act.invobject.components.musha_action then
        act.invobject.components.musha_action:UseItem(act.doer)
    end
    return true
end)
print("[Musha Actions] + AddAction MUSHA_OPEN_MAILBAG")

-- 动作11：回城石 · 回家（INVENTORY 右键 — 背包里右键石头）
--   ★ 2026-09-20 新增。逻辑在 components/musha_recall.lua:Recall()
AddAction("MUSHA_RECALL_HOME", STRINGS.ACTIONS.MUSHA_RECALL_HOME, function(act)
    if act.invobject and act.invobject.components.musha_action then
        act.invobject.components.musha_action:UseItem(act.doer)
    end
    return true
end)
print("[Musha Actions] + AddAction MUSHA_RECALL_HOME")

-- 动作12：回城石 · 绑定（USEITEM — 拿在手上对着任何东西右键/左键点它）
--   ★ 2026-09-20 新增。逻辑在 components/musha_recall.lua:Bind()
AddAction("MUSHA_BIND_STONE", STRINGS.ACTIONS.MUSHA_BIND_STONE, function(act)
    local inst, doer, target = act.invobject, act.doer, act.target
    if inst ~= nil and inst.components.musha_recall ~= nil then
        inst.components.musha_recall:Bind(doer, target)
    end
    return true
end)
ACTIONS.MUSHA_BIND_STONE.mount_valid = true      -- 骑着牛也能绑
ACTIONS.MUSHA_BIND_STONE.priority = 2            -- 手里拿着石头时，优先"绑定"而不是目标自带的动作
print("[Musha Actions] + AddAction MUSHA_BIND_STONE")

-- 动作13：职业重置石（INVENTORY 右键 — 背包里右键 = 重置职业，从 0 级重来）
--   ★ 2026-09-29 新增（用户："出一个物品 重置职业用的，不开放任何制作条件"）
--   权限在 prefab 里判（作者 SteamID / 测试安全员 / 本地房主），改包绕不过
AddAction("MUSHA_RESET_JOB", STRINGS.ACTIONS.MUSHA_RESET_JOB, function(act)
    if act.invobject and act.invobject.components.musha_action then
        act.invobject.components.musha_action:UseItem(act.doer)
    end
    return true
end)
print("[Musha Actions] + AddAction MUSHA_RESET_JOB")

print("[Musha Actions] 动作注册完成，开始注册 ComponentAction...")

-- =============================================
-- 第13步：注册 ComponentAction（注册动作触发条件）
-- =============================================

-- INVENTORY 动作（靠 tag 区分，整合为 1 个回调避免覆盖）
AddComponentAction("INVENTORY", "musha_action", function(inst, doer, actions, right)
    if inst:HasTag("musha_jobbook") then
        table.insert(actions, ACTIONS.MUSHA_USE_JOBBOOK)
    end
    if inst:HasTag("musha_learnable") then
        table.insert(actions, ACTIONS.MUSHA_LEARN_SKILL)
    end
    if inst:HasTag("musha_rest_skill") then
        table.insert(actions, ACTIONS.MUSHA_REST)
    end
    if inst:HasTag("musha_note") then
        table.insert(actions, ACTIONS.MUSHA_READ_NOTE)
    end
    if inst:HasTag("musha_panel") then
        table.insert(actions, ACTIONS.MUSHA_OPEN_PANEL)
    end
    if inst:HasTag("musha_scroll") then
        table.insert(actions, ACTIONS.MUSHA_UNROLL_SCROLL)
    end
    -- ★ 2026-09-18：进阶方向徽记（用掉一枚 = 选定方向）
    if inst:HasTag("musha_crest") then
        table.insert(actions, ACTIONS.MUSHA_USE_CREST)
    end
    -- ★ 2026-09-19：信差包（右键开/关；关包 → 寄件）
    if inst:HasTag("musha_mailbag") then
        table.insert(actions, ACTIONS.MUSHA_OPEN_MAILBAG)
    end
    -- ★ 2026-09-20：回城石（背包右键 = 回家）
    if inst:HasTag("musha_recall_stone") then
        table.insert(actions, ACTIONS.MUSHA_RECALL_HOME)
    end
    -- ★ 2026-09-29：职业重置石（背包右键 = 重置职业，测试道具）
    if inst:HasTag("musha_reset_job") then
        table.insert(actions, ACTIONS.MUSHA_RESET_JOB)
    end
end)
print("[Musha Actions] + ComponentAction INVENTORY musha_action (整合: musha_jobbook/musha_learnable/musha_rest_skill/musha_note/musha_panel/musha_scroll/musha_crest/musha_mailbag/musha_recall_stone/musha_reset_job)")

-- SCENE 动作
AddComponentAction("SCENE", "musha_action", function(inst, doer, actions, right)
    if inst:HasTag("musha_altar") then
        table.insert(actions, ACTIONS.MUSHA_OPEN_ALTAR)
    end
    -- ★ 2026-09-19：信箱（第一次摸=绑定；之后=开/关收件箱）
    if inst:HasTag("musha_mailbox") then
        table.insert(actions, ACTIONS.MUSHA_OPEN_MAILBOX)
    end
end)
print("[Musha Actions] + ComponentAction SCENE musha_action → musha_altar / musha_mailbox")

-- USEITEM 动作（★ 2026-09-20 回城石：拿在手上对着目标用 = 绑定）
--   ⚠️ 只挂我们自己的 musha_action 组件，绝不去挂原版组件（见 skill 的 AddComponentAction 规矩）
--   签名：function(inst, doer, target, actions, right)  inst = 手里那件物品
AddComponentAction("USEITEM", "musha_action", function(inst, doer, target, actions, right)
    if inst:HasTag("musha_recall_stone") and target ~= nil and target ~= doer then
        table.insert(actions, ACTIONS.MUSHA_BIND_STONE)
    end
end)
print("[Musha Actions] + ComponentAction USEITEM musha_action → musha_recall_stone（绑定）")

print("[Musha Actions] ComponentAction 注册完成，开始注册 Stategraph...")

-- =============================================
-- 第14步：注册 Stategraph 动作处理器
-- =============================================

-- 职业书 INVENTORY 右键
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MUSHA_USE_JOBBOOK, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MUSHA_USE_JOBBOOK, "doshortaction"))
print("[Musha Actions] + Stategraph MUSHA_USE_JOBBOOK")

-- 进阶建筑 SCENE 右键（打开祭坛）
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MUSHA_OPEN_ALTAR, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MUSHA_OPEN_ALTAR, "doshortaction"))
print("[Musha Actions] + Stategraph MUSHA_OPEN_ALTAR")

-- 技能书 INVENTORY 右键
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MUSHA_LEARN_SKILL, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MUSHA_LEARN_SKILL, "doshortaction"))
print("[Musha Actions] + Stategraph MUSHA_LEARN_SKILL")

-- 休息 INVENTORY 右键
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MUSHA_REST, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MUSHA_REST, "doshortaction"))
print("[Musha Actions] + Stategraph MUSHA_REST")

-- 便签 INVENTORY 右键
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MUSHA_READ_NOTE, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MUSHA_READ_NOTE, "doshortaction"))
print("[Musha Actions] + Stategraph MUSHA_READ_NOTE")

-- 转职卷轴 INVENTORY 右键（展开卷轴）
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MUSHA_UNROLL_SCROLL, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MUSHA_UNROLL_SCROLL, "doshortaction"))
print("[Musha Actions] + Stategraph MUSHA_UNROLL_SCROLL")

-- 职业面板 INVENTORY 右键
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MUSHA_OPEN_PANEL, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MUSHA_OPEN_PANEL, "doshortaction"))
print("[Musha Actions] + Stategraph MUSHA_OPEN_PANEL")

-- 方向徽记 INVENTORY 右键（用掉 = 选定进阶方向）
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MUSHA_USE_CREST, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MUSHA_USE_CREST, "doshortaction"))
print("[Musha Actions] + Stategraph MUSHA_USE_CREST")

-- 信箱 SCENE 右键（摸一下）
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MUSHA_OPEN_MAILBOX, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MUSHA_OPEN_MAILBOX, "doshortaction"))
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MUSHA_PUT_MAILBOX, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MUSHA_PUT_MAILBOX, "doshortaction"))
print("[Musha Actions] + Stategraph MUSHA_OPEN_MAILBOX")
print("[Musha Actions] + Stategraph MUSHA_PUT_MAILBOX")

-- 信差包 INVENTORY 右键（开 / 关）
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MUSHA_OPEN_MAILBAG, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MUSHA_OPEN_MAILBAG, "doshortaction"))
print("[Musha Actions] + Stategraph MUSHA_OPEN_MAILBAG")

-- 回城石 INVENTORY 右键（回家）
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MUSHA_RECALL_HOME, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MUSHA_RECALL_HOME, "doshortaction"))
print("[Musha Actions] + Stategraph MUSHA_RECALL_HOME")

-- 回城石 USEITEM（拿着石头对目标用 = 绑定）
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MUSHA_BIND_STONE, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MUSHA_BIND_STONE, "doshortaction"))
print("[Musha Actions] + Stategraph MUSHA_BIND_STONE")

-- 职业重置石 INVENTORY 右键（★ 2026-09-29 新增）
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MUSHA_RESET_JOB, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MUSHA_RESET_JOB, "doshortaction"))
print("[Musha Actions] + Stategraph MUSHA_RESET_JOB")

print("[Musha Actions] ✅ 全部动作注册完成")
