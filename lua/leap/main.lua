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
  local function _24_()
    if backward_3f then
      return "bwd"
    else
      return "fwd"
    end
  end
  new_line = push_cursor_21(_24_())
  if (new_line == 0) then
    return "dead-end"
  else
    return nil
  end
end
local function to_closed_fold_edge_21(backward_3f)
  local edge_line
  local _26_
  if backward_3f then
    _26_ = vim.fn.foldclosed
  else
    _26_ = vim.fn.foldclosedend
  end
  edge_line = _26_(vim.fn.line("."))
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
  local _let_29_ = {vim.fn.line("."), vim.fn.virtcol(".")}
  local line = _let_29_[1]
  local virtcol = _let_29_[2]
  local from_pos = _let_29_
  local left_off_3f = (virtcol < left_bound)
  local right_off_3f = (virtcol > right_bound)
  local _30_
  if (left_off_3f and backward_3f) then
    if (dec(line) >= stopline) then
      _30_ = {dec(line), right_bound}
    else
      _30_ = nil
    end
  elseif (left_off_3f and not backward_3f) then
    _30_ = {line, left_bound}
  elseif (right_off_3f and backward_3f) then
    _30_ = {line, right_bound}
  elseif (right_off_3f and not backward_3f) then
    if (inc(line) <= stopline) then
      _30_ = {inc(line), left_bound}
    else
      _30_ = nil
    end
  else
    _30_ = nil
  end
  if (nil ~= _30_) then
    local to_pos = _30_
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
local function get_match_positions(pattern, _37_, _39_)
  local _arg_38_ = _37_
  local left_bound = _arg_38_[1]
  local right_bound = _arg_38_[2]
  local _arg_40_ = _39_
  local backward_3f = _arg_40_["backward?"]
  local whole_window_3f = _arg_40_["whole-window?"]
  local skip_curpos_3f = _arg_40_["skip-curpos?"]
  local skip_orig_curpos_3f = skip_curpos_3f
  local _let_41_ = get_cursor_pos()
  local orig_curline = _let_41_[1]
  local orig_curcol = _let_41_[2]
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
  local function _43_()
    vim.fn.winrestview(saved_view)
    vim.o.cpo = saved_cpo
    return nil
  end
  cleanup = _43_
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
    local function _45_()
      if backward_3f then
        return "b"
      else
        return ""
      end
    end
    local function _46_()
      if match_at_curpos_3f0 then
        return "c"
      else
        return ""
      end
    end
    flags = (_45_() .. _46_())
    moved_to_topleft_3f = false
    local _47_ = vim.fn.searchpos(pattern, flags, stopline)
    if ((_G.type(_47_) == "table") and (nil ~= (_47_)[1]) and (nil ~= (_47_)[2])) then
      local line = (_47_)[1]
      local col = (_47_)[2]
      local pos = _47_
      if (line == 0) then
        return cleanup()
      elseif ((line == orig_curline) and (col == orig_curcol) and skip_orig_curpos_3f) then
        local _48_ = skip_one_21()
        if (_48_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _48_
          return iter(true)
        else
          return nil
        end
      elseif ((col < left_bound) and (col > right_bound) and not vim.wo.wrap) then
        local _50_ = to_next_in_window_pos_21(backward_3f, left_bound, right_bound, stopline)
        if (_50_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _50_
          return iter(true)
        else
          return nil
        end
      elseif (vim.fn.foldclosed(line) ~= -1) then
        to_closed_fold_edge_21(backward_3f)
        local _52_ = skip_one_21(backward_3f)
        if (_52_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _52_
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
local function get_targets_2a(pattern, _56_)
  local _arg_57_ = _56_
  local backward_3f = _arg_57_["backward?"]
  local wininfo = _arg_57_["wininfo"]
  local targets = _arg_57_["targets"]
  local source_winid = _arg_57_["source-winid"]
  local targets0 = (targets or {})
  local _let_58_ = get_horizontal_bounds()
  local _ = _let_58_[1]
  local right_bound = _let_58_[2]
  local bounds = _let_58_
  local whole_window_3f = wininfo
  local wininfo0 = (wininfo or vim.fn.getwininfo(vim.fn.win_getid())[1])
  local skip_curpos_3f = (whole_window_3f and (vim.fn.win_getid() == source_winid))
  local match_positions = get_match_positions(pattern, bounds, {["backward?"] = backward_3f, ["skip-curpos?"] = skip_curpos_3f, ["whole-window?"] = whole_window_3f})
  local prev_match = {}
  for _59_ in match_positions do
    local _each_60_ = _59_
    local line = _each_60_[1]
    local col = _each_60_[2]
    local pos = _each_60_
    local ch1 = util["get-char-at"](pos, {})
    local ch2, eol_3f = nil, nil
    do
      local _61_ = util["get-char-at"](pos, {["char-offset"] = 1})
      if (nil ~= _61_) then
        local char = _61_
        ch2, eol_3f = char
      elseif true then
        local _0 = _61_
        ch2, eol_3f = replace_keycodes(opts.special_keys.eol), true
      else
        ch2, eol_3f = nil
      end
    end
    local same_char_triplet_3f
    local _63_
    if backward_3f then
      _63_ = dec
    else
      _63_ = inc
    end
    same_char_triplet_3f = ((ch2 == prev_match.ch2) and (line == prev_match.line) and (col == _63_(prev_match.col)))
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
local function distance(_67_, _69_)
  local _arg_68_ = _67_
  local l1 = _arg_68_[1]
  local c1 = _arg_68_[2]
  local _arg_70_ = _69_
  local l2 = _arg_70_[1]
  local c2 = _arg_70_[2]
  local editor_grid_aspect_ratio = 0.3
  local _let_71_ = {abs((c1 - c2)), abs((l1 - l2))}
  local dx = _let_71_[1]
  local dy = _let_71_[2]
  local dx0 = (dx * editor_grid_aspect_ratio)
  return pow((pow(dx0, 2) + pow(dy, 2)), 0.5)
end
local function get_targets(pattern, _72_)
  local _arg_73_ = _72_
  local backward_3f = _arg_73_["backward?"]
  local target_windows = _arg_73_["target-windows"]
  if not target_windows then
    return get_targets_2a(pattern, {["backward?"] = backward_3f})
  else
    local targets = {}
    local cursor_positions = {}
    local source_winid = vim.fn.win_getid()
    local curr_win_only_3f
    do
      local _74_ = target_windows
      if ((_G.type(_74_) == "table") and ((_G.type((_74_)[1]) == "table") and (((_74_)[1]).winid == source_winid)) and ((_74_)[2] == nil)) then
        curr_win_only_3f = true
      else
        curr_win_only_3f = nil
      end
    end
    local cross_win_3f = not curr_win_only_3f
    for _, _76_ in ipairs(target_windows) do
      local _each_77_ = _76_
      local winid = _each_77_["winid"]
      local wininfo = _each_77_
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
        for winid, _80_ in pairs(cursor_positions) do
          local _each_81_ = _80_
          local line = _each_81_[1]
          local col = _each_81_[2]
          local _82_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_82_) == "table") and ((_82_).col == col) and (nil ~= (_82_).row)) then
            local row = (_82_).row
            cursor_positions[winid] = {row, col}
          else
          end
        end
      else
      end
      for _, _85_ in ipairs(targets) do
        local _each_86_ = _85_
        local _each_87_ = _each_86_["pos"]
        local line = _each_87_[1]
        local col = _each_87_[2]
        local _each_88_ = _each_86_["wininfo"]
        local winid = _each_88_["winid"]
        local t = _each_86_
        if by_screen_pos_3f then
          local _89_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_89_) == "table") and ((_89_).col == col) and (nil ~= (_89_).row)) then
            local row = (_89_).row
            t["screenpos"] = {row, col}
          else
          end
        else
        end
        t["rank"] = distance((t.screenpos or t.pos), cursor_positions[winid])
      end
      local function _92_(_241, _242)
        return ((_241).rank < (_242).rank)
      end
      table.sort(targets, _92_)
      return targets
    else
      return nil
    end
  end
