local api = vim.api
local empty_3f = vim.tbl_isempty
local map = vim.tbl_map
local _local_1_ = math
local abs = _local_1_["abs"]
local ceil = _local_1_["ceil"]
local max = _local_1_["max"]
local min = _local_1_["min"]
local pow = _local_1_["pow"]
local function clamp(val, min0, max0)
  if (val < min0) then
    return min0
  elseif (val > max0) then
    return max0
  elseif "else" then
    return val
  else
    return nil
  end
end
local function inc(x)
  return (x + 1)
end
local function dec(x)
  return (x - 1)
end
local function echo(msg)
  vim.cmd("redraw")
  return api.nvim_echo({{msg}}, false, {})
end
local function replace_keycodes(s)
  return api.nvim_replace_termcodes(s, true, false, true)
end
local _3cctrl_v_3e = replace_keycodes("<c-v>")
local _3cesc_3e = replace_keycodes("<esc>")
local function get_motion_force(mode)
  local _3_
  if mode:match("o") then
    _3_ = mode:sub(-1)
  else
    _3_ = nil
  end
  if (nil ~= _3_) then
    local last_ch = _3_
    if ((last_ch == _3cctrl_v_3e) or (last_ch == "V") or (last_ch == "v")) then
      return last_ch
    else
      return nil
    end
  else
    return nil
  end
end
local function get_cursor_pos()
  return {vim.fn.line("."), vim.fn.col(".")}
end
local function char_at_pos(_7_, _9_)
  local _arg_8_ = _7_
  local line = _arg_8_[1]
  local byte_col = _arg_8_[2]
  local _arg_10_ = _9_
  local char_offset = _arg_10_["char-offset"]
  local line_str = vim.fn.getline(line)
  local char_idx = vim.fn.charidx(line_str, dec(byte_col))
  local char_nr = vim.fn.strgetchar(line_str, (char_idx + (char_offset or 0)))
  if (char_nr ~= -1) then
    return vim.fn.nr2char(char_nr)
  else
    return nil
  end
end
local function get_fold_edge(lnum, reverse_3f)
  local _12_
  local _13_
  if reverse_3f then
    _13_ = vim.fn.foldclosed
  else
    _13_ = vim.fn.foldclosedend
  end
  _12_ = _13_(lnum)
  if (_12_ == -1) then
    return nil
  elseif (nil ~= _12_) then
    local fold_edge = _12_
    return fold_edge
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
local function _16_(self, _3ftarget_windows)
  if _3ftarget_windows then
    for _, w in ipairs(_3ftarget_windows) do
      api.nvim_buf_clear_namespace(w.bufnr, self.ns, dec(w.topline), w.botline)
    end
  else
  end
  return api.nvim_buf_clear_namespace(0, self.ns, dec(vim.fn.line("w0")), vim.fn.line("w$"))
end
hl = {group = {["label-primary"] = "LeapLabelPrimary", ["label-secondary"] = "LeapLabelSecondary", match = "LeapMatch", backdrop = "LeapBackdrop"}, priority = {label = 65535, cursor = 65534, backdrop = 65533}, ns = api.nvim_create_namespace(""), cleanup = _16_}
local function init_highlight(force_3f)
  local bg = vim.o.background
  local def_maps
  local _19_
  do
    local _18_ = bg
    if (_18_ == "light") then
      _19_ = "#222222"
    elseif true then
      local _ = _18_
      _19_ = "#ccff88"
    else
      _19_ = nil
    end
  end
  local _24_
  do
    local _23_ = bg
    if (_23_ == "light") then
      _24_ = "#ff8877"
    elseif true then
      local _ = _23_
      _24_ = "#ccff88"
    else
      _24_ = nil
    end
  end
  local _29_
  do
    local _28_ = bg
    if (_28_ == "light") then
      _29_ = "#77aaff"
    elseif true then
      local _ = _28_
      _29_ = "#99ccff"
    else
      _29_ = nil
    end
  end
  def_maps = {[hl.group.match] = {fg = _19_, ctermfg = "red", underline = true, nocombine = true}, [hl.group["label-primary"]] = {fg = "black", bg = _24_, ctermfg = "black", ctermbg = "red", nocombine = true}, [hl.group["label-secondary"]] = {fg = "black", bg = _29_, ctermfg = "black", ctermbg = "blue", nocombine = true}}
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
    local _let_34_ = map(dec, get_cursor_pos())
    local curline = _let_34_[1]
    local curcol = _let_34_[2]
    local _let_35_ = {dec(vim.fn.line("w0")), dec(vim.fn.line("w$"))}
    local win_top = _let_35_[1]
    local win_bot = _let_35_[2]
    local function _37_()
      if reverse_3f then
        return {{win_top, 0}, {curline, curcol}}
      else
        return {{curline, inc(curcol)}, {win_bot, -1}}
      end
    end
    local _let_36_ = _37_()
    local start = _let_36_[1]
    local finish = _let_36_[2]
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
  local function _40_()
    local _39_ = direction
    if (_39_ == "fwd") then
      return "W"
    elseif (_39_ == "bwd") then
      return "bW"
    else
      return nil
    end
  end
  return vim.fn.search("\\_.", _40_())
