-- ============================================================
-- musha_mail.lua（组件）— 挂在【玩家】身上的邮包系统逻辑
--   2026-09-19 新建。设计稿：musha-信箱邮包设计.md
--
--   挂法：modmain 里 AddPlayerPostInit（原版玩家实体不能改，只能后挂）
--   职责：
--     ① 绑定：第一次右键信箱 → 给这个玩家建一个隐形收件箱（永久，之后摸别的信箱不改）
--     ② 开关收件箱：右键信箱时把自己的收件箱开/关
--     ③ 寄件：关包（信差包 onclosefn）→ 能直投就直投，投不进就进包的"待寄区"
--     ④ 补投：定时 Pump()，玩家靠近自己的收件箱时把待寄区的东西倒进去
--
--   数据存哪：只存 `has_mailbox`（是否绑过）；收件箱本体是独立实体（自己存档）
--     掉线重进：影子实体随世界存档，has_mailbox 随玩家存档 → 两边都对得上
-- ============================================================

local ok, Mail = pcall(require, "musha_mail")
if not ok or Mail == nil then
    print("[Musha ERROR] musha_mail 模块没加载成功（信箱/邮包功能会失效）：" .. tostring(Mail))
end

local MushaMail = Class(function(self, inst)
    self.inst = inst
    self.has_mailbox = false      -- 是否已绑定过信箱（第一次绑定永久生效）
    self.starter_bag = false      -- ★ 是否已经发过"出生信差包"（存进组件存档：老玩家没有这个字段 → 补发一次）
	self.musha_rabbitpack_granted = false   -- ★ 兔子背包 15 天发放标记（随组件存档）
    self.shadow = nil             -- 运行时引用（不存档）

    -- 只有服务端需要定时补投
    if TheWorld ~= nil and TheWorld.ismastersim then
        inst:DoPeriodicTask(2, function() self:Pump() end)
    end
end)

-- ---------- 工具 ----------

function MushaMail:IsServer()
    return TheWorld ~= nil and TheWorld.ismastersim
end

function MushaMail:GetUserID()
    return Mail ~= nil and Mail.UserID(self.inst) or nil
end

-- 拿自己的收件箱：先看缓存的引用，失效就在自己脚下搜
function MushaMail:ResolveShadow()
    if not self:IsServer() or Mail == nil then return nil end
    local s = self.shadow
    if s ~= nil and (not s:IsValid()) then
        s = nil
        self.shadow = nil
    end
    if s == nil then
        local p = self.inst:GetPosition()
        if p == nil then return nil end
        s = Mail.FindShadow(p.x, p.y, p.z, self:GetUserID())
        if s ~= nil then self.shadow = s end
    end
    return s
end

-- ---------- 右键信箱 ----------

