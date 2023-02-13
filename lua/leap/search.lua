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
    if (((line == line_2a) and (virtcol == virtcol_2a)) or (backward_3f and (line_2a < stopline)) or (forward_3f and (line_2a > stopline))) then
      return "dead-end"
    else
      vim.fn.cursor({line_2a, virtcol_2a})
      if backward_3f then
        while ((vim.fn.virtcol(".") < right_bound) and (vim.fn.col(".") < dec(vim.fn.col("$")))) do
          vim.cmd("norm! l")
        end
        return nil
      else
        return nil
      end
    end
  else
    return nil
  end
end
local function get_match_positions(pattern, _9_, _11_)
  local _arg_10_ = _9_
  local left_bound = _arg_10_[1]
  local right_bound = _arg_10_[2]
  local _arg_12_ = _11_
  local backward_3f = _arg_12_["backward?"]
  local whole_window_3f = _arg_12_["whole-window?"]
  local wintop = vim.fn.line("w0")
  local winbot = vim.fn.line("w$")
  local stopline
  if backward_3f then
    stopline = wintop
  else
    stopline = winbot
  end
  local saved_view = vim.fn.winsaveview()
  local saved_cpo = vim.o.cpo
  local cleanup
  local function _14_()
    vim.fn.winrestview(saved_view)
    vim.o.cpo = saved_cpo
    return nil
  end
  cleanup = _14_
  local match_at_curpos_3f = false
  if whole_window_3f then
    vim.fn.cursor({wintop, left_bound})
    match_at_curpos_3f = true
  else
  end
  do end (vim.opt.cpo):remove("c")
  local res = {}
  local function loop()
    local flags
    local function _16_()
      if backward_3f then
        return "b"
      else
        return ""
      end
    end
    local function _17_()
      if match_at_curpos_3f then
        return "c"
      else
        return ""
      end
    end
    flags = (_16_() .. _17_())
    match_at_curpos_3f = false
    local _18_ = vim.fn.searchpos(pattern, flags, stopline)
    if ((_G.type(_18_) == "table") and (nil ~= (_18_)[1]) and (nil ~= (_18_)[2])) then
      local line = (_18_)[1]
      local col = (_18_)[2]
      local pos = _18_
      if (line == 0) then
        return cleanup()
      elseif not (vim.wo.wrap or (function(_19_,_20_,_21_) return (_19_ <= _20_) and (_20_ <= _21_) end)(left_bound,vim.fn.virtcol("."),right_bound)) then
        local _22_ = to_next_in_window_pos_21(backward_3f, left_bound, right_bound, stopline)
        if (_22_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _22_
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
    else
      return nil
    end
  end
  loop()
  return res
end
local function get_targets_in_current_window(pattern, _27_)
  local _arg_28_ = _27_
  local targets = _arg_28_["targets"]
  local backward_3f = _arg_28_["backward?"]
  local whole_window_3f = _arg_28_["whole-window?"]
  local match_last_overlapping_3f = _arg_28_["match-last-overlapping?"]
  local skip_curpos_3f = _arg_28_["skip-curpos?"]
  local targets0 = (targets or {})
  local wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1]
  local _let_29_ = get_cursor_pos()
  local curline = _let_29_[1]
  local curcol = _let_29_[2]
  local _let_30_ = get_horizontal_bounds()
  local left_bound = _let_30_[1]
  local right_bound_2a = _let_30_[2]
  local right_bound = dec(right_bound_2a)
  local match_positions = get_match_positions(pattern, {left_bound, right_bound}, {["backward?"] = backward_3f, ["whole-window?"] = whole_window_3f})
  local register_target
  local function _31_(target)
    target.wininfo = wininfo
    return table.insert(targets0, target)
  end
  register_target = _31_
  local prev_match = {}
  for _, _32_ in ipairs(match_positions) do
    local _each_33_ = _32_
    local line = _each_33_[1]
    local col = _each_33_[2]
    local pos = _each_33_
    if not (skip_curpos_3f and (line == curline) and (col == curcol)) then
      local _34_ = get_char_at(pos, {})
      if (_34_ == nil) then
        if (col == 1) then
          register_target({pos = pos, chars = {"\n"}, ["empty-line?"] = true})
        else
        end
      elseif (nil ~= _34_) then
        local ch1 = _34_
        local ch2 = (get_char_at(pos, {["char-offset"] = 1}) or "\n")
        local edge_pos_3f = ((ch2 == "\n") or (col == right_bound))
        local overlap_3f
        local function _36_()
          if backward_3f then
            return ((prev_match.col - col) == ch1:len())
          else
            return ((col - prev_match.col) == (prev_match.ch1):len())
          end
        end
        overlap_3f = ((line == prev_match.line) and _36_() and (__3erepresentative_char(ch2) == __3erepresentative_char((prev_match.ch2 or ""))))
        prev_match = {line = line, col = col, ch1 = ch1, ch2 = ch2}
        if (not overlap_3f or match_last_overlapping_3f) then
          if (overlap_3f and match_last_overlapping_3f) then
            table.remove(targets0)
          else
          end
          register_target({pos = pos, chars = {ch1, ch2}, ["edge-pos?"] = edge_pos_3f})
        else
        end
      else
      end
    else
    end
  end
  if not empty_3f(targets0) then
    return targets0
  else
    return nil
  end