end
local function force_matchparen_refresh()
  pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchparen"})
  return pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchup_matchparen"})
end
local function cursor_before_eof_3f()
  return ((vim.fn.line(".") == vim.fn.line("$")) and (vim.fn.virtcol(".") == dec(vim.fn.virtcol("$"))))
end
local function create_restore_virtualedit_autocmd(saved_val)
  local function _42_()
    vim.o.virtualedit = saved_val
    return nil
  end
  return api.nvim_create_autocmd({"CursorMoved", "WinLeave", "BufLeave", "InsertEnter", "CmdlineEnter", "CmdwinEnter"}, {callback = _42_, once = true})
end
local function adjust_inclusive(motion_force)
  local _43_ = motion_force
  if (_43_ == nil) then
    if cursor_before_eof_3f() then
      local virtualedit_saved = vim.o.virtualedit
      vim.o.virtualedit = "onemore"
      vim.cmd("norm! l")
      return create_restore_virtualedit_autocmd(virtualedit_saved)
    else
      return push_cursor_21("fwd")
    end
  elseif (_43_ == "v") then
    return push_cursor_21("bwd")
  elseif (_43_ == "V") then
    return nil
  elseif (_43_ == _3cctrl_v_3e) then
    return nil
  else
    return nil
  end
end
local function jump_to_21_2a(target, _46_)
  local _arg_47_ = _46_
  local mode = _arg_47_["mode"]
  local reverse_3f = _arg_47_["reverse?"]
  local inclusive_op_3f = _arg_47_["inclusive-op?"]
  local add_to_jumplist_3f = _arg_47_["add-to-jumplist?"]
  local adjust = _arg_47_["adjust"]
  local op_mode_3f = mode:match("o")
  if add_to_jumplist_3f then
    vim.cmd("norm! m`")
  else
  end
  vim.fn.cursor(target)
  adjust()
  if not op_mode_3f then
    force_matchparen_refresh()
  else
  end
  if (op_mode_3f and inclusive_op_3f and not reverse_3f) then
    return adjust_inclusive(get_motion_force(mode))
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
  echo("")
  local curcol = vim.fn.col(".")
  local endcol = vim.fn.col("$")
  local _3fright
  if (not vim.o.insertmode and (curcol > 1) and (curcol < endcol)) then
    _3fright = "<RIGHT>"
  else
    _3fright = ""
  end
  return api.nvim_feedkeys(replace_keycodes(("<C-\\><C-G>" .. _3fright)), "n", true)
end
local function exec_autocmds(pattern)
  return api.nvim_exec_autocmds("User", {pattern = pattern, modeline = false})
