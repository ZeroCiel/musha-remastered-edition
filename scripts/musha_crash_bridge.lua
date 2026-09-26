-- ============================================================================
-- musha_crash_bridge.lua —— 崩溃桥 mod 侧（挑战-应答门禁 + outbox）2026-09-26
--
-- 背景：崩溃后 mod 把错误交给本机 agent 找原因/自动修。Lua 沙箱验不了 OS/Steam
--   代码签名 → 变体方案 = **SteamID64 派生 HMAC-SHA256 挑战-应答**：
--   agent 必须答对当前 nonce 才放行。盘上只有临时 nonce/答复，**无常驻令牌**。
--
-- 协议 v1（与 crash_bridge/watcher.ps1 严格一致，改一处必须两处同步）：
--   key_hex  = SHA256_HEX("musha-crash-bridge/v1|" .. steamid64)   -- 十六进制小写
--   答复     = HMAC_SHA256( key_hex 的 ASCII 字节 , nonce )        -- 十六进制小写
--   crash_bridge/challenge.txt      : v=1 / sid=… / n=<32hex> / t=<epoch>（mod 写，30s 滚动）
--   crash_bridge/agent_response.txt : v=1 / n=<32hex> / h=<64hex>（agent 写，tmp+rename）
--   crash_bridge/out_<epoch>_<rand>.txt : 校验通过才写（交给 agent 的崩溃报告）
--   crash_bridge/status.txt / last_event.txt : 诊断
--
-- 滚动窗口：每 30s 换 nonce，内存保留 [当前, 上一个] → agent 最多容忍 1 格
--   （≈60s）失联；应答只对 [当前, 上一个] 有效 → 过期答复/重放一律拒。
--
-- 挂接点：modmain 安装 _G.DisplayError 包装（mainfunctions.lua:1586，按决定）
--   + _G.ScriptErrorWidget 构造包装（漏斗：gamelogic:58 / frontend:1640 /
--   mods.lua:653 的 SetGlobalErrorWidget 最终都 new 它 → 覆盖加载失败类错误）。
--   按 payload 去重：同一错误文本只写一份 outbox。
-- ============================================================================

local M = {}

local PREFIX        = "musha-crash-bridge/v1"
local SID_FALLBACK  = "76561198220617051"   -- 本机 SteamID64（vdf 读不到时的兜底，两处一致）
local ROLL_INTERVAL = 30

-- ---------------------------------------------------------------- bit / sha256
-- ★ 2026-09-26 真机修：DST 的 bit 库**没有 ror**（游戏自身 47×band/33×bor/25×lshift/11×rshift，
--   全库 0×ror/rol 实测）→ 启动即 `musha_crash_bridge.lua:90 attempt to call upvalue 'ror'`，
--   桥整个没挂上（client_log 01:02:21 start error 实锤）。WSL 测试垫片提供了 ror，掩盖了这个洞。
--   修法：ror 缺席时用 rshift/lshift/bxor 现搭（两者游戏在用=必在）。
local band, bxor, bnot, rshift, lshift, ror
if type(bit) == "table" then
    band, bxor, bnot = bit.band, bit.bxor, bit.bnot
    rshift, lshift = bit.rshift, bit.lshift
    ror = bit.ror
    if not ror and rshift and lshift and bxor then
        ror = function(x, n)
            n = n % 32
            if n == 0 then return band(x) end
            return bxor(rshift(x, n), lshift(x, 32 - n))
        end
    end
end

local K = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1,
    0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
    0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
    0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
    0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
    0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}

local function b32_bytes(v)   -- 无符号 32 位 → 4 字节
    return string.char(
        math.floor(v / 16777216) % 256,
        math.floor(v / 65536) % 256,
        math.floor(v / 256) % 256,
        v % 256)
end

local function preproc(msg)
    local len = #msg
    local k = (64 - ((len + 9) % 64)) % 64          -- 0x80 + k 个 0 + 8 字节长度
    local hi = math.floor(len / 536870912) % 4294967296   -- (len*8) / 2^32
    local lo = (len * 8) % 4294967296
    return msg .. "\128" .. string.rep("\0", k) .. b32_bytes(hi) .. b32_bytes(lo)
