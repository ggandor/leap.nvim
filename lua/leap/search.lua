local _local_1_ = require("leap.util")
local inc = _local_1_["inc"]
local dec = _local_1_["dec"]
local get_cursor_pos = _local_1_["get-cursor-pos"]
local __3erepresentative_char = _local_1_["->representative-char"]
local get_char_from = _local_1_["get-char-from"]
local api = vim.api
local empty_3f = vim.tbl_isempty
local _local_2_ = math
local abs = _local_2_["abs"]
local pow = _local_2_["pow"]
local function get_horizontal_bounds()
  local window_width = api.nvim_win_get_width(0)
  local textoff = vim.fn.getwininfo(vim.fn.win_getid())[1].textoff
  local offset_in_win = dec(vim.fn.wincol())
  local offset_in_editable_win = (offset_in_win - textoff)
  local left_bound = (vim.fn.virtcol(".") - offset_in_editable_win)
  local right_bound = (left_bound + dec((window_width - textoff)))
  return {left_bound, right_bound}
end
local function get_match_positions(pattern, _3_, _5_)
  local _arg_4_ = _3_
  local left_bound = _arg_4_[1]
  local right_bound = _arg_4_[2]
  local _arg_6_ = _5_
  local backward_3f = _arg_6_["backward?"]
  local whole_window_3f = _arg_6_["whole-window?"]
  local horizontal_bounds = ((not vim.wo.wrap and ("\\%>" .. (left_bound - 1) .. "v" .. "\\%<" .. (right_bound + 1) .. "v")) or "")
  local pattern0 = (horizontal_bounds .. pattern)
  local stopline
  local function _7_()
    if backward_3f then
      return "w0"
    else
      return "w$"
    end
  end
  stopline = vim.fn.line(_7_())
  local saved_view = vim.fn.winsaveview()
  local saved_cpo = vim.o.cpo
  local cleanup
  local function _8_()
    vim.fn.winrestview(saved_view)
    vim.o.cpo = saved_cpo
    return nil
  end
  cleanup = _8_
  do end (vim.opt.cpo):remove("c")
  local match_at_curpos_3f = false
  if whole_window_3f then
    vim.fn.cursor({vim.fn.line("w0"), 1})
    match_at_curpos_3f = true
  else
  end
  local i = 0
  local at_right_bound_3f = {}
  local match_positions = {}
  local function loop()
    local flags
    local function _10_()
      if backward_3f then
        return "b"
      else
        return ""
      end
    end
    local function _11_()
      if match_at_curpos_3f then
        return "c"
      else
        return ""
      end
    end
    flags = (_10_() .. _11_())
    match_at_curpos_3f = false
    local _local_12_ = vim.fn.searchpos(pattern0, flags, stopline)
    local line = _local_12_[1]
    local col = _local_12_[2]
    local pos = _local_12_
    if (line == 0) then
      return cleanup()
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
      if (vim.fn.virtcol(".") == right_bound) then
        at_right_bound_3f[i] = true
      else
      end
      return loop()
    end
  end
  loop()
  return match_positions, at_right_bound_3f