end
local function get_input()
  local _53_, _54_ = pcall(vim.fn.getcharstr)
  local function _55_()
    local ch = _54_
    return (ch ~= _3cesc_3e)
  end
  if (((_53_ == true) and (nil ~= _54_)) and _55_()) then
    local ch = _54_
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
  local function _58_(_241)
    return (vim.fn.getwininfo(_241))[1]
  end
  get_wininfo = _58_
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
local function get_match_positions(pattern, _61_)
  local _arg_62_ = _61_
  local reverse_3f = _arg_62_["reverse?"]
  local whole_window_3f = _arg_62_["whole-window?"]
  local source_winid = _arg_62_["source-winid"]
  local _arg_63_ = _arg_62_["bounds"]
  local left_bound = _arg_63_[1]
  local right_bound = _arg_63_[2]
  local reverse_3f0
  if whole_window_3f then
    reverse_3f0 = false
  else
    reverse_3f0 = reverse_3f
  end
  local curr_winid = vim.fn.win_getid()
  local view = vim.fn.winsaveview()
  local cpo = vim.o.cpo
  local opts0
  if reverse_3f0 then
    opts0 = "b"
  else
    opts0 = ""
  end
  local wintop = vim.fn.line("w0")
  local winbot = vim.fn.line("w$")
  local stopline
  if reverse_3f0 then
    stopline = wintop
  else
    stopline = winbot
  end
  local cleanup
  local function _67_()
    vim.fn.winrestview(view)
    vim.o.cpo = cpo
    return nil
  end
  cleanup = _67_
  local function reach_right_bound()
    while ((vim.fn.virtcol(".") < right_bound) and not (vim.fn.col(".") >= dec(vim.fn.col("$")))) do
      vim.cmd("norm! l")
    end
    return nil
  end
  local function skip_to_fold_edge_21()
    local _68_
    local _69_
    if reverse_3f0 then
      _69_ = vim.fn.foldclosed
    else
      _69_ = vim.fn.foldclosedend
    end
    _68_ = _69_(vim.fn.line("."))
    if (_68_ == -1) then
      return "not-in-fold"
    elseif (nil ~= _68_) then
      local fold_edge = _68_
      vim.fn.cursor(fold_edge, 0)
      local function _71_()
        if reverse_3f0 then
          return 1
        else
          return vim.fn.col("$")
        end
      end
      vim.fn.cursor(0, _71_())
      return "moved-the-cursor"
    else
      return nil
    end
  end
  local function skip_to_next_in_window_pos_21()
    local _local_73_ = {vim.fn.line("."), vim.fn.virtcol(".")}
    local line = _local_73_[1]
    local virtcol = _local_73_[2]
    local from_pos = _local_73_
    local _74_
    if (virtcol < left_bound) then
      if reverse_3f0 then
        if (dec(line) >= stopline) then
          _74_ = {dec(line), right_bound}
        else
          _74_ = nil
        end
      else
        _74_ = {line, left_bound}
      end
    elseif (virtcol > right_bound) then
      if reverse_3f0 then
        _74_ = {line, right_bound}
      else
        if (inc(line) <= stopline) then
          _74_ = {inc(line), left_bound}
        else
          _74_ = nil
        end
      end
    else
      _74_ = nil
    end
    if (nil ~= _74_) then
      local to_pos = _74_
      if (from_pos ~= to_pos) then
        vim.fn.cursor(to_pos)
        if reverse_3f0 then
          reach_right_bound()
        else
        end
        return "moved-the-cursor"
      else
        return nil
      end
    else
      return nil
    end
  end
  vim.o.cpo = cpo:gsub("c", "")
  local win_enter_3f = nil
  local match_count = 0
  local orig_curpos = get_cursor_pos()
  if whole_window_3f then
    win_enter_3f = true
    vim.fn.cursor({wintop, left_bound})
  else
  end
  local function recur(match_at_curpos_3f)
    local match_at_curpos_3f0
    local function _84_()
      if win_enter_3f then
        win_enter_3f = false
        return true
      else
        return nil
      end
    end
    match_at_curpos_3f0 = (match_at_curpos_3f or _84_())
    local _86_
    local function _87_()
      if match_at_curpos_3f0 then
        return "c"
      else
        return ""
      end
    end
    _86_ = vim.fn.searchpos(pattern, (opts0 .. _87_()), stopline)
    if ((_G.type(_86_) == "table") and ((_86_)[1] == 0) and true) then
      local _ = (_86_)[2]
      return cleanup()
    elseif ((_G.type(_86_) == "table") and (nil ~= (_86_)[1]) and (nil ~= (_86_)[2])) then
      local line = (_86_)[1]
      local col = (_86_)[2]
      local pos = _86_
      local _88_ = skip_to_fold_edge_21()
      if (_88_ == "moved-the-cursor") then
        return recur(false)
      elseif (_88_ == "not-in-fold") then
        if ((curr_winid == source_winid) and (view.lnum == line) and (inc(view.col) == col)) then
          push_cursor_21("fwd")
          return recur(true)
        elseif ((function(_89_,_90_,_91_) return (_89_ <= _90_) and (_90_ <= _91_) end)(left_bound,col,right_bound) or vim.wo.wrap) then
          match_count = (match_count + 1)
          return pos
        else
          local _92_ = skip_to_next_in_window_pos_21()
          if (_92_ == "moved-the-cursor") then
            return recur(true)
          elseif true then
            local _ = _92_
            return cleanup()
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
  return recur
end
local function get_targets_2a(input, _97_)
  local _arg_98_ = _97_
  local reverse_3f = _arg_98_["reverse?"]
  local wininfo = _arg_98_["wininfo"]
  local targets = _arg_98_["targets"]
  local source_winid = _arg_98_["source-winid"]
  local targets0 = (targets or {})
  local prev_match = {}
  local _let_99_ = get_horizontal_bounds()
  local _ = _let_99_[1]
  local right_bound = _let_99_[2]
  local bounds = _let_99_
  local pattern
  local function _100_()
    if opts.case_insensitive then
      return "\\c"
    else
      return "\\C"
    end
  end
  pattern = ("\\V" .. _100_() .. input:gsub("\\", "\\\\") .. "\\_.")
  for _101_ in get_match_positions(pattern, {bounds = bounds, ["reverse?"] = reverse_3f, ["source-winid"] = source_winid, ["whole-window?"] = wininfo}) do
    local _each_102_ = _101_
    local line = _each_102_[1]
    local col = _each_102_[2]
    local pos = _each_102_
    local ch1 = char_at_pos(pos, {})
    local ch2, eol_3f = nil, nil
    do
      local _103_ = char_at_pos(pos, {["char-offset"] = 1})
      if (nil ~= _103_) then
        local char = _103_
        ch2, eol_3f = char
      elseif true then
        local _0 = _103_
        ch2, eol_3f = replace_keycodes(opts.special_keys.eol), true
      else
        ch2, eol_3f = nil
      end
    end
    local same_char_triplet_3f
    local _105_
    if reverse_3f then
      _105_ = dec
    else
      _105_ = inc
    end
    same_char_triplet_3f = ((ch2 == prev_match.ch2) and (line == prev_match.line) and (col == _105_(prev_match.col)))
    prev_match = {line = line, col = col, ch2 = ch2}
    if not same_char_triplet_3f then
      table.insert(targets0, {pos = pos, pair = {ch1, ch2}, wininfo = wininfo, ["edge-pos?"] = (eol_3f or (col == right_bound))})
    else
    end
  end
  if next(targets0) then
    return targets0
  else
    return nil
  end
