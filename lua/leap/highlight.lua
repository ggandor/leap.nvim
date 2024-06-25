local _local_1_ = require("leap.util")
local inc = _local_1_["inc"]
local dec = _local_1_["dec"]
local get_cursor_pos = _local_1_["get-cursor-pos"]
local api = vim.api
local map = vim.tbl_map
local M = {ns = api.nvim_create_namespace(""), extmarks = {}, group = {match = "LeapMatch", backdrop = "LeapBackdrop"}, priority = {label = 65535, cursor = 65534, backdrop = 65533}}
local function _2_(_, key)
  if (key == "label") then
    if pcall(api.nvim_get_hl_by_name, "LeapLabel", false) then
      return "LeapLabel"
    else
      return "LeapLabelPrimary"
    end
  else
    return nil
  end
end
setmetatable(M.group, {__index = _2_})
M.cleanup = function(self, affected_windows)
  for _, _5_ in ipairs(self.extmarks) do
    local _each_6_ = _5_
    local bufnr = _each_6_[1]
    local id = _each_6_[2]
    if api.nvim_buf_is_valid(bufnr) then
      api.nvim_buf_del_extmark(bufnr, self.ns, id)
    else
    end
  end
  self.extmarks = {}
  if pcall(api.nvim_get_hl_by_name, self.group.backdrop, false) then
    for _, winid in ipairs(affected_windows) do
      if api.nvim_win_is_valid(winid) then
        local wininfo = vim.fn.getwininfo(winid)[1]
        api.nvim_buf_clear_namespace(wininfo.bufnr, self.ns, dec(wininfo.topline), wininfo.botline)
      else
      end
    end
    return api.nvim_buf_clear_namespace(0, self.ns, dec(vim.fn.line("w0")), vim.fn.line("w$"))
  else
    return nil
  end
end
M["apply-backdrop"] = function(self, backward_3f, _3ftarget_windows)
  if pcall(api.nvim_get_hl_by_name, self.group.backdrop, false) then
    if _3ftarget_windows then
      for _, winid in ipairs(_3ftarget_windows) do
        local wininfo = vim.fn.getwininfo(winid)[1]
        vim.highlight.range(wininfo.bufnr, self.ns, self.group.backdrop, {dec(wininfo.topline), 0}, {dec(wininfo.botline), -1}, {priority = self.priority.backdrop})
      end
      return nil
    else
      local _let_10_ = map(dec, get_cursor_pos())
      local curline = _let_10_[1]
      local curcol = _let_10_[2]
      local _let_11_ = map(dec, {vim.fn.line("w0"), vim.fn.line("w$")})
      local win_top = _let_11_[1]
      local win_bot = _let_11_[2]
      local function _13_()
        if backward_3f then
          return {{win_top, 0}, {curline, curcol}}
        else
          return {{curline, inc(curcol)}, {win_bot, -1}}
        end
      end
      local _let_12_ = _13_()
      local start = _let_12_[1]
      local finish = _let_12_[2]
      return vim.highlight.range(0, self.ns, self.group.backdrop, start, finish, {priority = self.priority.backdrop})
    end
  else
    return nil
  end
end
M["highlight-cursor"] = function(self)
  local _let_16_ = get_cursor_pos()
  local line = _let_16_[1]
  local col = _let_16_[2]
  local line_str = vim.fn.getline(line)
  local ch_at_curpos
  do
    local _17_ = vim.fn.strpart(line_str, dec(col), 1, true)
    if (_17_ == "") then
      ch_at_curpos = " "
    elseif (nil ~= _17_) then
      local ch = _17_
      ch_at_curpos = ch
    else
      ch_at_curpos = nil
    end
  end
  local id = api.nvim_buf_set_extmark(0, self.ns, dec(line), dec(col), {virt_text = {{ch_at_curpos, "Cursor"}}, virt_text_pos = "overlay", hl_mode = "combine", priority = self.priority.cursor})
  return table.insert(self.extmarks, {api.nvim_get_current_buf(), id})
end
M["init-highlight"] = function(self, force_3f)
  local bg = vim.o.background
  local defaults
  local _19_
  if (bg == "light") then
    _19_ = "#222222"
  else
    _19_ = "#ccff88"
  end
  local _21_
  if (bg == "light") then
    _21_ = "#ffaa99"
  else
    _21_ = "#ccff88"
  end
  defaults = {[self.group.match] = {fg = _19_, ctermfg = "red", underline = true, nocombine = true}, [self.group.label] = {fg = "black", bg = _21_, ctermfg = "black", ctermbg = "red", nocombine = true}}
  for group_name, def_map in pairs(defaults) do
    if not force_3f then
      def_map.default = true
    else
    end
    api.nvim_set_hl(0, group_name, def_map)
  end
  return nil
end
return M
