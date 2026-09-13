-- =====================================================
-- musha_advance_altar.lua — 进阶祭坛（2026-09-12 新建）
-- 作用：接取【转职任务】（3 轮，第 3 轮完成 → 进阶）
-- 交互链：SCENE 右键 → MUSHA_QUEST_INTERACT
--          → musha_action:InteractScene(doer)
--          → modmain 里 AddPrefabPostInit 绑定的 OnAltarInteract
--
-- ★★★ 模型移植点（唯一需要改的地方）★★★
--   当前占位 = 复用原版麦斯威尔雕像动画（与旧版 statuemaxwell 占位视觉一致）。
--   移植新模型时只改下面 3 个常量 + assets 表里的 2 个路径，其余不用动：
--     1) 把 anim/musha_advance_altar.zip(+build) 放进 mod 的 anim/ 目录
--     2) ALTAR_BANK / ALTAR_BUILD 改成新 zip 里的 bank / build 名
--     3) assets 里两个 Asset("ANIM", ...) 换成新路径，删掉原版雕像那两行
--   （bank/build 名 = 导出时 Spriter 工程名 / 编译后 anim.bin 里的 build 名，
--     不对的话游戏会 assert "Could not find bank/build"）
-- =====================================================

-- ===== 动画绑定（空间绑定）=====
local ALTAR_BANK  = "statue_maxwell"        -- AnimState:SetBank  —— 占位=原版雕像
local ALTAR_BUILD = "statue_maxwell_build"  -- AnimState:SetBuild —— 占位=原版雕像贴图
local ALTAR_ANIM  = "idle_full"             -- 默认播放的动画

local assets =
{
    -- 占位资源（原版游戏 data/anim/ 里就有，可直接引用）
    Asset("ANIM", "anim/statue_maxwell.zip"),
    Asset("ANIM", "anim/statue_maxwell_build.zip"),
    -- 移植模型后换成：
    -- Asset("ANIM", "anim/musha_advance_altar.zip"),
    -- Asset("ANIM", "anim/musha_advance_altar_build.zip"),
}

local prefabs = {}

local function displaynamefn(inst)
    return STRINGS.NAMES.MUSHA_ADVANCE_ALTAR or "进阶祭坛"
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    -- 占位体积（"空间"）：1.1 半径，玩家绕不开、可怼着点
    MakeObstaclePhysics(inst, 1.1)

    -- 动画绑定：bank 提供动画骨骼，build 提供贴图
    inst.AnimState:SetBank(ALTAR_BANK)
    inst.AnimState:SetBuild(ALTAR_BUILD)
    inst.AnimState:PlayAnimation(ALTAR_ANIM)

    -- ★ tag 必须在 SetPristine() 之前加：客户端也要有这个 tag，
    --   否则客机右键不出 MUSHA_QUEST_INTERACT（旧版占位就吃了这个亏）
    inst:AddTag("musha_altar")
    -- 注：不加 "structure" tag —— 会被 Deerclops 当建筑砸，而祭坛不该被破坏

    inst.displaynamefn = displaynamefn

    -- ★ 组件同样在 pristine 之前加：SCENE 的 AddComponentAction 靠它在客户端收集动作
    inst:AddComponent("musha_action")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- ===== 服务端专用 =====
    inst:AddComponent("inspectable")
    -- 注：动作回调（SetFn / SetCanUseCheck）在 modmain 的 AddPrefabPostInit 里绑定，
    --     因为 OnAltarInteract 要用到 modmain 作用域的任务池 / 职业组件

    return inst
end

-- ===== 放置预览（配方摆放时显示的"幽灵"）=====
-- 2026-09-12 加：祭坛现在有配方了（modmain 里 AddRecipe2），需要 placer 才能摆放。
-- MakePlacer 是 prefabutil 里的原版全局函数；万一取不到也不影响祭坛本体（只是没预览）。
local placer = nil
pcall(function()
    placer = MakePlacer("musha_advance_altar_placer", ALTAR_BANK, ALTAR_BUILD, ALTAR_ANIM)
end)

return Prefab("musha_advance_altar", fn, assets, prefabs), placer
