-- Code generated from fnl/leap/search.fnl - do not edit directly.

local opts = require("leap.opts")
local _local_1_ = require("leap.util")
local get_horizontal_bounds = _local_1_["get-horizontal-bounds"]
local get_cursor_pos = _local_1_["get-cursor-pos"]
local api = vim.api
local abs = math["abs"]
local max = math["max"]
local pow = math["pow"]
local function get_match_positions(pattern, bounds, _2_)
  local backward_3f = _2_["backward?"]
  local whole_window_3f = _2_["whole-window?"]
  local left_bound = bounds[1]
  local right_bound = bounds[2]
  local bounded_search_3f = (not vim.wo.wrap and whole_window_3f)
  local bounds_pat
  if bounded_search_3f then
    bounds_pat = ("\\(" .. "\\%>" .. (left_bound - 1) .. "v" .. "\\%<" .. (right_bound + 1) .. "v" .. "\\)")
  else
    bounds_pat = ""
  end
  local pattern0 = (bounds_pat .. pattern)
  local flags
  if backward_3f then
    flags = "bW"
  else
    flags = "W"
  end
  local stopline
  local function _5_()
    if backward_3f then
      return "w0"
    else
      return "w$"
    end
  end
  stopline = vim.fn.line(_5_())
  local saved_view = vim.fn.winsaveview()
  local saved_cpo = vim.o.cpo
  local match_at_curpos_3f = whole_window_3f
  vim.opt.cpo:remove("c")
  if whole_window_3f then
    vim.fn.cursor({vim.fn.line("w0"), 1})
  else
  end
  local positions = {}
  local win_edge_3f = {}
  local offscreen_3f = {}
  local idx = 0
  while true do
    local flags0 = ((match_at_curpos_3f and (flags .. "c")) or flags)
    match_at_curpos_3f = false
    local _local_7_ = vim.fn.searchpos(pattern0, flags0, stopline)
    local line = _local_7_[1]
    local pos = _local_7_
    if (line == 0) then
      vim.fn.winrestview(saved_view)
      vim.o.cpo = saved_cpo
      break
    elseif (vim.fn.foldclosed(line) ~= -1) then
      if backward_3f then
        vim.fn.cursor(vim.fn.foldclosed(line), 1)
      else
        vim.fn.cursor(vim.fn.foldclosedend(line), 0)
        vim.fn.cursor(0, vim.fn.col("$"))
      end
    else
      table.insert(positions, pos)
      idx = (idx + 1)
      local vcol = vim.fn.virtcol(".")
      if (vcol == right_bound) then
        win_edge_3f[idx] = true
      elseif (not vim.wo.wrap and ((vcol > right_bound) or (vcol < left_bound))) then
        offscreen_3f[idx] = true
      else
      end
    end
  end
  return positions, win_edge_3f, offscreen_3f
end
local function get_targets_in_current_window(pattern, targets, kwargs)
  local backward_3f = kwargs["backward?"]
  local offset = kwargs["offset"]
  local inputlen = kwargs["inputlen"]
  local whole_window_3f = kwargs["whole-window?"]
  local skip_curpos_3f = kwargs["skip-curpos?"]
  local offset0 = (offset or 0)
  local wininfo = vim.fn.getwininfo(api.nvim_get_current_win())[1]
  local _local_11_ = get_cursor_pos()
  local curline = _local_11_[1]
  local curcol = _local_11_[2]
  local bounds = get_horizontal_bounds()
  if inputlen then
    bounds[2] = (bounds[2] - max(0, (inputlen - 1)))
  else
  end
  local match_positions, win_edge_3f, offscreen_3f = get_match_positions(pattern, bounds, {["backward?"] = backward_3f, ["whole-window?"] = whole_window_3f})
  local prev_line = nil
  local line_str = nil
  for i, _13_ in ipairs(match_positions) do
    local line = _13_[1]
    local col = _13_[2]
    local pos = _13_
    if not (skip_curpos_3f and (line == curline) and ((col + offset0) == curcol)) then
      if (line ~= prev_line) then
        line_str = vim.fn.getline(line)
        prev_line = line
      else
      end
      local ch1 = vim.fn.strpart(line_str, (col - 1), 1, true)
      local ch2
      if ((ch1 == "") or (inputlen < 2)) then
        ch2 = ""
      else
        ch2 = vim.fn.strpart(line_str, (col + -1 + ch1:len()), 1, true)
      end
      local or_16_ = (inputlen < 2)
      if not or_16_ then
        local preview = (opts.preview_filter or opts.preview)
        or_16_ = ((type(preview) == "function") and preview(vim.fn.strpart(line_str, (col - 2), 1, true), ch1, ch2))
      end
      table.insert(targets, {wininfo = wininfo, pos = pos, chars = {ch1, ch2}, ["win-edge?"] = win_edge_3f[i], ["offscreen?"] = offscreen_3f[i], ["previewable?"] = (or_16_ or (not opts.preview_filter and (opts.preview == true)))})
    else
    end
  end
  return nil