end

local function tohex(bin)
    local parts = {}
    for i = 1, #bin do
        parts[i] = string.format("%02x", bin:byte(i))
    end
    return table.concat(parts)
end

local function sha256_bin(msg)
    if not band then error("bit library missing") end
    local data = preproc(msg)
    local h0, h1, h2, h3, h4, h5, h6, h7 =
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    local w = {}
    for off = 1, #data, 64 do
        for i = 0, 15 do
            local b1, b2, b3, b4 = data:byte(off + i * 4, off + i * 4 + 3)
            w[i] = b1 * 16777216 + b2 * 65536 + b3 * 256 + b4
        end
        for i = 16, 63 do
            local x, y = w[i - 15], w[i - 2]
            local s0 = bxor(ror(x, 7), ror(x, 18), rshift(x, 3))
            local s1 = bxor(ror(y, 17), ror(y, 19), rshift(y, 10))
            w[i] = band(w[i - 16] + s0 + w[i - 7] + s1)
        end
        local a, b, c, d, e, f, g, h = h0, h1, h2, h3, h4, h5, h6, h7
        for i = 0, 63 do
            local S1 = bxor(ror(e, 6), ror(e, 11), ror(e, 25))
            local ch = bxor(band(e, f), band(bnot(e), g))
            local t1 = band(h + S1 + ch + K[i + 1] + w[i])
            local S0 = bxor(ror(a, 2), ror(a, 13), ror(a, 22))
            local mj = bxor(band(a, b), band(a, c), band(b, c))
            local t2 = band(S0 + mj)
            h = g; g = f; f = e
            e = band(d + t1)
            d = c; c = b; b = a
            a = band(t1 + t2)
        end
        h0 = band(h0 + a); h1 = band(h1 + b); h2 = band(h2 + c); h3 = band(h3 + d)
        h4 = band(h4 + e); h5 = band(h5 + f); h6 = band(h6 + g); h7 = band(h7 + h)
    end
    -- 输出按无符号解释（LuaJIT bit 结果是带符号 32 位，% 2^32 归一）
    return b32_bytes(h0 % 4294967296) .. b32_bytes(h1 % 4294967296)
        .. b32_bytes(h2 % 4294967296) .. b32_bytes(h3 % 4294967296)
        .. b32_bytes(h4 % 4294967296) .. b32_bytes(h5 % 4294967296)
        .. b32_bytes(h6 % 4294967296) .. b32_bytes(h7 % 4294967296)
end

function M.sha256_hex(msg)
    return tohex(sha256_bin(msg))
end

local function xor_block(block, padbyte)
    local t = {}
    for i = 1, #block do
        t[i] = string.char(bxor(block:byte(i), padbyte))
    end
    return table.concat(t)
end

