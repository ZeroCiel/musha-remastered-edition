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
end)
print("[Musha Actions] + ComponentAction INVENTORY musha_action (整合: musha_jobbook/musha_learnable/musha_rest_skill/musha_note/musha_panel/musha_scroll)")

-- SCENE 动作
AddComponentAction("SCENE", "musha_action", function(inst, doer, actions, right)
    if inst:HasTag("musha_altar") then
        table.insert(actions, ACTIONS.MUSHA_OPEN_ALTAR)
    end
end)
print("[Musha Actions] + ComponentAction SCENE musha_action → musha_altar → MUSHA_OPEN_ALTAR")

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

print("[Musha Actions] ✅ 全部动作注册完成")
