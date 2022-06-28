local hl = require("leap.highlight")
local opts = require("leap.opts")
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
local function inc(x)
  return (x + 1)
end
local function dec(x)
  return (x - 1)
end
local function clamp(x, min0, max0)
  if (x < min0) then
    return min0
  elseif (x > max0) then
    return max0
  else
    return x
  end
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
  local backward_3f = _arg_19_["backward?"]
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
local function get_input_by_keymap()
  local input = get_input()
  if ((input ~= nil) and (vim.bo.iminsert == 1)) then
    local has_chars_3f = true
    while (has_chars_3f and (#input <= 4)) do
      local partial_keymap = vim.fn.mapcheck(input, "l")
      local full_keymap = vim.fn.maparg(input, "l")
      has_chars_3f = false
      if (partial_keymap ~= "") then
        if (full_keymap == partial_keymap) then
          input = full_keymap
        else
          local c = get_input()
          if (c ~= nil) then
            has_chars_3f = true
            input = (input .. c)
          else
          end
        end
      else
      end
    end
  else
  end
  return input
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
  local function _33_(_241)
    return ((api.nvim_win_get_config(_241)).focusable and (_241 ~= curr_win) and not (visual_7cop_mode_3f and (api.nvim_win_get_buf(_241) ~= curr_buf)))
  end
  return filter(_33_, wins)
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
  local function _34_()
    if backward_3f then
      return "bwd"
    else
      return "fwd"
    end
  end
  new_line = push_cursor_21(_34_())
  if (new_line == 0) then
    return "dead-end"
  else
    return nil
  end
end
local function to_closed_fold_edge_21(backward_3f)
  local edge_line
  local _36_
  if backward_3f then
    _36_ = vim.fn.foldclosed
  else
    _36_ = vim.fn.foldclosedend
  end
  edge_line = _36_(vim.fn.line("."))
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
  local _let_39_ = {vim.fn.line("."), vim.fn.virtcol(".")}
  local line = _let_39_[1]
  local virtcol = _let_39_[2]
  local from_pos = _let_39_
  local left_off_3f = (virtcol < left_bound)
  local right_off_3f = (virtcol > right_bound)
  local _40_
  if (left_off_3f and backward_3f) then
    if (dec(line) >= stopline) then
      _40_ = {dec(line), right_bound}
    else
      _40_ = nil
    end
  elseif (left_off_3f and not backward_3f) then
    _40_ = {line, left_bound}
  elseif (right_off_3f and backward_3f) then
    _40_ = {line, right_bound}
  elseif (right_off_3f and not backward_3f) then
    if (inc(line) <= stopline) then
      _40_ = {inc(line), left_bound}
    else
      _40_ = nil
    end
  else
    _40_ = nil
  end
  if (nil ~= _40_) then
    local to_pos = _40_
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
local function get_match_positions(pattern, _47_, _49_)
  local _arg_48_ = _47_
  local left_bound = _arg_48_[1]
  local right_bound = _arg_48_[2]
  local _arg_50_ = _49_
  local backward_3f = _arg_50_["backward?"]
  local whole_window_3f = _arg_50_["whole-window?"]
  local skip_curpos_3f = _arg_50_["skip-curpos?"]
  local skip_orig_curpos_3f = skip_curpos_3f
  local _let_51_ = get_cursor_pos()
  local orig_curline = _let_51_[1]
  local orig_curcol = _let_51_[2]
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
  local function _53_()
    vim.fn.winrestview(saved_view)
    vim.o.cpo = saved_cpo
    return nil
  end
  cleanup = _53_
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
    local function _55_()
      if backward_3f then
        return "b"
      else
        return ""
      end
    end
    local function _56_()
      if match_at_curpos_3f0 then
        return "c"
      else
        return ""
      end
    end
    flags = (_55_() .. _56_())
    moved_to_topleft_3f = false
    local _57_ = vim.fn.searchpos(pattern, flags, stopline)
    if ((_G.type(_57_) == "table") and (nil ~= (_57_)[1]) and (nil ~= (_57_)[2])) then
      local line = (_57_)[1]
      local col = (_57_)[2]
      local pos = _57_
      if (line == 0) then
        return cleanup()
      elseif ((line == orig_curline) and (col == orig_curcol) and skip_orig_curpos_3f) then
        local _58_ = skip_one_21()
        if (_58_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _58_
          return iter(true)
        else
          return nil
        end
      elseif ((col < left_bound) and (col > right_bound) and not vim.wo.wrap) then
        local _60_ = to_next_in_window_pos_21(backward_3f, left_bound, right_bound, stopline)
        if (_60_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _60_
          return iter(true)
        else
          return nil
        end
      elseif (vim.fn.foldclosed(line) ~= -1) then
        to_closed_fold_edge_21(backward_3f)
        local _62_ = skip_one_21(backward_3f)
        if (_62_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _62_
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
local function get_targets_2a(pattern, _66_)
  local _arg_67_ = _66_
  local backward_3f = _arg_67_["backward?"]
  local wininfo = _arg_67_["wininfo"]
  local targets = _arg_67_["targets"]
  local source_winid = _arg_67_["source-winid"]
  local targets0 = (targets or {})
  local _let_68_ = get_horizontal_bounds()
  local _ = _let_68_[1]
  local right_bound = _let_68_[2]
  local bounds = _let_68_
  local whole_window_3f = wininfo
  local wininfo0 = (wininfo or vim.fn.getwininfo(vim.fn.win_getid())[1])
  local skip_curpos_3f = (whole_window_3f and (vim.fn.win_getid() == source_winid))
  local match_positions = get_match_positions(pattern, bounds, {["backward?"] = backward_3f, ["skip-curpos?"] = skip_curpos_3f, ["whole-window?"] = whole_window_3f})
  local prev_match = {}
  for _69_ in match_positions do
    local _each_70_ = _69_
    local line = _each_70_[1]
    local col = _each_70_[2]
    local pos = _each_70_
    local ch1 = char_at_pos(pos, {})
    local ch2, eol_3f = nil, nil
    do
      local _71_ = char_at_pos(pos, {["char-offset"] = 1})
      if (nil ~= _71_) then
        local char = _71_
        ch2, eol_3f = char
      elseif true then
        local _0 = _71_
        ch2, eol_3f = replace_keycodes(opts.special_keys.eol), true
      else
        ch2, eol_3f = nil
      end
    end
    local same_char_triplet_3f
    local _73_
    if backward_3f then
      _73_ = dec
    else
      _73_ = inc
    end
    same_char_triplet_3f = ((ch2 == prev_match.ch2) and (line == prev_match.line) and (col == _73_(prev_match.col)))
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
local function distance(_77_, _79_)
  local _arg_78_ = _77_
  local l1 = _arg_78_[1]
  local c1 = _arg_78_[2]
  local _arg_80_ = _79_
  local l2 = _arg_80_[1]
  local c2 = _arg_80_[2]
  local editor_grid_aspect_ratio = 0.3
  local _let_81_ = {abs((c1 - c2)), abs((l1 - l2))}
  local dx = _let_81_[1]
  local dy = _let_81_[2]
  local dx0 = (dx * editor_grid_aspect_ratio)
  return pow((pow(dx0, 2) + pow(dy, 2)), 0.5)
end
local function get_targets(pattern, _82_)
  local _arg_83_ = _82_
  local backward_3f = _arg_83_["backward?"]
  local target_windows = _arg_83_["target-windows"]
  if not target_windows then
    return get_targets_2a(pattern, {["backward?"] = backward_3f})
  else
    local targets = {}
    local cursor_positions = {}
    local source_winid = vim.fn.win_getid()
    local curr_win_only_3f
    do
      local _84_ = target_windows
      if ((_G.type(_84_) == "table") and ((_G.type((_84_)[1]) == "table") and (((_84_)[1]).winid == source_winid)) and ((_84_)[2] == nil)) then
        curr_win_only_3f = true
      else
        curr_win_only_3f = nil
      end
    end
    local cross_win_3f = not curr_win_only_3f
    for _, _86_ in ipairs(target_windows) do
      local _each_87_ = _86_
      local winid = _each_87_["winid"]
      local wininfo = _each_87_
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
        for winid, _90_ in pairs(cursor_positions) do
          local _each_91_ = _90_
          local line = _each_91_[1]
          local col = _each_91_[2]
          local _92_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_92_) == "table") and (nil ~= (_92_).row) and ((_92_).col == col)) then
            local row = (_92_).row
            cursor_positions[winid] = {row, col}
          else
          end
        end
      else
      end
      for _, _95_ in ipairs(targets) do
        local _each_96_ = _95_
        local _each_97_ = _each_96_["pos"]
        local line = _each_97_[1]
        local col = _each_97_[2]
        local _each_98_ = _each_96_["wininfo"]
        local winid = _each_98_["winid"]
        local t = _each_96_
        if by_screen_pos_3f then
          local _99_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_99_) == "table") and (nil ~= (_99_).row) and ((_99_).col == col)) then
            local row = (_99_).row
            t["screenpos"] = {row, col}
          else
          end
        else
        end
        t["rank"] = distance((t.screenpos or t.pos), cursor_positions[winid])
      end
      local function _102_(_241, _242)
        return ((_241).rank < (_242).rank)
      end
      table.sort(targets, _102_)
      return targets
    else
      return nil
    end
  end
