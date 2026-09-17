-- =====================================================
-- musha_advance_altar.lua — 进阶祭坛（2026-09-12 新建 · 2026-09-17 改成"开坛取卷轴"）
-- 作用：**装**转职任务的容器（3 轮，第 3 轮完成 → 进阶）
-- 交互链（2026-09-17 改版）：
--   右键 → MUSHA_OPEN_ALTAR（"打开祭坛"）→ musha_action:InteractScene
--        → 本文件里绑的 SetFn → 打开本祭坛的【容器】（1 格）
--        → 里面躺着【转职卷轴 musha_advance_scroll】→ 取出 → 右键卷轴"展开" → 接取本轮任务
--   ⚠️ 容器本体（container 组件 + WidgetSetup + 开/关动作）就写在本文件里（照 Musha-beta 的写法：
--      musha_building_forge / arrowrest / icebox = 建筑自己带容器）；参数表在 scripts/musha_containers.lua，
--      modmain 只提供补卷/接取两个 GLOBAL 函数（跨文件用）
--
-- ★★★ 模型开关（唯一需要动的地方）★★★
--   贴图+scml 已经做好了，在 exported/musha_advance_altar/（打包步骤见那个目录的 README.txt）：
--     musha_advance_altar.scml             Spriter 工程（单帧 idle）
--     musha_advance_altar-0.png            贴图帧（320x320，原点=图正中心）
--   打包好两个 zip 放进 mods/musha/anim/ 之后，**只把下面这行改 true** 就换模型了。
local USE_CUSTOM_MODEL = true           -- 2026-09-14 用户已打包 anim/musha_advance_altar.zip → 开

-- ===== 动画绑定（空间绑定）=====
--   ⚠️ 名字对不上就 assert。本项目自己的 zip 是**一个包装齐** anim.bin+atlas+build.bin
--      （看 anim/musha_jobbook_warrior.zip）→ bank 名 = build 名 = zip 名 ✓
--      原版雕像那种"bank.zip + build.zip"分开的写法只在引用原版资源时用。
local ALTAR_BANK  = USE_CUSTOM_MODEL and "musha_advance_altar" or "statue_maxwell"
local ALTAR_BUILD = USE_CUSTOM_MODEL and "musha_advance_altar" or "statue_maxwell_build"
local ALTAR_ANIM  = USE_CUSTOM_MODEL and "idle"              or "idle_full"
local ALTAR_SCALE = 1.0                 -- 进游戏嫌大/嫌小就改这个（1.0=原始，0.8=缩两成）

local assets = USE_CUSTOM_MODEL and
{
    Asset("ANIM", "anim/musha_advance_altar.zip"),
} or
{
    -- 占位资源（原版游戏 data/anim/ 里就有，可直接引用）—— 这个才是分开两个包的
    Asset("ANIM", "anim/statue_maxwell.zip"),
    Asset("ANIM", "anim/statue_maxwell_build.zip"),
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

    -- 大小微调：改文件头的 ALTAR_SCALE 就行，别动贴图（1.0 = 原始大小）
    if ALTAR_SCALE ~= 1 then
        inst.Transform:SetScale(ALTAR_SCALE, ALTAR_SCALE, ALTAR_SCALE)
    end

    -- ★ tag 必须在 SetPristine() 之前加：客户端也要有这个 tag，
    --   否则客机右键不出 MUSHA_OPEN_ALTAR（旧版占位就吃了这个亏）
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

    -- ★ 容器（右键"打开祭坛"开的就是它）
    --   参数在 scripts/musha_containers.lua；写法照 **Musha-beta**：
    --   建筑自己的 prefab 里 AddComponent("container") + WidgetSetup(参数名)
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("musha_advance_altar")
    inst.components.container.onopenfn = function(altar, data)
        -- ⚠️ onopenfn 第 2 个参数是 { doer = doer } 这张表，不是 doer 本人（原版 container.lua:659）
        --    补卷逻辑在 modmain 的祭坛段（要查职业/任务状态），这里只负责转交
        local refill = GLOBAL.MUSHA_AltarRefillScroll
        if type(refill) == "function" then
            refill(altar, data and data.doer or nil)
        elseif not altar._warned_no_refill then
            altar._warned_no_refill = true
            print("[Musha ERROR] musha_advance_altar: 取不到 GLOBAL.MUSHA_AltarRefillScroll（modmain 祭坛段没跑？）")
        end
    end

    -- 右键祭坛 = 开 / 关容器（动作 MUSHA_OPEN_ALTAR → musha_action:InteractScene → 这里）
    inst.components.musha_action:SetFn(function(altar, doer)
        if doer == nil or not doer:IsValid() then return end
        local c = altar.components.container
        if c == nil then return end
        if c:IsOpenedBy(doer) then
            c:Close(doer)
        else
            c:Open(doer)
        end
    end)
    inst.components.musha_action:SetCanUseCheck(function(_, doer)
        return doer ~= nil and doer:IsValid() and doer.components.musha_profession_component ~= nil
    end)

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