function MushaMail:UseMailbox(mailbox, doer)
    if not self:IsServer() then return end
    if mailbox == nil or not mailbox:IsValid() then return end
    if Mail == nil then return end

    -- ★★ 2026-09-21 用户口径：**只有"套件真能升级"时才走升级**。
    --   档位不对 / 已经满级 / 还不是我的收件箱 → 当作普通右键 = 正常开（或绑定/关闭）箱子，
    --   不再弹"这件套件对不上：现在的收件箱要用第 N 档套件"那种提示。
    local kit = Mail.FindKit(doer)
    if kit ~= nil and self:UpgradeMailbox(mailbox, doer, kit) then
        return
    end

    local uid = self:GetUserID()
    if uid == nil then
        if doer.components.talker ~= nil then
            doer.components.talker:Say("（还没认领到你的身份，稍后再试）", 3)
        end
        return
    end

    -- ① 眼前这个信箱脚边：我自己的收件箱 / 没人认领的孤儿影子（老存档 bug 遗留 → 认领，别再造一个）
    local was_bound = self.has_mailbox
    local mpos = mailbox:GetPosition()
    local shadow, need_claim = Mail.ClaimNearbyShadow(mpos.x, mpos.y, mpos.z, uid)

    if shadow == nil then
        -- ② 眼前没有 → 我的收件箱是在别的信箱那儿，还是真的没了？
        --   ★ 2026-09-20：老存档 bug 会把 owner_userid 弄丢（读档后绑定消失），
        --     那时必须能就地重建，否则玩家永远卡在"绑过 → 摸哪个都不认"。
        local mine = Mail.FindMyShadowAnywhere(uid)
        if mine ~= nil then
            if doer.components.talker ~= nil then
                doer.components.talker:Say("（我的收件箱不在这儿……它绑在第一次那个信箱上）", 4)
            end
            return
        end
        -- ③ 真的没了 → 就地重建
        shadow = SpawnPrefab("musha_mailbox_shadow")
        if shadow ~= nil then
            shadow.Transform:SetPosition(mpos.x, mpos.y, mpos.z)
            need_claim = true
        end
    end

    if shadow == nil then return end

    if need_claim then
        shadow.owner_userid = uid
        Mail.SetShadowUnlocked(shadow, shadow.unlocked or Mail.BOX_SLOT_INIT)
        self.shadow = shadow
        self.has_mailbox = true
        doer:PushEvent("musha_mail_bound")
        -- ★ 把"已绑定"推给客户端：光标上的动作名要读它（触摸（绑定）→ 触摸（打开））
        --   走职业组件现成的推送通道；没有职业组件的角色跳过（动作名退回纯「触摸」）
        local pc = doer.components.musha_profession_component
        if pc ~= nil and pc.PushSettings ~= nil then
            pcall(function() pc:PushSettings() end)
        end
        if doer.components.talker ~= nil then
            doer.components.talker:Say("（收件箱绑定好了 —— 以后这里就是你的家）", 4)
        end
        print("[Musha] 玩家 " .. tostring(uid) .. " 绑定收件箱于信箱"
            .. (was_bound and "（重建：原有收件箱已丢失）" or ""))
    else
        self.shadow = shadow
    end

    local c = shadow.components.container
    if c == nil then return end
    if c:IsOpenedBy(doer) then
        c:Close(doer)
    else
        c:Open(doer)
    end
end

-- ---------- 右键物品自动放入信箱 ----------
function MushaMail:PutItemToMailbox(mailbox, doer, item)
    if not self:IsServer() or Mail == nil then return false end
    
    -- 收件箱优先看"眼前这块信箱脚下"，其次看自己早先绑定的那个
    local shadow = nil
    if mailbox ~= nil and mailbox:IsValid() then
        local p = mailbox:GetPosition()
        shadow = Mail.FindShadow(p.x, p.y, p.z, self:GetUserID())
    end
    if shadow == nil then
        shadow = self:ResolveShadow()
    end
    if shadow == nil then
        return false  -- 还不是我的收件箱
    end
    
    local c = shadow.components.container
    if c == nil or not c:IsOpenedBy(doer) then
        return false  -- 容器没打开或不是我的
    end
    
    -- 尝试把物品放进信箱
    local slot = c:GetOpenSlotForItem(item)
    if slot and slot <= (shadow.unlocked or 3) then
        return c:GiveItem(item, slot) == true
    end
    
    return false
end

