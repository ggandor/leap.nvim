local hl = require("leap.highlight")
local opts = require("leap.opts")
local util = require("leap.util")
local _local_1_ = util
local inc = _local_1_["inc"]
local dec = _local_1_["dec"]
local clamp = _local_1_["clamp"]
local api = vim.api
local empty_3f = vim.tbl_isempty
local map = vim.tbl_map
local _local_2_ = math
local abs = _local_2_["abs"]
local ceil = _local_2_["ceil"]
local max = _local_2_["max"]
local min = _local_2_["min"]
local pow = _local_2_["pow"]
local function echo(msg)
  return api.nvim_echo({{msg}}, false, {})
end
local function replace_keycodes(s)
  return api.nvim_replace_termcodes(s, true, false, true)
end
local function get_cursor_pos()
  return {vim.fn.line("."), vim.fn.col(".")}
end
local function user_forced_autojump_3f()
  return (not opts.labels or empty_3f(opts.labels))
end
local function user_forced_noautojump_3f()
  return (not opts.safe_labels or empty_3f(opts.safe_labels))
end
local function echo_no_prev_search()
  return echo("no previous search")
end
local function echo_not_found(s)
  return echo(("not found: " .. s))
end
local function push_cursor_21(direction)
  local function _4_()
    local _3_ = direction
    if (_3_ == "fwd") then
      return "W"
    elseif (_3_ == "bwd") then
      return "bW"
    else
      return nil
    end
  end
  return vim.fn.search("\\_.", _4_())
end
local function cursor_before_eol_3f()
  return (vim.fn.search("\\_.", "Wn") ~= vim.fn.line("."))
end
local function cursor_before_eof_3f()
  return ((vim.fn.line(".") == vim.fn.line("$")) and (vim.fn.virtcol(".") == dec(vim.fn.virtcol("$"))))
end
local function add_offset_21(offset)
  if (offset < 0) then
    return push_cursor_21("bwd")
  elseif (offset > 0) then
    if not cursor_before_eol_3f() then
      push_cursor_21("fwd")
    else
    end
    if (offset > 1) then
      return push_cursor_21("fwd")
    else
      return nil
    end
  else
    return nil
  end
end
local function push_beyond_eof_21()
  local saved = vim.o.virtualedit
  vim.o.virtualedit = "onemore"
  vim.cmd("norm! l")
  local function _9_()
    vim.o.virtualedit = saved
    return nil
  end
  return api.nvim_create_autocmd({"CursorMoved", "WinLeave", "BufLeave", "InsertEnter", "CmdlineEnter", "CmdwinEnter"}, {callback = _9_, once = true})
end
local function simulate_inclusive_op_21(mode)
  local _10_ = vim.fn.matchstr(mode, "^no\\zs.")
  if (_10_ == "") then
    if cursor_before_eof_3f() then
      return push_beyond_eof_21()
    else
      return push_cursor_21("fwd")
    end
  elseif (_10_ == "v") then
    return push_cursor_21("bwd")
  else
    return nil
  end
end
local function force_matchparen_refresh()
  pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchparen"})
  return pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchup_matchparen"})
end
local function jump_to_21_2a(pos, _13_)
  local _arg_14_ = _13_
  local winid = _arg_14_["winid"]
  local add_to_jumplist_3f = _arg_14_["add-to-jumplist?"]
  local mode = _arg_14_["mode"]
  local offset = _arg_14_["offset"]
  local backward_3f = _arg_14_["backward?"]
  local inclusive_op_3f = _arg_14_["inclusive-op?"]
  local op_mode_3f = mode:match("o")
  if add_to_jumplist_3f then
    vim.cmd("norm! m`")
  else
  end
  if (winid ~= vim.fn.win_getid()) then
    api.nvim_set_current_win(winid)
  else
  end
  vim.fn.cursor(pos)
  if offset then
    add_offset_21(offset)
  else
  end
  if (op_mode_3f and inclusive_op_3f and not backward_3f) then
    simulate_inclusive_op_21(mode)
  else
  end
  if not op_mode_3f then
    return force_matchparen_refresh()
  else
    return nil
  end
end
local function highlight_cursor(_3fpos)
  local _let_20_ = (_3fpos or get_cursor_pos())
  local line = _let_20_[1]
  local col = _let_20_[2]
  local pos = _let_20_
  local ch_at_curpos = (util["get-char-at"](pos, {}) or " ")
  return api.nvim_buf_set_extmark(0, hl.ns, dec(line), dec(col), {virt_text = {{ch_at_curpos, "Cursor"}}, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.cursor})
end
local function handle_interrupted_change_op_21()
  local seq
  local function _21_()
    if (vim.fn.col(".") > 1) then
      return "<RIGHT>"
    else
      return ""
    end
  end
  seq = ("<C-\\><C-G>" .. _21_())
  return api.nvim_feedkeys(replace_keycodes(seq), "n", true)
end
local function exec_user_autocmds(pattern)
  return api.nvim_exec_autocmds("User", {pattern = pattern, modeline = false})
end
local function get_input()
  local ok_3f, ch = pcall(vim.fn.getcharstr)
  if (ok_3f and (ch ~= replace_keycodes("<esc>"))) then
    return ch
  else
    return nil
  end
