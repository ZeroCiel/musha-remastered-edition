-- ============================================================
-- musha_mailbox_shadow.lua — 隐形收件箱实体（每个玩家一个）
--   2026-09-19 新建。设计稿：musha-信箱邮包设计.md 第 4 节「影子收件箱」
--
--   为什么要有它：
--     一个实体只能挂一个 container 组件 → 不能在一个信箱上给 N 个玩家开 N 个箱子。
--     → 真正的存储 = 每人一个**隐形实体**，信箱建筑只当"门面/入口"。
--     好处：完全复用原版 container 的存档/加载逻辑，0 行重写组件，玩家之间互不干扰。
--
--   ⚠️ 不渲染：**故意不加 AnimState**（没有 AnimState 就什么都不画），
--      同时原版 container / container_replica 里所有用到 AnimState 的地方都有
--      `self.inst.AnimState and ...` 保护（container.lua:642 / container_replica.lua:502,526）→ 安全。
--   ⚠️ 不能加 "INLIMBO" tag —— 那个 tag 会让实体**不进存档**，东西就丢了。
--   ⚠️ 不能加 "structure" tag —— 会被巨鹿当建筑砸。
-- ============================================================

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()          -- 有位置（放在信箱脚下）
    inst.entity:AddNetwork()

    inst:AddTag("musha_mail_shadow")
    inst:AddTag("NOCLICK")              -- 点不到、不进鼠标目标

    -- ★ 双端都要有 container（客户端要靠 replica 画格子），所以放在 SetPristine 之前
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("musha_mailbox")

    -- ★ 已解锁格数：组件 + 网络变量（客户端要按真实值画叉号格）
    --   用户口径「容器图一旦要改变，必须从组件里改，还得是 replica」→ 做法见组件注释
    inst:AddComponent("musha_maillevel")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- ===== 服务端专用 =====
    inst.owner_userid = nil             -- 谁的收件箱（玩家 userid）
    inst.unlocked     = 3               -- 已解锁格数（3 起步，最高 12；2026-09-20 起 12 格全可用）
    inst.components.musha_maillevel:SetUnlocked(inst.unlocked)   -- 建档时先把网络值推给客户端

    -- ⚠️⚠️ 这里**绝对不能**再写 `inst.components.container.itemtestfn = ...`
    --   原版 container.lua：`Container:WidgetSetup()` 里会把下面这些名字**锁成只读**：
    --     numslots / acceptsstacks / usespecificslotsforitems / issidewidget / type /
    --     widget / itemtestfn / priorityfn / openlimit
    --   （见 container.lua:73-97：WidgetSetup 先 removesetter 解锁 → 复制 params → makereadonly 锁上）
    --   锁上之后再赋值 = `class.lua:48: Cannot change read only property`（2026-09-19 实测炸过）
    --   → "按 unlocked 拦未解锁格" 那条判断写在 scripts/musha_containers.lua 的
    --     `params.musha_mailbox.itemtestfn` 里（WidgetSetup 会把它复制进来），逻辑一模一样。

    -- 未解锁的格子：放不进去（用户定：叉号格）
    --   ⚠️ 格子 UI 上的"叉"要靠 slotbg 画（用户自己做 UI）；代码这层只负责"拦"

    -- ★★ 2026-09-20 修「绑定过、读档就没了」的根因 ★★
    --   原版契约（entityscript.lua:1924-1932 / 1986-1988）：
    --     · **实体级** `inst.OnSave(inst, data)` 要往传进来的 `data` 里**写字段**；
    --       它的**返回值**被当成"引用列表(GUID)" → `for k,v in pairs(refs) do table.insert(references, v)`
    --     · 老写法 `return { owner_userid = ..., unlocked = ... }` →
    --       两个值被当成 GUID 去解析 → 存档没写进去，反而在存档时报
    --       `Missing reference: <影子实体> -> 3 nil` / `-> KU_Tz7vY-dt nil`（client_log 实证）
    --       ⇒ 读档后 owner_userid = nil → FindShadow 永远匹配不到 → 「绑定没了、摸哪个都不认」
    --   注：**组件**的 OnSave 返回表是对的（组件的返回值就是数据），只有实体级是反过来的，别抄错。
    -- ★★ 2026-09-21 修「读档时超过已解锁格的东西会被拒收 → 东西不见了」★★
    --   加载顺序（entityscript.lua:1954-1988）：
    --     OnPreLoad → 各组件 OnLoad（**容器在这里把物品往格子里塞**）→ 最后才 inst.OnLoad
    --   所以如果在 inst.OnLoad 里恢复 unlocked（旧写法），容器塞物品时 unlocked 还是默认 3
    --   → 第 4~12 格的物品被 params.musha_mailbox.itemtestfn 拦掉 →
    --     Container:OnLoad（container.lua:996-1005）里 `GiveItem(inst, k)` 直接返回 false（没有兜底槽）
    --     → 物品不进箱子、变散落实体 ⇒ 玩家看到的就是"升到 12 格存的东西，读档没了"。
    --   修法：① unlocked / owner_userid 提前到 **OnPreLoad** 恢复（它在所有组件 OnLoad 之前）
    --         ② 加载期间打 _loading 标，itemtestfn 见到就一律放行（双保险）
    inst.OnPreLoad = function(inst, data, newents)
        inst._loading = true
        if data ~= nil then
            inst.owner_userid = data.owner_userid
            inst.unlocked     = data.unlocked or 3
        end
        -- 网络值也要跟着恢复（客户端按它画叉号格；_loading 期间先放行塞物品）
        if inst.components.musha_maillevel ~= nil then
            inst.components.musha_maillevel:SetUnlocked(inst.unlocked)
        end
    end

    inst.OnSave = function(inst, data)
        data.owner_userid = inst.owner_userid
        data.unlocked     = inst.unlocked
    end

    inst.OnLoad = function(inst, data)
        inst._loading = nil                 -- 双保险解除：之后 itemtestfn 恢复正常拦未解锁格
        if data ~= nil then
            inst.owner_userid = data.owner_userid
            inst.unlocked     = data.unlocked or 3
        end
    end

    return inst
end

-- ★ 2026-09-20 叉号格底图（未解锁格用）：容器 widget.slotbg 引用的图集
--   铁律：assets 里写不存在的文件 → RegisterPrefabs assert → 整个 mod 被禁 → 先探再登记
local function FileOK(path)
    local f = softresolvefilepath
    if f == nil then return false end
    local o, r = pcall(f, path)
    return o and r ~= nil
end

local assets = {}
if FileOK("images/musha_mail_x.xml") and FileOK("images/musha_mail_x.tex") then
    table.insert(assets, Asset("ATLAS", "images/musha_mail_x.xml"))
    table.insert(assets, Asset("IMAGE", "images/musha_mail_x.tex"))
else
    print("[Musha] 未解锁格叉号底图没打包（images/musha_mail_x.{xml,tex}）→ 格子先不显示叉")
end

return Prefab("musha_mailbox_shadow", fn, assets, {})