function M.hmac_hex(key, msg)
    local k = key
    if #k > 64 then k = sha256_bin(k) end
    k = k .. string.rep("\0", 64 - #k)
    local inner = xor_block(k, 0x36) .. msg
    local outer = xor_block(k, 0x5c) .. sha256_bin(inner)
    return tohex(sha256_bin(outer))
end

-- ---------------------------------------------------------------- io（全 pcall）
local function try_open(path, mode)
    local ok, fh = pcall(io.open, path, mode)   -- DST 校验：抛=非法路径
    if ok and fh then return fh end
    return nil
end

local function write_file(path, content)
    local fh = try_open(path, "w")
    if not fh then return false end
    local ok = pcall(function() fh:write(content) fh:close() end)
    return ok == true
end

local function read_file(path)
    local fh = try_open(path, "r")
    if not fh then return nil end
    local ok, data = pcall(function() return fh:read("*a") end)
    pcall(function() fh:close() end)
    if ok and type(data) == "string" then return data end
    return nil
end

-- ---------------------------------------------------------------- 身份 / 密钥
local function read_sid_from_vdf()
    local cands = {}
    local pf = (type(os) == "table" and os.getenv) and os.getenv("ProgramFiles(x86)") or nil
    if type(pf) == "string" and pf ~= "" then
        cands[#cands + 1] = (pf:gsub("\\", "/")) .. "/Steam/config/loginusers.vdf"
    end
    cands[#cands + 1] = "C:/Program Files (x86)/Steam/config/loginusers.vdf"
    cands[#cands + 1] = "c:/program files (x86)/steam/config/loginusers.vdf"
    for _, p in ipairs(cands) do
        local data = read_file(p)
        if data then
            local sid = data:match('"(765611%d+)"')   -- SteamID64 固定前缀
            if sid then return sid, "vdf" end
        end
    end
    return SID_FALLBACK, "const"
end

-- ---------------------------------------------------------------- 基目录探测
local function probe_base(root)
    -- 探 <root>/crash_bridge/challenge.txt 可追加写（"a" 不截断）：
    -- 抛 = 路径非法；fh=nil = 目录不存在/不可写；两者都不选
    local fh = try_open(root .. "/crash_bridge/challenge.txt", "a")
    if fh then pcall(function() fh:close() end); return root .. "/crash_bridge" end
    return nil
end

local function resolve_base(modroot)
    local roots = {}
    if type(modroot) == "string" and modroot ~= "" then
        roots[#roots + 1] = modroot:gsub("\\", "/"):gsub("/+$", "")
    end
    roots[#roots + 1] = "mods/musha"
    roots[#roots + 1] = "../mods/musha"
    roots[#roots + 1] = "musha"
    for _, r in ipairs(roots) do
        local base = probe_base(r)
        if base then return base end
    end
    return nil
end

-- ---------------------------------------------------------------- nonce 滚动
local nonce_counter = 0
local function new_nonce()
    nonce_counter = nonce_counter + 1
    local t = (type(os) == "table" and os.time and os.time()) or 0
    local r1 = math.random(0, 1073741823)
    local r2 = math.random(0, 1073741823)
    return string.format("%08x%08x", t % 4294967296, r1)
        .. string.format("%08x%08x", r2, nonce_counter % 1073741823)
end

local function write_status()
    if not M.base then return end
    local lines = {
        "t=" .. tostring(os.time()),
        "sid=" .. tostring(M.sid) .. " src=" .. tostring(M.sid_src),
        "key_fp=" .. tostring(M.key_fp),
        "nonce_cur=" .. tostring(M.cur_nonce),
        "nonce_prev=" .. tostring(M.prev_nonce),
        "challenge_ok=" .. tostring(M.challenge_ok),
        "agent_seen=" .. tostring(M.agent_seen),
        "agent_verdict=" .. tostring(M.agent_verdict),
        "last_event=" .. tostring(M.last_event),
        "hooks de=" .. tostring(M._hooked_de) .. " sew=" .. tostring(M._hooked_sew),
    }
    write_file(M.base .. "/status.txt", table.concat(lines, "\n") .. "\n")
end

function M.roll()
    if M.disabled or not M.base then return end
    M.prev_nonce = M.cur_nonce
    M.cur_nonce = new_nonce()
    local ch = "v=1\nsid=" .. M.sid .. "\nn=" .. M.cur_nonce
        .. "\nt=" .. tostring(os.time()) .. "\n"
    M.challenge_ok = write_file(M.base .. "/challenge.txt", ch)
    M.install_hooks()   -- 顺带重试挂接（ScriptErrorWidget 可能晚于 modmain 加载）
    write_status()
end

local function schedule_next()
    if type(TheSim) ~= "table" or not TheSim.DoTaskInTime then return end
    pcall(function()
        TheSim:DoTaskInTime(ROLL_INTERVAL, function()
            M.roll()
            schedule_next()
        end)
    end)
end

-- ---------------------------------------------------------------- 应答校验
local function parse_kv(text)
    local t = {}
    for k, v in text:gmatch("([%w_]+)=([^\r\n]+)") do t[k] = v end
    return t
end

function M.verify_response()
    if not M.base or not M.key_hex then return false, "not_init" end
    local text = read_file(M.base .. "/agent_response.txt")
    if not text then return false, "no_response" end
    local kv = parse_kv(text)
    if not kv.n or not kv.h then return false, "malformed" end
    local expected = M.hmac_hex(M.key_hex, kv.n)
    if kv.h ~= expected then return false, "bad_mac" end
    if kv.n ~= M.cur_nonce and kv.n ~= M.prev_nonce then
        return false, "stale_nonce"
    end
    return true, "ok"
end

-- ---------------------------------------------------------------- 崩溃上报
local function add_line(buf, s) buf[#buf + 1] = s end

function M.on_crash(title, text)
    if M.disabled or not M.base then return end
    text = tostring(text or "")
    title = tostring(title or "")
    -- 同一错误只发一次（DisplayError 钩子先到，ScriptErrorWidget 钩子随后去重）
    local sig = (text ~= "") and text:sub(1, 400) or title
    M.seen = M.seen or {}
    if M.seen[sig] then return end
    M.seen[sig] = true

    local ok, why = M.verify_response()
    M.agent_verdict = (ok and "released") or ("rejected:" .. tostring(why))
    M.agent_seen = os.time()
    M.last_event = "t=" .. os.time() .. " " .. M.agent_verdict
    write_status()
    if not ok then
        write_file(M.base .. "/last_event.txt", M.last_event .. "\n")
        return
    end

    local buf = {}
    add_line(buf, "musha-crash-report v1")
    add_line(buf, "time=" .. os.date("%Y-%m-%d %H:%M:%S") .. " epoch=" .. tostring(os.time()))
    add_line(buf, "steamid64=" .. tostring(M.sid))
    pcall(function()
        local kid = TheNet and TheNet.GetUserID and TheNet:GetUserID()
        if kid then add_line(buf, "klei=" .. tostring(kid)) end
    end)
    add_line(buf, "title=" .. title)
    add_line(buf, "error=" .. text:sub(1, 8000))
    pcall(function()
        local tb = debug.traceback("at-capture", 2)
        if tb then add_line(buf, "traceback=" .. tb:sub(1, 4000)) end
    end)
    pcall(function()
        local names = ModManager and ModManager.GetEnabledModNames
            and ModManager:GetEnabledModNames()
        if type(names) == "table" then
            add_line(buf, "mods=" .. table.concat(names, ","))
        end
    end)
    add_line(buf, "bridge_base=" .. M.base)

    local name = string.format("out_%d_%06d.txt", os.time(),
        math.random(0, 999999))
    local wrote = write_file(M.base .. "/" .. name, table.concat(buf, "\n") .. "\n")
    M.last_event = M.last_event .. " outbox=" .. tostring(wrote and name or "FAIL")
    write_status()
    write_file(M.base .. "/last_event.txt", M.last_event .. "\n")
end

-- ---------------------------------------------------------------- 挂接
function M.install_hooks()
    -- 决定的挂接点：mainfunctions.lua:1586 DisplayError
    if not M._hooked_de and type(_G.DisplayError) == "function" then
        local orig = _G.DisplayError
        _G.DisplayError = function(err)
            pcall(M.on_crash, "DisplayError", tostring(err))
            return orig(err)
        end
        M._hooked_de = true
    end
    -- 漏斗兜底：所有错误屏最终 new ScriptErrorWidget
    if not M._hooked_sew and _G.ScriptErrorWidget ~= nil then
        local orig = _G.ScriptErrorWidget
        _G.ScriptErrorWidget = function(title, text, ...)
            pcall(M.on_crash, tostring(title), tostring(text))
            return orig(title, text, ...)
        end
        M._hooked_sew = true
    end
end

-- ---------------------------------------------------------------- 启动
function M.start(modroot)
    if M.started then return not M.disabled end
    M.started = true

    M.base = resolve_base(modroot)
    if not M.base then
        M.disabled = true
        print("[musha-crash-bridge] DISABLED: no writable crash_bridge/ dir")
        return false
    end
    M.sid, M.sid_src = read_sid_from_vdf()
    M.key_hex = M.sha256_hex(PREFIX .. "|" .. M.sid)
    M.key_fp = M.key_hex:sub(1, 16)
    M.roll()
    schedule_next()
    print("[musha-crash-bridge] ready base=" .. M.base
        .. " sid=" .. M.sid .. "(" .. M.sid_src .. ") key_fp=" .. M.key_fp)
    return true
end

return M