-- ---------- 用升级套件扩容收件箱 ----------
--   返回 true = 这件事已经处理掉（不管成没成），调用方不要再走"开箱"分支
function MushaMail:UpgradeMailbox(mailbox, doer, kit)
    if not self:IsServer() or Mail == nil then return true end

    local function say(s)
        if doer ~= nil and doer:IsValid() and doer.components.talker ~= nil then
            doer.components.talker:Say(s, 4)
        end
    end

    -- 收件箱优先看"眼前这块信箱脚下"，其次看自己早先绑定的那个
    local shadow = nil
    if mailbox ~= nil and mailbox:IsValid() then
        local p = mailbox:GetPosition()
        shadow = Mail.FindShadow(p.x, p.y, p.z, self:GetUserID())
    end
    if shadow == nil then
        shadow = self:ResolveShadow()
    end
    if shadow == nil then
        -- 还不是我的收件箱 → 不是"升级失败"，交给调用方走正常的绑定/开箱流程
        return false
    end

    local unlocked = shadow.unlocked or Mail.BOX_SLOT_INIT
    local need = Mail.KitStepFor(unlocked)
    if need == nil then
        return false                      -- 已满级 → 直接开箱（用户 09-21 口径）
    end
    if kit.mail_kit_step ~= need then
        return false                      -- 档位不对 → 直接开箱，不提示（用户 09-21 口径）
    end

    local new_unlocked = kit.mail_kit_to or (unlocked + 2)
    Mail.SetShadowUnlocked(shadow, new_unlocked)
    kit:Remove()
    self.shadow = shadow
    say("收件箱扩到 " .. new_unlocked .. " 格了")
    print("[Musha] 收件箱升级：" .. tostring(self:GetUserID()) .. " → " .. tostring(new_unlocked) .. " 格")
    return true
end

-- ---------- 把物品塞进包的待寄区（隐藏格） ----------

function MushaMail:StashToBuffer(bag, item)
    if bag == nil or not bag:IsValid() then return false end
    local c = bag.components.container
    if c == nil then return false end
    local base = bag.visible_slots or 5
    local total = base + (bag.buffer_slots or 9)
    for i = base + 1, total do
        if c.slots[i] == nil then
            return c:GiveItem(item, i) == true      -- ★ 物品已从原格拿出来 → 直接给（别再靠 owner 找）
        end
    end
    return false
end

-- ---------- 关包 = 寄件 ----------

function MushaMail:MailBag(bag, doer)
    if not self:IsServer() or Mail == nil then return end
    if bag == nil or not bag:IsValid() then return end
    local c = bag.components.container
    if c == nil then return end

    local shadow = self:ResolveShadow()
    local visible = bag.visible_slots or 5
    local sent, pending, blocked = 0, 0, 0

    for i = 1, visible do
        local item = c.slots[i]
        if item ~= nil and item:IsValid() then
            if not Mail.CanMail(item) then
                blocked = blocked + 1                       -- 禁寄（唯一任务道具等）→ 留在包里
            else
                -- ★ 2026-09-20：先"从这一格拿走"，再决定往哪送（修"包里不清除"）
                local taken = Mail.TakeFromSlot(c, i)
                if taken ~= nil and taken:IsValid() then
                    if shadow ~= nil and Mail.TryDeliver(shadow, taken) then
                        sent = sent + 1                     -- 直投成功
                    elseif self:StashToBuffer(bag, taken) then
                        pending = pending + 1               -- 收件箱不在 / 满了 → 走上邮路
                    elseif c:GiveItem(taken, i) then
                        blocked = blocked + 1               -- 连待寄区都满了 → 放回原格
                    else
                        -- 最后兜底：塞玩家背包 / 掉在包旁边，**绝不消失**
                        local inv = doer ~= nil and doer:IsValid() and doer.components.inventory or nil
                        if inv ~= nil and inv:GiveItem(taken) then
                            blocked = blocked + 1
                        else
                            local bp = bag:GetPosition()
                            taken.Transform:SetPosition(bp.x, bp.y, bp.z)
                            blocked = blocked + 1
                        end
                    end
                end
            end
        end
    end

    if doer ~= nil and doer:IsValid() and doer.components.talker ~= nil then
        if sent > 0 and pending == 0 and blocked == 0 then
            doer.components.talker:Say("寄出 " .. sent .. " 件 —— 已经到家了", 3)
        elseif pending > 0 then
            doer.components.talker:Say("寄出 " .. pending .. " 件 —— 还在邮路上，回家取", 3)
        elseif blocked > 0 then
            doer.components.talker:Say("有 " .. blocked .. " 件寄不出去", 3)
        elseif sent > 0 then
            doer.components.talker:Say("寄出 " .. sent .. " 件", 3)
        end
    end