end
local function populate_sublists(targets)
  targets["sublists"] = {}
  if not opts.case_sensitive then
    local function _95_(t, k)
      return rawget(t, k:lower())
    end
    local function _96_(t, k, v)
      return rawset(t, k:lower(), v)
    end
    setmetatable(targets.sublists, {__index = _95_, __newindex = _96_})
  else
  end
  for _, _98_ in ipairs(targets) do
    local _each_99_ = _98_
    local _each_100_ = _each_99_["pair"]
    local _0 = _each_100_[1]
    local ch2 = _each_100_[2]
    local target = _each_99_
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
  local _102_
  if user_forced_autojump_3f() then
    _102_ = opts.safe_labels
  elseif user_forced_noautojump_3f() then
    _102_ = opts.labels
  elseif sublist["autojump?"] then
    _102_ = opts.safe_labels
  else
    _102_ = opts.labels
  end
  sublist["label-set"] = _102_
  return nil
end
local function set_sublist_attributes(targets, _104_)
  local _arg_105_ = _104_
  local force_noautojump_3f = _arg_105_["force-noautojump?"]
  for _, sublist in pairs(targets.sublists) do
    set_autojump(sublist, force_noautojump_3f)
    attach_label_set(sublist)
  end
  return nil
end
local function set_labels(targets)
  for _, sublist in pairs(targets.sublists) do
    if (#sublist > 1) then
      local _local_106_ = sublist
      local autojump_3f = _local_106_["autojump?"]
      local label_set = _local_106_["label-set"]
      for i, target in ipairs(sublist) do
        local i_2a
        if autojump_3f then
          i_2a = dec(i)
        else
          i_2a = i
        end
        if (i_2a > 0) then
          local _109_
          do
            local _108_ = (i_2a % #label_set)
            if (_108_ == 0) then
              _109_ = label_set[#label_set]
            elseif (nil ~= _108_) then
              local n = _108_
              _109_ = label_set[n]
            else
              _109_ = nil
            end
          end
          target["label"] = _109_
        else
        end
      end
    else
    end
  end
  return nil
end
local function set_label_states(sublist, _115_)
  local _arg_116_ = _115_
  local group_offset = _arg_116_["group-offset"]
  local _7clabel_set_7c = #sublist["label-set"]
  local offset = (group_offset * _7clabel_set_7c)
  local primary_start
  local function _117_()
    if sublist["autojump?"] then
      return 2
    else
      return 1
    end
  end
  primary_start = (offset + _117_())
  local primary_end = (primary_start + dec(_7clabel_set_7c))
  local secondary_start = inc(primary_end)
  local secondary_end = (primary_end + _7clabel_set_7c)
  for i, target in ipairs(sublist) do
    if target.label then
      local _118_
      if (function(_119_,_120_,_121_) return (_119_ <= _120_) and (_120_ <= _121_) end)(primary_start,i,primary_end) then
        _118_ = "active-primary"
      elseif (function(_122_,_123_,_124_) return (_122_ <= _123_) and (_123_ <= _124_) end)(secondary_start,i,secondary_end) then
        _118_ = "active-secondary"
      elseif (i > secondary_end) then
        _118_ = "inactive"
      else
        _118_ = nil
      end
      target["label-state"] = _118_
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
  local _let_127_ = target
  local _let_128_ = _let_127_["pair"]
  local ch1 = _let_128_[1]
  local ch2 = _let_128_[2]
  local edge_pos_3f = _let_127_["edge-pos?"]
  local label = _let_127_["label"]
  local offset
  local function _129_()
    if edge_pos_3f then
      return 0
    else
      return ch2:len()
    end
  end
  offset = (ch1:len() + _129_())
  local virttext
  do
    local _130_ = target["label-state"]
    if (_130_ == "active-primary") then
      virttext = {{label, hl.group["label-primary"]}}
    elseif (_130_ == "active-secondary") then
      virttext = {{label, hl.group["label-secondary"]}}
    elseif (_130_ == "inactive") then
      if not opts.highlight_unlabeled then
        virttext = {{" ", hl.group["label-secondary"]}}
      else
        virttext = nil
      end
    else
      virttext = nil
    end
  end
  local _133_
  if virttext then
    _133_ = {offset, virttext}
  else
    _133_ = nil
  end
  target["beacon"] = _133_
  return nil
end
local function set_beacon_to_match_hl(target)
  local _let_135_ = target
  local _let_136_ = _let_135_["pair"]
  local ch1 = _let_136_[1]
  local ch2 = _let_136_[2]
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
    local _let_137_ = target
    local _let_138_ = _let_137_["pos"]
    local lnum = _let_138_[1]
    local col = _let_138_[2]
    local _let_139_ = _let_137_["pair"]
    local ch1 = _let_139_[1]
    local _ = _let_139_[2]
    local _let_140_ = _let_137_["wininfo"]
    local bufnr = _let_140_["bufnr"]
    local winid = _let_140_["winid"]
    if (not target.beacon or (opts.highlight_unlabeled and (target.beacon[2][1][2] == hl.group.match))) then
      local keys = {(bufnr .. " " .. winid .. " " .. lnum .. " " .. col), (bufnr .. " " .. winid .. " " .. lnum .. " " .. (col + ch1:len()))}
      for _0, k in ipairs(keys) do
        do
          local _141_ = label_positions[k]
          if (nil ~= _141_) then
            local other = _141_
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
        local _143_ = unlabeled_match_positions[k]
        if (nil ~= _143_) then
          local other = _143_
          target.beacon = nil
          set_beacon_to_match_hl(other)
        elseif true then
          local _0 = _143_
          local _144_ = label_positions[k]
          if (nil ~= _144_) then
            local other = _144_
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
local function set_beacons(target_list, _148_)
  local _arg_149_ = _148_
  local force_no_labels_3f = _arg_149_["force-no-labels?"]
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
    local _152_ = target.beacon
    if ((_G.type(_152_) == "table") and (nil ~= (_152_)[1]) and (nil ~= (_152_)[2])) then
      local offset = (_152_)[1]
      local virttext = (_152_)[2]
      local _let_153_ = map(dec, target.pos)
      local lnum = _let_153_[1]
      local col = _let_153_[2]
      api.nvim_buf_set_extmark(target.wininfo.bufnr, hl.ns, lnum, (col + offset), {virt_text = virttext, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.label})
    else
    end
  end
  return nil
end
local state = {["repeat"] = {in1 = nil, in2 = nil}, ["dot-repeat"] = {in1 = nil, in2 = nil, ["target-idx"] = nil, ["backward?"] = nil, ["inclusive-op?"] = nil, ["offset?"] = nil}}
local function leap(_155_)
  local _arg_156_ = _155_
  local dot_repeat_3f = _arg_156_["dot-repeat?"]
  local target_windows = _arg_156_["target-windows"]
  local kwargs = _arg_156_
  local function _158_()
    if dot_repeat_3f then
      return state["dot-repeat"]
    else
      return kwargs
    end
  end
  local _let_157_ = _158_()
  local backward_3f = _let_157_["backward?"]
  local inclusive_op_3f = _let_157_["inclusive-op?"]
  local offset = _let_157_["offset"]
  local mode = api.nvim_get_mode().mode
  local _3ftarget_windows
  do
    local _159_
    do
      local _160_ = target_windows
      if (_G.type(_160_) == "table") then
        local t = _160_
        _159_ = t
      elseif (_160_ == true) then
        _159_ = util.get_enterable_windows()
      else
        _159_ = nil
      end
    end
    if (_159_ ~= nil) then
      local function _162_(_241)
        return (vim.fn.getwininfo(_241))[1]
      end
      _3ftarget_windows = map(_162_, _159_)
    else
      _3ftarget_windows = _159_
    end
  end
  local source_window = vim.fn.getwininfo(vim.fn.win_getid())[1]
  local directional_3f = not _3ftarget_windows
  local op_mode_3f = mode:match("o")
  local change_op_3f = (op_mode_3f and (vim.v.operator == "c"))
  local dot_repeatable_op_3f = (op_mode_3f and directional_3f and (vim.v.operator ~= "y"))
  local force_noautojump_3f = (op_mode_3f or not directional_3f)
  local spec_keys
  local function _164_(_, k)
    return replace_keycodes(opts.special_keys[k])
  end
  spec_keys = setmetatable({}, {__index = _164_})
  local function prepare_pattern(in1, _3fin2)
    local function _165_()
      if opts.case_sensitive then
        return "\\C"
      else
        return "\\c"
      end
    end
    local function _167_()
      local _166_ = _3fin2
      if (_166_ == spec_keys.eol) then
        return ("\\(" .. _3fin2 .. "\\|\\r\\?\\n\\)")
      elseif true then
        local _ = _166_
        return (_3fin2 or "\\_.")
      else
        return nil
      end
    end
    return ("\\V" .. _165_() .. in1:gsub("\\", "\\\\") .. _167_())
  end
  local function get_target_with_active_primary_label(sublist, input)
    local res = nil
    for idx, _169_ in ipairs(sublist) do
      local _each_170_ = _169_
      local label = _each_170_["label"]
      local label_state = _each_170_["label-state"]
      local target = _each_170_
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
    local function _175_(target)
      jump_to_21_2a(target.pos, {winid = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["backward?"] = backward_3f, ["inclusive-op?"] = inclusive_op_3f})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _175_
  end
  local function traverse(targets, idx, _176_)
    local _arg_177_ = _176_
    local force_no_labels_3f = _arg_177_["force-no-labels?"]
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
    local _179_
    local function _180_()
      if dot_repeatable_op_3f then
        set_dot_repeat()
      else
      end
      do
      end
      local function _183_()
        if _3ftarget_windows then
          local _182_ = _3ftarget_windows
          table.insert(_182_, source_window)
          return _182_
        else
          return nil
        end
      end
      hl:cleanup(_183_())
      exec_user_autocmds("LeapLeave")
      return nil
    end
    _179_ = (get_input() or _180_())
    if (nil ~= _179_) then
      local input = _179_
      if ((input == spec_keys.next_match) or (input == spec_keys.prev_match)) then
        local new_idx
        do
          local _184_ = input
          if (_184_ == spec_keys.next_match) then
            new_idx = min(inc(idx), #targets)
          elseif (_184_ == spec_keys.prev_match) then
            new_idx = max(dec(idx), 1)
          else
            new_idx = nil
          end
        end
        update_state({["repeat"] = {in1 = state["repeat"].in1, in2 = targets[new_idx].pair[2]}})
        jump_to_21(targets[new_idx])
        return traverse(targets, new_idx, {["force-no-labels?"] = force_no_labels_3f})
      else
        local _186_ = get_target_with_active_primary_label(targets, input)
        if ((_G.type(_186_) == "table") and true and (nil ~= (_186_)[2])) then
          local _ = (_186_)[1]
          local target = (_186_)[2]
          if dot_repeatable_op_3f then
            set_dot_repeat()
          else
          end
          do
            jump_to_21(target)
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
        elseif true then
          local _ = _186_
          if dot_repeatable_op_3f then
            set_dot_repeat()
          else
          end
          do
            vim.fn.feedkeys(input, "i")
          end
          local function _192_()
            if _3ftarget_windows then
              local _191_ = _3ftarget_windows
              table.insert(_191_, source_window)
              return _191_
            else
              return nil
            end
          end
          hl:cleanup(_192_())
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
    local _196_
    local function _197_()
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      do
      end
      local function _200_()
        if _3ftarget_windows then
          local _199_ = _3ftarget_windows
          table.insert(_199_, source_window)
          return _199_
        else
          return nil
        end
      end
      hl:cleanup(_200_())
      exec_user_autocmds("LeapLeave")
      return nil
    end
    _196_ = (get_input() or _197_())
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
        local function _203_()
          if _3ftarget_windows then
            local _202_ = _3ftarget_windows
            table.insert(_202_, source_window)
            return _202_
          else
            return nil
          end
        end
        hl:cleanup(_203_())
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
      local _206_ = targets
      set_initial_label_states(_206_)
      set_beacons(_206_, {})
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
    return (get_input() or _207_())
  end
  local function get_full_pattern_input()
    local _211_, _212_ = get_first_pattern_input()
    if ((nil ~= _211_) and (nil ~= _212_)) then
      local in1 = _211_
      local in2 = _212_
      return in1, in2
    elseif ((nil ~= _211_) and (_212_ == nil)) then
      local in1 = _211_
      local _213_ = get_input()
      if (nil ~= _213_) then
        local in2 = _213_
        return in1, in2
      elseif true then
        local _ = _213_
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
        local _219_ = sublist
        set_label_states(_219_, {["group-offset"] = group_offset})
        set_beacons(_219_, {})
      end
      do
        hl:cleanup(_3ftarget_windows)
        hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
        do
          local function _220_()
            if sublist["autojump?"] then
              return 2
            else
              return nil
            end
          end
          light_up_beacons(sublist, _220_())
        end
        highlight_cursor()
        vim.cmd("redraw")
      end
      local _221_
      local function _222_()
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
        end
        local function _225_()
          if _3ftarget_windows then
            local _224_ = _3ftarget_windows
            table.insert(_224_, source_window)
            return _224_
          else
            return nil
          end
        end
        hl:cleanup(_225_())
        exec_user_autocmds("LeapLeave")
        return nil
      end
      _221_ = (get_input() or _222_())
      if (nil ~= _221_) then
        local input = _221_
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
  local function _229_(...)
    local _230_, _231_ = ...
    if ((nil ~= _230_) and true) then
      local in1 = _230_
      local _3fin2 = _231_
      local function _232_(...)
        local _233_ = ...
        if (nil ~= _233_) then
          local targets = _233_
          local function _234_(...)
            local _235_ = ...
            if (nil ~= _235_) then
              local in2 = _235_
              if dot_repeat_3f then
                local _236_ = targets[state["dot-repeat"]["target-idx"]]
                if (nil ~= _236_) then
                  local target = _236_
                  if dot_repeatable_op_3f then
                    set_dot_repeat()
                  else
                  end
                  do
                    jump_to_21(target)
                  end
                  local function _239_(...)
                    if _3ftarget_windows then
                      local _238_ = _3ftarget_windows
                      table.insert(_238_, source_window)
                      return _238_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_239_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                elseif true then
                  local _ = _236_
                  if change_op_3f then
                    handle_interrupted_change_op_21()
                  else
                  end
                  do
                  end
                  local function _242_(...)
                    if _3ftarget_windows then
                      local _241_ = _3ftarget_windows
                      table.insert(_241_, source_window)
                      return _241_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_242_(...))
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
                  local function _246_(...)
                    if _3ftarget_windows then
                      local _245_ = _3ftarget_windows
                      table.insert(_245_, source_window)
                      return _245_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_246_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                else
                  return traverse(targets, 1, {["force-no-labels?"] = true})
                end
              else
                update_state({["repeat"] = {in1 = in1, in2 = in2}})
                local update_dot_repeat_state
                local function _248_(_241)
                  return update_state({["dot-repeat"] = {in1 = in1, in2 = in2, ["target-idx"] = _241}})
                end
                update_dot_repeat_state = _248_
                local _249_
                local function _250_(...)
                  if change_op_3f then
                    handle_interrupted_change_op_21()
                  else
                  end
                  do
                    echo_not_found((in1 .. in2))
                  end
                  local function _253_(...)
                    if _3ftarget_windows then
                      local _252_ = _3ftarget_windows
                      table.insert(_252_, source_window)
                      return _252_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_253_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                end
                _249_ = (targets.sublists[in2] or _250_(...))
                if ((_G.type(_249_) == "table") and (nil ~= (_249_)[1]) and ((_249_)[2] == nil)) then
                  local only = (_249_)[1]
                  if dot_repeatable_op_3f then
                    set_dot_repeat()
                  else
                  end
                  do
                    update_dot_repeat_state(1)
                    jump_to_21(only)
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
                elseif (nil ~= _249_) then
                  local sublist = _249_
                  if sublist["autojump?"] then
                    jump_to_21(sublist[1])
                  else
                  end
                  local _258_ = post_pattern_input_loop(sublist)
                  if (nil ~= _258_) then
                    local in_final = _258_
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
                        local function _262_(...)
                          if _3ftarget_windows then
                            local _261_ = _3ftarget_windows
                            table.insert(_261_, source_window)
                            return _261_
                          else
                            return nil
                          end
                        end
                        hl:cleanup(_262_(...))
                        exec_user_autocmds("LeapLeave")
                        return nil
                      else
                        return traverse(sublist, new_idx, {["force-no-labels?"] = not sublist["autojump?"]})
                      end
                    else
                      local _264_ = get_target_with_active_primary_label(sublist, in_final)
                      if ((_G.type(_264_) == "table") and (nil ~= (_264_)[1]) and (nil ~= (_264_)[2])) then
                        local idx = (_264_)[1]
                        local target = (_264_)[2]
                        if dot_repeatable_op_3f then
                          set_dot_repeat()
                        else
                        end
                        do
                          update_dot_repeat_state(idx)
                          jump_to_21(target)
                        end
                        local function _267_(...)
                          if _3ftarget_windows then
                            local _266_ = _3ftarget_windows
                            table.insert(_266_, source_window)
                            return _266_
                          else
                            return nil
                          end
                        end
                        hl:cleanup(_267_(...))
                        exec_user_autocmds("LeapLeave")
                        return nil
                      elseif true then
                        local _ = _264_
                        if sublist["autojump?"] then
                          if dot_repeatable_op_3f then
                            set_dot_repeat()
                          else
                          end
                          do
                            vim.fn.feedkeys(in_final, "i")
                          end
                          local function _270_(...)
                            if _3ftarget_windows then
                              local _269_ = _3ftarget_windows
                              table.insert(_269_, source_window)
                              return _269_
                            else
                              return nil
                            end
                          end
                          hl:cleanup(_270_(...))
                          exec_user_autocmds("LeapLeave")
                          return nil
                        else
                          if change_op_3f then
                            handle_interrupted_change_op_21()
                          else
                          end
                          do
                          end
                          local function _273_(...)
                            if _3ftarget_windows then
                              local _272_ = _3ftarget_windows
                              table.insert(_272_, source_window)
                              return _272_
                            else
                              return nil
                            end
                          end
                          hl:cleanup(_273_(...))
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
              local __60_auto = _235_
              return ...
            else
              return nil
            end
          end
          local function _281_(...)
            do
              local _282_ = targets
              populate_sublists(_282_)
              set_sublist_attributes(_282_, {["force-noautojump?"] = force_noautojump_3f})
              set_labels(_282_)
            end
            return (_3fin2 or get_second_pattern_input(targets))
          end
          return _234_(_281_(...))
        elseif true then
          local __60_auto = _233_
          return ...
        else
          return nil
        end
      end
      local function _284_(...)
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
          echo_not_found((in1 .. (_3fin2 or "")))
        end
        local function _287_(...)
          if _3ftarget_windows then
            local _286_ = _3ftarget_windows
            table.insert(_286_, source_window)
            return _286_
          else
            return nil
          end
        end
        hl:cleanup(_287_(...))
        exec_user_autocmds("LeapLeave")
        return nil
      end
      return _232_((get_targets(prepare_pattern(in1, _3fin2), {["backward?"] = backward_3f, ["target-windows"] = _3ftarget_windows}) or _284_(...)))
    elseif true then
      local __60_auto = _230_
      return ...
    else
      return nil
    end
  end
  local function _289_()
    if dot_repeat_3f then
      return state["dot-repeat"].in1, state["dot-repeat"].in2
    elseif opts.highlight_ahead_of_time then
      return get_first_pattern_input()
    else
      return get_full_pattern_input()
    end
  end
  return _229_(_289_())
end
local temporary_editor_opts = {["vim.bo.modeline"] = false}
local saved_editor_opts = {}
local function save_editor_opts()
  for opt, _ in pairs(temporary_editor_opts) do
    local _let_290_ = vim.split(opt, ".", true)
    local _0 = _let_290_[1]
    local scope = _let_290_[2]
    local name = _let_290_[3]
    saved_editor_opts[opt] = _G.vim[scope][name]
  end
  return nil
end
local function set_editor_opts(opts0)
  for opt, val in pairs(opts0) do
    local _let_291_ = vim.split(opt, ".", true)
    local _ = _let_291_[1]
    local scope = _let_291_[2]
    local name = _let_291_[3]
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
local function _292_()
  return hl["init-highlight"](hl)
end
api.nvim_create_autocmd("ColorScheme", {callback = _292_, group = "LeapDefault"})
local function _293_()
  save_editor_opts()
  return set_temporary_editor_opts()
end
api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _293_, group = "LeapDefault"})
api.nvim_create_autocmd("User", {pattern = "LeapLeave", callback = restore_editor_opts, group = "LeapDefault"})
return {state = state, leap = leap}
