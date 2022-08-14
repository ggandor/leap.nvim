local opts = require("leap.opts")
local _local_1_ = require("leap.util")
local inc = _local_1_["inc"]
local dec = _local_1_["dec"]
local replace_keycodes = _local_1_["replace-keycodes"]
local get_cursor_pos = _local_1_["get-cursor-pos"]
local push_cursor_21 = _local_1_["push-cursor!"]
local get_char_at = _local_1_["get-char-at"]
local api = vim.api
local empty_3f = vim.tbl_isempty
local _local_2_ = math
local abs = _local_2_["abs"]
local pow = _local_2_["pow"]
local function get_horizontal_bounds()
  local match_length = 2
  local textoff = vim.fn.getwininfo(vim.fn.win_getid())[1].textoff
  local offset_in_win = dec(vim.fn.wincol())
  local offset_in_editable_win = (offset_in_win - textoff)
  local left_bound = (vim.fn.virtcol(".") - offset_in_editable_win)
  local window_width = api.nvim_win_get_width(0)
  local right_edge = (left_bound + dec((window_width - textoff)))
  local right_bound = (right_edge - dec(match_length))
  return {left_bound, right_bound}
end
local function skip_one_21(backward_3f)
  local new_line
  local function _3_()
    if backward_3f then
      return "bwd"
    else
      return "fwd"
    end
  end
  new_line = push_cursor_21(_3_())
  if (new_line == 0) then
    return "dead-end"
  else
    return nil
  end
end
local function to_closed_fold_edge_21(backward_3f)
  local edge_line
  local _5_
  if backward_3f then
    _5_ = vim.fn.foldclosed
  else
    _5_ = vim.fn.foldclosedend
  end
  edge_line = _5_(vim.fn.line("."))
  vim.fn.cursor(edge_line, 0)
  local edge_col
  if backward_3f then
    edge_col = 1
  else
    edge_col = vim.fn.col("$")
  end
  return vim.fn.cursor(0, edge_col)
end
local function reach_right_bound_21(right_bound)
  while ((vim.fn.virtcol(".") < right_bound) and not (vim.fn.col(".") >= dec(vim.fn.col("$")))) do
    vim.cmd("norm! l")
  end
  return nil
end
local function to_next_in_window_pos_21(backward_3f, left_bound, right_bound, stopline)
  local _let_8_ = {vim.fn.line("."), vim.fn.virtcol(".")}
  local line = _let_8_[1]
  local virtcol = _let_8_[2]
  local from_pos = _let_8_
  local left_off_3f = (virtcol < left_bound)
  local right_off_3f = (virtcol > right_bound)
  local _9_
  if (left_off_3f and backward_3f) then
    if (dec(line) >= stopline) then
      _9_ = {dec(line), right_bound}
    else
      _9_ = nil
    end
  elseif (left_off_3f and not backward_3f) then
    _9_ = {line, left_bound}
  elseif (right_off_3f and backward_3f) then
    _9_ = {line, right_bound}
  elseif (right_off_3f and not backward_3f) then
    if (inc(line) <= stopline) then
      _9_ = {inc(line), left_bound}
    else
      _9_ = nil
    end
  else
    _9_ = nil
  end
  if (nil ~= _9_) then
    local to_pos = _9_
    if (from_pos == to_pos) then
      return "dead-end"
    else
      vim.fn.cursor(to_pos)
      if backward_3f then
        return reach_right_bound_21(right_bound)
      else
        return nil
      end
    end
  else
    return nil
  end