end
local function get_targets_in_current_window(pattern, _16_)
  local _arg_17_ = _16_
  local targets = _arg_17_["targets"]
  local backward_3f = _arg_17_["backward?"]
  local whole_window_3f = _arg_17_["whole-window?"]
  local match_xxx_2a_at_the_end_3f = _arg_17_["match-xxx*-at-the-end?"]
  local skip_curpos_3f = _arg_17_["skip-curpos?"]
  local wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1]
  local _let_18_ = get_cursor_pos()
  local curline = _let_18_[1]
  local curcol = _let_18_[2]
  local _let_19_ = get_horizontal_bounds()
  local left_bound = _let_19_[1]
  local right_bound_2a = _let_19_[2]
  local right_bound = dec(right_bound_2a)
  local match_positions, at_right_bound_3f = get_match_positions(pattern, {left_bound, right_bound}, {["backward?"] = backward_3f, ["whole-window?"] = whole_window_3f})
  local line_str = nil
  local prev_match = {}
  for i, _20_ in ipairs(match_positions) do
    local _each_21_ = _20_
    local line = _each_21_[1]
    local col = _each_21_[2]
    local pos = _each_21_
    if not (skip_curpos_3f and (line == curline) and (col == curcol)) then
      if (line ~= prev_match.line) then
        line_str = vim.fn.getline(line)
      else
      end
      local start = vim.fn.charidx(line_str, (col - 1))
      local _23_ = get_char_from(line_str, start)
      if (_23_ == "") then
        if (col == 1) then
          table.insert(targets, {wininfo = wininfo, pos = pos, chars = {"\n"}, ["empty-line?"] = true})
        else
        end
      elseif (nil ~= _23_) then
        local ch1 = _23_
        local ch2
        do
          local _25_ = get_char_from(line_str, (start + 1))
          if (_25_ == "") then
            ch2 = "\n"
          elseif (nil ~= _25_) then
            local ch = _25_
            ch2 = ch
          else
            ch2 = nil
          end
        end
        local xxx_3f
        local function _27_()
          if backward_3f then
            return (col == (prev_match.col - ch1:len()))
          else
            return (col == (prev_match.col + (prev_match.ch1):len()))
          end
        end
        xxx_3f = ((line == prev_match.line) and _27_() and (__3erepresentative_char(ch2) == __3erepresentative_char((prev_match.ch2 or ""))))
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
local function distance(_32_, _34_)
  local _arg_33_ = _32_
  local l1 = _arg_33_[1]
  local c1 = _arg_33_[2]
  local _arg_35_ = _34_
  local l2 = _arg_35_[1]
  local c2 = _arg_35_[2]
  local editor_grid_aspect_ratio = 0.3
  local _let_36_ = {abs((c1 - c2)), abs((l1 - l2))}
  local dx = _let_36_[1]
  local dy = _let_36_[2]
  local dx0 = (dx * editor_grid_aspect_ratio)
  return pow((pow(dx0, 2) + pow(dy, 2)), 0.5)
end
local function sort_by_distance_from_cursor(targets, cursor_positions)
  local by_screen_pos_3f = (vim.o.wrap and (#targets < 200))
  if by_screen_pos_3f then
    for winid, _37_ in pairs(cursor_positions) do
      local _each_38_ = _37_
      local line = _each_38_[1]
      local col = _each_38_[2]
      local _local_39_ = vim.fn.screenpos(winid, line, col)
      local row = _local_39_["row"]
      local col0 = _local_39_["col"]
      cursor_positions[winid] = {row, col0}
    end
  else
  end
  for _, _41_ in ipairs(targets) do
    local _each_42_ = _41_
    local _each_43_ = _each_42_["pos"]
    local line = _each_43_[1]
    local col = _each_43_[2]
    local _each_44_ = _each_42_["wininfo"]
    local winid = _each_44_["winid"]
    local target = _each_42_
    if by_screen_pos_3f then
      local _local_45_ = vim.fn.screenpos(winid, line, col)
      local row = _local_45_["row"]
      local col0 = _local_45_["col"]
      target.screenpos = {row, col0}
    else
    end
    target.rank = distance((target.screenpos or target.pos), cursor_positions[winid])
  end
  local function _47_(_241, _242)
    return ((_241).rank < (_242).rank)
  end
  return table.sort(targets, _47_)
end
local function get_targets(pattern, _48_)
  local _arg_49_ = _48_
  local backward_3f = _arg_49_["backward?"]
  local match_xxx_2a_at_the_end_3f = _arg_49_["match-xxx*-at-the-end?"]
  local target_windows = _arg_49_["target-windows"]
  local whole_window_3f = target_windows
  local source_winid = vim.fn.win_getid()
  local target_windows0 = (target_windows or {source_winid})
  local curr_win_only_3f
  do
    local _50_ = target_windows0
    if ((_G.type(_50_) == "table") and ((_50_)[1] == source_winid) and ((_50_)[2] == nil)) then
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
    return targets
  else
    return nil
  end
end
return {["get-horizontal-bounds"] = get_horizontal_bounds, ["get-match-positions"] = get_match_positions, ["get-targets"] = get_targets}