end
local function add_directional_indexes(targets, cursor_positions, src_win)
  local _local_19_ = cursor_positions[src_win]
  local curline = _local_19_[1]
  local curcol = _local_19_[2]
  local first_after = (1 + #targets)
  local stop_3f = false
  for i, t in ipairs(targets) do
    if stop_3f then break end
    if ((t.pos[1] > curline) or ((t.pos[1] == curline) and (t.pos[2] >= curcol))) then
      first_after = i
      stop_3f = true
    else
    end
  end
  for i = 1, (first_after - 1) do
    targets[i]["idx"] = (i - first_after)
  end
  for i = first_after, #targets do
    targets[i]["idx"] = (i - (first_after - 1))
  end
  return nil
end
local function euclidean_distance(_21_, _22_)
  local l1 = _21_[1]
  local c1 = _21_[2]
  local l2 = _22_[1]
  local c2 = _22_[2]
  local editor_grid_aspect_ratio = 0.3
  local dx = (abs((c1 - c2)) * editor_grid_aspect_ratio)
  local dy = abs((l1 - l2))
  return pow(((dx * dx) + (dy * dy)), 0.5)
end
local function rank(targets, cursor_positions, src_win)
  for _, target in ipairs(targets) do
    local win = target.wininfo.winid
    local line = target.pos[1]
    local col = target.pos[2]
    local pos = target.pos
    local _let_23_ = cursor_positions[win]
    local cur_line = _let_23_[1]
    local cur_col = _let_23_[2]
    local cur_pos = _let_23_
    local distance = euclidean_distance(pos, cur_pos)
    local curr_win_bonus = ((win == src_win) and 30)
    local curr_line_bonus = (curr_win_bonus and (line == cur_line) and 999)
    local curr_line_fwd_bonus = (curr_line_bonus and (col > cur_col) and 999)
    target.rank = (distance - (curr_win_bonus or 0) - (curr_line_bonus or 0) - (curr_line_fwd_bonus or 0))
  end
  return nil
end
local function get_targets(pattern, _24_)
  local backward_3f = _24_["backward?"]
  local windows = _24_["windows"]
  local offset = _24_["offset"]
  local op_mode_3f = _24_["op-mode?"]
  local inputlen = _24_["inputlen"]
  local whole_window_3f = windows
  local src_win = api.nvim_get_current_win()
  local windows0 = (windows or {src_win})
  local curr_win_only_3f
  if ((_G.type(windows0) == "table") and (windows0[1] == src_win) and (windows0[2] == nil)) then
    curr_win_only_3f = true
  else
    curr_win_only_3f = nil
  end
  local cursor_positions = {[src_win] = get_cursor_pos()}
  local targets = {}
  for _, win in ipairs(windows0) do
    if not curr_win_only_3f then
      api.nvim_set_current_win(win)
    else
    end
    if whole_window_3f then
      cursor_positions[win] = get_cursor_pos()
    else
    end
    get_targets_in_current_window(pattern, targets, {["backward?"] = backward_3f, offset = offset, ["whole-window?"] = whole_window_3f, inputlen = inputlen, ["skip-curpos?"] = (win == src_win)})
  end
  if not curr_win_only_3f then
    api.nvim_set_current_win(src_win)
  else
  end
  if (#targets > 0) then
    if whole_window_3f then
      if (op_mode_3f and curr_win_only_3f) then
        add_directional_indexes(targets, cursor_positions, src_win)
      else
      end
      rank(targets, cursor_positions, src_win)
      local function _30_(_241, _242)
        return (_241.rank < _242.rank)
      end
      table.sort(targets, _30_)
    else
    end
    return targets
  else
    return nil
  end
end
return {["get-targets"] = get_targets}
