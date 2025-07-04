local opts = require("leap.opts")
local _local_1_ = require("leap.util")
local get_cursor_pos = _local_1_["get-cursor-pos"]
local __3erepresentative_char = _local_1_["->representative-char"]
local api = vim.api
local empty_3f = vim.tbl_isempty
local abs = math["abs"]
local pow = math["pow"]
local function get_horizontal_bounds()
  local window_width = api.nvim_win_get_width(0)
  local textoff = vim.fn.getwininfo(api.nvim_get_current_win())[1].textoff
  local offset_in_win = (vim.fn.wincol() - 1)
  local offset_in_editable_win = (offset_in_win - textoff)
  local left_bound = (vim.fn.virtcol(".") - offset_in_editable_win)
  local right_bound = (left_bound + (window_width - textoff - 1))
  return {left_bound, right_bound}
end
local function get_match_positions(pattern, _2_, _3_)
  local left_bound = _2_[1]
  local right_bound = _2_[2]
  local backward_3f = _3_["backward?"]
  local whole_window_3f = _3_["whole-window?"]
  local horizontal_bounds
  if vim.wo.wrap then
    horizontal_bounds = ""
  else
    horizontal_bounds = ("\\%>" .. (left_bound - 1) .. "v" .. "\\%<" .. (right_bound + 1) .. "v")
  end
  local pattern0 = (horizontal_bounds .. pattern)
  local flags
  if backward_3f then
    flags = "b"
  else
    flags = ""
  end
  local stopline
  local function _6_()
    if backward_3f then
      return "w0"
    else
      return "w$"
    end
  end
  stopline = vim.fn.line(_6_())
  local saved_view = vim.fn.winsaveview()
  local saved_cpo = vim.o.cpo
  local match_at_curpos_3f = whole_window_3f
  vim.opt.cpo:remove("c")
  if whole_window_3f then
    vim.fn.cursor({vim.fn.line("w0"), 1})
  else
  end
  local match_positions = {}
  local win_edge_3f = {}
  local idx = 0
  local function loop()
    local flags0 = ((match_at_curpos_3f and (flags .. "c")) or flags)
    match_at_curpos_3f = false
    local _local_8_ = vim.fn.searchpos(pattern0, flags0, stopline)
    local line = _local_8_[1]
    local pos = _local_8_
    if (line == 0) then
      vim.fn.winrestview(saved_view)
      vim.o.cpo = saved_cpo
      return nil
    elseif (vim.fn.foldclosed(line) ~= -1) then
      if backward_3f then
        vim.fn.cursor(vim.fn.foldclosed(line), 1)
      else
        vim.fn.cursor(vim.fn.foldclosedend(line), 0)
        vim.fn.cursor(0, vim.fn.col("$"))
      end
      return loop()
    else
      table.insert(match_positions, pos)
      idx = (idx + 1)
      if (vim.fn.virtcol(".") == right_bound) then
        win_edge_3f[idx] = true
      else
      end
      return loop()
    end
  end
  loop()
  return match_positions, win_edge_3f
end
local function get_targets_in_current_window(pattern, targets, _12_)
  local backward_3f = _12_["backward?"]
  local offset = _12_["offset"]
  local inputlen = _12_["inputlen"]
  local whole_window_3f = _12_["whole-window?"]
  local skip_curpos_3f = _12_["skip-curpos?"]
  local offset0 = (offset or 0)
  local wininfo = vim.fn.getwininfo(api.nvim_get_current_win())[1]
  local _local_13_ = get_cursor_pos()
  local curline = _local_13_[1]
  local curcol = _local_13_[2]
  local bounds = get_horizontal_bounds()
  if (inputlen ~= 1) then
    bounds[2] = (bounds[2] - 1)
  else
  end
  local match_positions, win_edge_3f = get_match_positions(pattern, bounds, {["backward?"] = backward_3f, ["whole-window?"] = whole_window_3f})
  local match_at_end_3f = (offset0 > 0)
  local match_at_start_3f = not match_at_end_3f
  local line_str = nil
  local prev_match = {line = nil, col = nil, ch1 = nil, ch2 = nil}
  local add_target_3f = false
  for i, _15_ in ipairs(match_positions) do
    local line = _15_[1]
    local col = _15_[2]
    local pos = _15_
    if not (skip_curpos_3f and (line == curline) and (col == curcol)) then
      if (line ~= prev_match.line) then
        line_str = vim.fn.getline(line)
      else
      end
      local ch1 = vim.fn.strpart(line_str, (col - 1), 1, true)
      local ch2 = nil
      if (ch1 == "") then
        ch1 = "\n"
        if (inputlen ~= 1) then
          ch2 = "\n"
        else
        end
        add_target_3f = true
      elseif (inputlen == 1) then
        add_target_3f = true
      else
        ch2 = vim.fn.strpart(line_str, (col + -1 + ch1:len()), 1, true)
        if (ch2 == "") then
          ch2 = "\n"
        else
        end
        local overlap_3f
        local and_19_ = (line == prev_match.line)
        if and_19_ then
          if backward_3f then
            and_19_ = (col == (prev_match.col - ch1:len()))
          else
            and_19_ = (col == (prev_match.col + prev_match.ch1:len()))
          end
        end
        overlap_3f = and_19_
        local triplet_3f = (overlap_3f and (__3erepresentative_char(ch2) == __3erepresentative_char(prev_match.ch2)))
        prev_match = {line = line, col = col, ch1 = ch1, ch2 = ch2}
        local skip_3f
        local and_21_ = triplet_3f
        if and_21_ then
          if backward_3f then
            and_21_ = match_at_end_3f
          else
            and_21_ = match_at_start_3f
          end
        end
        skip_3f = and_21_
        if skip_3f then
          add_target_3f = false
        else
          if triplet_3f then
            table.remove(targets)
          else
          end
          add_target_3f = true
        end
      end
      if add_target_3f then
        local or_26_ = (inputlen == 1) or not opts.preview_filter
        if not or_26_ then
          if (ch1 == "\n") then
            or_26_ = opts.preview_filter("", ch1, "")
          else
            or_26_ = opts.preview_filter(vim.fn.strpart(line_str, (col - 2), 1, true), ch1, ch2)
          end
        end
        table.insert(targets, {wininfo = wininfo, pos = pos, chars = {ch1, ch2}, ["win-edge?"] = win_edge_3f[i], ["previewable?"] = or_26_})
      else
      end
    else
    end
  end
  return nil
