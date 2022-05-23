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
local safe_labels = {"s", "f", "n", "u", "t", "/", "F", "L", "N", "H", "G", "M", "U", "T", "?", "Z"}
local labels = {"s", "f", "n", "j", "k", "l", "o", "d", "w", "e", "h", "m", "v", "g", "u", "t", "c", ".", "z", "/", "F", "L", "N", "H", "G", "M", "U", "T", "?", "Z"}
local opts = {case_insensitive = true, safe_labels = safe_labels, labels = labels, special_keys = {repeat_search = "<enter>", next_match = "<enter>", prev_match = "<tab>", next_group = "<space>", prev_group = "<tab>", eol = "<space>"}}
local function setup(user_opts)
  opts = setmetatable(user_opts, {__index = opts})
  return nil
end
local function user_forced_autojump_3f()
  return (not opts.labels or empty_3f(opts.labels))
end
local function user_forced_no_autojump_3f()
  return (not opts.safe_labels or empty_3f(opts.safe_labels))
end
local hl
local function _8_(self, _3ftarget_windows)
  if _3ftarget_windows then
    for _, wininfo in ipairs(_3ftarget_windows) do
      api.nvim_buf_clear_namespace(wininfo.bufnr, self.ns, dec(wininfo.topline), wininfo.botline)
    end
  else
  end
  return api.nvim_buf_clear_namespace(0, self.ns, dec(vim.fn.line("w0")), vim.fn.line("w$"))
end
hl = {group = {["label-primary"] = "LeapLabelPrimary", ["label-secondary"] = "LeapLabelSecondary", match = "LeapMatch", backdrop = "LeapBackdrop"}, priority = {label = 65535, cursor = 65534, backdrop = 65533}, ns = api.nvim_create_namespace(""), cleanup = _8_}
local function init_highlight(force_3f)
  local bg = vim.o.background
  local def_maps
  local _11_
  do
    local _10_ = bg
    if (_10_ == "light") then
      _11_ = "#222222"
    elseif true then
      local _ = _10_
      _11_ = "#ccff88"
    else
      _11_ = nil
    end
  end
  local _16_
  do
    local _15_ = bg
    if (_15_ == "light") then
      _16_ = "#ff8877"
    elseif true then
      local _ = _15_
      _16_ = "#ccff88"
    else
      _16_ = nil
    end
  end
  local _21_
  do
    local _20_ = bg
    if (_20_ == "light") then
      _21_ = "#77aaff"
    elseif true then
      local _ = _20_
      _21_ = "#99ccff"
    else
      _21_ = nil
    end
  end
  def_maps = {[hl.group.match] = {fg = _11_, ctermfg = "red", underline = true, nocombine = true}, [hl.group["label-primary"]] = {fg = "black", bg = _16_, ctermfg = "black", ctermbg = "red", nocombine = true}, [hl.group["label-secondary"]] = {fg = "black", bg = _21_, ctermfg = "black", ctermbg = "blue", nocombine = true}}
  for name, def_map in pairs(def_maps) do
    if not force_3f then
      def_map["default"] = true
    else
    end
    api.nvim_set_hl(0, name, def_map)
  end
  return nil
end
local function apply_backdrop(reverse_3f, _3ftarget_windows)
  local _26_, _27_ = pcall(api.nvim_get_hl_by_name, hl.group.backdrop, nil)
  if ((_26_ == true) and true) then
    local _ = _27_
    if _3ftarget_windows then
      for _0, win in ipairs(_3ftarget_windows) do
        vim.highlight.range(win.bufnr, hl.ns, hl.group.backdrop, {dec(win.topline), 0}, {dec(win.botline), -1}, {priority = hl.priority.backdrop})
      end
      return nil
    else
      local _let_28_ = map(dec, get_cursor_pos())
      local curline = _let_28_[1]
      local curcol = _let_28_[2]
      local _let_29_ = {dec(vim.fn.line("w0")), dec(vim.fn.line("w$"))}
      local win_top = _let_29_[1]
      local win_bot = _let_29_[2]
      local function _31_()
        if reverse_3f then
          return {{win_top, 0}, {curline, curcol}}
        else
          return {{curline, inc(curcol)}, {win_bot, -1}}
        end
      end
      local _let_30_ = _31_()
      local start = _let_30_[1]
      local finish = _let_30_[2]
      return vim.highlight.range(0, hl.ns, hl.group.backdrop, start, finish, {priority = hl.priority.backdrop})
    end
  else
    return nil
  end
end
local function echo_no_prev_search()
  return echo("no previous search")
end
local function echo_not_found(s)
  return echo(("not found: " .. s))
end
local function push_cursor_21(direction)
  local function _35_()
    local _34_ = direction
    if (_34_ == "fwd") then
      return "W"
    elseif (_34_ == "bwd") then
      return "bW"
    else
      return nil
    end
  end
  return vim.fn.search("\\_.", _35_())
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
  local function _40_()
    vim.o.virtualedit = saved
    return nil
  end
  return api.nvim_create_autocmd({"CursorMoved", "WinLeave", "BufLeave", "InsertEnter", "CmdlineEnter", "CmdwinEnter"}, {callback = _40_, once = true})
