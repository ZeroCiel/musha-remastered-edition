-- Musha UI 编辑模式
-- 记录面板元素的当前位置/比例/尺寸，开发者直观编辑后写入日志；
-- Hermes 读取日志反向改写 musha_panel_screen.lua 的代码。

local EditMode = {}

-- 默认值（与 musha_panel_screen.lua 当前值同步；Hermes 重写代码后同步更新）
EditMode.ELEMENTS = {
  { name="close_btn",       label="关闭按钮",     cat="主页",   x=573.0, y=371.0, sx=1,   sy=1,   w=81.8, h=85.4, visible=true,  desc="右上角红叉按钮热区（close_x 贴图=唯一X，底图烤叉已擦除，悬停1.24缩放）；09-27b 右移到最右上顶角(573,371)；09-26 B案：盘心=星bbox中心(1412,85)→content 圆心(538.8,370.0)；★ 09-27 修双X：09-26晚 +25(563.8) 只挪控件没重烤底图→两叉错开，归位 538.8" },
  { name="job_text",        label="职业名文字",   cat="主页",   x=40,   y=230,  sx=300, sy=70,  w=300,  h=70,   visible=true,  desc="职业名，LEFT对齐" },
  { name="job_icon",        label="职业头像",     cat="主页",   x=-257, y=207,  sx=30.4,sy=30.4,w=30.4, h=30.4, visible=true,  desc="三职业图标(战士/剑士/近卫)，初始隐藏；2026-09-24 用户定：当前比例再×0.8(38→30.4)" },
  { name="level_text",      label="等级文字",     cat="主页",   x=22,   y=170,  sx=34,  sy=34,  w=34,   h=34,   visible=true,  desc="Lv.1；2026-09-24 用户定：左移18px(40→22)" },
  { name="angel_new",      label="天使女孩装饰", cat="主页",   x=480,  y=-352, sx=390, sy=520, w=390,  h=520,  visible=true,  desc="右下角天使女孩 —— 09-25 三改：用户'比例按2.0算改成1.8'=432x576×0.9 → 390x520（仍 3:4；仍高于2.8底线）。中心不动 (480,-352)，脚底下探 ≈-460，允许溢出" },
  { name="purse",           label="荷包",          cat="主页",   x=485, y=-380, sx=48,  sy=72,  w=48,   h=72,   visible=true,  desc="★ 09-27 三调：482,-376 → 485,-380（右3 下4）；旋转 +7 在构造函数（编辑模式不接管 rotation；历次 15→50→-60→+7）；★ 赞助入口（愿者上钩，点开两段式面板）" },
  { name="sponsor_frame",   label="赞助二维码框架",cat="主页",   x=560,  y=-150, sx=96,  sy=65,  w=96,   h=65,   visible=false, desc="赞助入口(可点)：点了弹微信收款码；源图 1526x1031 等比 96x65；★ 2026-09-24 用户定：不直接显示(visible=false)，要考察玩家" },
  { name="decor_button",    label="左侧装饰按钮", cat="主页",   x=-450, y=230,  sx=117, sy=66,  w=117,  h=66,   visible=false, desc="用户不要，已隐藏(代码留着)" },
}

EditMode.LAYOUT = {
  HOME_TOP_Y=230, JOB_W=300, ITEM_W=680, ROW_W=660, ROW_H=58, ITEM_H=72, VISIBLE_ROWS=6,
  PANEL_ZOOM=0.93, BG_W=1232, BG_H=832,
  NAV_LEFT=true, NAV_ALWAYS_SHOW=true, NAV_X=-500, NAV_Y=-120,   -- ★ 2026-09-24 导航左移180(-320→-500)
  EXP_W=390.6, EXP_H=13, EXP_X=-33, EXP_Y=105.5,      -- ★ 2026-09-24 只缩长度（长 ×0.7），高不变
  SPONSOR_GATE_OPEN=true,                              -- ★ 赞助：愿者上钩（荷包摆着，赞助框不露脸）
}

