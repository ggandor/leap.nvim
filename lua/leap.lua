local api = vim.api
local empty_3f = vim.tbl_isempty
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
  if _3ftarget_windows then
    for _, win in ipairs(_3ftarget_windows) do
      vim.highlight.range(win.bufnr, hl.ns, hl.group.backdrop, {dec(win.topline), 0}, {dec(win.botline), -1}, {priority = hl.priority.backdrop})
    end
    return nil
  else
    local _let_26_ = map(dec, get_cursor_pos())
    local curline = _let_26_[1]
    local curcol = _let_26_[2]
    local _let_27_ = {dec(vim.fn.line("w0")), dec(vim.fn.line("w$"))}
    local win_top = _let_27_[1]
    local win_bot = _let_27_[2]
    local function _29_()
      if reverse_3f then
        return {{win_top, 0}, {curline, curcol}}
      else
        return {{curline, inc(curcol)}, {win_bot, -1}}
      end
    end
    local _let_28_ = _29_()
    local start = _let_28_[1]
    local finish = _let_28_[2]
    return vim.highlight.range(0, hl.ns, hl.group.backdrop, start, finish, {priority = hl.priority.backdrop})
  end
end
local function echo_no_prev_search()
  return echo("no previous search")
end
local function echo_not_found(s)
  return echo(("not found: " .. s))
end
local function push_cursor_21(direction)
  local function _32_()
    local _31_ = direction
    if (_31_ == "fwd") then
      return "W"
    elseif (_31_ == "bwd") then
      return "bW"
    else
      return nil
    end
  end
  return vim.fn.search("\\_.", _32_())
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
  local function _37_()
    vim.o.virtualedit = saved
    return nil
  end
  return api.nvim_create_autocmd({"CursorMoved", "WinLeave", "BufLeave", "InsertEnter", "CmdlineEnter", "CmdwinEnter"}, {callback = _37_, once = true})
end
local function simulate_inclusive_op_21(mode)
  local _38_ = vim.fn.matchstr(mode, "^no\\zs.")
  if (_38_ == "") then
    if cursor_before_eof_3f() then
      return push_beyond_eof_21()
    else
      return push_cursor_21("fwd")
    end
  elseif (_38_ == "v") then
    return push_cursor_21("bwd")
  else
    return nil
  end
end
local function force_matchparen_refresh()
  pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchparen"})
  return pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchup_matchparen"})
end
local function jump_to_21_2a(pos, _41_)
  local _arg_42_ = _41_
  local winid = _arg_42_["winid"]
  local add_to_jumplist_3f = _arg_42_["add-to-jumplist?"]
  local mode = _arg_42_["mode"]
  local offset = _arg_42_["offset"]
  local reverse_3f = _arg_42_["reverse?"]
  local inclusive_op_3f = _arg_42_["inclusive-op?"]
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
  local _let_48_ = (_3fpos or get_cursor_pos())
  local line = _let_48_[1]
  local col = _let_48_[2]
  local pos = _let_48_
  local ch_at_curpos = (char_at_pos(pos, {}) or " ")
  return api.nvim_buf_set_extmark(0, hl.ns, dec(line), dec(col), {virt_text = {{ch_at_curpos, "Cursor"}}, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.cursor})
end
local function handle_interrupted_change_op_21()
  local seq
  local function _49_()
    if (vim.fn.col(".") > 1) then
      return "<RIGHT>"
    else
      return ""
    end
  end
  seq = ("<C-\\><C-G>" .. _49_())
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
local function get_other_windows_on_tabpage()
  local visual_or_OP_mode_3f = (vim.fn.mode() ~= "n")
  local get_wininfo
  local function _52_(_241)
    return (vim.fn.getwininfo(_241))[1]
  end
  get_wininfo = _52_
  local get_buf = api.nvim_win_get_buf
  local curr_winid = vim.fn.win_getid()
  local ids = string.gmatch(vim.fn.string(vim.fn.winlayout()), "%d+")
  local ids0
  do
    local tbl_15_auto = {}
    local i_16_auto = #tbl_15_auto
    for id in ids do
      local val_17_auto
      if not ((tonumber(id) == curr_winid) or (visual_or_OP_mode_3f and (get_buf(tonumber(id)) ~= get_buf(curr_winid)))) then
        val_17_auto = id
      else
        val_17_auto = nil
      end
      if (nil ~= val_17_auto) then
        i_16_auto = (i_16_auto + 1)
        do end (tbl_15_auto)[i_16_auto] = val_17_auto
      else
      end
    end
    ids0 = tbl_15_auto
  end
  return map(get_wininfo, ids0)
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
  local function _55_()
    if reverse_3f then
      return "bwd"
    else
      return "fwd"
    end
  end
  new_line = push_cursor_21(_55_())
  if (new_line == 0) then
    return "dead-end"
  else
    return nil
  end