end
local function simulate_inclusive_op_21(mode)
  local _41_ = vim.fn.matchstr(mode, "^no\\zs.")
  if (_41_ == "") then
    if cursor_before_eof_3f() then
      return push_beyond_eof_21()
    else
      return push_cursor_21("fwd")
    end
  elseif (_41_ == "v") then
    return push_cursor_21("bwd")
  else
    return nil
  end
end
local function force_matchparen_refresh()
  pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchparen"})
  return pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchup_matchparen"})
end
local function jump_to_21_2a(pos, _44_)
  local _arg_45_ = _44_
  local winid = _arg_45_["winid"]
  local add_to_jumplist_3f = _arg_45_["add-to-jumplist?"]
  local mode = _arg_45_["mode"]
  local offset = _arg_45_["offset"]
  local reverse_3f = _arg_45_["reverse?"]
  local inclusive_op_3f = _arg_45_["inclusive-op?"]
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
  local _let_51_ = (_3fpos or get_cursor_pos())
  local line = _let_51_[1]
  local col = _let_51_[2]
  local pos = _let_51_
  local ch_at_curpos = (char_at_pos(pos, {}) or " ")
  return api.nvim_buf_set_extmark(0, hl.ns, dec(line), dec(col), {virt_text = {{ch_at_curpos, "Cursor"}}, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.cursor})
end
local function handle_interrupted_change_op_21()
  local seq
  local function _52_()
    if (vim.fn.col(".") > 1) then
      return "<RIGHT>"
    else
      return ""
    end
  end
  seq = ("<C-\\><C-G>" .. _52_())
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
  local function _55_(_241)
    return ((api.nvim_win_get_config(_241)).focusable and (_241 ~= curr_win) and not (visual_7cop_mode_3f and (api.nvim_win_get_buf(_241) ~= curr_buf)))
  end
  return filter(_55_, wins)
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
  local function _56_()
    if reverse_3f then
      return "bwd"
    else
      return "fwd"
    end
  end
  new_line = push_cursor_21(_56_())
  if (new_line == 0) then
    return "dead-end"
  else
    return nil
  end
