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
local M = {ns = api.nvim_create_namespace(""), extmarks = {}, group = {label = "LeapLabel", ["label-dimmed"] = "LeapLabelDimmed", match = "LeapMatch", backdrop = "LeapBackdrop"}, priority = {label = 65535, backdrop = 65534}}
M.cleanup = function(self, affected_windows)
  for _, _2_ in ipairs(self.extmarks) do
    local bufnr = _2_[1]
    local id = _2_[2]
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
      local _let_6_ = map(dec, get_cursor_pos())
      local curline = _let_6_[1]
      local curcol = _let_6_[2]
      local _let_7_ = map(dec, {vim.fn.line("w0"), vim.fn.line("w$")})
      local win_top = _let_7_[1]
      local win_bot = _let_7_[2]
      local function _8_()
        if backward_3f then
          return {{win_top, 0}, {curline, curcol}}
        else
          return {{curline, inc(curcol)}, {win_bot, -1}}
        end
      end
      local _let_9_ = _8_()
      local start = _let_9_[1]
      local finish = _let_9_[2]
      return vim.highlight.range(0, self.ns, self.group.backdrop, start, finish, {priority = self.priority.backdrop})
    end
  else
    return nil
  end
end
local function __3ergb(n)
  local r = math.floor((n / 65536))
  local g = math.floor(((n / 256) % 256))
  local b = (n % 256)
  return r, g, b
end
local function blend(color1, color2, weight)
  local r1, g1, b1 = __3ergb(color1)
  local r2, g2, b2 = __3ergb(color2)
  local r = ((r1 * (1 - weight)) + (r2 * weight))
  local g = ((g1 * (1 - weight)) + (g2 * weight))
  local b = ((b1 * (1 - weight)) + (b2 * weight))
  return string.format("#%02x%02x%02x", r, g, b)
end
local function dimmed(def_map_2a)
  local def_map = vim.deepcopy(def_map_2a)
  local normal = vim.api.nvim_get_hl(0, {name = "Normal", link = false})
  if (type(normal.bg) == "number") then
    if (type(def_map.bg) == "number") then
      def_map.bg = blend(def_map.bg, normal.bg, 0.7)
    else
    end
    if (type(def_map.fg) == "number") then
      def_map.fg = blend(def_map.fg, normal.bg, 0.5)
    else
    end
  else
  end
  return def_map
end
local custom_def_maps = {["leap-label-default-light"] = {fg = "#eef1f0", bg = "#5588aa", bold = true, nocombine = true, ctermfg = "red"}, ["leap-label-default-dark"] = {fg = "black", bg = "#ccff88", nocombine = true, ctermfg = "black", ctermbg = "red"}, ["leap-match-default-light"] = {bg = "#eef1f0", ctermfg = "black", ctermbg = "red"}, ["leap-match-default-dark"] = {fg = "#ccff88", underline = true, nocombine = true, ctermfg = "red"}}
M["init-highlight"] = function(self, force_3f)
  local custom_defaults_3f = ((vim.g.colors_name == "default") or vim.g.vscode)
  local defaults
  local _15_
  if custom_defaults_3f then
    if (vim.o.background == "light") then
      _15_ = custom_def_maps["leap-label-default-light"]
    else
      _15_ = custom_def_maps["leap-label-default-dark"]
    end
  else
    _15_ = {link = "IncSearch"}
  end
  local _18_
  if custom_defaults_3f then
    if (vim.o.background == "light") then
      _18_ = custom_def_maps["leap-match-default-light"]
    else
      _18_ = custom_def_maps["leap-match-default-dark"]
    end
  else
    _18_ = {link = "Search"}
  end
  defaults = {[self.group.label] = _15_, [self.group.match] = _18_}
  for group_name, def_map in pairs(vim.deepcopy(defaults)) do
    if not force_3f then
      def_map.default = true
    else
    end
    api.nvim_set_hl(0, group_name, def_map)
  end
  local label = vim.api.nvim_get_hl(0, {name = self.group.label, link = false})
  return vim.api.nvim_set_hl(0, self.group["label-dimmed"], dimmed(label))
end
return M
