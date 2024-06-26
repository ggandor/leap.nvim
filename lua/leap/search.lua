local opts = require("leap.opts")
local _local_1_ = require("leap.util")
local inc = _local_1_["inc"]
local dec = _local_1_["dec"]
local get_cursor_pos = _local_1_["get-cursor-pos"]
local get_eq_class_of = _local_1_["get-eq-class-of"]
local __3erepresentative_char = _local_1_["->representative-char"]
local api = vim.api
local empty_3f = vim.tbl_isempty
local _local_2_ = math
local abs = _local_2_["abs"]
local pow = _local_2_["pow"]
local function get_horizontal_bounds()
  local window_width = api.nvim_win_get_width(0)
  local textoff = vim.fn.getwininfo(api.nvim_get_current_win())[1].textoff
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
  local function _9_()
    if backward_3f then
      return "w0"
    else
      return "w$"
    end
  end
  stopline = vim.fn.line(_9_())
  local saved_view = vim.fn.winsaveview()
  local saved_cpo = vim.o.cpo
  local match_at_curpos_3f = whole_window_3f
  do end (vim.opt.cpo):remove("c")
  if whole_window_3f then
    vim.fn.cursor({vim.fn.line("w0"), 1})
  else
  end
  local match_positions = {}
  local edge_pos_idx_3f = {}
  local idx = 0
  local function loop()
    local flags0 = ((match_at_curpos_3f and (flags .. "c")) or flags)
    match_at_curpos_3f = false
    local _local_11_ = vim.fn.searchpos(pattern0, flags0, stopline)
    local line = _local_11_[1]
    local pos = _local_11_
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
        edge_pos_idx_3f[idx] = true
      else
      end
      return loop()
    end
  end
  loop()
  return match_positions, edge_pos_idx_3f
end
local function get_targets_in_current_window(pattern, _15_)
  local _arg_16_ = _15_
  local targets = _arg_16_["targets"]
  local backward_3f = _arg_16_["backward?"]
  local whole_window_3f = _arg_16_["whole-window?"]
  local match_same_char_seq_at_end_3f = _arg_16_["match-same-char-seq-at-end?"]
  local skip_curpos_3f = _arg_16_["skip-curpos?"]
  local wininfo = vim.fn.getwininfo(api.nvim_get_current_win())[1]
  local _local_17_ = get_cursor_pos()
  local curline = _local_17_[1]
  local curcol = _local_17_[2]
  local bounds = get_horizontal_bounds()
  do end (bounds)[2] = dec(bounds[2])
  local match_positions, edge_pos_idx_3f = get_match_positions(pattern, bounds, {["backward?"] = backward_3f, ["whole-window?"] = whole_window_3f})
  local line_str = nil
  local prev_match = {line = nil, col = nil, ch1 = nil, ch2 = nil}
  for i, _18_ in ipairs(match_positions) do
    local _each_19_ = _18_
    local line = _each_19_[1]
    local col = _each_19_[2]
    local pos = _each_19_
    if not (skip_curpos_3f and (line == curline) and (col == curcol)) then
      if (line ~= prev_match.line) then
        line_str = vim.fn.getline(line)
      else
      end
      local ch1 = vim.fn.strpart(line_str, (col - 1), 1, true)
      if (ch1 ~= "") then
        local ch2 = vim.fn.strpart(line_str, (col + -1 + ch1:len()), 1, true)
        if (ch2 == "") then
          ch2 = "\n"
        else
        end
        local overlap_3f
        local function _22_()
          if backward_3f then
            return (col == (prev_match.col - ch1:len()))
          else
            return (col == (prev_match.col + (prev_match.ch1):len()))
          end
        end
        overlap_3f = ((line == prev_match.line) and _22_())
        local triplet_3f = (overlap_3f and (__3erepresentative_char(ch2) == __3erepresentative_char(prev_match.ch2)))
        local skip_match_3f
        local function _23_()
          if backward_3f then
            return match_same_char_seq_at_end_3f
          else
            return not match_same_char_seq_at_end_3f
          end
        end
        skip_match_3f = (triplet_3f and _23_())
        prev_match = {line = line, col = col, ch1 = ch1, ch2 = ch2}
        if not skip_match_3f then
          if triplet_3f then
            table.remove(targets)
          else
          end
          table.insert(targets, {wininfo = wininfo, pos = pos, chars = {ch1, ch2}, ["edge-pos?"] = edge_pos_idx_3f[i], ["previewable?"] = (not opts.preview_filter or opts.preview_filter(vim.fn.strpart(line_str, (col - 2), 1, true), ch1, ch2))})
        else
        end
      else
        table.insert(targets, {wininfo = wininfo, pos = pos, chars = {"\n", "\n"}, ["previewable?"] = (not opts.preview_filter or opts.preview_filter("", "\n", "\n"))})
      end
    else
    end
  end
  return nil