end
local function get_input_by_keymap()
  local _3ccr_3e = replace_keycodes("<cr>")
  local function loop(seq)
    if (seq and (#seq <= 4)) then
      local rhs_candidate = vim.fn.mapcheck(seq, "l")
      local rhs = vim.fn.maparg(seq, "l")
      if (rhs_candidate == "") then
        return seq
      elseif (rhs == rhs_candidate) then
        return rhs
      else
        local _23_ = get_input()
        if (_23_ == _3ccr_3e) then
          if (rhs ~= "") then
            return rhs
          else
            return seq
          end
        elseif (nil ~= _23_) then
          local ch = _23_
          return loop((seq .. ch))
        else
          return nil
        end
      end
    else
      return nil
    end
  end
  if (vim.bo.iminsert ~= 1) then
    return get_input()
  else
    return loop(get_input())
  end
end
local function set_dot_repeat()
  local op = vim.v.operator
  local cmd = replace_keycodes("<cmd>lua require'leap'.leap {['dot-repeat?'] = true}<cr>")
  local change
  if (op == "c") then
    change = replace_keycodes("<c-r>.<esc>")
  else
    change = nil
  end
  local seq = (op .. cmd .. (change or ""))
  pcall(vim.fn["repeat#setreg"], seq, vim.v.register)
  return pcall(vim.fn["repeat#set"], seq, -1)
end
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
  local function _30_()
    if backward_3f then
      return "bwd"
    else
      return "fwd"
    end
  end
  new_line = push_cursor_21(_30_())
  if (new_line == 0) then
    return "dead-end"
  else
    return nil
  end
end
local function to_closed_fold_edge_21(backward_3f)
  local edge_line
  local _32_
  if backward_3f then
    _32_ = vim.fn.foldclosed
  else
    _32_ = vim.fn.foldclosedend
  end
  edge_line = _32_(vim.fn.line("."))
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
  local _let_35_ = {vim.fn.line("."), vim.fn.virtcol(".")}
  local line = _let_35_[1]
  local virtcol = _let_35_[2]
  local from_pos = _let_35_
  local left_off_3f = (virtcol < left_bound)
  local right_off_3f = (virtcol > right_bound)
  local _36_
  if (left_off_3f and backward_3f) then
    if (dec(line) >= stopline) then
      _36_ = {dec(line), right_bound}
    else
      _36_ = nil
    end
  elseif (left_off_3f and not backward_3f) then
    _36_ = {line, left_bound}
  elseif (right_off_3f and backward_3f) then
    _36_ = {line, right_bound}
  elseif (right_off_3f and not backward_3f) then
    if (inc(line) <= stopline) then
      _36_ = {inc(line), left_bound}
    else
      _36_ = nil
    end
  else
    _36_ = nil
  end
  if (nil ~= _36_) then
    local to_pos = _36_
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
local function get_match_positions(pattern, _43_, _45_)
  local _arg_44_ = _43_
  local left_bound = _arg_44_[1]
  local right_bound = _arg_44_[2]
  local _arg_46_ = _45_
  local backward_3f = _arg_46_["backward?"]
  local whole_window_3f = _arg_46_["whole-window?"]
  local skip_curpos_3f = _arg_46_["skip-curpos?"]
  local skip_orig_curpos_3f = skip_curpos_3f
  local _let_47_ = get_cursor_pos()
  local orig_curline = _let_47_[1]
  local orig_curcol = _let_47_[2]
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
  local function _49_()
    vim.fn.winrestview(saved_view)
    vim.o.cpo = saved_cpo
    return nil
  end
  cleanup = _49_
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
    local function _51_()
      if backward_3f then
        return "b"
      else
        return ""
      end
    end
    local function _52_()
      if match_at_curpos_3f0 then
        return "c"
      else
        return ""
      end
    end
    flags = (_51_() .. _52_())
    moved_to_topleft_3f = false
    local _53_ = vim.fn.searchpos(pattern, flags, stopline)
    if ((_G.type(_53_) == "table") and (nil ~= (_53_)[1]) and (nil ~= (_53_)[2])) then
      local line = (_53_)[1]
      local col = (_53_)[2]
      local pos = _53_
      if (line == 0) then
        return cleanup()
      elseif ((line == orig_curline) and (col == orig_curcol) and skip_orig_curpos_3f) then
        local _54_ = skip_one_21()
        if (_54_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _54_
          return iter(true)
        else
          return nil
        end
      elseif ((col < left_bound) and (col > right_bound) and not vim.wo.wrap) then
        local _56_ = to_next_in_window_pos_21(backward_3f, left_bound, right_bound, stopline)
        if (_56_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _56_
          return iter(true)
        else
          return nil
        end
      elseif (vim.fn.foldclosed(line) ~= -1) then
        to_closed_fold_edge_21(backward_3f)
        local _58_ = skip_one_21(backward_3f)
        if (_58_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _58_
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
local function get_targets_2a(pattern, _62_)
  local _arg_63_ = _62_
  local backward_3f = _arg_63_["backward?"]
  local wininfo = _arg_63_["wininfo"]
  local targets = _arg_63_["targets"]
  local source_winid = _arg_63_["source-winid"]
  local targets0 = (targets or {})
  local _let_64_ = get_horizontal_bounds()
  local _ = _let_64_[1]
  local right_bound = _let_64_[2]
  local bounds = _let_64_
  local whole_window_3f = wininfo
  local wininfo0 = (wininfo or vim.fn.getwininfo(vim.fn.win_getid())[1])
  local skip_curpos_3f = (whole_window_3f and (vim.fn.win_getid() == source_winid))
  local match_positions = get_match_positions(pattern, bounds, {["backward?"] = backward_3f, ["skip-curpos?"] = skip_curpos_3f, ["whole-window?"] = whole_window_3f})
  local prev_match = {}
  for _65_ in match_positions do
    local _each_66_ = _65_
    local line = _each_66_[1]
    local col = _each_66_[2]
    local pos = _each_66_
    local _67_ = util["get-char-at"](pos, {})
    if (nil ~= _67_) then
      local ch1 = _67_
      local ch2, eol_3f = nil, nil
      do
        local _68_ = util["get-char-at"](pos, {["char-offset"] = 1})
        if (nil ~= _68_) then
          local char = _68_
          ch2, eol_3f = char
        elseif true then
          local _0 = _68_
          ch2, eol_3f = replace_keycodes(opts.special_keys.eol), true
        else
          ch2, eol_3f = nil
        end
      end
      local same_char_triplet_3f
      local _70_
      if backward_3f then
        _70_ = dec
      else
        _70_ = inc
      end
      same_char_triplet_3f = ((ch2 == prev_match.ch2) and (line == prev_match.line) and (col == _70_(prev_match.col)))
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
local function distance(_75_, _77_)
  local _arg_76_ = _75_
  local l1 = _arg_76_[1]
  local c1 = _arg_76_[2]
  local _arg_78_ = _77_
  local l2 = _arg_78_[1]
  local c2 = _arg_78_[2]
  local editor_grid_aspect_ratio = 0.3
  local _let_79_ = {abs((c1 - c2)), abs((l1 - l2))}
  local dx = _let_79_[1]
  local dy = _let_79_[2]
  local dx0 = (dx * editor_grid_aspect_ratio)
  return pow((pow(dx0, 2) + pow(dy, 2)), 0.5)
end
local function get_targets(pattern, _80_)
  local _arg_81_ = _80_
  local backward_3f = _arg_81_["backward?"]
  local target_windows = _arg_81_["target-windows"]
  if not target_windows then
    return get_targets_2a(pattern, {["backward?"] = backward_3f})
  else
    local targets = {}
    local cursor_positions = {}
    local source_winid = vim.fn.win_getid()
    local curr_win_only_3f
    do
      local _82_ = target_windows
      if ((_G.type(_82_) == "table") and ((_G.type((_82_)[1]) == "table") and (((_82_)[1]).winid == source_winid)) and ((_82_)[2] == nil)) then
        curr_win_only_3f = true
      else
        curr_win_only_3f = nil
      end
    end
    local cross_win_3f = not curr_win_only_3f
    for _, _84_ in ipairs(target_windows) do
      local _each_85_ = _84_
      local winid = _each_85_["winid"]
      local wininfo = _each_85_
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
        for winid, _88_ in pairs(cursor_positions) do
          local _each_89_ = _88_
          local line = _each_89_[1]
          local col = _each_89_[2]
          local _90_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_90_) == "table") and ((_90_).col == col) and (nil ~= (_90_).row)) then
            local row = (_90_).row
            cursor_positions[winid] = {row, col}
          else
          end
        end
      else
      end
      for _, _93_ in ipairs(targets) do
        local _each_94_ = _93_
        local _each_95_ = _each_94_["pos"]
        local line = _each_95_[1]
        local col = _each_95_[2]
        local _each_96_ = _each_94_["wininfo"]
        local winid = _each_96_["winid"]
        local t = _each_94_
        if by_screen_pos_3f then
          local _97_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_97_) == "table") and ((_97_).col == col) and (nil ~= (_97_).row)) then
            local row = (_97_).row
            t["screenpos"] = {row, col}
          else
          end
        else
        end
        t["rank"] = distance((t.screenpos or t.pos), cursor_positions[winid])
      end
      local function _100_(_241, _242)
        return ((_241).rank < (_242).rank)
      end
      table.sort(targets, _100_)
      return targets
    else
      return nil
    end
  end