end
local function get_match_positions(pattern, _16_, _18_)
  local _arg_17_ = _16_
  local left_bound = _arg_17_[1]
  local right_bound = _arg_17_[2]
  local _arg_19_ = _18_
  local backward_3f = _arg_19_["backward?"]
  local whole_window_3f = _arg_19_["whole-window?"]
  local skip_curpos_3f = _arg_19_["skip-curpos?"]
  local skip_orig_curpos_3f = skip_curpos_3f
  local _let_20_ = get_cursor_pos()
  local orig_curline = _let_20_[1]
  local orig_curcol = _let_20_[2]
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
  local function _22_()
    vim.fn.winrestview(saved_view)
    vim.o.cpo = saved_cpo
    return nil
  end
  cleanup = _22_
  vim.o.cpo = (vim.o.cpo):gsub("c", "")
  local match_count = 0
  local moved_to_topleft_3f
  if whole_window_3f then
    vim.fn.cursor({wintop, left_bound})
    moved_to_topleft_3f = true
  else
    moved_to_topleft_3f = nil
  end
  local function iter(match_at_curpos_3f)
    local match_at_curpos_3f0 = (match_at_curpos_3f or moved_to_topleft_3f)
    local flags
    local function _24_()
      if backward_3f then
        return "b"
      else
        return ""
      end
    end
    local function _25_()
      if match_at_curpos_3f0 then
        return "c"
      else
        return ""
      end
    end
    flags = (_24_() .. _25_())
    moved_to_topleft_3f = false
    local _26_ = vim.fn.searchpos(pattern, flags, stopline)
    if ((_G.type(_26_) == "table") and (nil ~= (_26_)[1]) and (nil ~= (_26_)[2])) then
      local line = (_26_)[1]
      local col = (_26_)[2]
      local pos = _26_
      if (line == 0) then
        return cleanup()
      elseif ((line == orig_curline) and (col == orig_curcol) and skip_orig_curpos_3f) then
        local _27_ = skip_one_21()
        if (_27_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _27_
          return iter(true)
        else
          return nil
        end
      elseif not (vim.wo.wrap or (function(_29_,_30_,_31_) return (_29_ <= _30_) and (_30_ <= _31_) end)(left_bound,col,right_bound)) then
        local _32_ = to_next_in_window_pos_21(backward_3f, left_bound, right_bound, stopline)
        if (_32_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _32_
          return iter(true)
        else
          return nil
        end
      elseif (vim.fn.foldclosed(line) ~= -1) then
        to_closed_fold_edge_21(backward_3f)
        local _34_ = skip_one_21(backward_3f)
        if (_34_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _34_
          return iter(true)
        else
          return nil
        end
      else
        match_count = (match_count + 1)
        return pos
      end
    else
      return nil
    end
  end
  return iter
end
local function get_targets_2a(pattern, _38_)
  local _arg_39_ = _38_
  local backward_3f = _arg_39_["backward?"]
  local wininfo = _arg_39_["wininfo"]
  local targets = _arg_39_["targets"]
  local source_winid = _arg_39_["source-winid"]
  local targets0 = (targets or {})
  local _let_40_ = get_horizontal_bounds()
  local _ = _let_40_[1]
  local right_bound = _let_40_[2]
  local bounds = _let_40_
  local whole_window_3f = wininfo
  local wininfo0 = (wininfo or vim.fn.getwininfo(vim.fn.win_getid())[1])
  local skip_curpos_3f = (whole_window_3f and (vim.fn.win_getid() == source_winid))
  local match_positions = get_match_positions(pattern, bounds, {["backward?"] = backward_3f, ["skip-curpos?"] = skip_curpos_3f, ["whole-window?"] = whole_window_3f})
  local prev_match = {}
  for _41_ in match_positions do
    local _each_42_ = _41_
    local line = _each_42_[1]
    local col = _each_42_[2]
    local pos = _each_42_
    local _43_ = get_char_at(pos, {})
    if (nil ~= _43_) then
      local ch1 = _43_
      local ch2, eol_3f = nil, nil
      do
        local _44_ = get_char_at(pos, {["char-offset"] = 1})
        if (_44_ == nil) then
          ch2, eol_3f = "\n", true
        elseif (nil ~= _44_) then
          local ch = _44_
          ch2, eol_3f = ch
        else
          ch2, eol_3f = nil
        end
      end
      local same_char_triplet_3f
      local _46_
      if backward_3f then
        _46_ = dec
      else
        _46_ = inc
      end
      same_char_triplet_3f = ((ch2 == prev_match.ch2) and (line == prev_match.line) and (col == _46_(prev_match.col)))
      prev_match = {line = line, col = col, ch2 = ch2}
      if not same_char_triplet_3f then
        table.insert(targets0, {wininfo = wininfo0, pos = pos, pair = {ch1, ch2}, ["edge-pos?"] = (eol_3f or (col == right_bound))})
      else
      end
    else
    end
  end
  if next(targets0) then
    return targets0
  else
    return nil
  end
end
local function distance(_51_, _53_)
  local _arg_52_ = _51_
  local l1 = _arg_52_[1]
  local c1 = _arg_52_[2]
  local _arg_54_ = _53_
  local l2 = _arg_54_[1]
  local c2 = _arg_54_[2]
  local editor_grid_aspect_ratio = 0.3
  local _let_55_ = {abs((c1 - c2)), abs((l1 - l2))}
  local dx = _let_55_[1]
  local dy = _let_55_[2]
  local dx0 = (dx * editor_grid_aspect_ratio)
  return pow((pow(dx0, 2) + pow(dy, 2)), 0.5)
end
local function get_targets(pattern, _56_)
  local _arg_57_ = _56_
  local backward_3f = _arg_57_["backward?"]
  local target_windows = _arg_57_["target-windows"]
  if not target_windows then
    return get_targets_2a(pattern, {["backward?"] = backward_3f})
  else
    local targets = {}
    local cursor_positions = {}
    local source_winid = vim.fn.win_getid()
    local curr_win_only_3f
    do
      local _58_ = target_windows
      if ((_G.type(_58_) == "table") and ((_G.type((_58_)[1]) == "table") and (((_58_)[1]).winid == source_winid)) and ((_58_)[2] == nil)) then
        curr_win_only_3f = true
      else
        curr_win_only_3f = nil
      end
    end
    local cross_win_3f = not curr_win_only_3f
    for _, _60_ in ipairs(target_windows) do
      local _each_61_ = _60_
      local winid = _each_61_["winid"]
      local wininfo = _each_61_
      if cross_win_3f then
        api.nvim_set_current_win(winid)
      else
      end
      cursor_positions[winid] = get_cursor_pos()
      get_targets_2a(pattern, {targets = targets, wininfo = wininfo, ["source-winid"] = source_winid})
    end
    if cross_win_3f then
      api.nvim_set_current_win(source_winid)
    else
    end
    if not empty_3f(targets) then
      local by_screen_pos_3f = (vim.o.wrap and (#targets < 200))
      if by_screen_pos_3f then
        for winid, _64_ in pairs(cursor_positions) do
          local _each_65_ = _64_
          local line = _each_65_[1]
          local col = _each_65_[2]
          local _66_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_66_) == "table") and ((_66_).col == col) and (nil ~= (_66_).row)) then
            local row = (_66_).row
            cursor_positions[winid] = {row, col}
          else
          end
        end
      else
      end
      for _, _69_ in ipairs(targets) do
        local _each_70_ = _69_
        local _each_71_ = _each_70_["pos"]
        local line = _each_71_[1]
        local col = _each_71_[2]
        local _each_72_ = _each_70_["wininfo"]
        local winid = _each_72_["winid"]
        local t = _each_70_
        if by_screen_pos_3f then
          local _73_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_73_) == "table") and ((_73_).col == col) and (nil ~= (_73_).row)) then
            local row = (_73_).row
            t["screenpos"] = {row, col}
          else
          end
        else
        end
        t["rank"] = distance((t.screenpos or t.pos), cursor_positions[winid])
      end
      local function _76_(_241, _242)
        return ((_241).rank < (_242).rank)
      end
      table.sort(targets, _76_)
      return targets
    else
      return nil
    end
  end
end
return {["get-targets"] = get_targets}