end
local function to_closed_fold_edge_21(reverse_3f)
  local edge_line
  local _58_
  if reverse_3f then
    _58_ = vim.fn.foldclosed
  else
    _58_ = vim.fn.foldclosedend
  end
  edge_line = _58_(vim.fn.line("."))
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
  local _let_61_ = {vim.fn.line("."), vim.fn.virtcol(".")}
  local line = _let_61_[1]
  local virtcol = _let_61_[2]
  local from_pos = _let_61_
  local left_off_3f = (virtcol < left_bound)
  local right_off_3f = (virtcol > right_bound)
  local _62_
  if (left_off_3f and reverse_3f) then
    if (dec(line) >= stopline) then
      _62_ = {dec(line), right_bound}
    else
      _62_ = nil
    end
  elseif (left_off_3f and not reverse_3f) then
    _62_ = {line, left_bound}
  elseif (right_off_3f and reverse_3f) then
    _62_ = {line, right_bound}
  elseif (right_off_3f and not reverse_3f) then
    if (inc(line) <= stopline) then
      _62_ = {inc(line), left_bound}
    else
      _62_ = nil
    end
  else
    _62_ = nil
  end
  if (nil ~= _62_) then
    local to_pos = _62_
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
local function get_match_positions(pattern, _69_, _71_)
  local _arg_70_ = _69_
  local left_bound = _arg_70_[1]
  local right_bound = _arg_70_[2]
  local _arg_72_ = _71_
  local reverse_3f = _arg_72_["reverse?"]
  local whole_window_3f = _arg_72_["whole-window?"]
  local skip_curpos_3f = _arg_72_["skip-curpos?"]
  local skip_orig_curpos_3f = skip_curpos_3f
  local _let_73_ = get_cursor_pos()
  local orig_curline = _let_73_[1]
  local orig_curcol = _let_73_[2]
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
  local function _75_()
    vim.fn.winrestview(saved_view)
    vim.o.cpo = saved_cpo
    return nil
  end
  cleanup = _75_
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
    local function _77_()
      if reverse_3f then
        return "b"
      else
        return ""
      end
    end
    local function _78_()
      if match_at_curpos_3f0 then
        return "c"
      else
        return ""
      end
    end
    flags = (_77_() .. _78_())
    moved_to_topleft_3f = false
    local _79_ = vim.fn.searchpos(pattern, flags, stopline)
    if ((_G.type(_79_) == "table") and (nil ~= (_79_)[1]) and (nil ~= (_79_)[2])) then
      local line = (_79_)[1]
      local col = (_79_)[2]
      local pos = _79_
      if (line == 0) then
        return cleanup()
      elseif ((line == orig_curline) and (col == orig_curcol) and skip_orig_curpos_3f) then
        local _80_ = skip_one_21()
        if (_80_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _80_
          return iter(true)
        else
          return nil
        end
      elseif ((col < left_bound) and (col > right_bound) and not vim.wo.wrap) then
        local _82_ = to_next_in_window_pos_21(reverse_3f, left_bound, right_bound, stopline)
        if (_82_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _82_
          return iter(true)
        else
          return nil
        end
      elseif (vim.fn.foldclosed(line) ~= -1) then
        to_closed_fold_edge_21(reverse_3f)
        local _84_ = skip_one_21(reverse_3f)
        if (_84_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _84_
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
local function get_targets_2a(pattern, _88_)
  local _arg_89_ = _88_
  local reverse_3f = _arg_89_["reverse?"]
  local wininfo = _arg_89_["wininfo"]
  local targets = _arg_89_["targets"]
  local source_winid = _arg_89_["source-winid"]
  local targets0 = (targets or {})
  local _let_90_ = get_horizontal_bounds()
  local _ = _let_90_[1]
  local right_bound = _let_90_[2]
  local bounds = _let_90_
  local whole_window_3f = wininfo
  local wininfo0 = (wininfo or vim.fn.getwininfo(vim.fn.win_getid())[1])
  local skip_curpos_3f = (whole_window_3f and (vim.fn.win_getid() == source_winid))
  local match_positions = get_match_positions(pattern, bounds, {["reverse?"] = reverse_3f, ["skip-curpos?"] = skip_curpos_3f, ["whole-window?"] = whole_window_3f})
  local prev_match = {}
  for _91_ in match_positions do
    local _each_92_ = _91_
    local line = _each_92_[1]
    local col = _each_92_[2]
    local pos = _each_92_
    local ch1 = char_at_pos(pos, {})
    local ch2, eol_3f = nil, nil
    do
      local _93_ = char_at_pos(pos, {["char-offset"] = 1})
      if (nil ~= _93_) then
        local char = _93_
        ch2, eol_3f = char
      elseif true then
        local _0 = _93_
        ch2, eol_3f = replace_keycodes(opts.special_keys.eol), true
      else
        ch2, eol_3f = nil
      end
    end
    local same_char_triplet_3f
    local _95_
    if reverse_3f then
      _95_ = dec
    else
      _95_ = inc
    end
    same_char_triplet_3f = ((ch2 == prev_match.ch2) and (line == prev_match.line) and (col == _95_(prev_match.col)))
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
local function distance(_99_, _101_)
  local _arg_100_ = _99_
  local l1 = _arg_100_[1]
  local c1 = _arg_100_[2]
  local _arg_102_ = _101_
  local l2 = _arg_102_[1]
  local c2 = _arg_102_[2]
  local editor_grid_aspect_ratio = 0.3
  local _let_103_ = {abs((c1 - c2)), abs((l1 - l2))}
  local dx = _let_103_[1]
  local dy = _let_103_[2]
  local dx0 = (dx * editor_grid_aspect_ratio)
  return pow((pow(dx0, 2) + pow(dy, 2)), 0.5)
end
local function get_targets(pattern, _104_)
  local _arg_105_ = _104_
  local reverse_3f = _arg_105_["reverse?"]
  local target_windows = _arg_105_["target-windows"]
  if not target_windows then
    return get_targets_2a(pattern, {["reverse?"] = reverse_3f})
  else
    local targets = {}
    local cursor_positions = {}
    local source_winid = vim.fn.win_getid()
    local curr_win_only_3f
    do
      local _106_ = target_windows
      if ((_G.type(_106_) == "table") and ((_G.type((_106_)[1]) == "table") and (((_106_)[1]).winid == source_winid)) and ((_106_)[2] == nil)) then
        curr_win_only_3f = true
      else
        curr_win_only_3f = nil
      end
    end
    local cross_win_3f = not curr_win_only_3f
    for _, _108_ in ipairs(target_windows) do
      local _each_109_ = _108_
      local winid = _each_109_["winid"]
      local wininfo = _each_109_
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
        for winid, _112_ in pairs(cursor_positions) do
          local _each_113_ = _112_
          local line = _each_113_[1]
          local col = _each_113_[2]
          local _114_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_114_) == "table") and ((_114_).col == col) and (nil ~= (_114_).row)) then
            local row = (_114_).row
            cursor_positions[winid] = {row, col}
          else
          end
        end
      else
      end
      for _, _117_ in ipairs(targets) do
        local _each_118_ = _117_
        local _each_119_ = _each_118_["pos"]
        local line = _each_119_[1]
        local col = _each_119_[2]
        local _each_120_ = _each_118_["wininfo"]
        local winid = _each_120_["winid"]
        local t = _each_118_
        if by_screen_pos_3f then
          local _121_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_121_) == "table") and ((_121_).col == col) and (nil ~= (_121_).row)) then
            local row = (_121_).row
            t["screenpos"] = {row, col}
          else
          end
        else
        end
        t["rank"] = distance((t.screenpos or t.pos), cursor_positions[winid])
      end
      local function _124_(_241, _242)
        return ((_241).rank < (_242).rank)
      end
      table.sort(targets, _124_)
      return targets
    else
      return nil
    end
  end
