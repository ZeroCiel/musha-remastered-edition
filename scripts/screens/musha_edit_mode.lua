-- Musha UI 编辑模式
-- 记录面板元素的当前位置/比例/尺寸，开发者直观编辑后写入日志；
-- Hermes 读取日志反向改写 musha_panel_screen.lua 的代码。

local EditMode = {}

-- 默认值（与 musha_panel_screen.lua 当前值同步；Hermes 重写代码后同步更新）
EditMode.ELEMENTS = {
  { name="close_btn",       label="关闭按钮",     cat="主页",   x=562,  y=213,  sx=1,   sy=1,   w=60,   h=60,   visible=true,  desc="半透明暗红方块，等右上角底图重绘后换回正式按钮" },
  { name="job_text",        label="职业名文字",   cat="主页",   x=40,   y=230,  sx=300, sy=70,  w=300,  h=70,   visible=true,  desc="职业名，LEFT对齐" },
  { name="job_icon",        label="职业头像",     cat="主页",   x=-257, y=207,  sx=38,  sy=38,  w=38,   h=38,   visible=true,  desc="三职业图标(战士/剑士/近卫)，初始隐藏" },
  { name="level_text",      label="等级文字",     cat="主页",   x=40,   y=170,  sx=34,  sy=34,  w=34,   h=34,   visible=true,  desc="Lv.1" },
  { name="angel_girl",      label="天使女孩装饰", cat="主页",   x=480,  y=-300, sx=120, sy=160, w=120,  h=160,  visible=true,  desc="右下角天使女孩(缩小)" },
  { name="purse",           label="荷包",          cat="主页",   x=560,  y=-290, sx=32,  sy=48,  w=32,   h=48,   visible=true,  desc="拼接到天使女孩裙侧" },
  { name="sponsor_frame",   label="赞助二维码框架",cat="主页",   x=350,  y=-300, sx=96,  sy=96,  w=96,   h=96,   visible=true,  desc="赞助二维码框架" },
  { name="decor_button",    label="左侧装饰按钮", cat="主页",   x=-450, y=230,  sx=117, sy=66,  w=117,  h=66,   visible=false, desc="用户不要，已隐藏(代码留着)" },
}

EditMode.LAYOUT = {
  HOME_TOP_Y=230, JOB_W=300, ITEM_W=817, ROW_W=797, ITEM_H=78, VISIBLE_ROWS=6,
  PANEL_ZOOM=0.93, BG_W=1232, BG_H=832,
  NAV_LEFT=true, NAV_ALWAYS_SHOW=true,
}

EditMode._dir = nil
EditMode.buffer = {}
EditMode.edits = {}

local function copy(t)
  local n = {}
  for k,v in pairs(t) do n[k] = v end
  return n
end

function EditMode.set_log_dir(d)
  EditMode._dir = d
end

function EditMode._path()
  return (EditMode._dir or ".") .. "/musha_edit_log.json"
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
  local f, err = io.open(EditMode._path(), "r")
  if not f then return end
  local s = f:read("*a"); f:close()
  if not s or s == "" then return end
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
  local function sv(w,v) if w and w.SetVisible then pcall(function() w:SetVisible(v) end) end end
  local function sfsz(w,w_,h_) if w and w.ForceImageSize then pcall(function() w:ForceImageSize(w_,h_) end) end end
  local function sreg(w,w_,h_) if w and w.SetRegionSize then pcall(function() w:SetRegionSize(w_,h_) end) end end
  local eg=b.close_btn;  if eg then sfsz(panel.close_btn,eg.w,eg.h); sp(panel.close_btn,eg.x,eg.y); sv(panel.close_btn,eg.visible) end
  local jt=b.job_text;   if jt then sp(panel.job_text,jt.x,jt.y); sreg(panel.job_text,jt.w,jt.h) end
  local ji=b.job_icon;   if ji then sp(panel.job_icon,ji.x,ji.y); ss(panel.job_icon,ji.w,ji.h); sv(panel.job_icon,ji.visible) end
  local lv=b.level_text; if lv then sp(panel.level_text,lv.x,lv.y); sreg(panel.level_text,lv.w,lv.h) end
  local ag=b.angel_girl; if ag then sp(panel.angel_girl,ag.x,ag.y); ss(panel.angel_girl,ag.w,ag.h); sv(panel.angel_girl,ag.visible) end
  local pu=b.purse;      if pu then sp(panel.purse,pu.x,pu.y); ss(panel.purse,pu.w,pu.h); sv(panel.purse,pu.visible) end
  local sf=b.sponsor_frame; if sf then sp(panel.sponsor_frame,sf.x,sf.y); ss(panel.sponsor_frame,sf.w,sf.h); sv(panel.sponsor_frame,sf.visible) end
  local db=b.decor_button; if db then sp(panel.decor_button,db.x,db.y); sfsz(panel.decor_button,db.w,db.h); sv(panel.decor_button,db.visible) end
end

function EditMode.save()
  local out = {
    version=1, updated=os.date("!%Y-%m-%dT%H:%M:%SZ"),
    elements={}, layout=EditMode.LAYOUT, edits=EditMode.edits,
  }
  for n,e in pairs(EditMode.buffer) do
    out.elements[n] = { x=e.x,y=e.y,sx=e.sx,sy=e.sy,w=e.w,h=e.h,visible=e.visible,label=e.label,cat=e.cat,desc=e.desc }
  end
  local f,err = io.open(EditMode._path(),"w")
  if not f then return nil,err end
  f:write(json_encode(out)); f:close()
  return true
end

function EditMode.get_buffer() return EditMode.buffer end
function EditMode.get_elements() return EditMode.ELEMENTS end

return EditMode
