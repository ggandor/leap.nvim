local api = vim.api
local map = vim.tbl_map
local _local_1_ = require("leap.util")
local inc = _local_1_["inc"]
local dec = _local_1_["dec"]
local M = {ns = api.nvim_create_namespace(""), group = {["label-primary"] = "LeapLabelPrimary", ["label-secondary"] = "LeapLabelSecondary", match = "LeapMatch", backdrop = "LeapBackdrop"}, priority = {label = 65535, cursor = 65534, backdrop = 65533}}
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
  local _3_, _4_ = pcall(api.nvim_get_hl_by_name, self.group.backdrop, nil)
  if ((_3_ == true) and true) then
    local _ = _4_
    if _3ftarget_windows then
      for _0, win in ipairs(_3ftarget_windows) do
        vim.highlight.range(win.bufnr, self.ns, self.group.backdrop, {dec(win.topline), 0}, {dec(win.botline), -1}, {priority = self.priority.backdrop})
      end
      return nil
    else
      local _let_5_ = map(dec, {vim.fn.line("."), vim.fn.col(".")})
      local curline = _let_5_[1]
      local curcol = _let_5_[2]
      local _let_6_ = {dec(vim.fn.line("w0")), dec(vim.fn.line("w$"))}
      local win_top = _let_6_[1]
      local win_bot = _let_6_[2]
      local function _8_()
        if backward_3f then
          return {{win_top, 0}, {curline, curcol}}
        else
          return {{curline, inc(curcol)}, {win_bot, -1}}
        end
      end
      local _let_7_ = _8_()
      local start = _let_7_[1]
      local finish = _let_7_[2]
      return vim.highlight.range(0, self.ns, self.group.backdrop, start, finish, {priority = self.priority.backdrop})
    end
  else
    return nil
  end
end
M["init-highlight"] = function(self, force_3f)
  local bg = vim.o.background
  local defaults
  local _12_
  do
    local _11_ = bg
    if (_11_ == "light") then
      _12_ = "#222222"
    elseif true then
      local _ = _11_
      _12_ = "#ccff88"
    else
      _12_ = nil
    end
  end
  local _17_
  do
    local _16_ = bg
    if (_16_ == "light") then
      _17_ = "#ff8877"
    elseif true then
      local _ = _16_
      _17_ = "#ccff88"
    else
      _17_ = nil
    end
  end
  local _22_
  do
    local _21_ = bg
    if (_21_ == "light") then
      _22_ = "#77aaff"
    elseif true then
      local _ = _21_
      _22_ = "#99ccff"
    else
      _22_ = nil
    end
  end
  defaults = {[self.group.match] = {fg = _12_, ctermfg = "red", underline = true, nocombine = true}, [self.group["label-primary"]] = {fg = "black", bg = _17_, ctermfg = "black", ctermbg = "red", nocombine = true}, [self.group["label-secondary"]] = {fg = "black", bg = _22_, ctermfg = "black", ctermbg = "blue", nocombine = true}}
  for group_name, def_map in pairs(defaults) do
    if not force_3f then
      def_map["default"] = true
    else
    end
    api.nvim_set_hl(0, group_name, def_map)
  end
  return nil
end
return M
