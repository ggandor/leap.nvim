local api = vim.api
local map = vim.tbl_map
local function inc(x)
  return (x + 1)
end
local function dec(x)
  return (x - 1)
end
local M = {group = {["label-primary"] = "LeapLabelPrimary", ["label-secondary"] = "LeapLabelSecondary", match = "LeapMatch", backdrop = "LeapBackdrop"}, priority = {label = 65535, cursor = 65534, backdrop = 65533}, ns = api.nvim_create_namespace("")}
M.cleanup = function(self, _3ftarget_windows)
  if _3ftarget_windows then
    for _, wininfo in ipairs(_3ftarget_windows) do
      api.nvim_buf_clear_namespace(wininfo.bufnr, self.ns, dec(wininfo.topline), wininfo.botline)
    end
  else
  end
  return api.nvim_buf_clear_namespace(0, self.ns, dec(vim.fn.line("w0")), vim.fn.line("w$"))
end
M["apply-backdrop"] = function(self, backward_3f, _3ftarget_windows)
  local _2_, _3_ = pcall(api.nvim_get_hl_by_name, self.group.backdrop, nil)
  if ((_2_ == true) and true) then
    local _ = _3_
    if _3ftarget_windows then
      for _0, win in ipairs(_3ftarget_windows) do
        vim.highlight.range(win.bufnr, self.ns, self.group.backdrop, {dec(win.topline), 0}, {dec(win.botline), -1}, {priority = self.priority.backdrop})
      end
      return nil
    else
      local _let_4_ = map(dec, {vim.fn.line("."), vim.fn.col(".")})
      local curline = _let_4_[1]
      local curcol = _let_4_[2]
      local _let_5_ = {dec(vim.fn.line("w0")), dec(vim.fn.line("w$"))}
      local win_top = _let_5_[1]
      local win_bot = _let_5_[2]
      local function _7_()
        if backward_3f then
          return {{win_top, 0}, {curline, curcol}}
        else
          return {{curline, inc(curcol)}, {win_bot, -1}}
        end
      end
      local _let_6_ = _7_()
      local start = _let_6_[1]
      local finish = _let_6_[2]
      return vim.highlight.range(0, self.ns, self.group.backdrop, start, finish, {priority = self.priority.backdrop})
    end
  else
    return nil
  end
end
M["init-highlight"] = function(self, force_3f)
  local bg = vim.o.background
  local def_maps
  local _11_
  do
    local _10_ = bg
    if (_10_ == "light") then
      _11_ = "#222222"
    elseif true then
      local _ = _10_
      _11_ = "#ccff88"
    else
      _11_ = nil
    end
  end
  local _16_
  do
    local _15_ = bg
    if (_15_ == "light") then
      _16_ = "#ff8877"
    elseif true then
      local _ = _15_
      _16_ = "#ccff88"
    else
      _16_ = nil
    end
  end
  local _21_
  do
    local _20_ = bg
    if (_20_ == "light") then
      _21_ = "#77aaff"
    elseif true then
      local _ = _20_
      _21_ = "#99ccff"
    else
      _21_ = nil
    end
  end
  def_maps = {[self.group.match] = {fg = _11_, ctermfg = "red", underline = true, nocombine = true}, [self.group["label-primary"]] = {fg = "black", bg = _16_, ctermfg = "black", ctermbg = "red", nocombine = true}, [self.group["label-secondary"]] = {fg = "black", bg = _21_, ctermfg = "black", ctermbg = "blue", nocombine = true}}
  for name, def_map in pairs(def_maps) do
    if not force_3f then
      def_map["default"] = true
    else
    end
    api.nvim_set_hl(0, name, def_map)
  end
  return nil
end
return M