end

-- ---------- 定时补投：靠近自己的收件箱就把待寄区倒进去 ----------

function MushaMail:Pump()
    if not self:IsServer() or Mail == nil then return end
    local inst = self.inst
    if inst == nil or not inst:IsValid() then return end

    local shadow = self:ResolveShadow()
    if shadow == nil then return end
    local c = shadow.components.container
    if c == nil then return end

    local moved = 0
    for _, bag in ipairs(Mail.FindBags(inst)) do
        local bc = bag.components.container
        if bc ~= nil then
            local base = bag.visible_slots or 5
            local total = base + (bag.buffer_slots or 9)
            for i = base + 1, total do
                local item = bc.slots[i]
                if item ~= nil and item:IsValid() and Mail.CanMail(item) then
                    local taken = Mail.TakeFromSlot(bc, i)     -- ★ 同样：先按格拿走
                    if taken ~= nil and taken:IsValid() then
                        if Mail.TryDeliver(shadow, taken) then
                            moved = moved + 1
                        else
                            bc:GiveItem(taken, i)              -- 投不进 → 放回待寄区
                        end
                    end
                end
            end
        end
    end

    if moved > 0 and inst.components.talker ~= nil then
        inst.components.talker:Say("取件：" .. moved .. " 件已投入收件箱", 3)
    end
end

-- ---------- 存档 ----------

function MushaMail:OnSave()
    return {
        has_mailbox = self.has_mailbox or false,
        starter_bag  = self.starter_bag or false,
		musha_rabbitpack_granted = self.musha_rabbitpack_granted or false,
    }
end

function MushaMail:OnLoad(data)
    if data ~= nil then
        self.has_mailbox = data.has_mailbox or false
        self.starter_bag  = data.starter_bag or false
		self.musha_rabbitpack_granted = data.musha_rabbitpack_granted or false
    end
end

-- ---------- ★ 出生信差包（2026-09-20 用户要的"补发改"）----------
--   规则：**一人一次**（标记存进组件存档 starter_bag）
--     · 老存档 / 老玩家：存档里没有这个字段 → 补发一次  ✓
--     · 新玩家：第一次进 → 发一次  ✓
--     · 死了 / 掉了 / 用坏了 → **不再补**（要自己再做一个，配方已给）✓
--     · 已经自己做过包的人：直接打标记，不重复发 ✓
--   调用点：modmain 的 AddPlayerPostInit（延迟 0.5s，确保 OnLoad 已经跑完）
function MushaMail:GrantStarterBag()
    if not self:IsServer() then return false end
    if self.starter_bag then return false end
    local inst = self.inst
    if inst == nil or not inst:IsValid() then return false end
    local inv = inst.components.inventory
    if inv == nil then return false end

    -- 已经有包了（自己做的 / 别人给的）→ 只打标记，不重复发
    local has = false
    inv:ForEachItem(function(it)
        if it ~= nil and it:HasTag("musha_mailbag") then has = true end
    end)
    self.starter_bag = true
    if has then return false end

    local bag = SpawnPrefab("musha_mailbag")
    if bag == nil then return false end
    if not inv:GiveItem(bag) then
        local pt = inst:GetPosition()
        if pt ~= nil then bag.Transform:SetPosition(pt.x, pt.y, pt.z) end
    end
    if inst.components.talker ~= nil then
        inst.components.talker:Say("（这是你的信差包 —— 装东西进去，关包就寄回家）", 4)
    end
    print("[Musha] 补发/发放出生信差包 → " .. tostring(inst.userid))
    return true
end

function MushaMail:GetDebugString()
    return string.format("收件箱绑定=%s", tostring(self.has_mailbox))
end

return MushaMail