EditMode._dir = nil
EditMode.buffer = {}
EditMode.edits = {}

local function copy(t)
  local n = {}
  for k,v in pairs(t) do n[k] = v end
  return n
end

-- ★ 2026-09-24 修「技能书按了没反应 / 面板打不开」根因
--   DST 魔改过的 Lua 对 io.open 做了路径校验，**非法路径直接抛 Lua 错误**（不是返回 nil）：
--     日志实测：`musha_edit_mode.lua:150: invalid filepath`
--   当时的链路：面板取 _G.ModPath 当日志目录 → 该值只存在于 mod env，require 进来的文件取不到
--     → nil → _dir="" → 拼出 "/musha_edit_log.json" 这种根路径 → io.open 抛错 →
--     而这一行没包 pcall → 错误往上炸掉**整个面板构造** → OpenMushaPanel 的 pcall 兜住后
--     面板永远推不进屏幕栈（症状：技能书/事件都触发了，日志最后一行却停在"构造失败"）。
--   修法：① 候选路径逐个**探测**（pcall 不抛=合法；文件不存在只是返回 nil，不算非法）
--         ② 所有 io.open 一律包 pcall，保证本模块永不抛错
--         ③ 一个合法路径都找不到 → 退回 DST 官方持久化 API（不做路径校验）
EditMode.PERSIST_KEY = "mod_config_data/musha_edit_log"

local CANDIDATES = {
  "../mods/musha/musha_edit_log.json",   -- 最优：直接落在 mod 目录，Hermes 就近读写
  "mods/musha/musha_edit_log.json",
  "musha_edit_log.json",                 -- 原版 SCANLAYOUT_SAVE_DIR 同款：裸文件名（debugcommands.lua:4536 为 ""）
}

local function path_ok(p)
  local ok = pcall(io.open, p, "r")      -- 抛 = 路径非法；不抛（哪怕文件不存在）= 合法
  return ok == true
end

function EditMode.set_log_dir(d)
  EditMode._dir = (type(d) == "string" and d ~= "") and d or nil
  EditMode._resolved = nil               -- 换了目录要重新探
end

-- 返回**真正能用的 io.open 路径**；一个合法路径都没有时返回 nil
function EditMode._io_path()
  if EditMode._resolved == nil then
    EditMode._resolved = false
    if EditMode._dir then
      local p = EditMode._dir .. "/musha_edit_log.json"
      if path_ok(p) then EditMode._resolved = p end
    end
    if EditMode._resolved == false then
      for _, c in ipairs(CANDIDATES) do
        if path_ok(c) then EditMode._resolved = c; break end
      end
    end
  end
  if EditMode._resolved == false then return nil end
  return EditMode._resolved
end

-- 给日志/提示看的落点（永远返回字符串，方便直接 print）
function EditMode._path()
  return EditMode._io_path() or EditMode.PERSIST_KEY
end

