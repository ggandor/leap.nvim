local _local_1_ = require("leap.util")
local inc = _local_1_["inc"]
local dec = _local_1_["dec"]
local replace_keycodes = _local_1_["replace-keycodes"]
local get_cursor_pos = _local_1_["get-cursor-pos"]
local push_cursor_21 = _local_1_["push-cursor!"]
local get_char_at = _local_1_["get-char-at"]
local __3erepresentative_char = _local_1_["->representative-char"]
local api = vim.api
local empty_3f = vim.tbl_isempty
local _local_2_ = math
local abs = _local_2_["abs"]
local pow = _local_2_["pow"]
local function get_horizontal_bounds()
  local textoff = vim.fn.getwininfo(vim.fn.win_getid())[1].textoff
  local offset_in_win = dec(vim.fn.wincol())
  local offset_in_editable_win = (offset_in_win - textoff)
  local left_bound = (vim.fn.virtcol(".") - offset_in_editable_win)
  local window_width = api.nvim_win_get_width(0)
  local right_bound = (left_bound + dec((window_width - textoff)))
  return {left_bound, right_bound}
end
local function next_in_window_pos(line, virtcol, backward_3f, left_bound, right_bound, stopline)
  local forward_3f = not backward_3f
  local left_off_3f = (virtcol < left_bound)
  local right_off_3f = (virtcol > right_bound)
  local _3_
  if (left_off_3f and backward_3f) then
    _3_ = {dec(line), right_bound}
  elseif (left_off_3f and forward_3f) then
    _3_ = {line, left_bound}
  elseif (right_off_3f and backward_3f) then
    _3_ = {line, right_bound}
  elseif (right_off_3f and forward_3f) then
    _3_ = {inc(line), left_bound}
  else
    _3_ = nil
  end
  if ((_G.type(_3_) == "table") and (nil ~= (_3_)[1]) and (nil ~= (_3_)[2])) then
    local line_2a = (_3_)[1]
    local virtcol_2a = (_3_)[2]
    if not (((line == line_2a) and (virtcol == virtcol_2a)) or (backward_3f and (line_2a < stopline)) or (forward_3f and (line_2a > stopline))) then
      return {line_2a, vim.fn.virtcol2col(0, line_2a, virtcol_2a)}
    else
      return nil
    end
  else
    return nil
  end
end
local function get_match_positions(pattern, _7_, _9_)
  local _arg_8_ = _7_
  local left_bound = _arg_8_[1]
  local right_bound = _arg_8_[2]
  local _arg_10_ = _9_
  local backward_3f = _arg_10_["backward?"]
  local whole_window_3f = _arg_10_["whole-window?"]
  local stopline
  local function _11_()
    if backward_3f then
      return "w0"
    else
      return "w$"
    end
  end
  stopline = vim.fn.line(_11_())
  local saved_view = vim.fn.winsaveview()
  local saved_cpo = vim.o.cpo
  local cleanup
  local function _12_()
    vim.fn.winrestview(saved_view)
    vim.o.cpo = saved_cpo
    return nil
  end
  cleanup = _12_
  do end (vim.opt.cpo):remove("c")
  local match_at_curpos_3f = false
  if whole_window_3f then
    vim.fn.cursor({vim.fn.line("w0"), left_bound})
    match_at_curpos_3f = true
  else
  end
  local i = 0
  local at_right_bound_3f = {}
  local match_positions = {}
  local function loop()
    local flags
    local function _14_()
      if backward_3f then
        return "b"
      else
        return ""
      end
    end
    local function _15_()
      if match_at_curpos_3f then
        return "c"
      else
        return ""
      end
    end
    flags = (_14_() .. _15_())
    match_at_curpos_3f = false
    local _local_16_ = vim.fn.searchpos(pattern, flags, stopline)
    local line = _local_16_[1]
    local col = _local_16_[2]
    local pos = _local_16_
    local virtcol = vim.fn.virtcol(".")
    if (line == 0) then
      return cleanup()
    elseif not (vim.wo.wrap or (left_bound <= virtcol) and (virtcol <= right_bound)) then
      local _17_ = next_in_window_pos(line, virtcol, backward_3f, left_bound, right_bound, stopline)
      if (nil ~= _17_) then
        local pos0 = _17_
        vim.fn.cursor(pos0)
        match_at_curpos_3f = true
        return loop()
      else
        return nil
      end
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
      i = (i + 1)
      if (virtcol == right_bound) then
        at_right_bound_3f[i] = true
      else
      end
      return loop()
    end
  end
  loop()
  return match_positions, at_right_bound_3f
