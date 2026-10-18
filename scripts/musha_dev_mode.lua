-- ================================================================
-- musha_dev_mode —— 作者调试开关（2026-09-29 用户拍板）
--
--   用户原话：
--     "通过作者 steamid 判定，然后进游戏有全制造模式，0 级就能测试，切换职业测试内容"
--     "对，但只认 SteamID"（→ 不按"本地房主"自动开，只认账号）
--
--   ⚠️ 两个坑，别改回去：
--     ① **不能用 TheNet:GetUserID()** —— 那返回的是 **Klei ID**，不是 SteamID64。
--        （musha_crash_bridge.lua:312-315 把 steamid64= 和 klei= 分两行记，就是这个原因）
--     ② **不能裸 tonumber 比对就完事** —— SteamID64 ≈ 7.66e16，
--        超过 double 安全整数 9.007e15，末几位会被吃掉（2^56 附近 ulp=16）。
--        所以引擎返回值既可能是**完整 64 位**（要带容差比），也可能是**SteamID3 账号 ID**
--        （260351323，精确），两种都认。
--
--   判定顺序：引擎直读 → 本机 loginusers.vdf 字符串精确比对（兜底）。
--   **读不到就当没命中，绝不回退成常量** —— 否则别人机器上会误判成作者、白送全制造。
--
--   用法：
--     local ok, Dev = pcall(require, "musha_dev_mode")
--     Dev.Enabled()            -- 调试开关（= 作者账号）：全制造 / 放开等级门槛
--     Dev.CanUseTestItem()     -- 测试道具（作者 / 测试安全员 / 本地房主模式）
-- ================================================================

local DevMode = {}

local DEV_STEAM64_STR = "76561198220617051"        -- 作者本机（= crash bridge 的 SID_FALLBACK 同值）
local DEV_STEAM64_NUM = tonumber(DEV_STEAM64_STR)  -- 引擎若回完整 ID：四舍五入到同一个 double
local DEV_ACCOUNT_ID  = 260351323                  -- = DEV_STEAM64 - 76561197960265728（SteamID3）

-- 测试安全员白名单（用户："本地模式 / 使用者属于测试安全员都允许使用"）
-- 想放谁进来，把 SteamID64 字符串填进去即可
local TESTER_STEAM64 = {
    -- ["7656119xxxxxxxxxx"] = true,
}

local cached_enabled = nil

local function read_file(path)
    local ok, fh = pcall(io.open, path, "r")   -- DST 校验：非法路径会抛，必须 pcall
    if not ok or fh == nil then return nil end
    local ok2, data = pcall(function() return fh:read("*a") end)
    pcall(function() fh:close() end)
    return ok2 and data or nil
end

-- 本机 Steam 客户端登录过的所有 SteamID64（字符串，精确）
local function local_steam_ids()
    local out, seen = {}, {}
    local cands = {}
    local pf = (type(os) == "table" and os.getenv) and os.getenv("ProgramFiles(x86)") or nil
    if type(pf) == "string" and pf ~= "" then
        cands[#cands + 1] = (pf:gsub("\\", "/")) .. "/Steam/config/loginusers.vdf"
    end
    cands[#cands + 1] = "C:/Program Files (x86)/Steam/config/loginusers.vdf"
    for _, p in ipairs(cands) do
        local data = read_file(p)
        if data then
            for sid in data:gmatch('"(765611%d+)"') do
                if not seen[sid] then
                    seen[sid] = true
                    out[#out + 1] = sid
                end
            end
        end
    end
    return out
end

local function sim_steam_id()
    if TheSim == nil or type(TheSim.GetSteamIDNumber) ~= "function" then return nil end
    local ok, n = pcall(function() return TheSim:GetSteamIDNumber() end)
    if ok and type(n) == "number" and n ~= 0 then return n end
    return nil
end

local function id_in_list(sid, tbl)
    if type(sid) ~= "string" or tbl == nil then return false end
    return tbl[sid] == true
end

-- 作者账号命中？
function DevMode.IsAuthor()
    if cached_enabled ~= nil then return cached_enabled end

    local hit = false

    -- ① 引擎直读（最准，读不到就跳到②）
    local n = sim_steam_id()
    if n ~= nil then
        if n == DEV_ACCOUNT_ID then
            hit = true
        elseif math.abs(n - DEV_STEAM64_NUM) <= 16 then   -- 容差：double 在 2^56 附近 ulp=16
            hit = true
        end
    end

    -- ② 本机 loginusers.vdf（字符串精确比对；读不到 = 没命中，不回退）
    if not hit then
        for _, sid in ipairs(local_steam_ids()) do
            if sid == DEV_STEAM64 or id_in_list(sid, TESTER_STEAM64) then
                hit = true
                break
            end
        end
    end

    cached_enabled = hit
    if hit then
        print("[Musha] 调试模式：作者 SteamID 命中 → 全制造 + 放开等级门槛")
    end
    return hit
end

-- 测试安全员（含作者）？给测试道具用
function DevMode.IsTester()
    if DevMode.IsAuthor() then return true end
    for _, sid in ipairs(local_steam_ids()) do
        if id_in_list(sid, TESTER_STEAM64) then return true end
    end
    return false
end

-- 本地/房主模式（非专用服务器 = 房主自己开的局域网或单机）
function DevMode.IsLocalHost()
    if TheNet == nil then return false end
    if type(TheNet.GetServerIsClientHosted) == "function" then
        local ok, v = pcall(function() return TheNet:GetServerIsClientHosted() end)
        if ok then return v == true end
    end
    local ok2, v2 = pcall(function()
        return TheNet:GetIsServer() == true and not (type(TheNet.IsDedicated) == "function" and TheNet:IsDedicated())
    end)
    return ok2 and v2 == true
end

-- 调试开关本体：**只认 SteamID**（用户 09-29 拍板）
function DevMode.Enabled()
    return DevMode.IsAuthor()
end

-- 测试道具（职业重置石）：作者 / 测试安全员 / 本地房主模式
function DevMode.CanUseTestItem()
    return DevMode.IsTester() or DevMode.IsLocalHost()
end

return DevMode