end
local function to_closed_fold_edge_21(reverse_3f)
  local edge_line
  local _57_
  if reverse_3f then
    _57_ = vim.fn.foldclosed
  else
    _57_ = vim.fn.foldclosedend
  end
  edge_line = _57_(vim.fn.line("."))
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
  local _let_60_ = {vim.fn.line("."), vim.fn.virtcol(".")}
  local line = _let_60_[1]
  local virtcol = _let_60_[2]
  local from_pos = _let_60_
  local left_off_3f = (virtcol < left_bound)
  local right_off_3f = (virtcol > right_bound)
  local _61_
  if (left_off_3f and reverse_3f) then
    if (dec(line) >= stopline) then
      _61_ = {dec(line), right_bound}
    else
      _61_ = nil
    end
  elseif (left_off_3f and not reverse_3f) then
    _61_ = {line, left_bound}
  elseif (right_off_3f and reverse_3f) then
    _61_ = {line, right_bound}
  elseif (right_off_3f and not reverse_3f) then
    if (inc(line) <= stopline) then
      _61_ = {inc(line), left_bound}
    else
      _61_ = nil
    end
  else
    _61_ = nil
  end
  if (nil ~= _61_) then
    local to_pos = _61_
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
local function get_match_positions(pattern, _68_, _70_)
  local _arg_69_ = _68_
  local left_bound = _arg_69_[1]
  local right_bound = _arg_69_[2]
  local _arg_71_ = _70_
  local reverse_3f = _arg_71_["reverse?"]
  local whole_window_3f = _arg_71_["whole-window?"]
  local skip_curpos_3f = _arg_71_["skip-curpos?"]
  local skip_orig_curpos_3f = skip_curpos_3f
  local _let_72_ = get_cursor_pos()
  local orig_curline = _let_72_[1]
  local orig_curcol = _let_72_[2]
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
  local function _74_()
    vim.fn.winrestview(saved_view)
    vim.o.cpo = saved_cpo
    return nil
  end
  cleanup = _74_
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
    local function _76_()
      if reverse_3f then
        return "b"
      else
        return ""
      end
    end
    local function _77_()
      if match_at_curpos_3f0 then
        return "c"
      else
        return ""
      end
    end
    flags = (_76_() .. _77_())
    moved_to_topleft_3f = false
    local _78_ = vim.fn.searchpos(pattern, flags, stopline)
    if ((_G.type(_78_) == "table") and (nil ~= (_78_)[1]) and (nil ~= (_78_)[2])) then
      local line = (_78_)[1]
      local col = (_78_)[2]
      local pos = _78_
      if (line == 0) then
        return cleanup()
      elseif ((line == orig_curline) and (col == orig_curcol) and skip_orig_curpos_3f) then
        local _79_ = skip_one_21()
        if (_79_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _79_
          return iter(true)
        else
          return nil
        end
      elseif ((col < left_bound) and (col > right_bound) and not vim.wo.wrap) then
        local _81_ = to_next_in_window_pos_21(reverse_3f, left_bound, right_bound, stopline)
        if (_81_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _81_
          return iter(true)
        else
          return nil
        end
      elseif (vim.fn.foldclosed(line) ~= -1) then
        to_closed_fold_edge_21(reverse_3f)
        local _83_ = skip_one_21(reverse_3f)
        if (_83_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _83_
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
local function get_targets_2a(pattern, _87_)
  local _arg_88_ = _87_
  local reverse_3f = _arg_88_["reverse?"]
  local wininfo = _arg_88_["wininfo"]
  local targets = _arg_88_["targets"]
  local source_winid = _arg_88_["source-winid"]
  local targets0 = (targets or {})
  local _let_89_ = get_horizontal_bounds()
  local _ = _let_89_[1]
  local right_bound = _let_89_[2]
  local bounds = _let_89_
  local whole_window_3f = wininfo
  local wininfo0 = (wininfo or vim.fn.getwininfo(vim.fn.win_getid())[1])
  local skip_curpos_3f = (whole_window_3f and (vim.fn.win_getid() == source_winid))
  local match_positions = get_match_positions(pattern, bounds, {["reverse?"] = reverse_3f, ["skip-curpos?"] = skip_curpos_3f, ["whole-window?"] = whole_window_3f})
  local prev_match = {}
  for _90_ in match_positions do
    local _each_91_ = _90_
    local line = _each_91_[1]
    local col = _each_91_[2]
    local pos = _each_91_
    local ch1 = char_at_pos(pos, {})
    local ch2, eol_3f = nil, nil
    do
      local _92_ = char_at_pos(pos, {["char-offset"] = 1})
      if (nil ~= _92_) then
        local char = _92_
        ch2, eol_3f = char
      elseif true then
        local _0 = _92_
        ch2, eol_3f = replace_keycodes(opts.special_keys.eol), true
      else
        ch2, eol_3f = nil
      end
    end
    local same_char_triplet_3f
    local _94_
    if reverse_3f then
      _94_ = dec
    else
      _94_ = inc
    end
    same_char_triplet_3f = ((ch2 == prev_match.ch2) and (line == prev_match.line) and (col == _94_(prev_match.col)))
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
local function distance(_98_, _100_)
  local _arg_99_ = _98_
  local l1 = _arg_99_[1]
  local c1 = _arg_99_[2]
  local _arg_101_ = _100_
  local l2 = _arg_101_[1]
  local c2 = _arg_101_[2]
  local editor_grid_aspect_ratio = 0.3
  local _let_102_ = {abs((c1 - c2)), abs((l1 - l2))}
  local dx = _let_102_[1]
  local dy = _let_102_[2]
  local dx0 = (dx * editor_grid_aspect_ratio)
  return pow((pow(dx0, 2) + pow(dy, 2)), 0.5)
end
local function get_targets(pattern, _103_)
  local _arg_104_ = _103_
  local reverse_3f = _arg_104_["reverse?"]
  local target_windows = _arg_104_["target-windows"]
  if not target_windows then
    return get_targets_2a(pattern, {["reverse?"] = reverse_3f})
  else
    local targets = {}
    local cursor_positions = {}
    local source_winid = vim.fn.win_getid()
    local curr_win_only_3f
    do
      local _105_ = target_windows
      if ((_G.type(_105_) == "table") and ((_G.type((_105_)[1]) == "table") and (((_105_)[1]).winid == source_winid)) and ((_105_)[2] == nil)) then
        curr_win_only_3f = true
      else
        curr_win_only_3f = nil
      end
    end
    local cross_win_3f = not curr_win_only_3f
    for _, _107_ in ipairs(target_windows) do
      local _each_108_ = _107_
      local winid = _each_108_["winid"]
      local wininfo = _each_108_
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
        for winid, _111_ in pairs(cursor_positions) do
          local _each_112_ = _111_
          local line = _each_112_[1]
          local col = _each_112_[2]
          local _113_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_113_) == "table") and (nil ~= (_113_).row) and ((_113_).col == col)) then
            local row = (_113_).row
            cursor_positions[winid] = {row, col}
          else
          end
        end
      else
      end
      for _, _116_ in ipairs(targets) do
        local _each_117_ = _116_
        local _each_118_ = _each_117_["pos"]
        local line = _each_118_[1]
        local col = _each_118_[2]
        local _each_119_ = _each_117_["wininfo"]
        local winid = _each_119_["winid"]
        local t = _each_117_
        if by_screen_pos_3f then
          local _120_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_120_) == "table") and (nil ~= (_120_).row) and ((_120_).col == col)) then
            local row = (_120_).row
            t["screenpos"] = {row, col}
          else
          end
        else
        end
        t["rank"] = distance((t.screenpos or t.pos), cursor_positions[winid])
      end
      local function _123_(_241, _242)
        return ((_241).rank < (_242).rank)
      end
      table.sort(targets, _123_)
      return targets
    else
      return nil
    end
  end
