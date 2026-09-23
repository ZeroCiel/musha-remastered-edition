-- ============================================================
-- musha_mailbox.lua — 信箱（邮包系统的"家"）
--   2026-09-19 新建。设计稿：musha-信箱邮包设计.md
--
--   作用（只有两个）：
--     ① 第一次"摸"它 → 给这个玩家建一个**隐形收件箱**（永久绑定，之后摸别的信箱不改）
--     ② 之后摸它 → 打开 / 关闭 你自己的收件箱
--   ⚠️ 信箱建筑**自己不带 container**（一个实体只能挂一个容器，多玩家会打架）
--      → 真正的存储是每人一个 musha_mailbox_shadow（见那个文件）
--
--   美术：★ 2026-09-19 用户给了 `图片/信箱.png`
--         → `exported/_tools/make_mailbox_art.py` 出贴图帧 + scml（320x300，落地点=杆底往上 4px）
--         → scml.exe 编成 `anim/musha_mailbox.zip`（build/bank 名 = musha_mailbox，动画名 idle）
--         关掉开关（false）= 退回原版麦斯威尔雕像占位
-- ============================================================

local USE_CUSTOM_MODEL = true     -- ★ 2026-09-19 信箱 build 已装进 anim/ → 开

local MAILBOX_BANK  = USE_CUSTOM_MODEL and "musha_mailbox" or "statue_maxwell"
local MAILBOX_BUILD = USE_CUSTOM_MODEL and "musha_mailbox" or "statue_maxwell_build"
local MAILBOX_ANIM  = USE_CUSTOM_MODEL and "idle"          or "idle_full"
local MAILBOX_SCALE = 1.0

local assets = USE_CUSTOM_MODEL and
{
    Asset("ANIM", "anim/musha_mailbox.zip"),
} or
{
    -- 占位资源（原版游戏 data/anim/ 里自带，可直接引用；分开两个包的那种写法）
    Asset("ANIM", "anim/statue_maxwell.zip"),
    Asset("ANIM", "anim/statue_maxwell_build.zip"),
}

local prefabs = { "musha_mailbox_shadow" }

local function displaynamefn(inst)
    return STRINGS.NAMES.MUSHA_MAILBOX or "信箱"
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.3)     -- ★ 2026-09-20 用户实测后定 0.3（原 0.6 太大）

    inst.AnimState:SetBank(MAILBOX_BANK)
    inst.AnimState:SetBuild(MAILBOX_BUILD)
    inst.AnimState:PlayAnimation(MAILBOX_ANIM)

    if MAILBOX_SCALE ~= 1 then
        inst.Transform:SetScale(MAILBOX_SCALE, MAILBOX_SCALE, MAILBOX_SCALE)
    end

    -- ★ tag + 组件都要在 SetPristine() 之前：客机也要能右键出动作
    --   （这是旧版占位踩过的坑，照 musha_advance_altar.lua 的写法）
    inst:AddTag("musha_mailbox")
    -- 不加 "structure"：会被巨鹿当建筑砸；信箱不该被拆烂

    inst.displaynamefn = displaynamefn

    inst:AddComponent("musha_action")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    -- 右键信箱 = 「摸一下」→ 交给玩家身上的 musha_mail 组件决定（新建影子 / 开 / 关）
    inst.components.musha_action:SetFn(function(mailbox, doer)
        if doer == nil or not doer:IsValid() then return end
        local mc = doer.components.musha_mail
        if mc == nil then
            print("[Musha ERROR] musha_mailbox: 玩家身上没有 musha_mail 组件（AddPlayerPostInit 没跑？）")
            return
        end
        mc:UseMailbox(mailbox, doer)
    end)

    inst.components.musha_action:SetCanUseCheck(function(_, doer)
        return doer ~= nil and doer:IsValid() and doer.components.musha_mail ~= nil
    end)

    return inst
end

-- 放置预览（配方摆放时的"幽灵"）
local placer = nil
pcall(function()
    placer = MakePlacer("musha_mailbox_placer", MAILBOX_BANK, MAILBOX_BUILD, MAILBOX_ANIM)
end)

return Prefab("musha_mailbox", fn, assets, prefabs), placer