end
local function distance(_109_, _111_)
  local _arg_110_ = _109_
  local l1 = _arg_110_[1]
  local c1 = _arg_110_[2]
  local _arg_112_ = _111_
  local l2 = _arg_112_[1]
  local c2 = _arg_112_[2]
  local editor_grid_aspect_ratio = 0.3
  local _let_113_ = {abs((c1 - c2)), abs((l1 - l2))}
  local dx = _let_113_[1]
  local dy = _let_113_[2]
  local dx0 = (dx * editor_grid_aspect_ratio)
  return pow((pow(dx0, 2) + pow(dy, 2)), 0.5)
end
local function get_targets(input, _114_)
  local _arg_115_ = _114_
  local reverse_3f = _arg_115_["reverse?"]
  local target_windows = _arg_115_["target-windows"]
  if target_windows then
    local targets = {}
    local cursor_positions = {}
    local cross_win_3f = not ((#target_windows == 1) and (target_windows[1].winid == vim.fn.win_getid()))
    local source_winid = vim.fn.win_getid()
    for _, w in ipairs(target_windows) do
      if cross_win_3f then
        api.nvim_set_current_win(w.winid)
      else
      end
      cursor_positions[w.winid] = get_cursor_pos()
      get_targets_2a(input, {wininfo = w, ["source-winid"] = source_winid, targets = targets})
    end
    if cross_win_3f then
      api.nvim_set_current_win(source_winid)
    else
    end
    if not empty_3f(targets) then
      local by_screen_pos_3f = (vim.o.wrap and (#targets < 200))
      if by_screen_pos_3f then
        for winid, _118_ in pairs(cursor_positions) do
          local _each_119_ = _118_
          local line = _each_119_[1]
          local col = _each_119_[2]
          local _120_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_120_) == "table") and ((_120_).col == col) and (nil ~= (_120_).row)) then
            local row = (_120_).row
            cursor_positions[winid] = {row, col}
          else
          end
        end
      else
      end
      for _, _123_ in ipairs(targets) do
        local _each_124_ = _123_
        local _each_125_ = _each_124_["pos"]
        local line = _each_125_[1]
        local col = _each_125_[2]
        local _each_126_ = _each_124_["wininfo"]
        local winid = _each_126_["winid"]
        local t = _each_124_
        if by_screen_pos_3f then
          local _127_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_127_) == "table") and ((_127_).col == col) and (nil ~= (_127_).row)) then
            local row = (_127_).row
            t["screenpos"] = {row, col}
          else
          end
        else
        end
        t["rank"] = distance((t.screenpos or t.pos), cursor_positions[winid])
      end
      local function _130_(_241, _242)
        return ((_241).rank < (_242).rank)
      end
      table.sort(targets, _130_)
      return targets
    else
      return nil
    end
  else
    return get_targets_2a(input, {["reverse?"] = reverse_3f})
  end
end
local function populate_sublists(targets)
  targets["sublists"] = {}
  if opts.case_insensitive then
    local function _133_(t, k)
      return rawget(t, k:lower())
    end
    local function _134_(t, k, v)
      return rawset(t, k:lower(), v)
    end
    setmetatable(targets.sublists, {__index = _133_, __newindex = _134_})
  else
  end
  for _, _136_ in ipairs(targets) do
    local _each_137_ = _136_
    local _each_138_ = _each_137_["pair"]
    local _0 = _each_138_[1]
    local ch2 = _each_138_[2]
    local target = _each_137_
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
  local _140_
  if user_forced_autojump_3f() then
    _140_ = opts.safe_labels
  elseif user_forced_no_autojump_3f() then
    _140_ = opts.labels
  elseif sublist["autojump?"] then
    _140_ = opts.safe_labels
  else
    _140_ = opts.labels
  end
  sublist["label-set"] = _140_
  return nil
end
local function set_sublist_attributes(targets, _142_)
  local _arg_143_ = _142_
  local force_no_autojump_3f = _arg_143_["force-no-autojump?"]
  for _, sublist in pairs(targets.sublists) do
    set_autojump(sublist, force_no_autojump_3f)
    attach_label_set(sublist)
  end
  return nil
