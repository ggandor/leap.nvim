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
local function to_next_in_window_pos_21(backward_3f, left_bound, right_bound, stopline)
  local forward_3f = not backward_3f
  local _let_3_ = {vim.fn.line("."), vim.fn.virtcol(".")}
  local line = _let_3_[1]
  local virtcol = _let_3_[2]
  local left_off_3f = (virtcol < left_bound)
  local right_off_3f = (virtcol > right_bound)
  local _4_
  if (left_off_3f and backward_3f) then
    _4_ = {dec(line), right_bound}
  elseif (left_off_3f and forward_3f) then
    _4_ = {line, left_bound}
  elseif (right_off_3f and backward_3f) then
    _4_ = {line, right_bound}
  elseif (right_off_3f and forward_3f) then
    _4_ = {inc(line), left_bound}
  else
    _4_ = nil
  end
  if ((_G.type(_4_) == "table") and (nil ~= (_4_)[1]) and (nil ~= (_4_)[2])) then
    local line_2a = (_4_)[1]
    local virtcol_2a = (_4_)[2]
    if not (((line == line_2a) and (virtcol == virtcol_2a)) or (backward_3f and (line_2a < stopline)) or (forward_3f and (line_2a > stopline))) then
      vim.fn.cursor({line_2a, vim.fn.virtcol2col(0, line_2a, virtcol_2a)})
      return "moved"
    else
      return nil
    end
  else
    return nil
  end
end
local function get_match_positions(pattern, _8_, _10_)
  local _arg_9_ = _8_
  local left_bound = _arg_9_[1]
  local right_bound = _arg_9_[2]
  local _arg_11_ = _10_
  local backward_3f = _arg_11_["backward?"]
  local whole_window_3f = _arg_11_["whole-window?"]
  local stopline
  local function _12_()
    if backward_3f then
      return "w0"
    else
      return "w$"
    end
  end
  stopline = vim.fn.line(_12_())
  local saved_view = vim.fn.winsaveview()
  local saved_cpo = vim.o.cpo
  local cleanup
  local function _13_()
    vim.fn.winrestview(saved_view)
    vim.o.cpo = saved_cpo
    return nil
  end
  cleanup = _13_
  do end (vim.opt.cpo):remove("c")
  local match_at_curpos_3f = false
  if whole_window_3f then
    vim.fn.cursor({vim.fn.line("w0"), left_bound})
    match_at_curpos_3f = true
  else
  end
  local res = {}
  local function loop()
    local flags
    local function _15_()
      if backward_3f then
        return "b"
      else
        return ""
      end
    end
    local function _16_()
      if match_at_curpos_3f then
        return "c"
      else
        return ""
      end
    end
    flags = (_15_() .. _16_())
    match_at_curpos_3f = false
    local _local_17_ = vim.fn.searchpos(pattern, flags, stopline)
    local line = _local_17_[1]
    local col = _local_17_[2]
    local pos = _local_17_
    if (line == 0) then
      return cleanup()
    elseif not (vim.wo.wrap or (function(_18_,_19_,_20_) return (_18_ <= _19_) and (_19_ <= _20_) end)(left_bound,vim.fn.virtcol("."),right_bound)) then
      local _21_ = to_next_in_window_pos_21(backward_3f, left_bound, right_bound, stopline)
      if (_21_ == "moved") then
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
      table.insert(res, pos)
      return loop()
    end
  end
  loop()
  return res