--------------- JSON 编码器 ----------------
local function jesc(s)
  return ('"'..s:gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')..'\"')
end
local function json_encode(val)
  local t = type(val)
  if t == "number" then return tostring(val)
  elseif t == "boolean" then return val and "true" or "false"
  elseif t == "string" then return jesc(val)
  elseif t == "table" then
    local parts, isarr = {}, true
    for k in pairs(val) do if type(k) ~= "number" then isarr = false end end
    if isarr then
      for i=1,#val do if val[i]==nil then isarr=false end end
    end
    if isarr then
      for i=1,#val do parts[#parts+1]=json_encode(val[i]) end
      return "["..table.concat(parts,",").."]"
    else
      for k,v in pairs(val) do parts[#parts+1]=json_encode(k)..":"..json_encode(v) end
      return "{"..table.concat(parts,",").."}"
    end
  end
  return "null"
end

--------------- JSON 解析器（最小递归下降） ----------------
local function json_parse(s)
  local pos = 1
  local function skip_ws()
    while pos <= #s and s:sub(pos,pos):match("%s") do pos = pos + 1 end
  end
  local function parse_string()
    assert(s:sub(pos,pos) == '"', "expected string")
    pos = pos + 1; local t = ""
    while pos <= #s do
      local c = s:sub(pos,pos)
      if c == '"' then pos = pos+1; return t end
      if c == "\\" then
        pos = pos+1; local nc = s:sub(pos,pos)
        if nc == "n" then t=t.."\n" elseif nc == "t" then t=t.."\t"
        elseif nc == "\\" then t=t.."\\" elseif nc == '"' then t=t..'"'
        elseif nc == "u" then pos = pos+4; t = t.."[unicode]"
        else t = t..nc end
        pos = pos+1
      else t = t..c; pos = pos+1 end
    end
    error("unterminated string")
  end
  local function parse_number()
    local n = s:match("^[+-]?%d+%.?%d*([eE][+-]?%d+)?", pos)
    assert(n, "expected number")
    pos = pos + #n
    return tonumber(n)
  end
  local function parse_value()
    skip_ws()
    local c = s:sub(pos,pos)
    if c == '"' then return parse_string()
    elseif c == "{" then
      pos = pos+1; local t = {}; skip_ws()
      if s:sub(pos,pos) == "}" then pos=pos+1; return t end
      while true do
        skip_ws(); local key = parse_string(); skip_ws()
        assert(s:sub(pos,pos) == ":", "expected :"); pos = pos+1
        local val = parse_value()
        t[key] = val
        skip_ws(); local nxt = s:sub(pos,pos)
        if nxt == "," then pos=pos+1
        elseif nxt == "}" then pos=pos+1; break
        else error("expected , or }") end
      end
      return t
    elseif c == "[" then
      pos = pos+1; local a = {}; skip_ws()
      if s:sub(pos,pos) ~= "]" then
        while true do
          a[#a+1] = parse_value(); skip_ws(); local nxt = s:sub(pos,pos)
          if nxt == "," then pos=pos+1
          elseif nxt == "]" then pos=pos+1; break
          else error("expected , or ]") end
        end
      else pos=pos+1
      end
      return a
    elseif c == "t" then pos=pos+4; return true
    elseif c == "f" then pos=pos+5; return false
    elseif c == "n" then pos=pos+3; return nil
    else return parse_number()
    end
  end
  local res = parse_value(); skip_ws()
  assert(pos >= #s, "trailing chars")
  return res
end

--------------- 公共接口 ----------------
function EditMode.init()
  EditMode.buffer = {}
  for _, e in ipairs(EditMode.ELEMENTS) do
    EditMode.buffer[e.name] = copy(e)
  end
  EditMode.edits = {}
end

function EditMode.load()
  EditMode.init()
  local p = EditMode._io_path()
  if not p then return end
  local _ok, f = pcall(io.open, p, "r")   -- ★ 非法路径会抛错，必须 pcall（这是修面板打不开的关键）
  if not _ok or not f then return end
  local _rok, s = pcall(function() return f:read("*a") end)
  pcall(function() f:close() end)
  if not _rok or not s or s == "" then return end
  local ok, data = pcall(json_parse, s)
  if ok and type(data) == "table" then
    if data.elements then
      for n, v in pairs(data.elements) do
        if EditMode.buffer[n] then for k, val in pairs(v) do EditMode.buffer[n][k] = val end end
      end
    end
    if data.edits then EditMode.edits = data.edits end
  end
end

function EditMode.edit(name, field, value, reason)
  local e = EditMode.buffer[name]
  if not e or e[field] == value then return end
  local old = e[field]
  e[field] = value
  EditMode.edits[#EditMode.edits+1] = {
    ts = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    el = name, field = field, old = old, new = value, why = reason or "",
  }
end

function EditMode.apply_to_panel(panel)
  local b = EditMode.buffer
  local function sp(w,x,y) if w and w.SetPosition then pcall(function() w:SetPosition(x,y) end) end end
  local function ss(w,w_,h_) if w and w.SetSize then pcall(function() w:SetSize(w_,h_) end) end end
  local function sf(w,sx,sy) if w and w.SetScale then pcall(function() w:SetScale(sx,sy) end) end end
  -- ⚠️ DST 没有 SetVisible()（dst-api-pitfalls.md:121）。原来写 `if w.SetVisible` 永远为 nil，
  --    导致**编辑模式改 visible 从来没生效过** —— 改成按 Show()/Hide() 判。
  local function sv(w,v) if w and w.Show and w.Hide then pcall(function() if v then w:Show() else w:Hide() end end) end end
  local function sfsz(w,w_,h_) if w and w.ForceImageSize then pcall(function() w:ForceImageSize(w_,h_) end) end end
  local function sreg(w,w_,h_) if w and w.SetRegionSize then pcall(function() w:SetRegionSize(w_,h_) end) end end
  local eg=b.close_btn;  if eg then sfsz(panel.close_btn,eg.w,eg.h); sp(panel.close_btn,eg.x,eg.y); sv(panel.close_btn,eg.visible) end
  local jt=b.job_text;   if jt then sp(panel.job_text,jt.x,jt.y); sreg(panel.job_text,jt.w,jt.h) end
  local ji=b.job_icon;   if ji then sp(panel.job_icon,ji.x,ji.y); ss(panel.job_icon,ji.w,ji.h); sv(panel.job_icon,ji.visible) end
  local lv=b.level_text; if lv then sp(panel.level_text,lv.x,lv.y); sreg(panel.level_text,lv.w,lv.h) end
  local ag=b.angel_new; if ag then sp(panel.angel_new,ag.x,ag.y); ss(panel.angel_new,ag.w,ag.h); sv(panel.angel_new,ag.visible) end
  local pu=b.purse;      if pu then sp(panel.purse,pu.x,pu.y); ss(panel.purse,pu.w,pu.h); sv(panel.purse,pu.visible) end
  local sf=b.sponsor_frame; if sf then sp(panel.sponsor_frame,sf.x,sf.y); ss(panel.sponsor_frame,sf.w,sf.h); sv(panel.sponsor_frame,sf.visible) end
  local db=b.decor_button; if db then sp(panel.decor_button,db.x,db.y); sfsz(panel.decor_button,db.w,db.h); sv(panel.decor_button,db.visible) end
end

function EditMode.save()
  -- ★ 防静默丢数据：buffer 只有 init() 会填。万一 save() 先于 load() 被调到，
  --   这里会写出一个 elements 为空的 JSON —— Hermes 读到空表且日志毫无报错。
  if next(EditMode.buffer) == nil then EditMode.init() end

  local out = {
    version=1, updated=os.date("!%Y-%m-%dT%H:%M:%SZ"),
    elements={}, layout=EditMode.LAYOUT, edits=EditMode.edits,
  }
  for n,e in pairs(EditMode.buffer) do
    out.elements[n] = { x=e.x,y=e.y,sx=e.sx,sy=e.sy,w=e.w,h=e.h,visible=e.visible,label=e.label,cat=e.cat,desc=e.desc }
  end
  local payload = json_encode(out)

  local p = EditMode._io_path()
  if p then
    local _ok, f = pcall(io.open, p, "w")           -- ★ 非法路径会抛错，必须 pcall
    if _ok and f then
      local _wok, werr = pcall(function() f:write(payload) end)
      pcall(function() f:close() end)
      if _wok then return true, p end
      return nil, tostring(werr)
    end
  end

  -- 兜底：io.open 找不到合法路径 → 用 DST 官方持久化 API（不做路径校验）
  --   落点在 <Klei>\DoNotStarveTogether\mod_config_data\musha_edit_log，Hermes 也能直接读
  local _sok, serr = pcall(function()
    TheSim:SetPersistentString(EditMode.PERSIST_KEY, payload, false)
  end)
  if _sok then return true, EditMode.PERSIST_KEY .. " (persistent)" end
  return nil, tostring(serr)
end

function EditMode.get_buffer() return EditMode.buffer end
function EditMode.get_elements() return EditMode.ELEMENTS end

return EditMode
