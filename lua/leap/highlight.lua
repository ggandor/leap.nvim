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
    for _, wininfo in ipairs(affected_windows) do
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
      for _, win in ipairs(_3ftarget_windows) do
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
M["highlight-cursor"] = function(self, _3fpos)
  local _let_11_ = (_3fpos or util["get-cursor-pos"]())
  local line = _let_11_[1]
  local col = _let_11_[2]
  local pos = _let_11_
  local ch_at_curpos = (util["get-char-at"](pos, {}) or " ")
  local id = api.nvim_buf_set_extmark(0, self.ns, dec(line), dec(col), {virt_text = {{ch_at_curpos, "Cursor"}}, virt_text_pos = "overlay", hl_mode = "combine", priority = self.priority.cursor})
  return table.insert(self.extmarks, {api.nvim_get_current_buf(), id})
end
M["init-highlight"] = function(self, force_3f)
  local bg = vim.o.background
  local defaults
  local _13_
  do
    local _12_ = bg
    if (_12_ == "light") then
      _13_ = "#222222"
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
      _18_ = "#ff8877"
    elseif true then
      local _ = _17_
      _18_ = "#ccff88"
    else
      _18_ = nil
    end
  end
  local _23_
  do
    local _22_ = bg
    if (_22_ == "light") then
      _23_ = "#77aaff"
    elseif true then
      local _ = _22_
      _23_ = "#99ccff"
    else
      _23_ = nil
    end
  end
  defaults = {[self.group.match] = {fg = _13_, ctermfg = "red", underline = true, nocombine = true}, [self.group["label-primary"]] = {fg = "black", bg = _18_, ctermfg = "black", ctermbg = "red", nocombine = true}, [self.group["label-secondary"]] = {fg = "black", bg = _23_, ctermfg = "black", ctermbg = "blue", nocombine = true}, [self.group["label-selected"]] = {fg = "black", bg = "magenta", ctermfg = "black", ctermbg = "magenta", nocombine = true}}
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