end
local function distance(_28_, _30_)
  local _arg_29_ = _28_
  local l1 = _arg_29_[1]
  local c1 = _arg_29_[2]
  local _arg_31_ = _30_
  local l2 = _arg_31_[1]
  local c2 = _arg_31_[2]
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
      local _each_34_ = _33_
      local line = _each_34_[1]
      local col = _each_34_[2]
      local screenpos = vim.fn.screenpos(winid, line, col)
      do end (cursor_positions)[winid] = {screenpos.row, screenpos.col}
    end
  else
  end
  for _, _36_ in ipairs(targets) do
    local _each_37_ = _36_
    local _each_38_ = _each_37_["pos"]
    local line = _each_38_[1]
    local col = _each_38_[2]
    local _each_39_ = _each_37_["wininfo"]
    local winid = _each_39_["winid"]
    local target = _each_37_
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
  local function _44_(_241, _242)
    return (_241.rank < _242.rank)
  end
  return table.sort(targets, _44_)
end
local function prepare_pattern(in1, _3fin2)
  local function char_list_to_branching_regexp(chars)
    local branches
    local function _45_(_241)
      if (_241 == "\n") then
        return "\\n"
      elseif (_241 == "\\") then
        return "\\\\"
      elseif (nil ~= _241) then
        local ch = _241
        return ch
      else
        return nil
      end
    end
    branches = vim.tbl_map(_45_, chars)
    local pattern = table.concat(branches, "\\|")
    return ("\\(" .. pattern .. "\\)")
  end
  local function expand_to_equivalence_class(char)
    local _47_ = get_eq_class_of(char)
    if (nil ~= _47_) then
      return char_list_to_branching_regexp(_47_)
    else
      return _47_
    end
  end
  local pat1 = (expand_to_equivalence_class(in1) or in1:gsub("\\", "\\\\"))
  local pat2 = ((_3fin2 and expand_to_equivalence_class(_3fin2)) or _3fin2 or "\\_.")
  local potential_nl_nl_3f = (pat1:match("\\n") and (pat2:match("\\n") or not _3fin2))
  local pattern
  local function _49_()
    if potential_nl_nl_3f then
      return "\\|\\n"
    else
      return ""
    end
  end
  pattern = (pat1 .. pat2 .. _49_())
  local function _50_()
    if opts.case_sensitive then
      return "\\C"
    else
      return "\\c"
    end
  end
  return (_50_() .. "\\V" .. pattern)
end
local function get_targets(pattern, _51_)
  local _arg_52_ = _51_
  local backward_3f = _arg_52_["backward?"]
  local match_same_char_seq_at_end_3f = _arg_52_["match-same-char-seq-at-end?"]
  local target_windows = _arg_52_["target-windows"]
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
    get_targets_in_current_window(pattern, {targets = targets, ["backward?"] = backward_3f, ["whole-window?"] = whole_window_3f, ["match-same-char-seq-at-end?"] = match_same_char_seq_at_end_3f, ["skip-curpos?"] = (winid == source_winid)})
  end
  if not curr_win_only_3f then
    api.nvim_set_current_win(source_winid)
  else
  end
  if not empty_3f(targets) then
    if whole_window_3f then
      sort_by_distance_from_cursor(targets, cursor_positions, source_winid)
    else
    end
    return targets
  else
    return nil
  end
end
return {["get-horizontal-bounds"] = get_horizontal_bounds, ["get-match-positions"] = get_match_positions, ["prepare-pattern"] = prepare_pattern, ["get-targets"] = get_targets}