end
local function populate_sublists(targets)
  targets["sublists"] = {}
  if opts.case_insensitive then
    local function _126_(t, k)
      return rawget(t, k:lower())
    end
    local function _127_(t, k, v)
      return rawset(t, k:lower(), v)
    end
    setmetatable(targets.sublists, {__index = _126_, __newindex = _127_})
  else
  end
  for _, _129_ in ipairs(targets) do
    local _each_130_ = _129_
    local _each_131_ = _each_130_["pair"]
    local _0 = _each_131_[1]
    local ch2 = _each_131_[2]
    local target = _each_130_
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
  local _133_
  if user_forced_autojump_3f() then
    _133_ = opts.safe_labels
  elseif user_forced_no_autojump_3f() then
    _133_ = opts.labels
  elseif sublist["autojump?"] then
    _133_ = opts.safe_labels
  else
    _133_ = opts.labels
  end
  sublist["label-set"] = _133_
  return nil
end
local function set_sublist_attributes(targets, _135_)
  local _arg_136_ = _135_
  local force_no_autojump_3f = _arg_136_["force-no-autojump?"]
  for _, sublist in pairs(targets.sublists) do
    set_autojump(sublist, force_no_autojump_3f)
    attach_label_set(sublist)
  end
  return nil
end
local function set_labels(targets)
  for _, sublist in pairs(targets.sublists) do
    if (#sublist > 1) then
      local _local_137_ = sublist
      local autojump_3f = _local_137_["autojump?"]
      local label_set = _local_137_["label-set"]
      for i, target in ipairs(sublist) do
        local i_2a
        if autojump_3f then
          i_2a = dec(i)
        else
          i_2a = i
        end
        if (i_2a > 0) then
          local _140_
          do
            local _139_ = (i_2a % #label_set)
            if (_139_ == 0) then
              _140_ = label_set[#label_set]
            elseif (nil ~= _139_) then
              local n = _139_
              _140_ = label_set[n]
            else
              _140_ = nil
            end
          end
          target["label"] = _140_
        else
        end
      end
    else
    end
  end
  return nil
end
local function set_label_states(sublist, _146_)
  local _arg_147_ = _146_
  local group_offset = _arg_147_["group-offset"]
  local _7clabel_set_7c = #sublist["label-set"]
  local offset = (group_offset * _7clabel_set_7c)
  local primary_start
  local function _148_()
    if sublist["autojump?"] then
      return 2
    else
      return 1
    end
  end
  primary_start = (offset + _148_())
  local primary_end = (primary_start + dec(_7clabel_set_7c))
  local secondary_start = inc(primary_end)
  local secondary_end = (primary_end + _7clabel_set_7c)
  for i, target in ipairs(sublist) do
    if target.label then
      local _149_
      if (function(_150_,_151_,_152_) return (_150_ <= _151_) and (_151_ <= _152_) end)(primary_start,i,primary_end) then
        _149_ = "active-primary"
      elseif (function(_153_,_154_,_155_) return (_153_ <= _154_) and (_154_ <= _155_) end)(secondary_start,i,secondary_end) then
        _149_ = "active-secondary"
      elseif (i > secondary_end) then
        _149_ = "inactive"
      else
        _149_ = nil
      end
      target["label-state"] = _149_
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
    local _let_158_ = target
    local _let_159_ = _let_158_["pair"]
    local ch1 = _let_159_[1]
    local ch2 = _let_159_[2]
    local edge_pos_3f = _let_158_["edge-pos?"]
    local label = _let_158_["label"]
    local offset
    local function _160_()
      if edge_pos_3f then
        return 0
      else
        return ch2:len()
      end
    end
    offset = (ch1:len() + _160_())
    local virttext
    do
      local _161_ = target["label-state"]
      if (_161_ == "active-primary") then
        virttext = {{label, hl.group["label-primary"]}}
      elseif (_161_ == "active-secondary") then
        virttext = {{label, hl.group["label-secondary"]}}
      elseif (_161_ == "inactive") then
        virttext = {{" ", hl.group["label-secondary"]}}
      else
        virttext = nil
      end
    end
    local _163_
    if virttext then
      _163_ = {offset, virttext}
    else
      _163_ = nil
    end
    target["beacon"] = _163_
    return nil
  else
    return nil
  end
end
local function set_beacon_to_match_hl(target)
  local _let_166_ = target
  local _let_167_ = _let_166_["pair"]
  local ch1 = _let_167_[1]
  local ch2 = _let_167_[2]
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
    local _let_168_ = target
    local _let_169_ = _let_168_["pos"]
    local lnum = _let_169_[1]
    local col = _let_169_[2]
    local _let_170_ = _let_168_["pair"]
    local ch1 = _let_170_[1]
    local _ = _let_170_[2]
    local _let_171_ = _let_168_["wininfo"]
    local bufnr = _let_171_["bufnr"]
    local winid = _let_171_["winid"]
    local _172_ = target.beacon
    if (_172_ == nil) then
      local keys = {(bufnr .. " " .. winid .. " " .. lnum .. " " .. col), (bufnr .. " " .. winid .. " " .. lnum .. " " .. (col + ch1:len()))}
      for _0, k in ipairs(keys) do
        do
          local _173_ = label_positions[k]
          if (nil ~= _173_) then
            local other = _173_
            other.beacon = nil
            set_beacon_to_match_hl(target)
          else
          end
        end
        unlabeled_match_positions[k] = target
      end
    elseif ((_G.type(_172_) == "table") and (nil ~= (_172_)[1]) and true) then
      local offset = (_172_)[1]
      local _0 = (_172_)[2]
      local k = (bufnr .. " " .. winid .. " " .. lnum .. " " .. (col + offset))
      do
        local _175_ = unlabeled_match_positions[k]
        if (nil ~= _175_) then
          local other = _175_
          target.beacon = nil
          set_beacon_to_match_hl(other)
        elseif true then
          local _1 = _175_
          local _176_ = label_positions[k]
          if (nil ~= _176_) then
            local other = _176_
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
local function set_beacons(target_list, _180_)
  local _arg_181_ = _180_
  local force_no_labels_3f = _arg_181_["force-no-labels?"]
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
    local _183_ = target.beacon
    if ((_G.type(_183_) == "table") and (nil ~= (_183_)[1]) and (nil ~= (_183_)[2])) then
      local offset = (_183_)[1]
      local virttext = (_183_)[2]
      local _let_184_ = map(dec, target.pos)
      local lnum = _let_184_[1]
      local col = _let_184_[2]
      api.nvim_buf_set_extmark(target.wininfo.bufnr, hl.ns, lnum, (col + offset), {virt_text = virttext, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.label})
    else
    end
  end
  return nil
end
local state = {["repeat"] = {in1 = nil, in2 = nil}, ["dot-repeat"] = {in1 = nil, in2 = nil, ["target-idx"] = nil, ["reverse?"] = nil, ["inclusive-op?"] = nil, ["offset?"] = nil}}
local function leap(_186_)
  local _arg_187_ = _186_
  local dot_repeat_3f = _arg_187_["dot-repeat?"]
  local target_windows = _arg_187_["target-windows"]
  local kwargs = _arg_187_
  local function _189_()
    if dot_repeat_3f then
      return state["dot-repeat"]
    else
      return kwargs
    end
  end
  local _let_188_ = _189_()
  local reverse_3f = _let_188_["reverse?"]
  local inclusive_op_3f = _let_188_["inclusive-op?"]
  local offset = _let_188_["offset"]
  local _3ftarget_windows
  do
    local _190_ = target_windows
    if (_G.type(_190_) == "table") then
      local t = _190_
      _3ftarget_windows = t
    elseif (_190_ == true) then
      _3ftarget_windows = get_other_windows_on_tabpage()
    else
      _3ftarget_windows = nil
    end
  end
  local source_window = vim.fn.getwininfo(vim.fn.win_getid())[1]
  local directional_3f = not _3ftarget_windows
  local mode = api.nvim_get_mode().mode
  local op_mode_3f = mode:match("o")
  local change_op_3f = (op_mode_3f and (vim.v.operator == "c"))
  local dot_repeatable_op_3f = (op_mode_3f and directional_3f and (vim.v.operator ~= "y"))
  local force_no_autojump_3f = (op_mode_3f or not directional_3f)
  local spec_keys
  local function _192_(_, k)
    return replace_keycodes(opts.special_keys[k])
  end
  spec_keys = setmetatable({}, {__index = _192_})
  local function prepare_pattern(in1, _3fin2)
    local function _193_()
      if opts.case_insensitive then
        return "\\c"
      else
        return "\\C"
      end
    end
    local function _195_()
      local _194_ = _3fin2
      if (_194_ == spec_keys.eol) then
        return ("\\(" .. _3fin2 .. "\\|\\r\\?\\n\\)")
      elseif true then
        local _ = _194_
        return (_3fin2 or "\\_.")
      else
        return nil
      end
    end
    return ("\\V" .. _193_() .. in1:gsub("\\", "\\\\") .. _195_())
  end
  local function get_target_with_active_primary_label(sublist, input)
    local res = nil
    for idx, _197_ in ipairs(sublist) do
      local _each_198_ = _197_
      local label = _each_198_["label"]
      local label_state = _each_198_["label-state"]
      local target = _each_198_
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
    local function _203_(target)
      jump_to_21_2a(target.pos, {winid = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["reverse?"] = reverse_3f, ["inclusive-op?"] = inclusive_op_3f})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _203_
  end
  local function traverse(targets, idx, _204_)
    local _arg_205_ = _204_
    local force_no_labels_3f = _arg_205_["force-no-labels?"]
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
    local _207_
    local function _208_()
      if dot_repeatable_op_3f then
        set_dot_repeat()
      else
      end
      do
      end
      local function _211_()
        if _3ftarget_windows then
          local _210_ = _3ftarget_windows
          table.insert(_210_, source_window)
          return _210_
        else
          return nil
        end
      end
      hl:cleanup(_211_())
      exec_user_autocmds("LeapLeave")
      return nil
    end
    _207_ = (get_input() or _208_())
    if (nil ~= _207_) then
      local input = _207_
      if ((input == spec_keys.next_match) or (input == spec_keys.prev_match)) then
        local new_idx
        do
          local _212_ = input
          if (_212_ == spec_keys.next_match) then
            new_idx = min(inc(idx), #targets)
          elseif (_212_ == spec_keys.prev_match) then
            new_idx = max(dec(idx), 1)
          else
            new_idx = nil
          end
        end
        update_state({["repeat"] = {in1 = state["repeat"].in1, in2 = targets[new_idx].pair[2]}})
        jump_to_21(targets[new_idx])
        return traverse(targets, new_idx, {["force-no-labels?"] = force_no_labels_3f})
      else
        local _214_ = get_target_with_active_primary_label(targets, input)
        if ((_G.type(_214_) == "table") and true and (nil ~= (_214_)[2])) then
          local _ = (_214_)[1]
          local target = (_214_)[2]
          if dot_repeatable_op_3f then
            set_dot_repeat()
          else
          end
          do
            jump_to_21(target)
          end
          local function _217_()
            if _3ftarget_windows then
              local _216_ = _3ftarget_windows
              table.insert(_216_, source_window)
              return _216_
            else
              return nil
            end
          end
          hl:cleanup(_217_())
          exec_user_autocmds("LeapLeave")
          return nil
        elseif true then
          local _ = _214_
          if dot_repeatable_op_3f then
            set_dot_repeat()
          else
          end
          do
            vim.fn.feedkeys(input, "i")
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
    local _224_
    local function _225_()
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      do
      end
      local function _228_()
        if _3ftarget_windows then
          local _227_ = _3ftarget_windows
          table.insert(_227_, source_window)
          return _227_
        else
          return nil
        end
      end
      hl:cleanup(_228_())
      exec_user_autocmds("LeapLeave")
      return nil
    end
    _224_ = (get_input() or _225_())
    if (_224_ == spec_keys.repeat_search) then
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
        local function _231_()
          if _3ftarget_windows then
            local _230_ = _3ftarget_windows
            table.insert(_230_, source_window)
            return _230_
          else
            return nil
          end
        end
        hl:cleanup(_231_())
        exec_user_autocmds("LeapLeave")
        return nil
      end
    elseif (nil ~= _224_) then
      local in1 = _224_
      return in1
    else
      return nil
    end
  end
  local function get_second_pattern_input(targets)
    do
      local _234_ = targets
      set_initial_label_states(_234_)
      set_beacons(_234_, {})
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
    local function _235_()
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      do
      end
      local function _238_()
        if _3ftarget_windows then
          local _237_ = _3ftarget_windows
          table.insert(_237_, source_window)
          return _237_
        else
          return nil
        end
      end
      hl:cleanup(_238_())
      exec_user_autocmds("LeapLeave")
      return nil
    end
    return (get_input() or _235_())
  end
  local function post_pattern_input_loop(sublist)
    local function loop(group_offset, initial_invoc_3f)
      do
        local _239_ = sublist
        set_label_states(_239_, {["group-offset"] = group_offset})
        set_beacons(_239_, {})
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
      local _240_
      local function _241_()
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
        end
        local function _244_()
          if _3ftarget_windows then
            local _243_ = _3ftarget_windows
            table.insert(_243_, source_window)
            return _243_
          else
            return nil
          end
        end
        hl:cleanup(_244_())
        exec_user_autocmds("LeapLeave")
        return nil
      end
      _240_ = (get_input() or _241_())
      if (nil ~= _240_) then
        local input = _240_
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
  local function _248_(...)
    local _249_, _250_ = ...
    if ((nil ~= _249_) and true) then
      local in1 = _249_
      local _3fin2 = _250_
      local function _251_(...)
        local _252_ = ...
        if (nil ~= _252_) then
          local targets = _252_
          local function _253_(...)
            local _254_ = ...
            if (nil ~= _254_) then
              local in2 = _254_
              if dot_repeat_3f then
                local _255_ = targets[state["dot-repeat"]["target-idx"]]
                if (nil ~= _255_) then
                  local target = _255_
                  if dot_repeatable_op_3f then
                    set_dot_repeat()
                  else
                  end
                  do
                    jump_to_21(target)
                  end
                  local function _258_(...)
                    if _3ftarget_windows then
                      local _257_ = _3ftarget_windows
                      table.insert(_257_, source_window)
                      return _257_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_258_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                elseif true then
                  local _ = _255_
                  if change_op_3f then
                    handle_interrupted_change_op_21()
                  else
                  end
                  do
                  end
                  local function _261_(...)
                    if _3ftarget_windows then
                      local _260_ = _3ftarget_windows
                      table.insert(_260_, source_window)
                      return _260_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_261_(...))
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
                  return traverse(targets, 1, {["force-no-labels?"] = true})
                end
              else
                update_state({["repeat"] = {in1 = in1, in2 = in2}})
                local update_dot_repeat_state
                local function _267_(_241)
                  return update_state({["dot-repeat"] = {in1 = in1, in2 = in2, ["target-idx"] = _241}})
                end
                update_dot_repeat_state = _267_
                local _268_
                local function _269_(...)
                  if change_op_3f then
                    handle_interrupted_change_op_21()
                  else
                  end
                  do
                    echo_not_found((in1 .. in2))
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
                end
                _268_ = (targets.sublists[in2] or _269_(...))
                if ((_G.type(_268_) == "table") and (nil ~= (_268_)[1]) and ((_268_)[2] == nil)) then
                  local only = (_268_)[1]
                  if dot_repeatable_op_3f then
                    set_dot_repeat()
                  else
                  end
                  do
                    update_dot_repeat_state(1)
                    jump_to_21(only)
                  end
                  local function _275_(...)
                    if _3ftarget_windows then
                      local _274_ = _3ftarget_windows
                      table.insert(_274_, source_window)
                      return _274_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_275_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                elseif (nil ~= _268_) then
                  local sublist = _268_
                  if sublist["autojump?"] then
                    jump_to_21(sublist[1])
                  else
                  end
                  local _277_ = post_pattern_input_loop(sublist)
                  if (nil ~= _277_) then
                    local in_final = _277_
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
                        local function _281_(...)
                          if _3ftarget_windows then
                            local _280_ = _3ftarget_windows
                            table.insert(_280_, source_window)
                            return _280_
                          else
                            return nil
                          end
                        end
                        hl:cleanup(_281_(...))
                        exec_user_autocmds("LeapLeave")
                        return nil
                      else
                        return traverse(sublist, new_idx, {["force-no-labels?"] = not sublist["autojump?"]})
                      end
                    else
                      local _283_ = get_target_with_active_primary_label(sublist, in_final)
                      if ((_G.type(_283_) == "table") and (nil ~= (_283_)[1]) and (nil ~= (_283_)[2])) then
                        local idx = (_283_)[1]
                        local target = (_283_)[2]
                        if dot_repeatable_op_3f then
                          set_dot_repeat()
                        else
                        end
                        do
                          update_dot_repeat_state(idx)
                          jump_to_21(target)
                        end
                        local function _286_(...)
                          if _3ftarget_windows then
                            local _285_ = _3ftarget_windows
                            table.insert(_285_, source_window)
                            return _285_
                          else
                            return nil
                          end
                        end
                        hl:cleanup(_286_(...))
                        exec_user_autocmds("LeapLeave")
                        return nil
                      elseif true then
                        local _ = _283_
                        if sublist["autojump?"] then
                          if dot_repeatable_op_3f then
                            set_dot_repeat()
                          else
                          end
                          do
                            vim.fn.feedkeys(in_final, "i")
                          end
                          local function _289_(...)
                            if _3ftarget_windows then
                              local _288_ = _3ftarget_windows
                              table.insert(_288_, source_window)
                              return _288_
                            else
                              return nil
                            end
                          end
                          hl:cleanup(_289_(...))
                          exec_user_autocmds("LeapLeave")
                          return nil
                        else
                          if change_op_3f then
                            handle_interrupted_change_op_21()
                          else
                          end
                          do
                          end
                          local function _292_(...)
                            if _3ftarget_windows then
                              local _291_ = _3ftarget_windows
                              table.insert(_291_, source_window)
                              return _291_
                            else
                              return nil
                            end
                          end
                          hl:cleanup(_292_(...))
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
              local __60_auto = _254_
              return ...
            else
              return nil
            end
          end
          local function _300_(...)
            do
              local _301_ = targets
              populate_sublists(_301_)
              set_sublist_attributes(_301_, {["force-no-autojump?"] = force_no_autojump_3f})
              set_labels(_301_)
            end
            return (_3fin2 or get_second_pattern_input(targets))
          end
          return _253_(_300_(...))
        elseif true then
          local __60_auto = _252_
          return ...
        else
          return nil
        end
      end
      local function _303_(...)
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
          echo_not_found((in1 .. (_3fin2 or "")))
        end
        local function _306_(...)
          if _3ftarget_windows then
            local _305_ = _3ftarget_windows
            table.insert(_305_, source_window)
            return _305_
          else
            return nil
          end
        end
        hl:cleanup(_306_(...))
        exec_user_autocmds("LeapLeave")
        return nil
      end
      return _251_((get_targets(prepare_pattern(in1, _3fin2), {["reverse?"] = reverse_3f, ["target-windows"] = _3ftarget_windows}) or _303_(...)))
    elseif true then
      local __60_auto = _249_
      return ...
    else
      return nil
    end
  end
  local function _308_()
    if dot_repeat_3f then
      return state["dot-repeat"].in1, state["dot-repeat"].in2
    else
      return get_first_pattern_input()
    end
  end
  return _248_(_308_())
end
local function set_default_keymaps(force_3f)
  for _, _309_ in ipairs({{"n", "s", "<Plug>(leap-forward)"}, {"n", "S", "<Plug>(leap-backward)"}, {"x", "s", "<Plug>(leap-forward)"}, {"x", "S", "<Plug>(leap-backward)"}, {"o", "z", "<Plug>(leap-forward)"}, {"o", "Z", "<Plug>(leap-backward)"}, {"o", "x", "<Plug>(leap-forward-x)"}, {"o", "X", "<Plug>(leap-backward-x)"}, {"n", "gs", "<Plug>(leap-cross-window)"}, {"x", "gs", "<Plug>(leap-cross-window)"}, {"o", "gs", "<Plug>(leap-cross-window)"}}) do
    local _each_310_ = _309_
    local mode = _each_310_[1]
    local lhs = _each_310_[2]
    local rhs = _each_310_[3]
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
    local _let_312_ = vim.split(opt, ".", true)
    local _0 = _let_312_[1]
    local scope = _let_312_[2]
    local name = _let_312_[3]
    saved_editor_opts[opt] = _G.vim[scope][name]
  end
  return nil
end
local function set_editor_opts(opts0)
  for opt, val in pairs(opts0) do
    local _let_313_ = vim.split(opt, ".", true)
    local _ = _let_313_[1]
    local scope = _let_313_[2]
    local name = _let_313_[3]
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
local function _314_()
  return init_highlight()
end
api.nvim_create_autocmd("ColorScheme", {callback = _314_, group = "LeapDefault"})
local function _315_()
  save_editor_opts()
  return set_temporary_editor_opts()
end
api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _315_, group = "LeapDefault"})
api.nvim_create_autocmd("User", {pattern = "LeapLeave", callback = restore_editor_opts, group = "LeapDefault"})
return {opts = opts, setup = setup, state = state, leap = leap, init_highlight = init_highlight, set_default_keymaps = set_default_keymaps}