end
local function populate_sublists(targets)
  targets["sublists"] = {}
  if not opts.case_sensitive then
    local function _105_(t, k)
      return rawget(t, k:lower())
    end
    local function _106_(t, k, v)
      return rawset(t, k:lower(), v)
    end
    setmetatable(targets.sublists, {__index = _105_, __newindex = _106_})
  else
  end
  for _, _108_ in ipairs(targets) do
    local _each_109_ = _108_
    local _each_110_ = _each_109_["pair"]
    local _0 = _each_110_[1]
    local ch2 = _each_110_[2]
    local target = _each_109_
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
  local _112_
  if user_forced_autojump_3f() then
    _112_ = opts.safe_labels
  elseif user_forced_noautojump_3f() then
    _112_ = opts.labels
  elseif sublist["autojump?"] then
    _112_ = opts.safe_labels
  else
    _112_ = opts.labels
  end
  sublist["label-set"] = _112_
  return nil
end
local function set_sublist_attributes(targets, _114_)
  local _arg_115_ = _114_
  local force_noautojump_3f = _arg_115_["force-noautojump?"]
  for _, sublist in pairs(targets.sublists) do
    set_autojump(sublist, force_noautojump_3f)
    attach_label_set(sublist)
  end
  return nil
end
local function set_labels(targets)
  for _, sublist in pairs(targets.sublists) do
    if (#sublist > 1) then
      local _local_116_ = sublist
      local autojump_3f = _local_116_["autojump?"]
      local label_set = _local_116_["label-set"]
      for i, target in ipairs(sublist) do
        local i_2a
        if autojump_3f then
          i_2a = dec(i)
        else
          i_2a = i
        end
        if (i_2a > 0) then
          local _119_
          do
            local _118_ = (i_2a % #label_set)
            if (_118_ == 0) then
              _119_ = label_set[#label_set]
            elseif (nil ~= _118_) then
              local n = _118_
              _119_ = label_set[n]
            else
              _119_ = nil
            end
          end
          target["label"] = _119_
        else
        end
      end
    else
    end
  end
  return nil
end
local function set_label_states(sublist, _125_)
  local _arg_126_ = _125_
  local group_offset = _arg_126_["group-offset"]
  local _7clabel_set_7c = #sublist["label-set"]
  local offset = (group_offset * _7clabel_set_7c)
  local primary_start
  local function _127_()
    if sublist["autojump?"] then
      return 2
    else
      return 1
    end
  end
  primary_start = (offset + _127_())
  local primary_end = (primary_start + dec(_7clabel_set_7c))
  local secondary_start = inc(primary_end)
  local secondary_end = (primary_end + _7clabel_set_7c)
  for i, target in ipairs(sublist) do
    if target.label then
      local _128_
      if (function(_129_,_130_,_131_) return (_129_ <= _130_) and (_130_ <= _131_) end)(primary_start,i,primary_end) then
        _128_ = "active-primary"
      elseif (function(_132_,_133_,_134_) return (_132_ <= _133_) and (_133_ <= _134_) end)(secondary_start,i,secondary_end) then
        _128_ = "active-secondary"
      elseif (i > secondary_end) then
        _128_ = "inactive"
      else
        _128_ = nil
      end
      target["label-state"] = _128_
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
  local _let_137_ = target
  local _let_138_ = _let_137_["pair"]
  local ch1 = _let_138_[1]
  local ch2 = _let_138_[2]
  local edge_pos_3f = _let_137_["edge-pos?"]
  local label = _let_137_["label"]
  local offset
  local function _139_()
    if edge_pos_3f then
      return 0
    else
      return ch2:len()
    end
  end
  offset = (ch1:len() + _139_())
  local virttext
  do
    local _140_ = target["label-state"]
    if (_140_ == "active-primary") then
      virttext = {{label, hl.group["label-primary"]}}
    elseif (_140_ == "active-secondary") then
      virttext = {{label, hl.group["label-secondary"]}}
    elseif (_140_ == "inactive") then
      if not opts.highlight_unlabeled then
        virttext = {{" ", hl.group["label-secondary"]}}
      else
        virttext = nil
      end
    else
      virttext = nil
    end
  end
  local _143_
  if virttext then
    _143_ = {offset, virttext}
  else
    _143_ = nil
  end
  target["beacon"] = _143_
  return nil
end
local function set_beacon_to_match_hl(target)
  local _let_145_ = target
  local _let_146_ = _let_145_["pair"]
  local ch1 = _let_146_[1]
  local ch2 = _let_146_[2]
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
    local _let_147_ = target
    local _let_148_ = _let_147_["pos"]
    local lnum = _let_148_[1]
    local col = _let_148_[2]
    local _let_149_ = _let_147_["pair"]
    local ch1 = _let_149_[1]
    local _ = _let_149_[2]
    local _let_150_ = _let_147_["wininfo"]
    local bufnr = _let_150_["bufnr"]
    local winid = _let_150_["winid"]
    if (not target.beacon or (opts.highlight_unlabeled and (target.beacon[2][1][2] == hl.group.match))) then
      local keys = {(bufnr .. " " .. winid .. " " .. lnum .. " " .. col), (bufnr .. " " .. winid .. " " .. lnum .. " " .. (col + ch1:len()))}
      for _0, k in ipairs(keys) do
        do
          local _151_ = label_positions[k]
          if (nil ~= _151_) then
            local other = _151_
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
        local _153_ = unlabeled_match_positions[k]
        if (nil ~= _153_) then
          local other = _153_
          target.beacon = nil
          set_beacon_to_match_hl(other)
        elseif true then
          local _0 = _153_
          local _154_ = label_positions[k]
          if (nil ~= _154_) then
            local other = _154_
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
local function set_beacons(target_list, _158_)
  local _arg_159_ = _158_
  local force_no_labels_3f = _arg_159_["force-no-labels?"]
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
    local _162_ = target.beacon
    if ((_G.type(_162_) == "table") and (nil ~= (_162_)[1]) and (nil ~= (_162_)[2])) then
      local offset = (_162_)[1]
      local virttext = (_162_)[2]
      local _let_163_ = map(dec, target.pos)
      local lnum = _let_163_[1]
      local col = _let_163_[2]
      api.nvim_buf_set_extmark(target.wininfo.bufnr, hl.ns, lnum, (col + offset), {virt_text = virttext, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.label})
    else
    end
  end
  return nil
end
local state = {["repeat"] = {in1 = nil, in2 = nil}, ["dot-repeat"] = {in1 = nil, in2 = nil, ["target-idx"] = nil, ["backward?"] = nil, ["inclusive-op?"] = nil, ["offset?"] = nil}}
local function leap(_165_)
  local _arg_166_ = _165_
  local dot_repeat_3f = _arg_166_["dot-repeat?"]
  local target_windows = _arg_166_["target-windows"]
  local kwargs = _arg_166_
  local function _168_()
    if dot_repeat_3f then
      return state["dot-repeat"]
    else
      return kwargs
    end
  end
  local _let_167_ = _168_()
  local backward_3f = _let_167_["backward?"]
  local inclusive_op_3f = _let_167_["inclusive-op?"]
  local offset = _let_167_["offset"]
  local mode = api.nvim_get_mode().mode
  local _3ftarget_windows
  do
    local _169_
    do
      local _170_ = target_windows
      if (_G.type(_170_) == "table") then
        local t = _170_
        _169_ = t
      elseif (_170_ == true) then
        _169_ = get_other_windows_on_tabpage(mode)
      else
        _169_ = nil
      end
    end
    if (_169_ ~= nil) then
      local function _172_(_241)
        return (vim.fn.getwininfo(_241))[1]
      end
      _3ftarget_windows = map(_172_, _169_)
    else
      _3ftarget_windows = _169_
    end
  end
  local source_window = vim.fn.getwininfo(vim.fn.win_getid())[1]
  local directional_3f = not _3ftarget_windows
  local op_mode_3f = mode:match("o")
  local change_op_3f = (op_mode_3f and (vim.v.operator == "c"))
  local dot_repeatable_op_3f = (op_mode_3f and directional_3f and (vim.v.operator ~= "y"))
  local force_noautojump_3f = (op_mode_3f or not directional_3f)
  local spec_keys
  local function _174_(_, k)
    return replace_keycodes(opts.special_keys[k])
  end
  spec_keys = setmetatable({}, {__index = _174_})
  local function prepare_pattern(in1, _3fin2)
    local function _175_()
      if opts.case_sensitive then
        return "\\C"
      else
        return "\\c"
      end
    end
    local function _177_()
      local _176_ = _3fin2
      if (_176_ == spec_keys.eol) then
        return ("\\(" .. _3fin2 .. "\\|\\r\\?\\n\\)")
      elseif true then
        local _ = _176_
        return (_3fin2 or "\\_.")
      else
        return nil
      end
    end
    return ("\\V" .. _175_() .. in1:gsub("\\", "\\\\") .. _177_())
  end
  local function get_target_with_active_primary_label(sublist, input)
    local res = nil
    for idx, _179_ in ipairs(sublist) do
      local _each_180_ = _179_
      local label = _each_180_["label"]
      local label_state = _each_180_["label-state"]
      local target = _each_180_
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
    local function _185_(target)
      jump_to_21_2a(target.pos, {winid = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["backward?"] = backward_3f, ["inclusive-op?"] = inclusive_op_3f})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _185_
  end
  local function traverse(targets, idx, _186_)
    local _arg_187_ = _186_
    local force_no_labels_3f = _arg_187_["force-no-labels?"]
    if force_no_labels_3f then
      inactivate_labels(targets)
    else
    end
    set_beacons(targets, {["force-no-labels?"] = force_no_labels_3f})
    do
      hl:cleanup(_3ftarget_windows)
      hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
      do
        light_up_beacons(targets, inc(idx))
      end
      highlight_cursor()
      vim.cmd("redraw")
    end
    local _189_
    local function _190_()
      if dot_repeatable_op_3f then
        set_dot_repeat()
      else
      end
      do
      end
      local function _193_()
        if _3ftarget_windows then
          local _192_ = _3ftarget_windows
          table.insert(_192_, source_window)
          return _192_
        else
          return nil
        end
      end
      hl:cleanup(_193_())
      exec_user_autocmds("LeapLeave")
      return nil
    end
    _189_ = (get_input_by_keymap() or _190_())
    if (nil ~= _189_) then
      local input = _189_
      if ((input == spec_keys.next_match) or (input == spec_keys.prev_match)) then
        local new_idx
        do
          local _194_ = input
          if (_194_ == spec_keys.next_match) then
            new_idx = min(inc(idx), #targets)
          elseif (_194_ == spec_keys.prev_match) then
            new_idx = max(dec(idx), 1)
          else
            new_idx = nil
          end
        end
        update_state({["repeat"] = {in1 = state["repeat"].in1, in2 = targets[new_idx].pair[2]}})
        jump_to_21(targets[new_idx])
        return traverse(targets, new_idx, {["force-no-labels?"] = force_no_labels_3f})
      else
        local _196_ = get_target_with_active_primary_label(targets, input)
        if ((_G.type(_196_) == "table") and true and (nil ~= (_196_)[2])) then
          local _ = (_196_)[1]
          local target = (_196_)[2]
          if dot_repeatable_op_3f then
            set_dot_repeat()
          else
          end
          do
            jump_to_21(target)
          end
          local function _199_()
            if _3ftarget_windows then
              local _198_ = _3ftarget_windows
              table.insert(_198_, source_window)
              return _198_
            else
              return nil
            end
          end
          hl:cleanup(_199_())
          exec_user_autocmds("LeapLeave")
          return nil
        elseif true then
          local _ = _196_
          if dot_repeatable_op_3f then
            set_dot_repeat()
          else
          end
          do
            vim.fn.feedkeys(input, "i")
          end
          local function _202_()
            if _3ftarget_windows then
              local _201_ = _3ftarget_windows
              table.insert(_201_, source_window)
              return _201_
            else
              return nil
            end
          end
          hl:cleanup(_202_())
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
      hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
      do
        echo("")
      end
      highlight_cursor()
      vim.cmd("redraw")
    end
    local _206_
    local function _207_()
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      do
      end
      local function _210_()
        if _3ftarget_windows then
          local _209_ = _3ftarget_windows
          table.insert(_209_, source_window)
          return _209_
        else
          return nil
        end
      end
      hl:cleanup(_210_())
      exec_user_autocmds("LeapLeave")
      return nil
    end
    _206_ = (get_input_by_keymap() or _207_())
    if (_206_ == spec_keys.repeat_search) then
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
        local function _213_()
          if _3ftarget_windows then
            local _212_ = _3ftarget_windows
            table.insert(_212_, source_window)
            return _212_
          else
            return nil
          end
        end
        hl:cleanup(_213_())
        exec_user_autocmds("LeapLeave")
        return nil
      end
    elseif (nil ~= _206_) then
      local in1 = _206_
      return in1
    else
      return nil
    end
  end
  local function get_second_pattern_input(targets)
    do
      local _216_ = targets
      set_initial_label_states(_216_)
      set_beacons(_216_, {})
    end
    do
      hl:cleanup(_3ftarget_windows)
      hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
      do
        light_up_beacons(targets)
      end
      highlight_cursor()
      vim.cmd("redraw")
    end
    local function _217_()
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      do
      end
      local function _220_()
        if _3ftarget_windows then
          local _219_ = _3ftarget_windows
          table.insert(_219_, source_window)
          return _219_
        else
          return nil
        end
      end
      hl:cleanup(_220_())
      exec_user_autocmds("LeapLeave")
      return nil
    end
    return (get_input_by_keymap() or _217_())
  end
  local function get_full_pattern_input()
    local _221_, _222_ = get_first_pattern_input()
    if ((nil ~= _221_) and (nil ~= _222_)) then
      local in1 = _221_
      local in2 = _222_
      return in1, in2
    elseif ((nil ~= _221_) and (_222_ == nil)) then
      local in1 = _221_
      local _223_ = get_input_by_keymap()
      if (nil ~= _223_) then
        local in2 = _223_
        return in1, in2
      elseif true then
        local _ = _223_
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
        end
        local function _226_()
          if _3ftarget_windows then
            local _225_ = _3ftarget_windows
            table.insert(_225_, source_window)
            return _225_
          else
            return nil
          end
        end
        hl:cleanup(_226_())
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
        local _229_ = sublist
        set_label_states(_229_, {["group-offset"] = group_offset})
        set_beacons(_229_, {})
      end
      do
        hl:cleanup(_3ftarget_windows)
        hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
        do
          local function _230_()
            if sublist["autojump?"] then
              return 2
            else
              return nil
            end
          end
          light_up_beacons(sublist, _230_())
        end
        highlight_cursor()
        vim.cmd("redraw")
      end
      local _231_
      local function _232_()
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
        end
        local function _235_()
          if _3ftarget_windows then
            local _234_ = _3ftarget_windows
            table.insert(_234_, source_window)
            return _234_
          else
            return nil
          end
        end
        hl:cleanup(_235_())
        exec_user_autocmds("LeapLeave")
        return nil
      end
      _231_ = (get_input() or _232_())
      if (nil ~= _231_) then
        local input = _231_
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
  local function _239_(...)
    local _240_, _241_ = ...
    if ((nil ~= _240_) and true) then
      local in1 = _240_
      local _3fin2 = _241_
      local function _242_(...)
        local _243_ = ...
        if (nil ~= _243_) then
          local targets = _243_
          local function _244_(...)
            local _245_ = ...
            if (nil ~= _245_) then
              local in2 = _245_
              if dot_repeat_3f then
                local _246_ = targets[state["dot-repeat"]["target-idx"]]
                if (nil ~= _246_) then
                  local target = _246_
                  if dot_repeatable_op_3f then
                    set_dot_repeat()
                  else
                  end
                  do
                    jump_to_21(target)
                  end
                  local function _249_(...)
                    if _3ftarget_windows then
                      local _248_ = _3ftarget_windows
                      table.insert(_248_, source_window)
                      return _248_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_249_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                elseif true then
                  local _ = _246_
                  if change_op_3f then
                    handle_interrupted_change_op_21()
                  else
                  end
                  do
                  end
                  local function _252_(...)
                    if _3ftarget_windows then
                      local _251_ = _3ftarget_windows
                      table.insert(_251_, source_window)
                      return _251_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_252_(...))
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
                  local function _256_(...)
                    if _3ftarget_windows then
                      local _255_ = _3ftarget_windows
                      table.insert(_255_, source_window)
                      return _255_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_256_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                else
                  return traverse(targets, 1, {["force-no-labels?"] = true})
                end
              else
                update_state({["repeat"] = {in1 = in1, in2 = in2}})
                local update_dot_repeat_state
                local function _258_(_241)
                  return update_state({["dot-repeat"] = {in1 = in1, in2 = in2, ["target-idx"] = _241}})
                end
                update_dot_repeat_state = _258_
                local _259_
                local function _260_(...)
                  if change_op_3f then
                    handle_interrupted_change_op_21()
                  else
                  end
                  do
                    echo_not_found((in1 .. in2))
                  end
                  local function _263_(...)
                    if _3ftarget_windows then
                      local _262_ = _3ftarget_windows
                      table.insert(_262_, source_window)
                      return _262_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_263_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                end
                _259_ = (targets.sublists[in2] or _260_(...))
                if ((_G.type(_259_) == "table") and (nil ~= (_259_)[1]) and ((_259_)[2] == nil)) then
                  local only = (_259_)[1]
                  if dot_repeatable_op_3f then
                    set_dot_repeat()
                  else
                  end
                  do
                    update_dot_repeat_state(1)
                    jump_to_21(only)
                  end
                  local function _266_(...)
                    if _3ftarget_windows then
                      local _265_ = _3ftarget_windows
                      table.insert(_265_, source_window)
                      return _265_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_266_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                elseif (nil ~= _259_) then
                  local sublist = _259_
                  if sublist["autojump?"] then
                    jump_to_21(sublist[1])
                  else
                  end
                  local _268_ = post_pattern_input_loop(sublist)
                  if (nil ~= _268_) then
                    local in_final = _268_
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
                        local function _272_(...)
                          if _3ftarget_windows then
                            local _271_ = _3ftarget_windows
                            table.insert(_271_, source_window)
                            return _271_
                          else
                            return nil
                          end
                        end
                        hl:cleanup(_272_(...))
                        exec_user_autocmds("LeapLeave")
                        return nil
                      else
                        return traverse(sublist, new_idx, {["force-no-labels?"] = not sublist["autojump?"]})
                      end
                    else
                      local _274_ = get_target_with_active_primary_label(sublist, in_final)
                      if ((_G.type(_274_) == "table") and (nil ~= (_274_)[1]) and (nil ~= (_274_)[2])) then
                        local idx = (_274_)[1]
                        local target = (_274_)[2]
                        if dot_repeatable_op_3f then
                          set_dot_repeat()
                        else
                        end
                        do
                          update_dot_repeat_state(idx)
                          jump_to_21(target)
                        end
                        local function _277_(...)
                          if _3ftarget_windows then
                            local _276_ = _3ftarget_windows
                            table.insert(_276_, source_window)
                            return _276_
                          else
                            return nil
                          end
                        end
                        hl:cleanup(_277_(...))
                        exec_user_autocmds("LeapLeave")
                        return nil
                      elseif true then
                        local _ = _274_
                        if sublist["autojump?"] then
                          if dot_repeatable_op_3f then
                            set_dot_repeat()
                          else
                          end
                          do
                            vim.fn.feedkeys(in_final, "i")
                          end
                          local function _280_(...)
                            if _3ftarget_windows then
                              local _279_ = _3ftarget_windows
                              table.insert(_279_, source_window)
                              return _279_
                            else
                              return nil
                            end
                          end
                          hl:cleanup(_280_(...))
                          exec_user_autocmds("LeapLeave")
                          return nil
                        else
                          if change_op_3f then
                            handle_interrupted_change_op_21()
                          else
                          end
                          do
                          end
                          local function _283_(...)
                            if _3ftarget_windows then
                              local _282_ = _3ftarget_windows
                              table.insert(_282_, source_window)
                              return _282_
                            else
                              return nil
                            end
                          end
                          hl:cleanup(_283_(...))
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
              local __60_auto = _245_
              return ...
            else
              return nil
            end
          end
          local function _291_(...)
            do
              local _292_ = targets
              populate_sublists(_292_)
              set_sublist_attributes(_292_, {["force-noautojump?"] = force_noautojump_3f})
              set_labels(_292_)
            end
            return (_3fin2 or get_second_pattern_input(targets))
          end
          return _244_(_291_(...))
        elseif true then
          local __60_auto = _243_
          return ...
        else
          return nil
        end
      end
      local function _294_(...)
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
          echo_not_found((in1 .. (_3fin2 or "")))
        end
        local function _297_(...)
          if _3ftarget_windows then
            local _296_ = _3ftarget_windows
            table.insert(_296_, source_window)
            return _296_
          else
            return nil
          end
        end
        hl:cleanup(_297_(...))
        exec_user_autocmds("LeapLeave")
        return nil
      end
      return _242_((get_targets(prepare_pattern(in1, _3fin2), {["backward?"] = backward_3f, ["target-windows"] = _3ftarget_windows}) or _294_(...)))
    elseif true then
      local __60_auto = _240_
      return ...
    else
      return nil
    end
  end
  local function _299_()
    if dot_repeat_3f then
      return state["dot-repeat"].in1, state["dot-repeat"].in2
    elseif opts.highlight_ahead_of_time then
      return get_first_pattern_input()
    else
      return get_full_pattern_input()
    end
  end
  return _239_(_299_())
end
local temporary_editor_opts = {["vim.bo.modeline"] = false}
local saved_editor_opts = {}
local function save_editor_opts()
  for opt, _ in pairs(temporary_editor_opts) do
    local _let_300_ = vim.split(opt, ".", true)
    local _0 = _let_300_[1]
    local scope = _let_300_[2]
    local name = _let_300_[3]
    saved_editor_opts[opt] = _G.vim[scope][name]
  end
  return nil
end
local function set_editor_opts(opts0)
  for opt, val in pairs(opts0) do
    local _let_301_ = vim.split(opt, ".", true)
    local _ = _let_301_[1]
    local scope = _let_301_[2]
    local name = _let_301_[3]
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
local function _302_()
  return hl["init-highlight"](hl)
end
api.nvim_create_autocmd("ColorScheme", {callback = _302_, group = "LeapDefault"})
local function _303_()
  save_editor_opts()
  return set_temporary_editor_opts()
end
api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _303_, group = "LeapDefault"})
api.nvim_create_autocmd("User", {pattern = "LeapLeave", callback = restore_editor_opts, group = "LeapDefault"})
return {state = state, leap = leap}
