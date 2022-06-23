local api = vim.api
local empty_3f = vim.tbl_isempty
local filter = vim.tbl_filter
local map = vim.tbl_map
local _local_1_ = math
local abs = _local_1_["abs"]
local ceil = _local_1_["ceil"]
local max = _local_1_["max"]
local min = _local_1_["min"]
local pow = _local_1_["pow"]
local hl = require("leap.highlight")
local opts = require("leap.opts")
local function clamp(x, min0, max0)
  if (x < min0) then
    return min0
  elseif (x > max0) then
    return max0
  else
    return x
  end
end
local function inc(x)
  return (x + 1)
end
local function dec(x)
  return (x - 1)
end
local function echo(msg)
  return api.nvim_echo({{msg}}, false, {})
end
local function replace_keycodes(s)
  return api.nvim_replace_termcodes(s, true, false, true)
end
local function get_cursor_pos()
  return {vim.fn.line("."), vim.fn.col(".")}
end
local function char_at_pos(_3_, _5_)
  local _arg_4_ = _3_
  local line = _arg_4_[1]
  local byte_col = _arg_4_[2]
  local _arg_6_ = _5_
  local char_offset = _arg_6_["char-offset"]
  local line_str = vim.fn.getline(line)
  local char_idx = vim.fn.charidx(line_str, dec(byte_col))
  local char_nr = vim.fn.strgetchar(line_str, (char_idx + (char_offset or 0)))
  if (char_nr ~= -1) then
    return vim.fn.nr2char(char_nr)
  else
    return nil
  end
end
local function user_forced_autojump_3f()
  return (not opts.labels or empty_3f(opts.labels))
end
local function user_forced_no_autojump_3f()
  return (not opts.safe_labels or empty_3f(opts.safe_labels))
end
local function echo_no_prev_search()
  return echo("no previous search")
end
local function echo_not_found(s)
  return echo(("not found: " .. s))
end
local function push_cursor_21(direction)
  local function _9_()
    local _8_ = direction
    if (_8_ == "fwd") then
      return "W"
    elseif (_8_ == "bwd") then
      return "bW"
    else
      return nil
    end
  end
  return vim.fn.search("\\_.", _9_())
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
  local function _14_()
    vim.o.virtualedit = saved
    return nil
  end
  return api.nvim_create_autocmd({"CursorMoved", "WinLeave", "BufLeave", "InsertEnter", "CmdlineEnter", "CmdwinEnter"}, {callback = _14_, once = true})
end
local function simulate_inclusive_op_21(mode)
  local _15_ = vim.fn.matchstr(mode, "^no\\zs.")
  if (_15_ == "") then
    if cursor_before_eof_3f() then
      return push_beyond_eof_21()
    else
      return push_cursor_21("fwd")
    end
  elseif (_15_ == "v") then
    return push_cursor_21("bwd")
  else
    return nil
  end
end
local function force_matchparen_refresh()
  pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchparen"})
  return pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchup_matchparen"})
end
local function jump_to_21_2a(pos, _18_)
  local _arg_19_ = _18_
  local winid = _arg_19_["winid"]
  local add_to_jumplist_3f = _arg_19_["add-to-jumplist?"]
  local mode = _arg_19_["mode"]
  local offset = _arg_19_["offset"]
  local reverse_3f = _arg_19_["reverse?"]
  local inclusive_op_3f = _arg_19_["inclusive-op?"]
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
  if (op_mode_3f and inclusive_op_3f and not reverse_3f) then
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
  local _let_25_ = (_3fpos or get_cursor_pos())
  local line = _let_25_[1]
  local col = _let_25_[2]
  local pos = _let_25_
  local ch_at_curpos = (char_at_pos(pos, {}) or " ")
  return api.nvim_buf_set_extmark(0, hl.ns, dec(line), dec(col), {virt_text = {{ch_at_curpos, "Cursor"}}, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.cursor})
