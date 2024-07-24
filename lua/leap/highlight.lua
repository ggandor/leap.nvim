local _local_1_ = require("leap.util")
local inc = _local_1_["inc"]
local dec = _local_1_["dec"]
local get_cursor_pos = _local_1_["get-cursor-pos"]
local api = vim.api
local map = vim.tbl_map
local empty_3f = vim.tbl_isempty
local function has_hl_group_3f(name)
  return not empty_3f(api.nvim_get_hl(0, {name = name}))
end
local M
local function _2_(_, key)
  if (key == "label") then
    if has_hl_group_3f("LeapLabel") then
      return "LeapLabel"
    else
      return "LeapLabelPrimary"
    end
  else
    return nil
  end
end
M = {ns = api.nvim_create_namespace(""), extmarks = {}, group = setmetatable({match = "LeapMatch", backdrop = "LeapBackdrop"}, {__index = _2_}), priority = {label = 65535, cursor = 65534, backdrop = 65533}}
M.cleanup = function(self, affected_windows)
  for _, _5_ in ipairs(self.extmarks) do
    local bufnr = _5_[1]
    local id = _5_[2]
    if api.nvim_buf_is_valid(bufnr) then
      api.nvim_buf_del_extmark(bufnr, self.ns, id)
    else
    end
  end
  self.extmarks = {}
  if has_hl_group_3f(self.group.backdrop) then
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
  if has_hl_group_3f(self.group.backdrop) then
    if _3ftarget_windows then
      for _, winid in ipairs(_3ftarget_windows) do
        local wininfo = vim.fn.getwininfo(winid)[1]
        vim.highlight.range(wininfo.bufnr, self.ns, self.group.backdrop, {dec(wininfo.topline), 0}, {dec(wininfo.botline), -1}, {priority = self.priority.backdrop})
      end
      return nil
    else
      local _let_9_ = map(dec, get_cursor_pos())
      local curline = _let_9_[1]
      local curcol = _let_9_[2]
      local _let_10_ = map(dec, {vim.fn.line("w0"), vim.fn.line("w$")})
      local win_top = _let_10_[1]
      local win_bot = _let_10_[2]
      local function _11_()
        if backward_3f then
          return {{win_top, 0}, {curline, curcol}}
        else
          return {{curline, inc(curcol)}, {win_bot, -1}}
        end
      end
      local _let_12_ = _11_()
      local start = _let_12_[1]
      local finish = _let_12_[2]
      return vim.highlight.range(0, self.ns, self.group.backdrop, start, finish, {priority = self.priority.backdrop})
    end
  else
    return nil
  end
end
M["highlight-cursor"] = function(self)
  local _let_15_ = get_cursor_pos()
  local line = _let_15_[1]
  local col = _let_15_[2]
  local line_str = vim.fn.getline(line)
  local ch_at_curpos
  do
    local _16_ = vim.fn.strpart(line_str, dec(col), 1, true)
    if (_16_ == "") then
      ch_at_curpos = " "
    elseif (nil ~= _16_) then
      local ch = _16_
      ch_at_curpos = ch
    else
      ch_at_curpos = nil
    end
  end
  local id = api.nvim_buf_set_extmark(0, self.ns, dec(line), dec(col), {virt_text = {{ch_at_curpos, "Cursor"}}, virt_text_pos = "overlay", hl_mode = "combine", priority = self.priority.cursor})
  return table.insert(self.extmarks, {api.nvim_get_current_buf(), id})
end
M["init-highlight"] = function(self, force_3f)
  local name = vim.g.colors_name
  local bg = vim.o.background
  local default_3f = ((name == "default") or vim.g.vscode)
  local defaults
  local _18_
  if (default_3f and (bg == "light")) then
    _18_ = {fg = "#eef1f0", bg = "#5588aa", bold = true, nocombine = true, ctermfg = "red"}
  elseif (default_3f and (bg == "dark")) then
    _18_ = {fg = "black", bg = "#ccff88", nocombine = true, ctermfg = "black", ctermbg = "red"}
  else
    _18_ = {link = "IncSearch"}
  end
  local _20_
  if (default_3f and (bg == "light")) then
    _20_ = {bg = "#eef1f0", ctermfg = "black", ctermbg = "red"}
  elseif (default_3f and (bg == "dark")) then
    _20_ = {fg = "#ccff88", underline = true, nocombine = true, ctermfg = "red"}
  else
    _20_ = {link = "Search"}
  end
  defaults = {[self.group.label] = _18_, [self.group.match] = _20_}
  if (force_3f or not has_hl_group_3f("LeapLabelPrimary")) then
    for group_name, def_map in pairs(defaults) do
      if not force_3f then
        def_map["default"] = true
      else
      end
      api.nvim_set_hl(0, group_name, def_map)
    end
    return nil
  else
    return nil
  end
end
return M
