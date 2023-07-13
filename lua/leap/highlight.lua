local _local_1_ = require("leap.util")
local inc = _local_1_["inc"]
local dec = _local_1_["dec"]
local get_cursor_pos = _local_1_["get-cursor-pos"]
local strcharpart = _local_1_["strcharpart"]
local api = vim.api
local map = vim.tbl_map
local M = {ns = api.nvim_create_namespace(""), extmarks = {}, group = {["label-primary"] = "LeapLabelPrimary", ["label-secondary"] = "LeapLabelSecondary", ["label-selected"] = "LeapLabelSelected", match = "LeapMatch", backdrop = "LeapBackdrop"}, priority = {label = 65535, cursor = 65534, backdrop = 65533}}
M.cleanup = function(self, affected_windows)
  for _, _2_ in ipairs(self.extmarks) do
    local _each_3_ = _2_
    local bufnr = _each_3_[1]
    local id = _each_3_[2]
    api.nvim_buf_del_extmark(bufnr, self.ns, id)
  end
  self.extmarks = {}
  if pcall(api.nvim_get_hl_by_name, self.group.backdrop, false) then
    for _, winid in ipairs(affected_windows) do
      local wininfo = vim.fn.getwininfo(winid)[1]
      api.nvim_buf_clear_namespace(wininfo.bufnr, self.ns, dec(wininfo.topline), wininfo.botline)
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
M["highlight-cursor"] = function(self, _3fpos)
  local _let_11_ = (_3fpos or get_cursor_pos())
  local line = _let_11_[1]
  local col = _let_11_[2]
  local pos = _let_11_
  local line_str = vim.fn.getline(line)
  local start = vim.fn.charidx(line_str, (col - 1))
  local ch_at_curpos
  do
    local _12_ = strcharpart(line_str, start, 1)
    if (_12_ == "") then
      ch_at_curpos = " "
    elseif (nil ~= _12_) then
      local ch = _12_
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
  local _15_
  do
    local _14_ = bg
    if (_14_ == "light") then
      _15_ = "#222222"
    elseif true then
      local _ = _14_
      _15_ = "#ccff88"
    else
      _15_ = nil
    end
  end
  local _20_
  do
    local _19_ = bg
    if (_19_ == "light") then
      _20_ = "#ff8877"
    elseif true then
      local _ = _19_
      _20_ = "#ccff88"
    else
      _20_ = nil
    end
  end
  local _25_
  do
    local _24_ = bg
    if (_24_ == "light") then
      _25_ = "#77aaff"
    elseif true then
      local _ = _24_
      _25_ = "#99ccff"
    else
      _25_ = nil
    end
  end
  defaults = {[self.group.match] = {fg = _15_, ctermfg = "red", underline = true, nocombine = true}, [self.group["label-primary"]] = {fg = "black", bg = _20_, ctermfg = "black", ctermbg = "red", nocombine = true}, [self.group["label-secondary"]] = {fg = "black", bg = _25_, ctermfg = "black", ctermbg = "blue", nocombine = true}, [self.group["label-selected"]] = {fg = "black", bg = "magenta", ctermfg = "black", ctermbg = "magenta", nocombine = true}}
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