end
local function set_labels(targets)
  for _, sublist in pairs(targets.sublists) do
    if (#sublist > 1) then
      for i, target in ipairs(sublist) do
        local i0
        if sublist["autojump?"] then
          i0 = dec(i)
        else
          i0 = i
        end
        if (i0 > 0) then
          local labels0 = sublist["label-set"]
          local _146_
          do
            local _145_ = (i0 % #labels0)
            if (_145_ == 0) then
              _146_ = (labels0)[#labels0]
            elseif (nil ~= _145_) then
              local n = _145_
              _146_ = (labels0)[n]
            else
              _146_ = nil
            end
          end
          target["label"] = _146_
        else
        end
      end
    else
    end
  end
  return nil
end
local function set_label_states(sublist, _152_)
  local _arg_153_ = _152_
  local group_offset = _arg_153_["group-offset"]
  local labels0 = sublist["label-set"]
  local _7clabels_7c = #labels0
  local offset = (group_offset * _7clabels_7c)
  local primary_start
  local function _154_()
    if sublist["autojump?"] then
      return 2
    else
      return 1
    end
  end
  primary_start = (offset + _154_())
  local primary_end = (primary_start + dec(_7clabels_7c))
  local secondary_start = inc(primary_end)
  local secondary_end = (primary_end + _7clabels_7c)
  for i, target in ipairs(sublist) do
    if target.label then
      local _155_
      if (function(_156_,_157_,_158_) return (_156_ <= _157_) and (_157_ <= _158_) end)(primary_start,i,primary_end) then
        _155_ = "active-primary"
      elseif (function(_159_,_160_,_161_) return (_159_ <= _160_) and (_160_ <= _161_) end)(secondary_start,i,secondary_end) then
        _155_ = "active-secondary"
      elseif (i > secondary_end) then
        _155_ = "inactive"
      else
        _155_ = nil
      end
      target["label-state"] = _155_
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
local function set_beacon_for_labeled(_164_)
  local _arg_165_ = _164_
  local label_state = _arg_165_["label-state"]
  local target = _arg_165_
  if label_state then
    local _let_166_ = target
    local _let_167_ = _let_166_["pair"]
    local ch1 = _let_167_[1]
    local ch2 = _let_167_[2]
    local edge_pos_3f = _let_166_["edge-pos?"]
    local label = _let_166_["label"]
    local offset
    local function _168_()
      if edge_pos_3f then
        return 0
      else
        return ch2:len()
      end
    end
    offset = (ch1:len() + _168_())
    local virttext
    do
      local _169_ = label_state
      if (_169_ == "active-primary") then
        virttext = {{label, hl.group["label-primary"]}}
      elseif (_169_ == "active-secondary") then
        virttext = {{label, hl.group["label-secondary"]}}
      elseif (_169_ == "inactive") then
        virttext = {{" ", hl.group["label-secondary"]}}
      else
        virttext = nil
      end
    end
    target["beacon"] = {offset, virttext}
    return nil
  else
    return nil
  end
end
local function set_beacon_to_match_hl(target)
  local _let_172_ = target
  local _let_173_ = _let_172_["pair"]
  local ch1 = _let_173_[1]
  local ch2 = _let_173_[2]
  target["beacon"] = {0, {{(ch1 .. ch2), hl.group.match}}}
  return nil
end
local function resolve_conflicts(target_list)
  local unlabeled_match_positions = {}
  local label_positions = {}
  for i, target in ipairs(target_list) do
    local _let_174_ = target
    local _let_175_ = _let_174_["pos"]
    local lnum = _let_175_[1]
    local col = _let_175_[2]
    local _let_176_ = _let_174_["pair"]
    local ch1 = _let_176_[1]
    local _ = _let_176_[2]
    local bufnr
    local function _177_()
      local t_178_ = target.wininfo
      if (nil ~= t_178_) then
        t_178_ = (t_178_).bufnr
      else
      end
      return t_178_
    end
    bufnr = (_177_() or 0)
    local winid
    local function _180_()
      local t_181_ = target.wininfo
      if (nil ~= t_181_) then
        t_181_ = (t_181_).winid
      else
      end
      return t_181_
    end
    winid = (_180_() or 0)
    local _183_ = target.beacon
    if (_183_ == nil) then
      local keys = {(bufnr .. " " .. winid .. " " .. lnum .. " " .. col), (bufnr .. " " .. winid .. " " .. lnum .. " " .. (col + ch1:len()))}
      for _0, k in ipairs(keys) do
        do
          local _184_ = label_positions[k]
          if (nil ~= _184_) then
            local other = _184_
            other["beacon"] = nil
            set_beacon_to_match_hl(target)
          else
          end
        end
        unlabeled_match_positions[k] = target
      end
    elseif ((_G.type(_183_) == "table") and (nil ~= (_183_)[1]) and true) then
      local offset = (_183_)[1]
      local _0 = (_183_)[2]
      local set_empty_label
      local function _186_(_241)
        _241["beacon"][2][1][1] = " "
        return nil
      end
      set_empty_label = _186_
      local k = (bufnr .. " " .. winid .. " " .. lnum .. " " .. (col + offset))
      do
        local _187_ = unlabeled_match_positions[k]
        if (nil ~= _187_) then
          local other = _187_
          target["beacon"] = nil
          set_beacon_to_match_hl(other)
        elseif true then
          local _1 = _187_
          local _188_ = label_positions[k]
          if (nil ~= _188_) then
            local other = _188_
            target["beacon"] = nil
            set_empty_label(other)
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
local function set_beacons(target_list, _192_)
  local _arg_193_ = _192_
  local force_no_labels_3f = _arg_193_["force-no-labels?"]
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
local function light_up_beacons(target_list, _3fstart_from)
  for i = (_3fstart_from or 1), #target_list do
    local target = target_list[i]
    local _195_ = target.beacon
    if ((_G.type(_195_) == "table") and (nil ~= (_195_)[1]) and (nil ~= (_195_)[2])) then
      local offset = (_195_)[1]
      local virttext = (_195_)[2]
      local _let_196_ = map(dec, target.pos)
      local lnum = _let_196_[1]
      local col = _let_196_[2]
      local bufnr
      local function _197_()
        local t_198_ = target.wininfo
        if (nil ~= t_198_) then
          t_198_ = (t_198_).bufnr
        else
        end
        return t_198_
      end
      bufnr = (_197_() or 0)
      api.nvim_buf_set_extmark(bufnr, hl.ns, lnum, (col + offset), {virt_text = virttext, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.label})
    else
    end
  end
  return nil
end
local state = {["repeat"] = {in1 = nil, in2 = nil}, ["dot-repeat"] = {in1 = nil, in2 = nil, ["reverse?"] = nil, ["x-mode?"] = nil, ["target-idx"] = nil}}
local function leap(_201_)
  local _arg_202_ = _201_
  local reverse_3f = _arg_202_["reverse?"]
  local x_mode_3f = _arg_202_["x-mode?"]
  local dot_repeat_3f = _arg_202_["dot-repeat?"]
  local target_windows = _arg_202_["target-windows"]
  local reverse_3f0
  if dot_repeat_3f then
    reverse_3f0 = state["dot-repeat"]["reverse?"]
  else
    reverse_3f0 = reverse_3f
  end
  local x_mode_3f0
  if dot_repeat_3f then
    x_mode_3f0 = state["dot-repeat"]["x-mode?"]
  else
    x_mode_3f0 = x_mode_3f
  end
  local _3ftarget_windows
  do
    local _205_ = target_windows
    if (_G.type(_205_) == "table") then
      local t = _205_
      _3ftarget_windows = t
    elseif (_205_ == true) then
      _3ftarget_windows = get_other_windows_on_tabpage()
    else
      _3ftarget_windows = nil
    end
  end
  local bidirectional_3f = _3ftarget_windows
  local mode = api.nvim_get_mode().mode
  local op_mode_3f = mode:match("o")
  local change_op_3f = (op_mode_3f and (vim.v.operator == "c"))
  local dot_repeatable_op_3f = (op_mode_3f and not bidirectional_3f and (vim.v.operator ~= "y"))
  local force_no_autojump_3f = (op_mode_3f or bidirectional_3f)
  local spec_keys
  local function _207_(_, k)
    return replace_keycodes(opts.special_keys[k])
  end
  spec_keys = setmetatable({}, {__index = _207_})
  local function get_target_with_active_primary_label(sublist, input)
    local res = nil
    for idx, _208_ in ipairs(sublist) do
      local _each_209_ = _208_
      local label = _each_209_["label"]
      local label_state = _each_209_["label-state"]
      local target = _each_209_
      if (res or (label_state == "inactive")) then break end
      if ((label == input) and (label_state == "active-primary")) then
        res = {idx, target}
      else
      end
    end
    return res
  end
  local function update_state_2a(in1)
    local function _211_(t)
      if not dot_repeat_3f then
        do
          local _212_ = t
          if ((_G.type(_212_) == "table") and ((_G.type((_212_)["repeat"]) == "table") and (nil ~= ((_212_)["repeat"]).in2))) then
            local in2 = ((_212_)["repeat"]).in2
            state["repeat"] = {in1 = in1, in2 = in2}
          else
          end
        end
        if dot_repeatable_op_3f then
          local _214_ = t
          if ((_G.type(_214_) == "table") and ((_G.type((_214_)["dot-repeat"]) == "table") and (nil ~= ((_214_)["dot-repeat"]).in2) and (nil ~= ((_214_)["dot-repeat"])["target-idx"]))) then
            local in2 = ((_214_)["dot-repeat"]).in2
            local target_idx = ((_214_)["dot-repeat"])["target-idx"]
            state["dot-repeat"] = {in1 = in1, in2 = in2, ["target-idx"] = target_idx, ["reverse?"] = reverse_3f0, ["x-mode?"] = x_mode_3f0}
            return nil
          else
            return nil
          end
        else
          return nil
        end
      else
        return nil
      end
    end
    return _211_
  end
  local jump_to_21
  do
    local first_jump_3f = true
    local function _218_(target)
      if target.wininfo then
        api.nvim_set_current_win(target.wininfo.winid)
      else
      end
      local function _220_()
        if x_mode_3f0 then
          push_cursor_21("fwd")
          if reverse_3f0 then
            return push_cursor_21("fwd")
          else
            return nil
          end
        else
          return nil
        end
      end
      jump_to_21_2a(target.pos, {mode = mode, ["reverse?"] = reverse_3f0, ["inclusive-op?"] = (x_mode_3f0 and not reverse_3f0), ["add-to-jumplist?"] = first_jump_3f, adjust = _220_})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _218_
  end
  local function traverse(targets, idx, _223_)
    local _arg_224_ = _223_
    local force_no_labels_3f = _arg_224_["force-no-labels?"]
    if force_no_labels_3f then
      inactivate_labels(targets)
    else
    end
    set_beacons(targets, {["force-no-labels?"] = force_no_labels_3f})
    do
      apply_backdrop(reverse_3f0, _3ftarget_windows)
      do
        light_up_beacons(targets, inc(idx))
      end
      highlight_cursor()
      vim.cmd("redraw")
    end
    local _226_
    local function _227_()
      local res_2_auto
      do
        res_2_auto = get_input()
      end
      hl:cleanup(_3ftarget_windows)
      return res_2_auto
    end
    local function _228_()
      if dot_repeatable_op_3f then
        set_dot_repeat()
      else
      end
      do
      end
      exec_autocmds("LeapLeave")
      return nil
    end
    _226_ = (_227_() or _228_())
    if (nil ~= _226_) then
      local input = _226_
      if ((input == spec_keys.next_match) or (input == spec_keys.prev_match)) then
        local update_state = update_state_2a(state["repeat"].in1)
        local new_idx
        do
          local _230_ = input
          if (_230_ == spec_keys.next_match) then
            new_idx = min(inc(idx), #targets)
          elseif (_230_ == spec_keys.prev_match) then
            new_idx = max(dec(idx), 1)
          else
            new_idx = nil
          end
        end
        update_state({["repeat"] = {in2 = targets[new_idx].pair[2]}})
        jump_to_21(targets[new_idx])
        return traverse(targets, new_idx, {["force-no-labels?"] = force_no_labels_3f})
      else
        local _232_ = get_target_with_active_primary_label(targets, input)
        if ((_G.type(_232_) == "table") and true and (nil ~= (_232_)[2])) then
          local _ = (_232_)[1]
          local target = (_232_)[2]
          if dot_repeatable_op_3f then
            set_dot_repeat()
          else
          end
          do
            jump_to_21(target)
          end
          exec_autocmds("LeapLeave")
          return nil
        elseif true then
          local _ = _232_
          if dot_repeatable_op_3f then
            set_dot_repeat()
          else
          end
          do
            vim.fn.feedkeys(input, "i")
          end
          exec_autocmds("LeapLeave")
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
      apply_backdrop(reverse_3f0, _3ftarget_windows)
      do
        echo("")
      end
      highlight_cursor()
      vim.cmd("redraw")
    end
    local _238_
    local function _239_()
      local res_2_auto
      do
        res_2_auto = get_input()
      end
      hl:cleanup(_3ftarget_windows)
      return res_2_auto
    end
    local function _240_()
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      do
      end
      exec_autocmds("LeapLeave")
      return nil
    end
    _238_ = (_239_() or _240_())
    if (_238_ == spec_keys.repeat_search) then
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
        exec_autocmds("LeapLeave")
        return nil
      end
    elseif (nil ~= _238_) then
      local in1 = _238_
      return in1
    else
      return nil
    end
  end
  local function get_second_pattern_input(targets)
    do
      local _245_ = targets
      set_initial_label_states(_245_)
      set_beacons(_245_, {})
    end
    do
      apply_backdrop(reverse_3f0, _3ftarget_windows)
      do
        light_up_beacons(targets)
      end
      highlight_cursor()
      vim.cmd("redraw")
    end
    local function _246_()
      local res_2_auto
      do
        res_2_auto = get_input()
      end
      hl:cleanup(_3ftarget_windows)
      return res_2_auto
    end
    local function _247_()
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      do
      end
      exec_autocmds("LeapLeave")
      return nil
    end
    return (_246_() or _247_())
  end
  local function post_pattern_input_loop(sublist)
    local function loop(group_offset, initial_invoc_3f)
      do
        local _249_ = sublist
        set_label_states(_249_, {["group-offset"] = group_offset})
        set_beacons(_249_, {})
      end
      do
        apply_backdrop(reverse_3f0, _3ftarget_windows)
        do
          light_up_beacons(sublist)
        end
        highlight_cursor()
        vim.cmd("redraw")
      end
      local _250_
      local function _251_()
        local res_2_auto
        do
          res_2_auto = get_input()
        end
        hl:cleanup(_3ftarget_windows)
        return res_2_auto
      end
      local function _252_()
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
        end
        exec_autocmds("LeapLeave")
        return nil
      end
      _250_ = (_251_() or _252_())
      if (nil ~= _250_) then
        local input = _250_
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
  exec_autocmds("LeapEnter")
  local function _257_(...)
    local _258_, _259_ = ...
    if ((nil ~= _258_) and true) then
      local in1 = _258_
      local _3fin2 = _259_
      local function _260_(...)
        local _261_ = ...
        if (nil ~= _261_) then
          local targets = _261_
          local function _262_(...)
            local _263_ = ...
            if (nil ~= _263_) then
              local in2 = _263_
              local update_state = update_state_2a(in1)
              if dot_repeat_3f then
                local _264_ = targets[state["dot-repeat"]["target-idx"]]
                if (nil ~= _264_) then
                  local target = _264_
                  if dot_repeatable_op_3f then
                    set_dot_repeat()
                  else
                  end
                  do
                    jump_to_21(target)
                  end
                  exec_autocmds("LeapLeave")
                  return nil
                elseif true then
                  local _ = _264_
                  if change_op_3f then
                    handle_interrupted_change_op_21()
                  else
                  end
                  do
                  end
                  exec_autocmds("LeapLeave")
                  return nil
                else
                  return nil
                end
              elseif ((in2 == spec_keys.next_match) and not bidirectional_3f) then
                local in20 = targets[1].pair[2]
                update_state({["repeat"] = {in2 = in20}})
                jump_to_21(targets[1])
                if op_mode_3f then
                  if dot_repeatable_op_3f then
                    set_dot_repeat()
                  else
                  end
                  do
                    update_state({["dot-repeat"] = {in2 = in20, ["target-idx"] = 1}})
                  end
                  exec_autocmds("LeapLeave")
                  return nil
                else
                  return traverse(targets, 1, {["force-no-labels?"] = true})
                end
              else
                update_state({["repeat"] = {in2 = in2}})
                local _270_
                local function _271_(...)
                  if change_op_3f then
                    handle_interrupted_change_op_21()
                  else
                  end
                  do
                    echo_not_found((in1 .. in2))
                  end
                  exec_autocmds("LeapLeave")
                  return nil
                end
                _270_ = (targets.sublists[in2] or _271_(...))
                if ((_G.type(_270_) == "table") and (nil ~= (_270_)[1]) and ((_270_)[2] == nil)) then
                  local only = (_270_)[1]
                  if dot_repeatable_op_3f then
                    set_dot_repeat()
                  else
                  end
                  do
                    update_state({["dot-repeat"] = {in2 = in2, ["target-idx"] = 1}})
                    jump_to_21(only)
                  end
                  exec_autocmds("LeapLeave")
                  return nil
                elseif (nil ~= _270_) then
                  local sublist = _270_
                  if sublist["autojump?"] then
                    jump_to_21(sublist[1])
                  else
                  end
                  local _275_ = post_pattern_input_loop(sublist)
                  local function _276_(...)
                    return not bidirectional_3f
                  end
                  if ((_275_ == spec_keys.next_match) and _276_(...)) then
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
                        update_state({["dot-repeat"] = {in2 = in2, ["target-idx"] = 1}})
                      end
                      exec_autocmds("LeapLeave")
                    else
                    end
                    return traverse(sublist, new_idx, {["force-no-labels?"] = not sublist["autojump?"]})
                  elseif (nil ~= _275_) then
                    local input = _275_
                    local _280_ = get_target_with_active_primary_label(sublist, input)
                    if ((_G.type(_280_) == "table") and (nil ~= (_280_)[1]) and (nil ~= (_280_)[2])) then
                      local idx = (_280_)[1]
                      local target = (_280_)[2]
                      if dot_repeatable_op_3f then
                        set_dot_repeat()
                      else
                      end
                      do
                        update_state({["dot-repeat"] = {in2 = in2, ["target-idx"] = idx}})
                        jump_to_21(target)
                      end
                      exec_autocmds("LeapLeave")
                      return nil
                    elseif true then
                      local _ = _280_
                      if sublist["autojump?"] then
                        if dot_repeatable_op_3f then
                          set_dot_repeat()
                        else
                        end
                        do
                          vim.fn.feedkeys(input, "i")
                        end
                        exec_autocmds("LeapLeave")
                        return nil
                      else
                        if change_op_3f then
                          handle_interrupted_change_op_21()
                        else
                        end
                        do
                        end
                        exec_autocmds("LeapLeave")
                        return nil
                      end
                    else
                      return nil
                    end
                  else
                    return nil
                  end
                else
                  return nil
                end
              end
            elseif true then
              local __60_auto = _263_
              return ...
            else
              return nil
            end
          end
          local function _290_(...)
            do
              local _291_ = targets
              populate_sublists(_291_)
              set_sublist_attributes(_291_, {["force-no-autojump?"] = force_no_autojump_3f})
              set_labels(_291_)
            end
            return (_3fin2 or get_second_pattern_input(targets))
          end
          return _262_(_290_(...))
        elseif true then
          local __60_auto = _261_
          return ...
        else
          return nil
        end
      end
      local function _293_(...)
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
          echo_not_found((in1 .. (_3fin2 or "")))
        end
        exec_autocmds("LeapLeave")
        return nil
      end
      return _260_((get_targets(in1, {["reverse?"] = reverse_3f0, ["target-windows"] = _3ftarget_windows}) or _293_(...)))
    elseif true then
      local __60_auto = _258_
      return ...
    else
      return nil
    end
  end
  local function _296_()
    if dot_repeat_3f then
      return state["dot-repeat"].in1, state["dot-repeat"].in2
    else
      return get_first_pattern_input()
    end
  end
  return _257_(_296_())
end
local function set_default_keymaps(force_3f)
  for _, _297_ in ipairs({{"n", "s", "<Plug>(leap-forward)"}, {"n", "S", "<Plug>(leap-backward)"}, {"x", "s", "<Plug>(leap-forward)"}, {"x", "S", "<Plug>(leap-backward)"}, {"o", "z", "<Plug>(leap-forward)"}, {"o", "Z", "<Plug>(leap-backward)"}, {"o", "x", "<Plug>(leap-forward-x)"}, {"o", "X", "<Plug>(leap-backward-x)"}, {"n", "gs", "<Plug>(leap-cross-window)"}, {"x", "gs", "<Plug>(leap-cross-window)"}, {"o", "gs", "<Plug>(leap-cross-window)"}}) do
    local _each_298_ = _297_
    local mode = _each_298_[1]
    local lhs = _each_298_[2]
    local rhs = _each_298_[3]
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
init_highlight()
api.nvim_create_augroup("LeapDefault", {})
api.nvim_create_autocmd("ColorScheme", {callback = init_highlight, group = "LeapDefault"})
local function _302_()
  save_editor_opts()
  return set_temporary_editor_opts()
end
api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _302_, group = "LeapDefault"})
api.nvim_create_autocmd("User", {pattern = "LeapLeave", callback = restore_editor_opts, group = "LeapDefault"})
return {opts = opts, setup = setup, state = state, leap = leap, init_highlight = init_highlight, set_default_keymaps = set_default_keymaps}
