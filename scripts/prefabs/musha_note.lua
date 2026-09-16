-- 文件: scripts/prefabs/musha_note.lua
-- 便签 - 开局携带，右键弹 UI 显示逐行浮现的职业引导文本
--
-- ============================================================
-- 素材自检测（2026-09-16 事故修复 —— 和 mushа_lifebranch 那次同款）
--   事故：Asset 改成 anim/musha_note_item.zip、但 zip 还没打包 →
--         RegisterPrefabs 阶段直接
--         "Could not find an asset matching anim/musha_note_item.zip" → **整个 mod 被游戏禁用**。
--   修法：用原版全局 softresolvefilepath()（util.lua:645，找不到只返回 nil、不 assert）先探；
--         不在 → 不登记这项资源、bank/build 回退到旧的 mushа_note（世界里先空白，但不崩）；
--         等 zip 丢进 anim/ 之后进游戏自动全功能，**不用再改代码**。
-- ============================================================
local function asset_exists(path)
    local f = softresolvefilepath or (GLOBAL ~= nil and GLOBAL.softresolvefilepath)
    if f == nil then return false end
    local ok, resolved = pcall(f, path)
    return ok and resolved ~= nil
end

local HAS_ITEM_ART = asset_exists("anim/musha_note_item.zip")
local HAS_OLD_ART  = asset_exists("anim/musha_note.zip")
if not HAS_ITEM_ART then
    print("[Musha] 便签：anim/musha_note_item.zip 还没打包 → 世界里先不显示（不影响 mod 加载），打包后自动生效")
end

local assets = {
    -- 世界里的道具形态（2026-09-15 新增）：一卷系绳的纸，动画 idle。
    -- 旧的 anim/musha_note.zip 里装的是 UI 那套（1800x1011 底纸 + 9 行文字，动画 anim/disappear），
    -- 里面**没有 idle** → 以前 PlayAnimation("idle") 对不上号 → 便签掉地上是空白。
    Asset("ATLAS", "images/inventoryimages/musha_note.xml"),
    Asset("IMAGE", "images/inventoryimages/musha_note.tex"),
    Asset("ATLAS", "images/musha_note_bg.xml"),
    Asset("IMAGE", "images/musha_note_bg.tex")
}
if HAS_ITEM_ART then
    table.insert(assets, Asset("ANIM", "anim/musha_note_item.zip"))
end

local function OnUseNote(inst, doer)
    if not doer or not doer:IsValid() then
        return
    end

    -- 防止重复打开
    if inst._playing then
        return
    end
    inst._playing = true

    -- 触发事件，UI 通过 owner.screen_musha_note 找到实例
    doer:PushEvent("musha_use_note")

    -- 冷却后重置
    inst:DoTaskInTime(0.5, function()
        inst._playing = false
    end)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    if HAS_ITEM_ART then
        inst.AnimState:SetBank("musha_note_item")
        inst.AnimState:SetBuild("musha_note_item")
        inst.AnimState:PlayAnimation("idle")
    elseif HAS_OLD_ART then
        -- zip 还没打包时的回退：挂旧 build（里面没有 idle → 世界里不显示，但不会崩）
        inst.AnimState:SetBank("musha_note")
        inst.AnimState:SetBuild("musha_note")
    end

    inst:AddTag("musha_note")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "musha_note"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/musha_note.xml"

    -- musha_action 组件（modmain 里注册了 INVENTORY 右键触发 MUSHA_READ_NOTE → UseItem）
    inst:AddComponent("musha_action")
    inst.components.musha_action:SetFn(OnUseNote)

    return inst
end

return Prefab("musha_note", fn, assets)