end
local function populate_sublists(targets)
  targets["sublists"] = {}
  if opts.case_insensitive then
    local function _127_(t, k)
      return rawget(t, k:lower())
    end
    local function _128_(t, k, v)
      return rawset(t, k:lower(), v)
    end
    setmetatable(targets.sublists, {__index = _127_, __newindex = _128_})
  else
  end
  for _, _130_ in ipairs(targets) do
    local _each_131_ = _130_
    local _each_132_ = _each_131_["pair"]
    local _0 = _each_132_[1]
    local ch2 = _each_132_[2]
    local target = _each_131_
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
  local _134_
  if user_forced_autojump_3f() then
    _134_ = opts.safe_labels
  elseif user_forced_no_autojump_3f() then
    _134_ = opts.labels
  elseif sublist["autojump?"] then
    _134_ = opts.safe_labels
  else
    _134_ = opts.labels
  end
  sublist["label-set"] = _134_
  return nil
end
local function set_sublist_attributes(targets, _136_)
  local _arg_137_ = _136_
  local force_no_autojump_3f = _arg_137_["force-no-autojump?"]
  for _, sublist in pairs(targets.sublists) do
    set_autojump(sublist, force_no_autojump_3f)
    attach_label_set(sublist)
  end
  return nil
end
local function set_labels(targets)
  for _, sublist in pairs(targets.sublists) do
    if (#sublist > 1) then
      local _local_138_ = sublist
      local autojump_3f = _local_138_["autojump?"]
      local label_set = _local_138_["label-set"]
      for i, target in ipairs(sublist) do
        local i_2a
        if autojump_3f then
          i_2a = dec(i)
        else
          i_2a = i
        end
        if (i_2a > 0) then
          local _141_
          do
            local _140_ = (i_2a % #label_set)
            if (_140_ == 0) then
              _141_ = label_set[#label_set]
            elseif (nil ~= _140_) then
              local n = _140_
              _141_ = label_set[n]
            else
              _141_ = nil
            end
          end
          target["label"] = _141_
        else
        end
      end
    else
    end
  end
  return nil
end
local function set_label_states(sublist, _147_)
  local _arg_148_ = _147_
  local group_offset = _arg_148_["group-offset"]
  local _7clabel_set_7c = #sublist["label-set"]
  local offset = (group_offset * _7clabel_set_7c)
  local primary_start
  local function _149_()
    if sublist["autojump?"] then
      return 2
    else
      return 1
    end
  end
  primary_start = (offset + _149_())
  local primary_end = (primary_start + dec(_7clabel_set_7c))
  local secondary_start = inc(primary_end)
  local secondary_end = (primary_end + _7clabel_set_7c)
  for i, target in ipairs(sublist) do
    if target.label then
      local _150_
      if (function(_151_,_152_,_153_) return (_151_ <= _152_) and (_152_ <= _153_) end)(primary_start,i,primary_end) then
        _150_ = "active-primary"
      elseif (function(_154_,_155_,_156_) return (_154_ <= _155_) and (_155_ <= _156_) end)(secondary_start,i,secondary_end) then
        _150_ = "active-secondary"
      elseif (i > secondary_end) then
        _150_ = "inactive"
      else
        _150_ = nil
      end
      target["label-state"] = _150_
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
  if target.label then
    local _let_159_ = target
    local _let_160_ = _let_159_["pair"]
    local ch1 = _let_160_[1]
    local ch2 = _let_160_[2]
    local edge_pos_3f = _let_159_["edge-pos?"]
    local label = _let_159_["label"]
    local offset
    local function _161_()
      if edge_pos_3f then
        return 0
      else
        return ch2:len()
      end
    end
    offset = (ch1:len() + _161_())
    local virttext
    do
      local _162_ = target["label-state"]
      if (_162_ == "active-primary") then
        virttext = {{label, hl.group["label-primary"]}}
      elseif (_162_ == "active-secondary") then
        virttext = {{label, hl.group["label-secondary"]}}
      elseif (_162_ == "inactive") then
        virttext = {{" ", hl.group["label-secondary"]}}
      else
        virttext = nil
      end
    end
    local _164_
    if virttext then
      _164_ = {offset, virttext}
    else
      _164_ = nil
    end
    target["beacon"] = _164_
    return nil
  else
    return nil
  end
end
local function set_beacon_to_match_hl(target)
  local _let_167_ = target
  local _let_168_ = _let_167_["pair"]
  local ch1 = _let_168_[1]
  local ch2 = _let_168_[2]
  target["beacon"] = {0, {{(ch1 .. ch2), hl.group.match}}}
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
    local _let_169_ = target
    local _let_170_ = _let_169_["pos"]
    local lnum = _let_170_[1]
    local col = _let_170_[2]
    local _let_171_ = _let_169_["pair"]
    local ch1 = _let_171_[1]
    local _ = _let_171_[2]
    local _let_172_ = _let_169_["wininfo"]
    local bufnr = _let_172_["bufnr"]
    local winid = _let_172_["winid"]
    local _173_ = target.beacon
    if (_173_ == nil) then
      local keys = {(bufnr .. " " .. winid .. " " .. lnum .. " " .. col), (bufnr .. " " .. winid .. " " .. lnum .. " " .. (col + ch1:len()))}
      for _0, k in ipairs(keys) do
        do
          local _174_ = label_positions[k]
          if (nil ~= _174_) then
            local other = _174_
            other.beacon = nil
            set_beacon_to_match_hl(target)
          else
          end
        end
        unlabeled_match_positions[k] = target
      end
    elseif ((_G.type(_173_) == "table") and (nil ~= (_173_)[1]) and true) then
      local offset = (_173_)[1]
      local _0 = (_173_)[2]
      local k = (bufnr .. " " .. winid .. " " .. lnum .. " " .. (col + offset))
      do
        local _176_ = unlabeled_match_positions[k]
        if (nil ~= _176_) then
          local other = _176_
          target.beacon = nil
          set_beacon_to_match_hl(other)
        elseif true then
          local _1 = _176_
          local _177_ = label_positions[k]
          if (nil ~= _177_) then
            local other = _177_
            target.beacon = nil
            set_beacon_to_empty_label(other)
          else
          end
        else
        end
      end
      label_positions[k] = target
    else
    end
  end
  return nil
end
local function set_beacons(target_list, _181_)
  local _arg_182_ = _181_
  local force_no_labels_3f = _arg_182_["force-no-labels?"]
  if force_no_labels_3f then
    for _, target in ipairs(target_list) do
      set_beacon_to_match_hl(target)
    end
    return nil
  else
    for _, target in ipairs(target_list) do
      set_beacon_for_labeled(target)
    end
    return resolve_conflicts(target_list)
  end
end
local function light_up_beacons(target_list, _3fstart)
  for i = (_3fstart or 1), #target_list do
    local target = target_list[i]
    local _184_ = target.beacon
    if ((_G.type(_184_) == "table") and (nil ~= (_184_)[1]) and (nil ~= (_184_)[2])) then
      local offset = (_184_)[1]
      local virttext = (_184_)[2]
      local _let_185_ = map(dec, target.pos)
      local lnum = _let_185_[1]
      local col = _let_185_[2]
      api.nvim_buf_set_extmark(target.wininfo.bufnr, hl.ns, lnum, (col + offset), {virt_text = virttext, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.label})
    else
    end
  end
  return nil
end
local state = {["repeat"] = {in1 = nil, in2 = nil}, ["dot-repeat"] = {in1 = nil, in2 = nil, ["target-idx"] = nil, ["reverse?"] = nil, ["inclusive-op?"] = nil, ["offset?"] = nil}}
local function leap(_187_)
  local _arg_188_ = _187_
  local dot_repeat_3f = _arg_188_["dot-repeat?"]
  local target_windows = _arg_188_["target-windows"]
  local kwargs = _arg_188_
  local function _190_()
    if dot_repeat_3f then
      return state["dot-repeat"]
    else
      return kwargs
    end
  end
  local _let_189_ = _190_()
  local reverse_3f = _let_189_["reverse?"]
  local inclusive_op_3f = _let_189_["inclusive-op?"]
  local offset = _let_189_["offset"]
  local mode = api.nvim_get_mode().mode
  local _3ftarget_windows
  do
    local _191_
    do
      local _192_ = target_windows
      if (_G.type(_192_) == "table") then
        local t = _192_
        _191_ = t
      elseif (_192_ == true) then
        _191_ = get_other_windows_on_tabpage(mode)
      else
        _191_ = nil
      end
    end
    if (_191_ ~= nil) then
      local function _194_(_241)
        return (vim.fn.getwininfo(_241))[1]
      end
      _3ftarget_windows = map(_194_, _191_)
    else
      _3ftarget_windows = _191_
    end
  end
  local source_window = vim.fn.getwininfo(vim.fn.win_getid())[1]
  local directional_3f = not _3ftarget_windows
  local op_mode_3f = mode:match("o")
  local change_op_3f = (op_mode_3f and (vim.v.operator == "c"))
  local dot_repeatable_op_3f = (op_mode_3f and directional_3f and (vim.v.operator ~= "y"))
  local force_no_autojump_3f = (op_mode_3f or not directional_3f)
  local spec_keys
  local function _196_(_, k)
    return replace_keycodes(opts.special_keys[k])
  end
  spec_keys = setmetatable({}, {__index = _196_})
  local function prepare_pattern(in1, _3fin2)
    local function _197_()
      if opts.case_insensitive then
        return "\\c"
      else
        return "\\C"
      end
    end
    local function _199_()
      local _198_ = _3fin2
      if (_198_ == spec_keys.eol) then
        return ("\\(" .. _3fin2 .. "\\|\\r\\?\\n\\)")
      elseif true then
        local _ = _198_
        return (_3fin2 or "\\_.")
      else
        return nil
      end
    end
    return ("\\V" .. _197_() .. in1:gsub("\\", "\\\\") .. _199_())
  end
  local function get_target_with_active_primary_label(sublist, input)
    local res = nil
    for idx, _201_ in ipairs(sublist) do
      local _each_202_ = _201_
      local label = _each_202_["label"]
      local label_state = _each_202_["label-state"]
      local target = _each_202_
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
    local function _207_(target)
      jump_to_21_2a(target.pos, {winid = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["reverse?"] = reverse_3f, ["inclusive-op?"] = inclusive_op_3f})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _207_
  end
  local function traverse(targets, idx, _208_)
    local _arg_209_ = _208_
    local force_no_labels_3f = _arg_209_["force-no-labels?"]
    if force_no_labels_3f then
      inactivate_labels(targets)
    else
    end
    set_beacons(targets, {["force-no-labels?"] = force_no_labels_3f})
    do
      hl:cleanup(_3ftarget_windows)
      apply_backdrop(reverse_3f, _3ftarget_windows)
      do
        light_up_beacons(targets, inc(idx))
      end
      highlight_cursor()
      vim.cmd("redraw")
    end
    local _211_
    local function _212_()
      if dot_repeatable_op_3f then
        set_dot_repeat()
      else
      end
      do
      end
      local function _215_()
        if _3ftarget_windows then
          local _214_ = _3ftarget_windows
          table.insert(_214_, source_window)
          return _214_
        else
          return nil
        end
      end
      hl:cleanup(_215_())
      exec_user_autocmds("LeapLeave")
      return nil
    end
    _211_ = (get_input() or _212_())
    if (nil ~= _211_) then
      local input = _211_
      if ((input == spec_keys.next_match) or (input == spec_keys.prev_match)) then
        local new_idx
        do
          local _216_ = input
          if (_216_ == spec_keys.next_match) then
            new_idx = min(inc(idx), #targets)
          elseif (_216_ == spec_keys.prev_match) then
            new_idx = max(dec(idx), 1)
          else
            new_idx = nil
          end
        end
        update_state({["repeat"] = {in1 = state["repeat"].in1, in2 = targets[new_idx].pair[2]}})
        jump_to_21(targets[new_idx])
        return traverse(targets, new_idx, {["force-no-labels?"] = force_no_labels_3f})
      else
        local _218_ = get_target_with_active_primary_label(targets, input)
        if ((_G.type(_218_) == "table") and true and (nil ~= (_218_)[2])) then
          local _ = (_218_)[1]
          local target = (_218_)[2]
          if dot_repeatable_op_3f then
            set_dot_repeat()
          else
          end
          do
            jump_to_21(target)
          end
          local function _221_()
            if _3ftarget_windows then
              local _220_ = _3ftarget_windows
              table.insert(_220_, source_window)
              return _220_
            else
              return nil
            end
          end
          hl:cleanup(_221_())
          exec_user_autocmds("LeapLeave")
          return nil
        elseif true then
          local _ = _218_
          if dot_repeatable_op_3f then
            set_dot_repeat()
          else
          end
          do
            vim.fn.feedkeys(input, "i")
          end
          local function _224_()
            if _3ftarget_windows then
              local _223_ = _3ftarget_windows
              table.insert(_223_, source_window)
              return _223_
            else
              return nil
            end
          end
          hl:cleanup(_224_())
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
      apply_backdrop(reverse_3f, _3ftarget_windows)
      do
        echo("")
      end
      highlight_cursor()
      vim.cmd("redraw")
    end
    local _228_
    local function _229_()
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      do
      end
      local function _232_()
        if _3ftarget_windows then
          local _231_ = _3ftarget_windows
          table.insert(_231_, source_window)
          return _231_
        else
          return nil
        end
      end
      hl:cleanup(_232_())
      exec_user_autocmds("LeapLeave")
      return nil
    end
    _228_ = (get_input() or _229_())
    if (_228_ == spec_keys.repeat_search) then
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
    elseif (nil ~= _228_) then
      local in1 = _228_
      return in1
    else
      return nil
    end
  end
  local function get_second_pattern_input(targets)
    do
      local _238_ = targets
      set_initial_label_states(_238_)
      set_beacons(_238_, {})
    end
    do
      hl:cleanup(_3ftarget_windows)
      apply_backdrop(reverse_3f, _3ftarget_windows)
      do
        light_up_beacons(targets)
      end
      highlight_cursor()
      vim.cmd("redraw")
    end
    local function _239_()
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      do
      end
      local function _242_()
        if _3ftarget_windows then
          local _241_ = _3ftarget_windows
          table.insert(_241_, source_window)
          return _241_
        else
          return nil
        end
      end
      hl:cleanup(_242_())
      exec_user_autocmds("LeapLeave")
      return nil
    end
    return (get_input() or _239_())
  end
  local function post_pattern_input_loop(sublist)
    local function loop(group_offset, initial_invoc_3f)
      do
        local _243_ = sublist
        set_label_states(_243_, {["group-offset"] = group_offset})
        set_beacons(_243_, {})
      end
      do
        hl:cleanup(_3ftarget_windows)
        apply_backdrop(reverse_3f, _3ftarget_windows)
        do
          light_up_beacons(sublist)
        end
        highlight_cursor()
        vim.cmd("redraw")
      end
      local _244_
      local function _245_()
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
        end
        local function _248_()
          if _3ftarget_windows then
            local _247_ = _3ftarget_windows
            table.insert(_247_, source_window)
            return _247_
          else
            return nil
          end
        end
        hl:cleanup(_248_())
        exec_user_autocmds("LeapLeave")
        return nil
      end
      _244_ = (get_input() or _245_())
      if (nil ~= _244_) then
        local input = _244_
        if (((input == spec_keys.next_group) or ((input == spec_keys.prev_group) and not initial_invoc_3f)) and (not sublist["autojump?"] or user_forced_autojump_3f)) then
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
  local function _252_(...)
    local _253_, _254_ = ...
    if ((nil ~= _253_) and true) then
      local in1 = _253_
      local _3fin2 = _254_
      local function _255_(...)
        local _256_ = ...
        if (nil ~= _256_) then
          local targets = _256_
          local function _257_(...)
            local _258_ = ...
            if (nil ~= _258_) then
              local in2 = _258_
              if dot_repeat_3f then
                local _259_ = targets[state["dot-repeat"]["target-idx"]]
                if (nil ~= _259_) then
                  local target = _259_
                  if dot_repeatable_op_3f then
                    set_dot_repeat()
                  else
                  end
                  do
                    jump_to_21(target)
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
                elseif true then
                  local _ = _259_
                  if change_op_3f then
                    handle_interrupted_change_op_21()
                  else
                  end
                  do
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
                  local function _269_(...)
                    if _3ftarget_windows then
                      local _268_ = _3ftarget_windows
                      table.insert(_268_, source_window)
                      return _268_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_269_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                else
                  return traverse(targets, 1, {["force-no-labels?"] = true})
                end
              else
                update_state({["repeat"] = {in1 = in1, in2 = in2}})
                local update_dot_repeat_state
                local function _271_(_241)
                  return update_state({["dot-repeat"] = {in1 = in1, in2 = in2, ["target-idx"] = _241}})
                end
                update_dot_repeat_state = _271_
                local _272_
                local function _273_(...)
                  if change_op_3f then
                    handle_interrupted_change_op_21()
                  else
                  end
                  do
                    echo_not_found((in1 .. in2))
                  end
                  local function _276_(...)
                    if _3ftarget_windows then
                      local _275_ = _3ftarget_windows
                      table.insert(_275_, source_window)
                      return _275_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_276_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                end
                _272_ = (targets.sublists[in2] or _273_(...))
                if ((_G.type(_272_) == "table") and (nil ~= (_272_)[1]) and ((_272_)[2] == nil)) then
                  local only = (_272_)[1]
                  if dot_repeatable_op_3f then
                    set_dot_repeat()
                  else
                  end
                  do
                    update_dot_repeat_state(1)
                    jump_to_21(only)
                  end
                  local function _279_(...)
                    if _3ftarget_windows then
                      local _278_ = _3ftarget_windows
                      table.insert(_278_, source_window)
                      return _278_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_279_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                elseif (nil ~= _272_) then
                  local sublist = _272_
                  if sublist["autojump?"] then
                    jump_to_21(sublist[1])
                  else
                  end
                  local _281_ = post_pattern_input_loop(sublist)
                  if (nil ~= _281_) then
                    local in_final = _281_
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
                      else
                        return traverse(sublist, new_idx, {["force-no-labels?"] = not sublist["autojump?"]})
                      end
                    else
                      local _287_ = get_target_with_active_primary_label(sublist, in_final)
                      if ((_G.type(_287_) == "table") and (nil ~= (_287_)[1]) and (nil ~= (_287_)[2])) then
                        local idx = (_287_)[1]
                        local target = (_287_)[2]
                        if dot_repeatable_op_3f then
                          set_dot_repeat()
                        else
                        end
                        do
                          update_dot_repeat_state(idx)
                          jump_to_21(target)
                        end
                        local function _290_(...)
                          if _3ftarget_windows then
                            local _289_ = _3ftarget_windows
                            table.insert(_289_, source_window)
                            return _289_
                          else
                            return nil
                          end
                        end
                        hl:cleanup(_290_(...))
                        exec_user_autocmds("LeapLeave")
                        return nil
                      elseif true then
                        local _ = _287_
                        if sublist["autojump?"] then
                          if dot_repeatable_op_3f then
                            set_dot_repeat()
                          else
                          end
                          do
                            vim.fn.feedkeys(in_final, "i")
                          end
                          local function _293_(...)
                            if _3ftarget_windows then
                              local _292_ = _3ftarget_windows
                              table.insert(_292_, source_window)
                              return _292_
                            else
                              return nil
                            end
                          end
                          hl:cleanup(_293_(...))
                          exec_user_autocmds("LeapLeave")
                          return nil
                        else
                          if change_op_3f then
                            handle_interrupted_change_op_21()
                          else
                          end
                          do
                          end
                          local function _296_(...)
                            if _3ftarget_windows then
                              local _295_ = _3ftarget_windows
                              table.insert(_295_, source_window)
                              return _295_
                            else
                              return nil
                            end
                          end
                          hl:cleanup(_296_(...))
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
              local __60_auto = _258_
              return ...
            else
              return nil
            end
          end
          local function _304_(...)
            do
              local _305_ = targets
              populate_sublists(_305_)
              set_sublist_attributes(_305_, {["force-no-autojump?"] = force_no_autojump_3f})
              set_labels(_305_)
            end
            return (_3fin2 or get_second_pattern_input(targets))
          end
          return _257_(_304_(...))
        elseif true then
          local __60_auto = _256_
          return ...
        else
          return nil
        end
      end
      local function _307_(...)
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
          echo_not_found((in1 .. (_3fin2 or "")))
        end
        local function _310_(...)
          if _3ftarget_windows then
            local _309_ = _3ftarget_windows
            table.insert(_309_, source_window)
            return _309_
          else
            return nil
          end
        end
        hl:cleanup(_310_(...))
        exec_user_autocmds("LeapLeave")
        return nil
      end
      return _255_((get_targets(prepare_pattern(in1, _3fin2), {["reverse?"] = reverse_3f, ["target-windows"] = _3ftarget_windows}) or _307_(...)))
    elseif true then
      local __60_auto = _253_
      return ...
    else
      return nil
    end
  end
  local function _312_()
    if dot_repeat_3f then
      return state["dot-repeat"].in1, state["dot-repeat"].in2
    else
      return get_first_pattern_input()
    end
  end
  return _252_(_312_())
end
local function set_default_keymaps(force_3f)
  for _, _313_ in ipairs({{"n", "s", "<Plug>(leap-forward)"}, {"n", "S", "<Plug>(leap-backward)"}, {"x", "s", "<Plug>(leap-forward)"}, {"x", "S", "<Plug>(leap-backward)"}, {"o", "z", "<Plug>(leap-forward)"}, {"o", "Z", "<Plug>(leap-backward)"}, {"o", "x", "<Plug>(leap-forward-x)"}, {"o", "X", "<Plug>(leap-backward-x)"}, {"n", "gs", "<Plug>(leap-cross-window)"}, {"x", "gs", "<Plug>(leap-cross-window)"}, {"o", "gs", "<Plug>(leap-cross-window)"}}) do
    local _each_314_ = _313_
    local mode = _each_314_[1]
    local lhs = _each_314_[2]
    local rhs = _each_314_[3]
    if (force_3f or ((vim.fn.mapcheck(lhs, mode) == "") and (vim.fn.hasmapto(rhs, mode) == 0))) then
      vim.keymap.set(mode, lhs, rhs, {silent = true})
    else
    end
  end
  return nil
end
local temporary_editor_opts = {["vim.bo.modeline"] = false}
local saved_editor_opts = {}
local function save_editor_opts()
  for opt, _ in pairs(temporary_editor_opts) do
    local _let_316_ = vim.split(opt, ".", true)
    local _0 = _let_316_[1]
    local scope = _let_316_[2]
    local name = _let_316_[3]
    saved_editor_opts[opt] = _G.vim[scope][name]
  end
  return nil
end
local function set_editor_opts(opts0)
  for opt, val in pairs(opts0) do
    local _let_317_ = vim.split(opt, ".", true)
    local _ = _let_317_[1]
    local scope = _let_317_[2]
    local name = _let_317_[3]
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
init_highlight()
api.nvim_create_augroup("LeapDefault", {})
local function _318_()
  return init_highlight()
end
api.nvim_create_autocmd("ColorScheme", {callback = _318_, group = "LeapDefault"})
local function _319_()
  save_editor_opts()
  return set_temporary_editor_opts()
end
api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _319_, group = "LeapDefault"})
api.nvim_create_autocmd("User", {pattern = "LeapLeave", callback = restore_editor_opts, group = "LeapDefault"})
return {opts = opts, setup = setup, state = state, leap = leap, init_highlight = init_highlight, set_default_keymaps = set_default_keymaps}