end
local function get_targets_in_current_window(pattern, _25_)
  local _arg_26_ = _25_
  local targets = _arg_26_["targets"]
  local backward_3f = _arg_26_["backward?"]
  local whole_window_3f = _arg_26_["whole-window?"]
  local match_last_overlapping_3f = _arg_26_["match-last-overlapping?"]
  local skip_curpos_3f = _arg_26_["skip-curpos?"]
  local wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1]
  local _let_27_ = get_cursor_pos()
  local curline = _let_27_[1]
  local curcol = _let_27_[2]
  local _let_28_ = get_horizontal_bounds()
  local left_bound = _let_28_[1]
  local right_bound_2a = _let_28_[2]
  local right_bound = dec(right_bound_2a)
  local right_bound_at = {}
  local window_edge_3f
  local function _29_(line, col)
    if not right_bound_at[line] then
      right_bound_at[line] = vim.fn.virtcol2col(0, line, right_bound)
    else
    end
    return (col == right_bound_at[line])
  end
  window_edge_3f = _29_
  local match_positions = get_match_positions(pattern, {left_bound, right_bound}, {["backward?"] = backward_3f, ["whole-window?"] = whole_window_3f})
  local prev_match = {}
  for _, _31_ in ipairs(match_positions) do
    local _each_32_ = _31_
    local line = _each_32_[1]
    local col = _each_32_[2]
    local pos = _each_32_
    if not (skip_curpos_3f and (line == curline) and (col == curcol)) then
      local _33_ = get_char_at(pos, {})
      if (_33_ == nil) then
        if (col == 1) then
          table.insert(targets, {wininfo = wininfo, pos = pos, chars = {"\n"}, ["empty-line?"] = true})
        else
        end
      elseif (nil ~= _33_) then
        local ch1 = _33_
        local ch2 = (get_char_at(pos, {["char-offset"] = 1}) or "\n")
        local overlap_3f
        local function _35_()
          if backward_3f then
            return (col == (prev_match.col - ch1:len()))
          else
            return (col == (prev_match.col + (prev_match.ch1):len()))
          end
        end
        overlap_3f = ((line == prev_match.line) and _35_() and (__3erepresentative_char(ch2) == __3erepresentative_char((prev_match.ch2 or ""))))
        prev_match = {line = line, col = col, ch1 = ch1, ch2 = ch2}
        if (not overlap_3f or match_last_overlapping_3f) then
          if (overlap_3f and match_last_overlapping_3f) then
            table.remove(targets)
          else
          end
          table.insert(targets, {wininfo = wininfo, pos = pos, chars = {ch1, ch2}, ["edge-pos?"] = ((ch2 == "\n") or window_edge_3f(line, col))})
        else
        end
      else
      end
    else
    end
  end
  if not empty_3f(targets) then
    return targets
  else
    return nil
  end
end
local function distance(_41_, _43_)
  local _arg_42_ = _41_
  local l1 = _arg_42_[1]
  local c1 = _arg_42_[2]
  local _arg_44_ = _43_
  local l2 = _arg_44_[1]
  local c2 = _arg_44_[2]
  local editor_grid_aspect_ratio = 0.3
  local _let_45_ = {abs((c1 - c2)), abs((l1 - l2))}
  local dx = _let_45_[1]
  local dy = _let_45_[2]
  local dx0 = (dx * editor_grid_aspect_ratio)
  return pow((pow(dx0, 2) + pow(dy, 2)), 0.5)
end
local function sort_by_distance_from_cursor(targets, cursor_positions)
  local by_screen_pos_3f = (vim.o.wrap and (#targets < 200))
  if by_screen_pos_3f then
    for winid, _46_ in pairs(cursor_positions) do
      local _each_47_ = _46_
      local line = _each_47_[1]
      local col = _each_47_[2]
      local _local_48_ = vim.fn.screenpos(winid, line, col)
      local row = _local_48_["row"]
      local col0 = _local_48_["col"]
      cursor_positions[winid] = {row, col0}
    end
  else
  end
  for _, _50_ in ipairs(targets) do
    local _each_51_ = _50_
    local _each_52_ = _each_51_["pos"]
    local line = _each_52_[1]
    local col = _each_52_[2]
    local _each_53_ = _each_51_["wininfo"]
    local winid = _each_53_["winid"]
    local target = _each_51_
    if by_screen_pos_3f then
      local _local_54_ = vim.fn.screenpos(winid, line, col)
      local row = _local_54_["row"]
      local col0 = _local_54_["col"]
      target.screenpos = {row, col0}
    else
    end
    target.rank = distance((target.screenpos or target.pos), cursor_positions[winid])
  end
  local function _56_(_241, _242)
    return ((_241).rank < (_242).rank)
  end
  return table.sort(targets, _56_)
end
local function get_targets(pattern, _57_)
  local _arg_58_ = _57_
  local backward_3f = _arg_58_["backward?"]
  local match_last_overlapping_3f = _arg_58_["match-last-overlapping?"]
  local target_windows = _arg_58_["target-windows"]
  local whole_window_3f = target_windows
  local source_winid = vim.fn.win_getid()
  local target_windows0 = (target_windows or {source_winid})
  local curr_win_only_3f
  do
    local _59_ = target_windows0
    if ((_G.type(_59_) == "table") and ((_59_)[1] == source_winid) and ((_59_)[2] == nil)) then
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
    get_targets_in_current_window(pattern, {targets = targets, ["backward?"] = backward_3f, ["whole-window?"] = whole_window_3f, ["match-last-overlapping?"] = match_last_overlapping_3f, ["skip-curpos?"] = (winid == source_winid)})
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