end
local function distance(_30_, _31_)
  local l1 = _30_[1]
  local c1 = _30_[2]
  local l2 = _31_[1]
  local c2 = _31_[2]
  local editor_grid_aspect_ratio = 0.3
  local dx = (abs((c1 - c2)) * editor_grid_aspect_ratio)
  local dy = abs((l1 - l2))
  return pow(((dx * dx) + (dy * dy)), 0.5)
end
local function sort_by_distance_from_cursor(targets, cursor_positions, source_winid)
  local by_screen_pos_3f = (vim.o.wrap and (#targets < 200))
  local _let_32_ = (cursor_positions[source_winid] or {-1, -1})
  local source_line = _let_32_[1]
  local source_col = _let_32_[2]
  if by_screen_pos_3f then
    for winid, _33_ in pairs(cursor_positions) do
      local line = _33_[1]
      local col = _33_[2]
      local screenpos = vim.fn.screenpos(winid, line, col)
      cursor_positions[winid] = {screenpos.row, screenpos.col}
    end
  else
  end
  for _, _35_ in ipairs(targets) do
    local _each_36_ = _35_["pos"]
    local line = _each_36_[1]
    local col = _each_36_[2]
    local _each_37_ = _35_["wininfo"]
    local winid = _each_37_["winid"]
    local target = _35_
    if by_screen_pos_3f then
      local screenpos = vim.fn.screenpos(winid, line, col)
      target.rank = distance({screenpos.row, screenpos.col}, cursor_positions[winid])
    else
      target.rank = distance(target.pos, cursor_positions[winid])
    end
    if (winid == source_winid) then
      target.rank = (target.rank - 30)
      if (line == source_line) then
        target.rank = (target.rank - 999)
        if (col >= source_col) then
          target.rank = (target.rank - 999)
        else
        end
      else
      end
    else
    end
  end
  local function _42_(_241, _242)
    return (_241.rank < _242.rank)
  end
  return table.sort(targets, _42_)
end
local function get_targets(pattern, _43_)
  local backward_3f = _43_["backward?"]
  local offset = _43_["offset"]
  local op_mode_3f = _43_["op-mode?"]
  local target_windows = _43_["target-windows"]
  local inputlen = _43_["inputlen"]
  local whole_window_3f = target_windows
  local source_winid = api.nvim_get_current_win()
  local target_windows0 = (target_windows or {source_winid})
  local curr_win_only_3f
  if ((_G.type(target_windows0) == "table") and (target_windows0[1] == source_winid) and (target_windows0[2] == nil)) then
    curr_win_only_3f = true
  else
    curr_win_only_3f = nil
  end
  local cursor_positions = {}
  local targets = {}
  for _, winid in ipairs(target_windows0) do
    if not curr_win_only_3f then
      api.nvim_set_current_win(winid)
    else
    end
    if whole_window_3f then
      cursor_positions[winid] = get_cursor_pos()
    else
    end
    get_targets_in_current_window(pattern, targets, {["backward?"] = backward_3f, offset = offset, ["whole-window?"] = whole_window_3f, inputlen = inputlen, ["skip-curpos?"] = (winid == source_winid)})
  end
  if not curr_win_only_3f then
    api.nvim_set_current_win(source_winid)
  else
  end
  if not empty_3f(targets) then
    if whole_window_3f then
      if (op_mode_3f and curr_win_only_3f) then
        local _local_48_ = cursor_positions[source_winid]
        local curline = _local_48_[1]
        local curcol = _local_48_[2]
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
      else
      end
      sort_by_distance_from_cursor(targets, cursor_positions, source_winid)
    else
    end
    return targets
  else
    return nil
  end
end
return {["get-horizontal-bounds"] = get_horizontal_bounds, ["get-match-positions"] = get_match_positions, ["get-targets"] = get_targets}