end
local function populate_sublists(targets)
  targets.sublists = {}
  local function __3ecommon_key(k)
    local function _103_()
      if not opts.case_sensitive then
        return k:lower()
      else
        return nil
      end
    end
    return (opts.character_class_of[k] or _103_() or k)
  end
  local function _105_(t, k)
    return rawget(t, __3ecommon_key(k))
  end
  local function _106_(t, k, v)
    return rawset(t, __3ecommon_key(k), v)
  end
  setmetatable(targets.sublists, {__index = _105_, __newindex = _106_})
  for _, _107_ in ipairs(targets) do
    local _each_108_ = _107_
    local _each_109_ = _each_108_["pair"]
    local _0 = _each_109_[1]
    local ch2 = _each_109_[2]
    local target = _each_108_
    if not targets.sublists[ch2] then
      targets["sublists"][ch2] = {}
    else
    end
    table.insert(targets.sublists[ch2], target)
  end
  return nil
end
local function set_autojump(sublist, force_noautojump_3f)
  sublist["autojump?"] = (not (force_noautojump_3f or user_forced_noautojump_3f()) and (user_forced_autojump_3f() or (#opts.safe_labels >= dec(#sublist))))
  return nil
end
local function attach_label_set(sublist)
  local _111_
  if user_forced_autojump_3f() then
    _111_ = opts.safe_labels
  elseif user_forced_noautojump_3f() then
    _111_ = opts.labels
  elseif sublist["autojump?"] then
    _111_ = opts.safe_labels
  else
    _111_ = opts.labels
  end
  sublist["label-set"] = _111_
  return nil
end
local function set_sublist_attributes(targets, _113_)
  local _arg_114_ = _113_
  local force_noautojump_3f = _arg_114_["force-noautojump?"]
  for _, sublist in pairs(targets.sublists) do
    set_autojump(sublist, force_noautojump_3f)
    attach_label_set(sublist)
  end
  return nil
end
local function set_labels(targets)
  for _, sublist in pairs(targets.sublists) do
    if (#sublist > 1) then
      local _local_115_ = sublist
      local autojump_3f = _local_115_["autojump?"]
      local label_set = _local_115_["label-set"]
      for i, target in ipairs(sublist) do
        local i_2a
        if autojump_3f then
          i_2a = dec(i)
        else
          i_2a = i
        end
        if (i_2a > 0) then
          local _118_
          do
            local _117_ = (i_2a % #label_set)
            if (_117_ == 0) then
              _118_ = label_set[#label_set]
            elseif (nil ~= _117_) then
              local n = _117_
              _118_ = label_set[n]
            else
              _118_ = nil
            end
          end
          target["label"] = _118_
        else
        end
      end
    else
    end
  end
  return nil
end
local function set_label_states(sublist, _124_)
  local _arg_125_ = _124_
  local group_offset = _arg_125_["group-offset"]
  local _7clabel_set_7c = #sublist["label-set"]
  local offset = (group_offset * _7clabel_set_7c)
  local primary_start
  local function _126_()
    if sublist["autojump?"] then
      return 2
    else
      return 1
    end
  end
  primary_start = (offset + _126_())
  local primary_end = (primary_start + dec(_7clabel_set_7c))
  local secondary_start = inc(primary_end)
  local secondary_end = (primary_end + _7clabel_set_7c)
  for i, target in ipairs(sublist) do
    if target.label then
      local _127_
      if (function(_128_,_129_,_130_) return (_128_ <= _129_) and (_129_ <= _130_) end)(primary_start,i,primary_end) then
        _127_ = "active-primary"
      elseif (function(_131_,_132_,_133_) return (_131_ <= _132_) and (_132_ <= _133_) end)(secondary_start,i,secondary_end) then
        _127_ = "active-secondary"
      elseif (i > secondary_end) then
        _127_ = "inactive"
      else
        _127_ = nil
      end
      target["label-state"] = _127_
    else
    end
  end
  return nil
end
local function set_initial_label_states(targets)
  for _, sublist in pairs(targets.sublists) do
    set_label_states(sublist, {["group-offset"] = 0})
  end
  return nil
end
local function inactivate_labels(target_list)
  for _, target in ipairs(target_list) do
    target["label-state"] = "inactive"
  end
  return nil
end
local function set_beacon_for_labeled(target)
  local _let_136_ = target
  local _let_137_ = _let_136_["pair"]
  local ch1 = _let_137_[1]
  local ch2 = _let_137_[2]
  local edge_pos_3f = _let_136_["edge-pos?"]
  local label = _let_136_["label"]
  local offset
  local function _138_()
    if edge_pos_3f then
      return 0
    else
      return ch2:len()
    end
  end
  offset = (ch1:len() + _138_())
  local virttext
  do
    local _139_ = target["label-state"]
    if (_139_ == "active-primary") then
      virttext = {{label, hl.group["label-primary"]}}
    elseif (_139_ == "active-secondary") then
      virttext = {{label, hl.group["label-secondary"]}}
    elseif (_139_ == "inactive") then
      if not opts.highlight_unlabeled then
        virttext = {{" ", hl.group["label-secondary"]}}
      else
        virttext = nil
      end
    else
      virttext = nil
    end
  end
  local _142_
  if virttext then
    _142_ = {offset, virttext}
  else
    _142_ = nil
  end
  target["beacon"] = _142_
  return nil
end
local function set_beacon_to_match_hl(target)
  local _let_144_ = target
  local _let_145_ = _let_144_["pair"]
  local ch1 = _let_145_[1]
  local ch2 = _let_145_[2]
  local virttext = {{(ch1 .. ch2), hl.group.match}}
  target["beacon"] = {0, virttext}
  return nil
end
local function set_beacon_to_empty_label(target)
  target["beacon"][2][1][1] = " "
  return nil
end
local function resolve_conflicts(target_list)
  local unlabeled_match_positions = {}
  local label_positions = {}
  for i, target in ipairs(target_list) do
    local _let_146_ = target
    local _let_147_ = _let_146_["pos"]
    local lnum = _let_147_[1]
    local col = _let_147_[2]
    local _let_148_ = _let_146_["pair"]
    local ch1 = _let_148_[1]
    local _ = _let_148_[2]
    local _let_149_ = _let_146_["wininfo"]
    local bufnr = _let_149_["bufnr"]
    local winid = _let_149_["winid"]
    if (not target.beacon or (opts.highlight_unlabeled and (target.beacon[2][1][2] == hl.group.match))) then
      local keys = {(bufnr .. " " .. winid .. " " .. lnum .. " " .. col), (bufnr .. " " .. winid .. " " .. lnum .. " " .. (col + ch1:len()))}
      for _0, k in ipairs(keys) do
        do
          local _150_ = label_positions[k]
          if (nil ~= _150_) then
            local other = _150_
            other.beacon = nil
            set_beacon_to_match_hl(target)
          else
          end
        end
        unlabeled_match_positions[k] = target
      end
    else
      local label_offset = target.beacon[1]
      local k = (bufnr .. " " .. winid .. " " .. lnum .. " " .. (col + label_offset))
      do
        local _152_ = unlabeled_match_positions[k]
        if (nil ~= _152_) then
          local other = _152_
          target.beacon = nil
          set_beacon_to_match_hl(other)
        elseif true then
          local _0 = _152_
          local _153_ = label_positions[k]
          if (nil ~= _153_) then
            local other = _153_
            target.beacon = nil
            set_beacon_to_empty_label(other)
          else
          end
        else
        end
      end
      label_positions[k] = target
    end
  end
  return nil
end
local function set_beacons(target_list, _157_)
  local _arg_158_ = _157_
  local force_no_labels_3f = _arg_158_["force-no-labels?"]
  if force_no_labels_3f then
    for _, target in ipairs(target_list) do
      set_beacon_to_match_hl(target)
    end
    return nil
  else
    for _, target in ipairs(target_list) do
      if target.label then
        set_beacon_for_labeled(target)
      elseif opts.highlight_unlabeled then
        set_beacon_to_match_hl(target)
      else
      end
    end
    return resolve_conflicts(target_list)
  end
end
local function light_up_beacons(target_list, _3fstart)
  for i = (_3fstart or 1), #target_list do
    local target = target_list[i]
    local _161_ = target.beacon
    if ((_G.type(_161_) == "table") and (nil ~= (_161_)[1]) and (nil ~= (_161_)[2])) then
      local offset = (_161_)[1]
      local virttext = (_161_)[2]
      local _let_162_ = map(dec, target.pos)
      local lnum = _let_162_[1]
      local col = _let_162_[2]
      api.nvim_buf_set_extmark(target.wininfo.bufnr, hl.ns, lnum, (col + offset), {virt_text = virttext, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.label})
    else
    end
  end
  return nil
end
local state = {["repeat"] = {in1 = nil, in2 = nil}, ["dot-repeat"] = {in1 = nil, in2 = nil, ["target-idx"] = nil, ["backward?"] = nil, ["inclusive-op?"] = nil, ["offset?"] = nil}}
local function leap(_164_)
  local _arg_165_ = _164_
  local dot_repeat_3f = _arg_165_["dot-repeat?"]
  local target_windows = _arg_165_["target-windows"]
  local kwargs = _arg_165_
  local function _167_()
    if dot_repeat_3f then
      return state["dot-repeat"]
    else
      return kwargs
    end
  end
  local _let_166_ = _167_()
  local backward_3f = _let_166_["backward?"]
  local inclusive_op_3f = _let_166_["inclusive-op?"]
  local offset = _let_166_["offset"]
  local directional_3f = not target_windows
  local __3ewininfo
  local function _168_(_241)
    return (vim.fn.getwininfo(_241))[1]
  end
  __3ewininfo = _168_
  local _3ftarget_windows
  do
    local _169_ = target_windows
    if (_169_ ~= nil) then
      _3ftarget_windows = map(__3ewininfo, _169_)
    else
      _3ftarget_windows = _169_
    end
  end
  local current_window = __3ewininfo(vim.fn.win_getid())
  local hl_affected_windows
  do
    local t = {current_window}
    for _, w in ipairs((_3ftarget_windows or {})) do
      table.insert(t, w)
    end
    hl_affected_windows = t
  end
  local mode = api.nvim_get_mode().mode
  local op_mode_3f = mode:match("o")
  local change_op_3f = (op_mode_3f and (vim.v.operator == "c"))
  local dot_repeatable_op_3f = (op_mode_3f and directional_3f and (vim.v.operator ~= "y"))
  local force_noautojump_3f = (op_mode_3f or not directional_3f)
  local spec_keys
  local function _171_(_, k)
    return replace_keycodes(opts.special_keys[k])
  end
  spec_keys = setmetatable({}, {__index = _171_})
  local function expand_to_user_defined_character_class(_in)
    local _172_ = opts.character_class_of[_in]
    if (nil ~= _172_) then
      local chars = _172_
      return ("\\(" .. table.concat(chars, "\\|") .. "\\)")
    else
      return nil
    end
  end
  local function prepare_pattern(in1, _3fin2)
    local function _174_()
      if opts.case_sensitive then
        return "\\C"
      else
        return "\\c"
      end
    end
    return ("\\V" .. _174_() .. (expand_to_user_defined_character_class(in1) or string.gsub(in1, "\\", "\\\\")) .. (expand_to_user_defined_character_class(_3fin2) or _3fin2 or "\\_."))
  end
  local function get_target_with_active_primary_label(sublist, input)
    local res = nil
    for idx, _175_ in ipairs(sublist) do
      local _each_176_ = _175_
      local label = _each_176_["label"]
      local label_state = _each_176_["label-state"]
      local target = _each_176_
      if (res or (label_state == "inactive")) then break end
      if ((label == input) and (label_state == "active-primary")) then
        res = {idx, target}
      else
      end
    end
    return res
  end
  local function update_state(state_2a)
    if not dot_repeat_3f then
      if state_2a["repeat"] then
        state["repeat"] = state_2a["repeat"]
      else
      end
      if (state_2a["dot-repeat"] and dot_repeatable_op_3f) then
        state["dot-repeat"] = vim.tbl_extend("error", state_2a["dot-repeat"], {["backward?"] = backward_3f, offset = offset, ["inclusive-op?"] = inclusive_op_3f})
        return nil
      else
        return nil
      end
    else
      return nil
    end
  end
  local jump_to_21
  do
    local first_jump_3f = true
    local function _181_(target)
      jump_to_21_2a(target.pos, {winid = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["backward?"] = backward_3f, ["inclusive-op?"] = inclusive_op_3f})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _181_
  end
  local function traverse(targets, idx, _182_)
    local _arg_183_ = _182_
    local force_no_labels_3f = _arg_183_["force-no-labels?"]
    if force_no_labels_3f then
      inactivate_labels(targets)
    else
    end
    set_beacons(targets, {["force-no-labels?"] = force_no_labels_3f})
    do
      hl:cleanup(hl_affected_windows)
      hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
      do
        light_up_beacons(targets, inc(idx))
      end
      highlight_cursor()
      vim.cmd("redraw")
    end
    local _185_
    local function _186_()
      if dot_repeatable_op_3f then
        set_dot_repeat()
      else
      end
      do
      end
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return nil
    end
    _185_ = (get_input() or _186_())
    if (nil ~= _185_) then
      local input = _185_
      if ((input == spec_keys.next_match) or (input == spec_keys.prev_match)) then
        local new_idx
        do
          local _188_ = input
          if (_188_ == spec_keys.next_match) then
            new_idx = min(inc(idx), #targets)
          elseif (_188_ == spec_keys.prev_match) then
            new_idx = max(dec(idx), 1)
          else
            new_idx = nil
          end
        end
        update_state({["repeat"] = {in1 = state["repeat"].in1, in2 = targets[new_idx].pair[2]}})
        jump_to_21(targets[new_idx])
        return traverse(targets, new_idx, {["force-no-labels?"] = force_no_labels_3f})
      else
        local _190_ = get_target_with_active_primary_label(targets, input)
        if ((_G.type(_190_) == "table") and true and (nil ~= (_190_)[2])) then
          local _ = (_190_)[1]
          local target = (_190_)[2]
          if dot_repeatable_op_3f then
            set_dot_repeat()
          else
          end
          do
            jump_to_21(target)
          end
          hl:cleanup(hl_affected_windows)
          exec_user_autocmds("LeapLeave")
          return nil
        elseif true then
          local _ = _190_
          if dot_repeatable_op_3f then
            set_dot_repeat()
          else
          end
          do
            vim.fn.feedkeys(input, "i")
          end
          hl:cleanup(hl_affected_windows)
          exec_user_autocmds("LeapLeave")
          return nil
        else
          return nil
        end
      end
    else
      return nil
    end
  end
  local function get_first_pattern_input()
    do
      hl:cleanup(hl_affected_windows)
      hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
      do
        echo("")
      end
      highlight_cursor()
      vim.cmd("redraw")
    end
    local _196_
    local function _197_()
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      do
      end
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return nil
    end
    _196_ = (get_input_by_keymap() or _197_())
    if (_196_ == spec_keys.repeat_search) then
      if state["repeat"].in1 then
        return state["repeat"].in1, state["repeat"].in2
      else
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
          echo_no_prev_search()
        end
        hl:cleanup(hl_affected_windows)
        exec_user_autocmds("LeapLeave")
        return nil
      end
    elseif (nil ~= _196_) then
      local in1 = _196_
      return in1
    else
      return nil
    end
  end
  local function get_second_pattern_input(targets)
    do
      hl:cleanup(hl_affected_windows)
      hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
      do
        light_up_beacons(targets)
      end
      highlight_cursor()
      vim.cmd("redraw")
    end
    local function _202_()
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      do
      end
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return nil
    end
    return (get_input_by_keymap() or _202_())
  end
  local function get_full_pattern_input()
    local _204_, _205_ = get_first_pattern_input()
    if ((nil ~= _204_) and (nil ~= _205_)) then
      local in1 = _204_
      local in2 = _205_
      return in1, in2
    elseif ((nil ~= _204_) and (_205_ == nil)) then
      local in1 = _204_
      local _206_ = get_input_by_keymap()
      if (nil ~= _206_) then
        local in2 = _206_
        return in1, in2
      elseif true then
        local _ = _206_
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
        end
        hl:cleanup(hl_affected_windows)
        exec_user_autocmds("LeapLeave")
        return nil
      else
        return nil
      end
    else
      return nil
    end
  end
  local function post_pattern_input_loop(sublist)
    local function loop(group_offset, initial_invoc_3f)
      do
        local _210_ = sublist
        set_label_states(_210_, {["group-offset"] = group_offset})
        set_beacons(_210_, {})
      end
      do
        hl:cleanup(hl_affected_windows)
        hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
        do
          local function _211_()
            if sublist["autojump?"] then
              return 2
            else
              return nil
            end
          end
          light_up_beacons(sublist, _211_())
        end
        highlight_cursor()
        vim.cmd("redraw")
      end
      local _212_
      local function _213_()
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
        end
        hl:cleanup(hl_affected_windows)
        exec_user_autocmds("LeapLeave")
        return nil
      end
      _212_ = (get_input() or _213_())
      if (nil ~= _212_) then
        local input = _212_
        if (((input == spec_keys.next_group) or ((input == spec_keys.prev_group) and not initial_invoc_3f)) and (not sublist["autojump?"] or user_forced_autojump_3f())) then
          local _7cgroups_7c = ceil((#sublist / #sublist["label-set"]))
          local max_offset = dec(_7cgroups_7c)
          local inc_2fdec
          if (input == spec_keys.next_group) then
            inc_2fdec = inc
          else
            inc_2fdec = dec
          end
          local new_offset = clamp(inc_2fdec(group_offset), 0, max_offset)
          return loop(new_offset, false)
        else
          return input
        end
      else
        return nil
      end
    end
    return loop(0, true)
  end
  exec_user_autocmds("LeapEnter")
  local function _218_(...)
    local _219_, _220_ = ...
    if ((nil ~= _219_) and true) then
      local in1 = _219_
      local _3fin2 = _220_
      local function _221_(...)
        local _222_ = ...
        if (nil ~= _222_) then
          local targets = _222_
          local function _223_(...)
            local _224_ = ...
            if (nil ~= _224_) then
              local in2 = _224_
              if (directional_3f and (in2 == spec_keys.next_match)) then
                local in20 = targets[1].pair[2]
                update_state({["repeat"] = {in1 = in1, in2 = in20}})
                jump_to_21(targets[1])
                if (op_mode_3f or (#targets == 1)) then
                  if dot_repeatable_op_3f then
                    set_dot_repeat()
                  else
                  end
                  do
                    update_state({["dot-repeat"] = {in1 = in1, in2 = in20, ["target-idx"] = 1}})
                  end
                  hl:cleanup(hl_affected_windows)
                  exec_user_autocmds("LeapLeave")
                  return nil
                else
                  return traverse(targets, 1, {["force-no-labels?"] = true})
                end
              else
                local function update_dot_repeat_state()
                  return update_state({["dot-repeat"] = {in1 = in1, in2 = in2, ["target-idx"] = __fnl_global___24}})
                end
                update_state({["repeat"] = {in1 = in1, in2 = in2}})
                local _227_
                local function _228_(...)
                  if change_op_3f then
                    handle_interrupted_change_op_21()
                  else
                  end
                  do
                    echo_not_found((in1 .. in2))
                  end
                  hl:cleanup(hl_affected_windows)
                  exec_user_autocmds("LeapLeave")
                  return nil
                end
                _227_ = (targets.sublists[in2] or _228_(...))
                if ((_G.type(_227_) == "table") and (nil ~= (_227_)[1]) and ((_227_)[2] == nil)) then
                  local only = (_227_)[1]
                  if dot_repeatable_op_3f then
                    set_dot_repeat()
                  else
                  end
                  do
                    update_dot_repeat_state(1)
                    jump_to_21(only)
                  end
                  hl:cleanup(hl_affected_windows)
                  exec_user_autocmds("LeapLeave")
                  return nil
                elseif (nil ~= _227_) then
                  local sublist = _227_
                  if sublist["autojump?"] then
                    jump_to_21(sublist[1])
                  else
                  end
                  local _232_ = post_pattern_input_loop(sublist)
                  if (nil ~= _232_) then
                    local in_final = _232_
                    if (directional_3f and (in_final == spec_keys.next_match)) then
                      local new_idx
                      if sublist["autojump?"] then
                        new_idx = 2
                      else
                        new_idx = 1
                      end
                      jump_to_21(sublist[new_idx])
                      if op_mode_3f then
                        if dot_repeatable_op_3f then
                          set_dot_repeat()
                        else
                        end
                        do
                          update_dot_repeat_state(1)
                        end
                        hl:cleanup(hl_affected_windows)
                        exec_user_autocmds("LeapLeave")
                        return nil
                      else
                        return traverse(sublist, new_idx, {["force-no-labels?"] = not sublist["autojump?"]})
                      end
                    else
                      local _236_ = get_target_with_active_primary_label(sublist, in_final)
                      if ((_G.type(_236_) == "table") and (nil ~= (_236_)[1]) and (nil ~= (_236_)[2])) then
                        local idx = (_236_)[1]
                        local target = (_236_)[2]
                        if dot_repeatable_op_3f then
                          set_dot_repeat()
                        else
                        end
                        do
                          update_dot_repeat_state(idx)
                          jump_to_21(target)
                        end
                        hl:cleanup(hl_affected_windows)
                        exec_user_autocmds("LeapLeave")
                        return nil
                      elseif true then
                        local _ = _236_
                        if sublist["autojump?"] then
                          if dot_repeatable_op_3f then
                            set_dot_repeat()
                          else
                          end
                          do
                            vim.fn.feedkeys(in_final, "i")
                          end
                          hl:cleanup(hl_affected_windows)
                          exec_user_autocmds("LeapLeave")
                          return nil
                        else
                          if change_op_3f then
                            handle_interrupted_change_op_21()
                          else
                          end
                          do
                          end
                          hl:cleanup(hl_affected_windows)
                          exec_user_autocmds("LeapLeave")
                          return nil
                        end
                      else
                        return nil
                      end
                    end
                  else
                    return nil
                  end
                else
                  return nil
                end
              end
            elseif true then
              local __60_auto = _224_
              return ...
            else
              return nil
            end
          end
          local function _254_(...)
            if dot_repeat_3f then
              local _247_ = targets[state["dot-repeat"]["target-idx"]]
              if (nil ~= _247_) then
                local target = _247_
                if dot_repeatable_op_3f then
                  set_dot_repeat()
                else
                end
                do
                  jump_to_21(target)
                end
                hl:cleanup(hl_affected_windows)
                exec_user_autocmds("LeapLeave")
                return nil
              elseif true then
                local _ = _247_
                if change_op_3f then
                  handle_interrupted_change_op_21()
                else
                end
                do
                end
                hl:cleanup(hl_affected_windows)
                exec_user_autocmds("LeapLeave")
                return nil
              else
                return nil
              end
            else
              do
                local _251_ = targets
                populate_sublists(_251_)
                set_sublist_attributes(_251_, {["force-noautojump?"] = force_noautojump_3f})
                set_labels(_251_)
              end
              local function _252_(...)
                do
                  local _253_ = targets
                  set_initial_label_states(_253_)
                  set_beacons(_253_, {})
                end
                return get_second_pattern_input(targets)
              end
              return (_3fin2 or _252_(...))
            end
          end
          return _223_(_254_(...))
        elseif true then
          local __60_auto = _222_
          return ...
        else
          return nil
        end
      end
      local function _256_(...)
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
          echo_not_found((in1 .. (_3fin2 or "")))
        end
        hl:cleanup(hl_affected_windows)
        exec_user_autocmds("LeapLeave")
        return nil
      end
      return _221_((get_targets(prepare_pattern(in1, _3fin2), {["backward?"] = backward_3f, ["target-windows"] = _3ftarget_windows}) or _256_(...)))
    elseif true then
      local __60_auto = _219_
      return ...
    else
      return nil
    end
  end
  local function _259_()
    if dot_repeat_3f then
      return state["dot-repeat"].in1, state["dot-repeat"].in2
    elseif opts.highlight_ahead_of_time then
      return get_first_pattern_input()
    else
      return get_full_pattern_input()
    end
  end
  return _218_(_259_())
end
local temporary_editor_opts = {["vim.bo.modeline"] = false}
local saved_editor_opts = {}
local function save_editor_opts()
  for opt, _ in pairs(temporary_editor_opts) do
    local _let_260_ = vim.split(opt, ".", true)
    local _0 = _let_260_[1]
    local scope = _let_260_[2]
    local name = _let_260_[3]
    saved_editor_opts[opt] = _G.vim[scope][name]
  end
  return nil
end
local function set_editor_opts(opts0)
  for opt, val in pairs(opts0) do
    local _let_261_ = vim.split(opt, ".", true)
    local _ = _let_261_[1]
    local scope = _let_261_[2]
    local name = _let_261_[3]
    _G.vim[scope][name] = val
  end
  return nil
end
local function set_temporary_editor_opts()
  return set_editor_opts(temporary_editor_opts)
end
local function restore_editor_opts()
  return set_editor_opts(saved_editor_opts)
end
local _262_
do
  local t = {}
  for _, cc in ipairs((opts.character_classes or {})) do
    local cc_2a
    if (type(cc) == "string") then
      local tbl_15_auto = {}
      local i_16_auto = #tbl_15_auto
      for char in cc:gmatch(".") do
        local val_17_auto = char
        if (nil ~= val_17_auto) then
          i_16_auto = (i_16_auto + 1)
          do end (tbl_15_auto)[i_16_auto] = val_17_auto
        else
        end
      end
      cc_2a = tbl_15_auto
    else
      cc_2a = cc
    end
    for _0, char in ipairs(cc_2a) do
      t[char] = cc_2a
    end
  end
  _262_ = t
end
opts["character_class_of"] = _262_
hl["init-highlight"](hl)
api.nvim_create_augroup("LeapDefault", {})
local function _265_()
  return hl["init-highlight"](hl)
end
api.nvim_create_autocmd("ColorScheme", {callback = _265_, group = "LeapDefault"})
local function _266_()
  save_editor_opts()
  return set_temporary_editor_opts()
end
api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _266_, group = "LeapDefault"})
api.nvim_create_autocmd("User", {pattern = "LeapLeave", callback = restore_editor_opts, group = "LeapDefault"})
return {state = state, leap = leap}