end
local function distance(_42_, _44_)
  local _arg_43_ = _42_
  local l1 = _arg_43_[1]
  local c1 = _arg_43_[2]
  local _arg_45_ = _44_
  local l2 = _arg_45_[1]
  local c2 = _arg_45_[2]
  local editor_grid_aspect_ratio = 0.3
  local _let_46_ = {abs((c1 - c2)), abs((l1 - l2))}
  local dx = _let_46_[1]
  local dy = _let_46_[2]
  local dx0 = (dx * editor_grid_aspect_ratio)
  return pow((pow(dx0, 2) + pow(dy, 2)), 0.5)
end
local function get_targets(pattern, _47_)
  local _arg_48_ = _47_
  local backward_3f = _arg_48_["backward?"]
  local match_last_overlapping_3f = _arg_48_["match-last-overlapping?"]
  local target_windows = _arg_48_["target-windows"]
  if not target_windows then
    return get_targets_in_current_window(pattern, {["backward?"] = backward_3f, ["match-last-overlapping?"] = match_last_overlapping_3f})
  else
    local targets = {}
    local cursor_positions = {}
    local source_winid = vim.fn.win_getid()
    local curr_win_only_3f
    do
      local _49_ = target_windows
      if ((_G.type(_49_) == "table") and ((_49_)[1] == source_winid) and ((_49_)[2] == nil)) then
        curr_win_only_3f = true
      else
        curr_win_only_3f = nil
      end
    end
    for _, winid in ipairs(target_windows) do
      if not curr_win_only_3f then
        api.nvim_set_current_win(winid)
      else
      end
      cursor_positions[winid] = get_cursor_pos()
      get_targets_in_current_window(pattern, {targets = targets, ["whole-window?"] = true, ["match-last-overlapping?"] = match_last_overlapping_3f, ["skip-curpos?"] = (winid == source_winid)})
    end
    if not curr_win_only_3f then
      api.nvim_set_current_win(source_winid)
    else
    end
    if not empty_3f(targets) then
      local by_screen_pos_3f = (vim.o.wrap and (#targets < 200))
      if by_screen_pos_3f then
        for winid, _53_ in pairs(cursor_positions) do
          local _each_54_ = _53_
          local line = _each_54_[1]
          local col = _each_54_[2]
          local _55_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_55_) == "table") and (nil ~= (_55_).row) and ((_55_).col == col)) then
            local row = (_55_).row
            cursor_positions[winid] = {row, col}
          else
          end
        end
      else
      end
      for _, _58_ in ipairs(targets) do
        local _each_59_ = _58_
        local _each_60_ = _each_59_["pos"]
        local line = _each_60_[1]
        local col = _each_60_[2]
        local _each_61_ = _each_59_["wininfo"]
        local winid = _each_61_["winid"]
        local t = _each_59_
        if by_screen_pos_3f then
          local _62_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_62_) == "table") and (nil ~= (_62_).row) and ((_62_).col == col)) then
            local row = (_62_).row
            t.screenpos = {row, col}
          else
          end
        else
        end
        t.rank = distance((t.screenpos or t.pos), cursor_positions[winid])
      end
      local function _65_(_241, _242)
        return ((_241).rank < (_242).rank)
      end
      table.sort(targets, _65_)
      return targets
    else
      return nil
    end
  end
end
return {["get-horizontal-bounds"] = get_horizontal_bounds, ["get-match-positions"] = get_match_positions, ["get-targets"] = get_targets}