end
local function handle_interrupted_change_op_21()
  local seq
  local function _26_()
    if (vim.fn.col(".") > 1) then
      return "<RIGHT>"
    else
      return ""
    end
  end
  seq = ("<C-\\><C-G>" .. _26_())
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
local function get_other_windows_on_tabpage(mode)
  local wins = api.nvim_tabpage_list_wins(0)
  local curr_win = api.nvim_get_current_win()
  local curr_buf = api.nvim_get_current_buf()
  local visual_7cop_mode_3f = (mode ~= "n")
  local function _29_(_241)
    return ((api.nvim_win_get_config(_241)).focusable and (_241 ~= curr_win) and not (visual_7cop_mode_3f and (api.nvim_win_get_buf(_241) ~= curr_buf)))
  end
  return filter(_29_, wins)
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
local function skip_one_21(reverse_3f)
  local new_line
  local function _30_()
    if reverse_3f then
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
local function to_closed_fold_edge_21(reverse_3f)
  local edge_line
  local _32_
  if reverse_3f then
    _32_ = vim.fn.foldclosed
  else
    _32_ = vim.fn.foldclosedend
  end
  edge_line = _32_(vim.fn.line("."))
  vim.fn.cursor(edge_line, 0)
  local edge_col
  if reverse_3f then
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
local function to_next_in_window_pos_21(reverse_3f, left_bound, right_bound, stopline)
  local _let_35_ = {vim.fn.line("."), vim.fn.virtcol(".")}
  local line = _let_35_[1]
  local virtcol = _let_35_[2]
  local from_pos = _let_35_
  local left_off_3f = (virtcol < left_bound)
  local right_off_3f = (virtcol > right_bound)
  local _36_
  if (left_off_3f and reverse_3f) then
    if (dec(line) >= stopline) then
      _36_ = {dec(line), right_bound}
    else
      _36_ = nil
    end
  elseif (left_off_3f and not reverse_3f) then
    _36_ = {line, left_bound}
  elseif (right_off_3f and reverse_3f) then
    _36_ = {line, right_bound}
  elseif (right_off_3f and not reverse_3f) then
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
      if reverse_3f then
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
  local reverse_3f = _arg_46_["reverse?"]
  local whole_window_3f = _arg_46_["whole-window?"]
  local skip_curpos_3f = _arg_46_["skip-curpos?"]
  local skip_orig_curpos_3f = skip_curpos_3f
  local _let_47_ = get_cursor_pos()
  local orig_curline = _let_47_[1]
  local orig_curcol = _let_47_[2]
  local wintop = vim.fn.line("w0")
  local winbot = vim.fn.line("w$")
  local stopline
  if reverse_3f then
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
      if reverse_3f then
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
        local _56_ = to_next_in_window_pos_21(reverse_3f, left_bound, right_bound, stopline)
        if (_56_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _56_
          return iter(true)
        else
          return nil
        end
      elseif (vim.fn.foldclosed(line) ~= -1) then
        to_closed_fold_edge_21(reverse_3f)
        local _58_ = skip_one_21(reverse_3f)
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
  local reverse_3f = _arg_63_["reverse?"]
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
  local match_positions = get_match_positions(pattern, bounds, {["reverse?"] = reverse_3f, ["skip-curpos?"] = skip_curpos_3f, ["whole-window?"] = whole_window_3f})
  local prev_match = {}
  for _65_ in match_positions do
    local _each_66_ = _65_
    local line = _each_66_[1]
    local col = _each_66_[2]
    local pos = _each_66_
    local ch1 = char_at_pos(pos, {})
    local ch2, eol_3f = nil, nil
    do
      local _67_ = char_at_pos(pos, {["char-offset"] = 1})
      if (nil ~= _67_) then
        local char = _67_
        ch2, eol_3f = char
      elseif true then
        local _0 = _67_
        ch2, eol_3f = replace_keycodes(opts.special_keys.eol), true
      else
        ch2, eol_3f = nil
      end
    end
    local same_char_triplet_3f
    local _69_
    if reverse_3f then
      _69_ = dec
    else
      _69_ = inc
    end
    same_char_triplet_3f = ((ch2 == prev_match.ch2) and (line == prev_match.line) and (col == _69_(prev_match.col)))
    prev_match = {line = line, col = col, ch2 = ch2}
    if not same_char_triplet_3f then
      table.insert(targets0, {wininfo = wininfo0, pos = pos, pair = {ch1, ch2}, ["edge-pos?"] = (eol_3f or (col == right_bound))})
    else
    end
  end
  if next(targets0) then
    return targets0
  else
    return nil
  end
end
local function distance(_73_, _75_)
  local _arg_74_ = _73_
  local l1 = _arg_74_[1]
  local c1 = _arg_74_[2]
  local _arg_76_ = _75_
  local l2 = _arg_76_[1]
  local c2 = _arg_76_[2]
  local editor_grid_aspect_ratio = 0.3
  local _let_77_ = {abs((c1 - c2)), abs((l1 - l2))}
  local dx = _let_77_[1]
  local dy = _let_77_[2]
  local dx0 = (dx * editor_grid_aspect_ratio)
  return pow((pow(dx0, 2) + pow(dy, 2)), 0.5)
end
local function get_targets(pattern, _78_)
  local _arg_79_ = _78_
  local reverse_3f = _arg_79_["reverse?"]
  local target_windows = _arg_79_["target-windows"]
  if not target_windows then
    return get_targets_2a(pattern, {["reverse?"] = reverse_3f})
  else
    local targets = {}
    local cursor_positions = {}
    local source_winid = vim.fn.win_getid()
    local curr_win_only_3f
    do
      local _80_ = target_windows
      if ((_G.type(_80_) == "table") and ((_G.type((_80_)[1]) == "table") and (((_80_)[1]).winid == source_winid)) and ((_80_)[2] == nil)) then
        curr_win_only_3f = true
      else
        curr_win_only_3f = nil
      end
    end
    local cross_win_3f = not curr_win_only_3f
    for _, _82_ in ipairs(target_windows) do
      local _each_83_ = _82_
      local winid = _each_83_["winid"]
      local wininfo = _each_83_
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
        for winid, _86_ in pairs(cursor_positions) do
          local _each_87_ = _86_
          local line = _each_87_[1]
          local col = _each_87_[2]
          local _88_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_88_) == "table") and ((_88_).col == col) and (nil ~= (_88_).row)) then
            local row = (_88_).row
            cursor_positions[winid] = {row, col}
          else
          end
        end
      else
      end
      for _, _91_ in ipairs(targets) do
        local _each_92_ = _91_
        local _each_93_ = _each_92_["pos"]
        local line = _each_93_[1]
        local col = _each_93_[2]
        local _each_94_ = _each_92_["wininfo"]
        local winid = _each_94_["winid"]
        local t = _each_92_
        if by_screen_pos_3f then
          local _95_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_95_) == "table") and ((_95_).col == col) and (nil ~= (_95_).row)) then
            local row = (_95_).row
            t["screenpos"] = {row, col}
          else
          end
        else
        end
        t["rank"] = distance((t.screenpos or t.pos), cursor_positions[winid])
      end
      local function _98_(_241, _242)
        return ((_241).rank < (_242).rank)
      end
      table.sort(targets, _98_)
      return targets
    else
      return nil
    end
  end