end
local function get_targets_in_current_window(pattern, _22_)
  local _arg_23_ = _22_
  local targets = _arg_23_["targets"]
  local backward_3f = _arg_23_["backward?"]
  local whole_window_3f = _arg_23_["whole-window?"]
  local match_xxx_2a_at_the_end_3f = _arg_23_["match-xxx*-at-the-end?"]
  local skip_curpos_3f = _arg_23_["skip-curpos?"]
  local wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1]
  local _let_24_ = get_cursor_pos()
  local curline = _let_24_[1]
  local curcol = _let_24_[2]
  local _let_25_ = get_horizontal_bounds()
  local left_bound = _let_25_[1]
  local right_bound_2a = _let_25_[2]
  local right_bound = dec(right_bound_2a)
  local match_positions, at_right_bound_3f = get_match_positions(pattern, {left_bound, right_bound}, {["backward?"] = backward_3f, ["whole-window?"] = whole_window_3f})
  local prev_match = {}
  for i, _26_ in ipairs(match_positions) do
    local _each_27_ = _26_
    local line = _each_27_[1]
    local col = _each_27_[2]
    local pos = _each_27_
    if not (skip_curpos_3f and (line == curline) and (col == curcol)) then
      local _28_ = get_char_at(pos, {})
      if (_28_ == nil) then
        if (col == 1) then
          table.insert(targets, {wininfo = wininfo, pos = pos, chars = {"\n"}, ["empty-line?"] = true})
        else
        end
      elseif (nil ~= _28_) then
        local ch1 = _28_
        local ch2 = (get_char_at(pos, {["char-offset"] = 1}) or "\n")
        local xxx_3f
        local function _30_()
          if backward_3f then
            return (col == (prev_match.col - ch1:len()))
          else
            return (col == (prev_match.col + (prev_match.ch1):len()))
          end
        end
        xxx_3f = ((line == prev_match.line) and _30_() and (__3erepresentative_char(ch2) == __3erepresentative_char((prev_match.ch2 or ""))))
        prev_match = {line = line, col = col, ch1 = ch1, ch2 = ch2}
        if (not xxx_3f or (xxx_3f and match_xxx_2a_at_the_end_3f)) then
          if (xxx_3f and match_xxx_2a_at_the_end_3f) then
            table.remove(targets)
          else
          end
          table.insert(targets, {wininfo = wininfo, pos = pos, chars = {ch1, ch2}, ["edge-pos?"] = ((at_right_bound_3f)[i] or (ch2 == "\n"))})
        else
        end
      else
      end
    else
    end
  end
  return nil
end
local function distance(_35_, _37_)
  local _arg_36_ = _35_
  local l1 = _arg_36_[1]
  local c1 = _arg_36_[2]
  local _arg_38_ = _37_
  local l2 = _arg_38_[1]
  local c2 = _arg_38_[2]
  local editor_grid_aspect_ratio = 0.3
  local _let_39_ = {abs((c1 - c2)), abs((l1 - l2))}
  local dx = _let_39_[1]
  local dy = _let_39_[2]
  local dx0 = (dx * editor_grid_aspect_ratio)
  return pow((pow(dx0, 2) + pow(dy, 2)), 0.5)
end
local function sort_by_distance_from_cursor(targets, cursor_positions)
  local by_screen_pos_3f = (vim.o.wrap and (#targets < 200))
  if by_screen_pos_3f then
    for winid, _40_ in pairs(cursor_positions) do
      local _each_41_ = _40_
      local line = _each_41_[1]
      local col = _each_41_[2]
      local _local_42_ = vim.fn.screenpos(winid, line, col)
      local row = _local_42_["row"]
      local col0 = _local_42_["col"]
      cursor_positions[winid] = {row, col0}
    end
  else
  end
  for _, _44_ in ipairs(targets) do
    local _each_45_ = _44_
    local _each_46_ = _each_45_["pos"]
    local line = _each_46_[1]
    local col = _each_46_[2]
    local _each_47_ = _each_45_["wininfo"]
    local winid = _each_47_["winid"]
    local target = _each_45_
    if by_screen_pos_3f then
      local _local_48_ = vim.fn.screenpos(winid, line, col)
      local row = _local_48_["row"]
      local col0 = _local_48_["col"]
      target.screenpos = {row, col0}
    else
    end
    target.rank = distance((target.screenpos or target.pos), cursor_positions[winid])
  end
  local function _50_(_241, _242)
    return ((_241).rank < (_242).rank)
  end
  return table.sort(targets, _50_)
end
local function get_targets(pattern, _51_)
  local _arg_52_ = _51_
  local backward_3f = _arg_52_["backward?"]
  local match_xxx_2a_at_the_end_3f = _arg_52_["match-xxx*-at-the-end?"]
  local target_windows = _arg_52_["target-windows"]
  local whole_window_3f = target_windows
  local source_winid = vim.fn.win_getid()
  local target_windows0 = (target_windows or {source_winid})
  local curr_win_only_3f
  do
    local _53_ = target_windows0
    if ((_G.type(_53_) == "table") and ((_53_)[1] == source_winid) and ((_53_)[2] == nil)) then
      curr_win_only_3f = true
    else
      curr_win_only_3f = nil
    end
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
    get_targets_in_current_window(pattern, {targets = targets, ["backward?"] = backward_3f, ["whole-window?"] = whole_window_3f, ["match-xxx*-at-the-end?"] = match_xxx_2a_at_the_end_3f, ["skip-curpos?"] = (winid == source_winid)})
  end
  if not curr_win_only_3f then
    api.nvim_set_current_win(source_winid)
  else
  end
  if not empty_3f(targets) then
    if whole_window_3f then
      sort_by_distance_from_cursor(targets, cursor_positions)
    else
    end
  else
  end
  return targets
end
return {["get-horizontal-bounds"] = get_horizontal_bounds, ["get-match-positions"] = get_match_positions, ["get-targets"] = get_targets}
