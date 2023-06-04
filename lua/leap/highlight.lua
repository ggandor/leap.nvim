local util = require("leap.util")
local _local_1_ = util
local inc = _local_1_["inc"]
local dec = _local_1_["dec"]
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
M["apply-backdrop"] = function(self, ranges)
  if pcall(api.nvim_get_hl_by_name, self.group.backdrop, false) then
    for _, range in ipairs(ranges) do
      vim.highlight.range(range.bufnr, self.ns, self.group.backdrop, {range.startrow, range.startcol}, {range.endrow, range.endcol}, {priority = self.priority.backdrop})
    end
    return nil
  else
    return nil
  end
end
M["highlight-cursor"] = function(self, _3fpos)
  local _let_6_ = (_3fpos or util["get-cursor-pos"]())
  local line = _let_6_[1]
  local col = _let_6_[2]
  local pos = _let_6_
  local ch_at_curpos = (util["get-char-at"](pos, {}) or " ")
  local id = api.nvim_buf_set_extmark(0, self.ns, dec(line), dec(col), {virt_text = {{ch_at_curpos, "Cursor"}}, virt_text_pos = "overlay", hl_mode = "combine", priority = self.priority.cursor})
  return table.insert(self.extmarks, {api.nvim_get_current_buf(), id})
end
M["init-highlight"] = function(self, force_3f)
  local bg = vim.o.background
  local defaults
  local _8_
  do
    local _7_ = bg
    if (_7_ == "light") then
      _8_ = "#222222"
    elseif true then
      local _ = _7_
      _8_ = "#ccff88"
    else
      _8_ = nil
    end
  end
  local _13_
  do
    local _12_ = bg
    if (_12_ == "light") then
      _13_ = "#ff8877"
    elseif true then
      local _ = _12_
      _13_ = "#ccff88"
    else
      _13_ = nil
    end
  end
  local _18_
  do
    local _17_ = bg
    if (_17_ == "light") then
      _18_ = "#77aaff"
    elseif true then
      local _ = _17_
      _18_ = "#99ccff"
    else
      _18_ = nil
    end
  end
  defaults = {[self.group.match] = {fg = _8_, ctermfg = "red", underline = true, nocombine = true}, [self.group["label-primary"]] = {fg = "black", bg = _13_, ctermfg = "black", ctermbg = "red", nocombine = true}, [self.group["label-secondary"]] = {fg = "black", bg = _18_, ctermfg = "black", ctermbg = "blue", nocombine = true}, [self.group["label-selected"]] = {fg = "black", bg = "magenta", ctermfg = "black", ctermbg = "magenta", nocombine = true}}
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