end
local function populate_sublists(targets)
  targets["sublists"] = {}
  if opts.case_insensitive then
    local function _101_(t, k)
      return rawget(t, k:lower())
    end
    local function _102_(t, k, v)
      return rawset(t, k:lower(), v)
    end
    setmetatable(targets.sublists, {__index = _101_, __newindex = _102_})
  else
  end
  for _, _104_ in ipairs(targets) do
    local _each_105_ = _104_
    local _each_106_ = _each_105_["pair"]
    local _0 = _each_106_[1]
    local ch2 = _each_106_[2]
    local target = _each_105_
    if not targets.sublists[ch2] then
      targets["sublists"][ch2] = {}
    else
    end
    table.insert(targets.sublists[ch2], target)
  end
  return nil
end
local function set_autojump(sublist, force_no_autojump_3f)
  sublist["autojump?"] = (not (force_no_autojump_3f or user_forced_no_autojump_3f()) and (user_forced_autojump_3f() or (#opts.safe_labels >= dec(#sublist))))
  return nil
end
local function attach_label_set(sublist)
  local _108_
  if user_forced_autojump_3f() then
    _108_ = opts.safe_labels
  elseif user_forced_no_autojump_3f() then
    _108_ = opts.labels
  elseif sublist["autojump?"] then
    _108_ = opts.safe_labels
  else
    _108_ = opts.labels
  end
  sublist["label-set"] = _108_
  return nil
end
local function set_sublist_attributes(targets, _110_)
  local _arg_111_ = _110_
  local force_no_autojump_3f = _arg_111_["force-no-autojump?"]
  for _, sublist in pairs(targets.sublists) do
    set_autojump(sublist, force_no_autojump_3f)
    attach_label_set(sublist)
  end
  return nil
end
local function set_labels(targets)
  for _, sublist in pairs(targets.sublists) do
    if (#sublist > 1) then
      local _local_112_ = sublist
      local autojump_3f = _local_112_["autojump?"]
      local label_set = _local_112_["label-set"]
      for i, target in ipairs(sublist) do
        local i_2a
        if autojump_3f then
          i_2a = dec(i)
        else
          i_2a = i
        end
        if (i_2a > 0) then
          local _115_
          do
            local _114_ = (i_2a % #label_set)
            if (_114_ == 0) then
              _115_ = label_set[#label_set]
            elseif (nil ~= _114_) then
              local n = _114_
              _115_ = label_set[n]
            else
              _115_ = nil
            end
          end
          target["label"] = _115_
        else
        end
      end
    else
    end
  end
  return nil
end
local function set_label_states(sublist, _121_)
  local _arg_122_ = _121_
  local group_offset = _arg_122_["group-offset"]
  local _7clabel_set_7c = #sublist["label-set"]
  local offset = (group_offset * _7clabel_set_7c)
  local primary_start
  local function _123_()
    if sublist["autojump?"] then
      return 2
    else
      return 1
    end
  end
  primary_start = (offset + _123_())
  local primary_end = (primary_start + dec(_7clabel_set_7c))
  local secondary_start = inc(primary_end)
  local secondary_end = (primary_end + _7clabel_set_7c)
  for i, target in ipairs(sublist) do
    if target.label then
      local _124_
      if (function(_125_,_126_,_127_) return (_125_ <= _126_) and (_126_ <= _127_) end)(primary_start,i,primary_end) then
        _124_ = "active-primary"
      elseif (function(_128_,_129_,_130_) return (_128_ <= _129_) and (_129_ <= _130_) end)(secondary_start,i,secondary_end) then
        _124_ = "active-secondary"
      elseif (i > secondary_end) then
        _124_ = "inactive"
      else
        _124_ = nil
      end
      target["label-state"] = _124_
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
  local _let_133_ = target
  local _let_134_ = _let_133_["pair"]
  local ch1 = _let_134_[1]
  local ch2 = _let_134_[2]
  local edge_pos_3f = _let_133_["edge-pos?"]
  local label = _let_133_["label"]
  local offset
  local function _135_()
    if edge_pos_3f then
      return 0
    else
      return ch2:len()
    end
  end
  offset = (ch1:len() + _135_())
  local virttext
  do
    local _136_ = target["label-state"]
    if (_136_ == "active-primary") then
      virttext = {{label, hl.group["label-primary"]}}
    elseif (_136_ == "active-secondary") then
      virttext = {{label, hl.group["label-secondary"]}}
    elseif (_136_ == "inactive") then
      if not opts.highlight_unlabeled then
        virttext = {{" ", hl.group["label-secondary"]}}
      else
        virttext = nil
      end
    else
      virttext = nil
    end
  end
  local _139_
  if virttext then
    _139_ = {offset, virttext}
  else
    _139_ = nil
  end
  target["beacon"] = _139_
  return nil
end
local function set_beacon_to_match_hl(target)
  local _let_141_ = target
  local _let_142_ = _let_141_["pair"]
  local ch1 = _let_142_[1]
  local ch2 = _let_142_[2]
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
    local _let_143_ = target
    local _let_144_ = _let_143_["pos"]
    local lnum = _let_144_[1]
    local col = _let_144_[2]
    local _let_145_ = _let_143_["pair"]
    local ch1 = _let_145_[1]
    local _ = _let_145_[2]
    local _let_146_ = _let_143_["wininfo"]
    local bufnr = _let_146_["bufnr"]
    local winid = _let_146_["winid"]
    if (not target.beacon or (opts.highlight_unlabeled and (target.beacon[2][1][2] == hl.group.match))) then
      local keys = {(bufnr .. " " .. winid .. " " .. lnum .. " " .. col), (bufnr .. " " .. winid .. " " .. lnum .. " " .. (col + ch1:len()))}
      for _0, k in ipairs(keys) do
        do
          local _147_ = label_positions[k]
          if (nil ~= _147_) then
            local other = _147_
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
        local _149_ = unlabeled_match_positions[k]
        if (nil ~= _149_) then
          local other = _149_
          target.beacon = nil
          set_beacon_to_match_hl(other)
        elseif true then
          local _0 = _149_
          local _150_ = label_positions[k]
          if (nil ~= _150_) then
            local other = _150_
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
local function set_beacons(target_list, _154_)
  local _arg_155_ = _154_
  local force_no_labels_3f = _arg_155_["force-no-labels?"]
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
    local _158_ = target.beacon
    if ((_G.type(_158_) == "table") and (nil ~= (_158_)[1]) and (nil ~= (_158_)[2])) then
      local offset = (_158_)[1]
      local virttext = (_158_)[2]
      local _let_159_ = map(dec, target.pos)
      local lnum = _let_159_[1]
      local col = _let_159_[2]
      api.nvim_buf_set_extmark(target.wininfo.bufnr, hl.ns, lnum, (col + offset), {virt_text = virttext, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.label})
    else
    end
  end
  return nil
end
local state = {["repeat"] = {in1 = nil, in2 = nil}, ["dot-repeat"] = {in1 = nil, in2 = nil, ["target-idx"] = nil, ["reverse?"] = nil, ["inclusive-op?"] = nil, ["offset?"] = nil}}
local function leap(_161_)
  local _arg_162_ = _161_
  local dot_repeat_3f = _arg_162_["dot-repeat?"]
  local target_windows = _arg_162_["target-windows"]
  local kwargs = _arg_162_
  local function _164_()
    if dot_repeat_3f then
      return state["dot-repeat"]
    else
      return kwargs
    end
  end
  local _let_163_ = _164_()
  local reverse_3f = _let_163_["reverse?"]
  local inclusive_op_3f = _let_163_["inclusive-op?"]
  local offset = _let_163_["offset"]
  local mode = api.nvim_get_mode().mode
  local _3ftarget_windows
  do
    local _165_
    do
      local _166_ = target_windows
      if (_G.type(_166_) == "table") then
        local t = _166_
        _165_ = t
      elseif (_166_ == true) then
        _165_ = get_other_windows_on_tabpage(mode)
      else
        _165_ = nil
      end
    end
    if (_165_ ~= nil) then
      local function _168_(_241)
        return (vim.fn.getwininfo(_241))[1]
      end
      _3ftarget_windows = map(_168_, _165_)
    else
      _3ftarget_windows = _165_
    end
  end
  local source_window = vim.fn.getwininfo(vim.fn.win_getid())[1]
  local directional_3f = not _3ftarget_windows
  local op_mode_3f = mode:match("o")
  local change_op_3f = (op_mode_3f and (vim.v.operator == "c"))
  local dot_repeatable_op_3f = (op_mode_3f and directional_3f and (vim.v.operator ~= "y"))
  local force_no_autojump_3f = (op_mode_3f or not directional_3f)
  local spec_keys
  local function _170_(_, k)
    return replace_keycodes(opts.special_keys[k])
  end
  spec_keys = setmetatable({}, {__index = _170_})
  local function prepare_pattern(in1, _3fin2)
    local function _171_()
      if opts.case_insensitive then
        return "\\c"
      else
        return "\\C"
      end
    end
    local function _173_()
      local _172_ = _3fin2
      if (_172_ == spec_keys.eol) then
        return ("\\(" .. _3fin2 .. "\\|\\r\\?\\n\\)")
      elseif true then
        local _ = _172_
        return (_3fin2 or "\\_.")
      else
        return nil
      end
    end
    return ("\\V" .. _171_() .. in1:gsub("\\", "\\\\") .. _173_())
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
        state["dot-repeat"] = vim.tbl_extend("error", state_2a["dot-repeat"], {["reverse?"] = reverse_3f, offset = offset, ["inclusive-op?"] = inclusive_op_3f})
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
      jump_to_21_2a(target.pos, {winid = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["reverse?"] = reverse_3f, ["inclusive-op?"] = inclusive_op_3f})
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
      hl:cleanup(_3ftarget_windows)
      hl["apply-backdrop"](hl, reverse_3f, _3ftarget_windows)
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
      local function _189_()
        if _3ftarget_windows then
          local _188_ = _3ftarget_windows
          table.insert(_188_, source_window)
          return _188_
        else
          return nil
        end
      end
      hl:cleanup(_189_())
      exec_user_autocmds("LeapLeave")
      return nil
    end
    _185_ = (get_input() or _186_())
    if (nil ~= _185_) then
      local input = _185_
      if ((input == spec_keys.next_match) or (input == spec_keys.prev_match)) then
        local new_idx
        do
          local _190_ = input
          if (_190_ == spec_keys.next_match) then
            new_idx = min(inc(idx), #targets)
          elseif (_190_ == spec_keys.prev_match) then
            new_idx = max(dec(idx), 1)
          else
            new_idx = nil
          end
        end
        update_state({["repeat"] = {in1 = state["repeat"].in1, in2 = targets[new_idx].pair[2]}})
        jump_to_21(targets[new_idx])
        return traverse(targets, new_idx, {["force-no-labels?"] = force_no_labels_3f})
      else
        local _192_ = get_target_with_active_primary_label(targets, input)
        if ((_G.type(_192_) == "table") and true and (nil ~= (_192_)[2])) then
          local _ = (_192_)[1]
          local target = (_192_)[2]
          if dot_repeatable_op_3f then
            set_dot_repeat()
          else
          end
          do
            jump_to_21(target)
          end
          local function _195_()
            if _3ftarget_windows then
              local _194_ = _3ftarget_windows
              table.insert(_194_, source_window)
              return _194_
            else
              return nil
            end
          end
          hl:cleanup(_195_())
          exec_user_autocmds("LeapLeave")
          return nil
        elseif true then
          local _ = _192_
          if dot_repeatable_op_3f then
            set_dot_repeat()
          else
          end
          do
            vim.fn.feedkeys(input, "i")
          end
          local function _198_()
            if _3ftarget_windows then
              local _197_ = _3ftarget_windows
              table.insert(_197_, source_window)
              return _197_
            else
              return nil
            end
          end
          hl:cleanup(_198_())
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
      hl:cleanup(_3ftarget_windows)
      hl["apply-backdrop"](hl, reverse_3f, _3ftarget_windows)
      do
        echo("")
      end
      highlight_cursor()
      vim.cmd("redraw")
    end
    local _202_
    local function _203_()
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      do
      end
      local function _206_()
        if _3ftarget_windows then
          local _205_ = _3ftarget_windows
          table.insert(_205_, source_window)
          return _205_
        else
          return nil
        end
      end
      hl:cleanup(_206_())
      exec_user_autocmds("LeapLeave")
      return nil
    end
    _202_ = (get_input() or _203_())
    if (_202_ == spec_keys.repeat_search) then
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
        local function _209_()
          if _3ftarget_windows then
            local _208_ = _3ftarget_windows
            table.insert(_208_, source_window)
            return _208_
          else
            return nil
          end
        end
        hl:cleanup(_209_())
        exec_user_autocmds("LeapLeave")
        return nil
      end
    elseif (nil ~= _202_) then
      local in1 = _202_
      return in1
    else
      return nil
    end
  end
  local function get_second_pattern_input(targets)
    do
      local _212_ = targets
      set_initial_label_states(_212_)
      set_beacons(_212_, {})
    end
    do
      hl:cleanup(_3ftarget_windows)
      hl["apply-backdrop"](hl, reverse_3f, _3ftarget_windows)
      do
        light_up_beacons(targets)
      end
      highlight_cursor()
      vim.cmd("redraw")
    end
    local function _213_()
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      do
      end
      local function _216_()
        if _3ftarget_windows then
          local _215_ = _3ftarget_windows
          table.insert(_215_, source_window)
          return _215_
        else
          return nil
        end
      end
      hl:cleanup(_216_())
      exec_user_autocmds("LeapLeave")
      return nil
    end
    return (get_input() or _213_())
  end
  local function post_pattern_input_loop(sublist)
    local function loop(group_offset, initial_invoc_3f)
      do
        local _217_ = sublist
        set_label_states(_217_, {["group-offset"] = group_offset})
        set_beacons(_217_, {})
      end
      do
        hl:cleanup(_3ftarget_windows)
        hl["apply-backdrop"](hl, reverse_3f, _3ftarget_windows)
        do
          local function _218_()
            if sublist["autojump?"] then
              return 2
            else
              return nil
            end
          end
          light_up_beacons(sublist, _218_())
        end
        highlight_cursor()
        vim.cmd("redraw")
      end
      local _219_
      local function _220_()
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
        end
        local function _223_()
          if _3ftarget_windows then
            local _222_ = _3ftarget_windows
            table.insert(_222_, source_window)
            return _222_
          else
            return nil
          end
        end
        hl:cleanup(_223_())
        exec_user_autocmds("LeapLeave")
        return nil
      end
      _219_ = (get_input() or _220_())
      if (nil ~= _219_) then
        local input = _219_
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
  local function _227_(...)
    local _228_, _229_ = ...
    if ((nil ~= _228_) and true) then
      local in1 = _228_
      local _3fin2 = _229_
      local function _230_(...)
        local _231_ = ...
        if (nil ~= _231_) then
          local targets = _231_
          local function _232_(...)
            local _233_ = ...
            if (nil ~= _233_) then
              local in2 = _233_
              if dot_repeat_3f then
                local _234_ = targets[state["dot-repeat"]["target-idx"]]
                if (nil ~= _234_) then
                  local target = _234_
                  if dot_repeatable_op_3f then
                    set_dot_repeat()
                  else
                  end
                  do
                    jump_to_21(target)
                  end
                  local function _237_(...)
                    if _3ftarget_windows then
                      local _236_ = _3ftarget_windows
                      table.insert(_236_, source_window)
                      return _236_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_237_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                elseif true then
                  local _ = _234_
                  if change_op_3f then
                    handle_interrupted_change_op_21()
                  else
                  end
                  do
                  end
                  local function _240_(...)
                    if _3ftarget_windows then
                      local _239_ = _3ftarget_windows
                      table.insert(_239_, source_window)
                      return _239_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_240_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                else
                  return nil
                end
              elseif (directional_3f and (in2 == spec_keys.next_match)) then
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
                  local function _244_(...)
                    if _3ftarget_windows then
                      local _243_ = _3ftarget_windows
                      table.insert(_243_, source_window)
                      return _243_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_244_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                else
                  return traverse(targets, 1, {["force-no-labels?"] = true})
                end
              else
                update_state({["repeat"] = {in1 = in1, in2 = in2}})
                local update_dot_repeat_state
                local function _246_(_241)
                  return update_state({["dot-repeat"] = {in1 = in1, in2 = in2, ["target-idx"] = _241}})
                end
                update_dot_repeat_state = _246_
                local _247_
                local function _248_(...)
                  if change_op_3f then
                    handle_interrupted_change_op_21()
                  else
                  end
                  do
                    echo_not_found((in1 .. in2))
                  end
                  local function _251_(...)
                    if _3ftarget_windows then
                      local _250_ = _3ftarget_windows
                      table.insert(_250_, source_window)
                      return _250_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_251_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                end
                _247_ = (targets.sublists[in2] or _248_(...))
                if ((_G.type(_247_) == "table") and (nil ~= (_247_)[1]) and ((_247_)[2] == nil)) then
                  local only = (_247_)[1]
                  if dot_repeatable_op_3f then
                    set_dot_repeat()
                  else
                  end
                  do
                    update_dot_repeat_state(1)
                    jump_to_21(only)
                  end
                  local function _254_(...)
                    if _3ftarget_windows then
                      local _253_ = _3ftarget_windows
                      table.insert(_253_, source_window)
                      return _253_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_254_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                elseif (nil ~= _247_) then
                  local sublist = _247_
                  if sublist["autojump?"] then
                    jump_to_21(sublist[1])
                  else
                  end
                  local _256_ = post_pattern_input_loop(sublist)
                  if (nil ~= _256_) then
                    local in_final = _256_
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
                        local function _260_(...)
                          if _3ftarget_windows then
                            local _259_ = _3ftarget_windows
                            table.insert(_259_, source_window)
                            return _259_
                          else
                            return nil
                          end
                        end
                        hl:cleanup(_260_(...))
                        exec_user_autocmds("LeapLeave")
                        return nil
                      else
                        return traverse(sublist, new_idx, {["force-no-labels?"] = not sublist["autojump?"]})
                      end
                    else
                      local _262_ = get_target_with_active_primary_label(sublist, in_final)
                      if ((_G.type(_262_) == "table") and (nil ~= (_262_)[1]) and (nil ~= (_262_)[2])) then
                        local idx = (_262_)[1]
                        local target = (_262_)[2]
                        if dot_repeatable_op_3f then
                          set_dot_repeat()
                        else
                        end
                        do
                          update_dot_repeat_state(idx)
                          jump_to_21(target)
                        end
                        local function _265_(...)
                          if _3ftarget_windows then
                            local _264_ = _3ftarget_windows
                            table.insert(_264_, source_window)
                            return _264_
                          else
                            return nil
                          end
                        end
                        hl:cleanup(_265_(...))
                        exec_user_autocmds("LeapLeave")
                        return nil
                      elseif true then
                        local _ = _262_
                        if sublist["autojump?"] then
                          if dot_repeatable_op_3f then
                            set_dot_repeat()
                          else
                          end
                          do
                            vim.fn.feedkeys(in_final, "i")
                          end
                          local function _268_(...)
                            if _3ftarget_windows then
                              local _267_ = _3ftarget_windows
                              table.insert(_267_, source_window)
                              return _267_
                            else
                              return nil
                            end
                          end
                          hl:cleanup(_268_(...))
                          exec_user_autocmds("LeapLeave")
                          return nil
                        else
                          if change_op_3f then
                            handle_interrupted_change_op_21()
                          else
                          end
                          do
                          end
                          local function _271_(...)
                            if _3ftarget_windows then
                              local _270_ = _3ftarget_windows
                              table.insert(_270_, source_window)
                              return _270_
                            else
                              return nil
                            end
                          end
                          hl:cleanup(_271_(...))
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
              local __60_auto = _233_
              return ...
            else
              return nil
            end
          end
          local function _279_(...)
            do
              local _280_ = targets
              populate_sublists(_280_)
              set_sublist_attributes(_280_, {["force-no-autojump?"] = force_no_autojump_3f})
              set_labels(_280_)
            end
            return (_3fin2 or get_second_pattern_input(targets))
          end
          return _232_(_279_(...))
        elseif true then
          local __60_auto = _231_
          return ...
        else
          return nil
        end
      end
      local function _282_(...)
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
          echo_not_found((in1 .. (_3fin2 or "")))
        end
        local function _285_(...)
          if _3ftarget_windows then
            local _284_ = _3ftarget_windows
            table.insert(_284_, source_window)
            return _284_
          else
            return nil
          end
        end
        hl:cleanup(_285_(...))
        exec_user_autocmds("LeapLeave")
        return nil
      end
      return _230_((get_targets(prepare_pattern(in1, _3fin2), {["reverse?"] = reverse_3f, ["target-windows"] = _3ftarget_windows}) or _282_(...)))
    elseif true then
      local __60_auto = _228_
      return ...
    else
      return nil
    end
  end
  local function _287_()
    if dot_repeat_3f then
      return state["dot-repeat"].in1, state["dot-repeat"].in2
    else
      return get_first_pattern_input()
    end
  end
  return _227_(_287_())
end
local temporary_editor_opts = {["vim.bo.modeline"] = false}
local saved_editor_opts = {}
local function save_editor_opts()
  for opt, _ in pairs(temporary_editor_opts) do
    local _let_288_ = vim.split(opt, ".", true)
    local _0 = _let_288_[1]
    local scope = _let_288_[2]
    local name = _let_288_[3]
    saved_editor_opts[opt] = _G.vim[scope][name]
  end
  return nil
end
local function set_editor_opts(opts0)
  for opt, val in pairs(opts0) do
    local _let_289_ = vim.split(opt, ".", true)
    local _ = _let_289_[1]
    local scope = _let_289_[2]
    local name = _let_289_[3]
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
hl["init-highlight"](hl)
api.nvim_create_augroup("LeapDefault", {})
local function _290_()
  return hl["init-highlight"](hl)
end
api.nvim_create_autocmd("ColorScheme", {callback = _290_, group = "LeapDefault"})
local function _291_()
  save_editor_opts()
  return set_temporary_editor_opts()
end
api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _291_, group = "LeapDefault"})
api.nvim_create_autocmd("User", {pattern = "LeapLeave", callback = restore_editor_opts, group = "LeapDefault"})
return {state = state, leap = leap}
