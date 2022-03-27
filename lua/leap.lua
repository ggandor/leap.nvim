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
local opts = {case_insensitive = true, safe_labels = safe_labels, labels = labels, special_keys = {next_match_group = "<space>", prev_match_group = "<tab>", ["repeat"] = "<enter>", revert = "<tab>"}}
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
  for name, def_map in pairs({[hl.group.backdrop] = {gui = "none", cterm = "none"}, [hl.group.match] = {guifg = _19_, guibg = "none", gui = "underline,nocombine", ctermfg = "red", ctermbg = "none", cterm = "underline,nocombine"}, [hl.group["label-primary"]] = {guifg = "black", guibg = _24_, gui = "none", ctermfg = "black", ctermbg = "red", cterm = "none"}, [hl.group["label-secondary"]] = {guifg = "black", guibg = _29_, gui = "none", ctermfg = "black", ctermbg = "blue", cterm = "none"}}) do
    local attr_str
    local _33_
    do
      local tbl_15_auto = {}
      local i_16_auto = #tbl_15_auto
      for k, v in pairs(def_map) do
        local val_17_auto = (k .. "=" .. v)
        if (nil ~= val_17_auto) then
          i_16_auto = (i_16_auto + 1)
          do end (tbl_15_auto)[i_16_auto] = val_17_auto
        else
        end
      end
      _33_ = tbl_15_auto
    end
    attr_str = table.concat(_33_, " ")
    local function _35_()
      if force_3f then
        return ""
      else
        return "default "
      end
    end
    vim.cmd(("highlight " .. _35_() .. name .. " " .. attr_str))
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
    local _let_36_ = map(dec, get_cursor_pos())
    local curline = _let_36_[1]
    local curcol = _let_36_[2]
    local _let_37_ = {dec(vim.fn.line("w0")), dec(vim.fn.line("w$"))}
    local win_top = _let_37_[1]
    local win_bot = _let_37_[2]
    local function _39_()
      if reverse_3f then
        return {{win_top, 0}, {curline, curcol}}
      else
        return {{curline, inc(curcol)}, {win_bot, -1}}
      end
    end
    local _let_38_ = _39_()
    local start = _let_38_[1]
    local finish = _let_38_[2]
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
  local function _42_()
    local _41_ = direction
    if (_41_ == "fwd") then
      return "W"
    elseif (_41_ == "bwd") then
      return "bW"
    else
      return nil
    end
  end
  return vim.fn.search("\\_.", _42_())
end
local function force_matchparen_refresh()
  pcall(api.nvim_exec_autocmd, "CursorMoved", {group = "matchparen"})
  return pcall(api.nvim_exec_autocmd, "CursorMoved", {group = "matchup_matchparen"})
end
local function cursor_before_eof_3f()
  return ((vim.fn.line(".") == vim.fn.line("$")) and (vim.fn.virtcol(".") == dec(vim.fn.virtcol("$"))))
end
local function add_restore_virtualedit_autocmd(saved_val)
  local function _44_()
    vim.o.virtualedit = saved_val
    return nil
  end
  return api.nvim_create_autocmd({"CursorMoved", "WinLeave", "BufLeave", "InsertEnter", "CmdlineEnter", "CmdwinEnter"}, {callback = _44_, once = true})
end
local function jump_to_21_2a(target, _45_)
  local _arg_46_ = _45_
  local mode = _arg_46_["mode"]
  local reverse_3f = _arg_46_["reverse?"]
  local inclusive_motion_3f = _arg_46_["inclusive-motion?"]
  local add_to_jumplist_3f = _arg_46_["add-to-jumplist?"]
  local adjust = _arg_46_["adjust"]
  local op_mode_3f = string.match(mode, "o")
  local motion_force = get_motion_force(mode)
  local virtualedit_saved = vim.o.virtualedit
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
  if (op_mode_3f and not reverse_3f and inclusive_motion_3f) then
    local _49_ = motion_force
    if (_49_ == nil) then
      if not cursor_before_eof_3f() then
        return push_cursor_21("fwd")
      else
        vim.o.virtualedit = "onemore"
        vim.cmd("norm! l")
        return add_restore_virtualedit_autocmd(virtualedit_saved)
      end
    elseif (_49_ == "V") then
      return nil
    elseif (_49_ == _3cctrl_v_3e) then
      return nil
    elseif (_49_ == "v") then
      return push_cursor_21("bwd")
    else
      return nil
    end
  else
    return nil
  end
end
local function highlight_cursor(_3fpos)
  local _let_53_ = (_3fpos or get_cursor_pos())
  local line = _let_53_[1]
  local col = _let_53_[2]
  local pos = _let_53_
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
local function doau_when_exists(pattern)
  if vim.fn.exists(("#User#" .. pattern)) then
    return api.nvim_exec_autocmd("User", {pattern = pattern, modeline = false})
  else
    return nil
  end
end
local function get_input()
  local _56_, _57_ = pcall(vim.fn.getcharstr)
  local function _58_()
    local ch = _57_
    return (ch ~= _3cesc_3e)
  end
  if (((_56_ == true) and (nil ~= _57_)) and _58_()) then
    local ch = _57_
    return ch
  else
    return nil
  end
end
local function set_dot_repeat(cmd, _3fcount)
  local op = vim.v.operator
  local change
  if (op == "c") then
    change = replace_keycodes("<c-r>.<esc>")
  else
    change = nil
  end
  local seq = (op .. (_3fcount or "") .. cmd .. (change or ""))
  pcall(vim.fn["repeat#setreg"], seq, vim.v.register)
  return pcall(vim.fn["repeat#set"], seq, -1)
end
local function get_plug_key(reverse_3f, x_mode_3f, dot_repeat_3f)
  local function _61_()
    if dot_repeat_3f then
      return "dotrepeat-"
    else
      return ""
    end
  end
  local function _63_()
    local _62_ = {not not reverse_3f, not not x_mode_3f}
    if ((_G.type(_62_) == "table") and ((_62_)[1] == false) and ((_62_)[2] == false)) then
      return "forward)"
    elseif ((_G.type(_62_) == "table") and ((_62_)[1] == true) and ((_62_)[2] == false)) then
      return "backward)"
    elseif ((_G.type(_62_) == "table") and ((_62_)[1] == false) and ((_62_)[2] == true)) then
      return "forward-x)"
    elseif ((_G.type(_62_) == "table") and ((_62_)[1] == true) and ((_62_)[2] == true)) then
      return "backward-x)"
    else
      return nil
    end
  end
  return ("<Plug>(leap-" .. _61_() .. _63_())
end
local function get_targetable_windows()
  local visual_or_OP_mode_3f = (vim.fn.mode() ~= "n")
  local get_wininfo
  local function _65_(_241)
    return (vim.fn.getwininfo(_241))[1]
  end
  get_wininfo = _65_
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
local function get_match_positions(pattern, _68_)
  local _arg_69_ = _68_
  local reverse_3f = _arg_69_["reverse?"]
  local whole_window_3f = _arg_69_["whole-window?"]
  local source_winid = _arg_69_["source-winid"]
  local _arg_70_ = _arg_69_["bounds"]
  local left_bound = _arg_70_[1]
  local right_bound = _arg_70_[2]
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
  local function _74_()
    vim.fn.winrestview(view)
    vim.o.cpo = cpo
    return nil
  end
  cleanup = _74_
  local function reach_right_bound()
    while ((vim.fn.virtcol(".") < right_bound) and not (vim.fn.col(".") >= dec(vim.fn.col("$")))) do
      vim.cmd("norm! l")
    end
    return nil
  end
  local function skip_to_fold_edge_21()
    local _75_
    local _76_
    if reverse_3f0 then
      _76_ = vim.fn.foldclosed
    else
      _76_ = vim.fn.foldclosedend
    end
    _75_ = _76_(vim.fn.line("."))
    if (_75_ == -1) then
      return "not-in-fold"
    elseif (nil ~= _75_) then
      local fold_edge = _75_
      vim.fn.cursor(fold_edge, 0)
      local function _78_()
        if reverse_3f0 then
          return 1
        else
          return vim.fn.col("$")
        end
      end
      vim.fn.cursor(0, _78_())
      return "moved-the-cursor"
    else
      return nil
    end
  end
  local function skip_to_next_in_window_pos_21()
    local _local_80_ = {vim.fn.line("."), vim.fn.virtcol(".")}
    local line = _local_80_[1]
    local virtcol = _local_80_[2]
    local from_pos = _local_80_
    local _81_
    if (virtcol < left_bound) then
      if reverse_3f0 then
        if (dec(line) >= stopline) then
          _81_ = {dec(line), right_bound}
        else
          _81_ = nil
        end
      else
        _81_ = {line, left_bound}
      end
    elseif (virtcol > right_bound) then
      if reverse_3f0 then
        _81_ = {line, right_bound}
      else
        if (inc(line) <= stopline) then
          _81_ = {inc(line), left_bound}
        else
          _81_ = nil
        end
      end
    else
      _81_ = nil
    end
    if (nil ~= _81_) then
      local to_pos = _81_
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
    local function _91_()
      if win_enter_3f then
        win_enter_3f = false
        return true
      else
        return nil
      end
    end
    match_at_curpos_3f0 = (match_at_curpos_3f or _91_())
    local _92_
    local function _93_()
      if match_at_curpos_3f0 then
        return "c"
      else
        return ""
      end
    end
    _92_ = vim.fn.searchpos(pattern, (opts0 .. _93_()), stopline)
    if ((_G.type(_92_) == "table") and ((_92_)[1] == 0) and true) then
      local _ = (_92_)[2]
      return cleanup()
    elseif ((_G.type(_92_) == "table") and (nil ~= (_92_)[1]) and (nil ~= (_92_)[2])) then
      local line = (_92_)[1]
      local col = (_92_)[2]
      local pos = _92_
      local _94_ = skip_to_fold_edge_21()
      if (_94_ == "moved-the-cursor") then
        return recur(false)
      elseif (_94_ == "not-in-fold") then
        if ((curr_winid == source_winid) and (view.lnum == line) and (inc(view.col) == col)) then
          push_cursor_21("fwd")
          return recur(true)
        elseif ((function(_95_,_96_,_97_) return (_95_ <= _96_) and (_96_ <= _97_) end)(left_bound,col,right_bound) or vim.wo.wrap) then
          match_count = (match_count + 1)
          return pos
        else
          local _98_ = skip_to_next_in_window_pos_21()
          if (_98_ == "moved-the-cursor") then
            return recur(true)
          elseif true then
            local _ = _98_
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
local function get_targets_2a(input, _103_)
  local _arg_104_ = _103_
  local reverse_3f = _arg_104_["reverse?"]
  local wininfo = _arg_104_["wininfo"]
  local targets = _arg_104_["targets"]
  local source_winid = _arg_104_["source-winid"]
  local targets0 = (targets or {})
  local prev_match = {}
  local _let_105_ = get_horizontal_bounds()
  local _ = _let_105_[1]
  local right_bound = _let_105_[2]
  local bounds = _let_105_
  local pattern
  local function _106_()
    if opts.case_insensitive then
      return "\\c"
    else
      return "\\C"
    end
  end
  pattern = ("\\V" .. _106_() .. input:gsub("\\", "\\\\") .. "\\_.")
  for _107_ in get_match_positions(pattern, {bounds = bounds, ["reverse?"] = reverse_3f, ["source-winid"] = source_winid, ["whole-window?"] = wininfo}) do
    local _each_108_ = _107_
    local line = _each_108_[1]
    local col = _each_108_[2]
    local pos = _each_108_
    local ch1 = char_at_pos(pos, {})
    local ch2 = (char_at_pos(pos, {["char-offset"] = 1}) or "\13")
    local same_char_triplet_3f
    local _109_
    if reverse_3f then
      _109_ = dec
    else
      _109_ = inc
    end
    same_char_triplet_3f = ((ch2 == prev_match.ch2) and (line == prev_match.line) and (col == _109_(prev_match.col)))
    prev_match = {line = line, col = col, ch2 = ch2}
    if not same_char_triplet_3f then
      table.insert(targets0, {pos = pos, pair = {ch1, ch2}, wininfo = wininfo, ["edge-pos?"] = ((ch2 == "\13") or (col == right_bound))})
    else
    end
  end
  if next(targets0) then
    return targets0
  else
    return nil
  end
end
local function distance(_113_, _115_)
  local _arg_114_ = _113_
  local l1 = _arg_114_[1]
  local c1 = _arg_114_[2]
  local _arg_116_ = _115_
  local l2 = _arg_116_[1]
  local c2 = _arg_116_[2]
  local editor_grid_aspect_ratio = 0.3
  local _let_117_ = {abs((c1 - c2)), abs((l1 - l2))}
  local dx = _let_117_[1]
  local dy = _let_117_[2]
  local dx0 = (dx * editor_grid_aspect_ratio)
  return pow((pow(dx0, 2) + pow(dy, 2)), 0.5)
end
local function get_targets(input, _118_)
  local _arg_119_ = _118_
  local reverse_3f = _arg_119_["reverse?"]
  local target_windows = _arg_119_["target-windows"]
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
        for winid, _122_ in pairs(cursor_positions) do
          local _each_123_ = _122_
          local line = _each_123_[1]
          local col = _each_123_[2]
          local _124_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_124_) == "table") and (nil ~= (_124_).row) and ((_124_).col == col)) then
            local row = (_124_).row
            cursor_positions[winid] = {row, col}
          else
          end
        end
      else
      end
      for _, _127_ in ipairs(targets) do
        local _each_128_ = _127_
        local _each_129_ = _each_128_["pos"]
        local line = _each_129_[1]
        local col = _each_129_[2]
        local _each_130_ = _each_128_["wininfo"]
        local winid = _each_130_["winid"]
        local t = _each_128_
        if by_screen_pos_3f then
          local _131_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_131_) == "table") and (nil ~= (_131_).row) and ((_131_).col == col)) then
            local row = (_131_).row
            t["screenpos"] = {row, col}
          else
          end
        else
        end
        t["rank"] = distance((t.screenpos or t.pos), cursor_positions[winid])
      end
      local function _134_(_241, _242)
        return ((_241).rank < (_242).rank)
      end
      table.sort(targets, _134_)
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
    local function _137_(self, k)
      return rawget(self, k:lower())
    end
    local function _138_(self, k, v)
      return rawset(self, k:lower(), v)
    end
    setmetatable(targets.sublists, {__index = _137_, __newindex = _138_})
  else
  end
  for _, _140_ in ipairs(targets) do
    local _each_141_ = _140_
    local _each_142_ = _each_141_["pair"]
    local _0 = _each_142_[1]
    local ch2 = _each_142_[2]
    local target = _each_141_
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
  local _144_
  if user_forced_autojump_3f() then
    _144_ = opts.safe_labels
  elseif user_forced_no_autojump_3f() then
    _144_ = opts.labels
  elseif sublist["autojump?"] then
    _144_ = opts.safe_labels
  else
    _144_ = opts.labels
  end
  sublist["label-set"] = _144_
  return nil
end
local function set_sublist_attributes(targets, _146_)
  local _arg_147_ = _146_
  local force_no_autojump_3f = _arg_147_["force-no-autojump?"]
  for _, sublist in pairs(targets.sublists) do
    set_autojump(sublist, force_no_autojump_3f)
    attach_label_set(sublist)
  end
  return nil
end
local function set_labels(targets)
  for _, sublist in pairs(targets.sublists) do
    if (#sublist > 1) then
      local autojump_3f = sublist["autojump?"]
      local labels0 = sublist["label-set"]
      for i, target in ipairs(sublist) do
        local _148_
        if not (autojump_3f and (i == 1)) then
          local _149_
          local function _151_()
            if autojump_3f then
              return dec(i)
            else
              return i
            end
          end
          _149_ = (_151_() % #labels0)
          if (_149_ == 0) then
            _148_ = (labels0)[#labels0]
          elseif (nil ~= _149_) then
            local n = _149_
            _148_ = (labels0)[n]
          else
            _148_ = nil
          end
        else
          _148_ = nil
        end
        target["label"] = _148_
      end
    else
    end
  end
  return nil
end
local function set_label_states(sublist, _157_)
  local _arg_158_ = _157_
  local group_offset = _arg_158_["group-offset"]
  local labels0 = sublist["label-set"]
  local _7clabels_7c = #labels0
  local offset = (group_offset * _7clabels_7c)
  local primary_start
  local function _159_()
    if sublist["autojump?"] then
      return 2
    else
      return 1
    end
  end
  primary_start = (offset + _159_())
  local primary_end = (primary_start + dec(_7clabels_7c))
  local secondary_end = (primary_end + _7clabels_7c)
  for i, target in ipairs(sublist) do
    if target.label then
      local _160_
      if ((i < primary_start) or (i > secondary_end)) then
        _160_ = "inactive"
      elseif (i <= primary_end) then
        _160_ = "active-primary"
      else
        _160_ = "active-secondary"
      end
      target["label-state"] = _160_
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
local function set_beacon(target, force_no_labels_3f)
  local _let_163_ = target
  local _let_164_ = _let_163_["pair"]
  local ch1 = _let_164_[1]
  local ch2 = _let_164_[2]
  local label = _let_163_["label"]
  local label_state = _let_163_["label-state"]
  local edge_pos_3f = _let_163_["edge-pos?"]
  local offset
  local function _165_()
    if edge_pos_3f then
      return 0
    else
      return ch2:len()
    end
  end
  offset = (ch1:len() + _165_())
  local _166_
  if (not label_state or force_no_labels_3f) then
    _166_ = "match-highlight"
  else
    local _167_ = label_state
    if (_167_ == "active-primary") then
      _166_ = {offset, {{label, hl.group["label-primary"]}}}
    elseif (_167_ == "active-secondary") then
      _166_ = {offset, {{label, hl.group["label-secondary"]}}}
    elseif (_167_ == "inactive") then
      _166_ = nil
    else
      _166_ = nil
    end
  end
  target["beacon"] = _166_
  return nil
end
local function set_beacons(target_list, _174_)
  local _arg_175_ = _174_
  local force_no_labels_3f = _arg_175_["force-no-labels?"]
  for _, target in ipairs(target_list) do
    set_beacon(target, force_no_labels_3f)
  end
  return nil
end
local function light_up_beacons(target_list, _3fstart_from)
  local match_hl_positions = {}
  local label_positions = {}
  for i = (_3fstart_from or 1), #target_list do
    local target = target_list[i]
    if target.beacon then
      local _let_176_ = map(dec, target.pos)
      local lnum = _let_176_[1]
      local col = _let_176_[2]
      local bufnr
      local function _178_()
        local t_177_ = target.wininfo
        if (nil ~= t_177_) then
          t_177_ = (t_177_).bufnr
        else
        end
        return t_177_
      end
      bufnr = (_178_() or 0)
      local winid
      local function _181_()
        local t_180_ = target.wininfo
        if (nil ~= t_180_) then
          t_180_ = (t_180_).winid
        else
        end
        return t_180_
      end
      winid = (_181_() or 0)
      local _183_ = target.beacon
      if (_183_ == "match-highlight") then
        local _let_184_ = target.pair
        local ch1 = _let_184_[1]
        local ch2 = _let_184_[2]
        local k1 = (bufnr .. " " .. winid .. " " .. lnum .. " " .. col)
        local k2 = (bufnr .. " " .. winid .. " " .. lnum .. " " .. (col + ch1:len()))
        for _, k in ipairs({k1, k2}) do
          match_hl_positions[k] = true
          local _185_ = label_positions[k]
          if (nil ~= _185_) then
            local id = _185_
            api.nvim_buf_del_extmark(bufnr, hl.ns, id)
          else
          end
        end
        api.nvim_buf_add_highlight(bufnr, hl.ns, hl.group.match, lnum, col, (col + ch1:len() + ch2:len()))
      elseif ((_G.type(_183_) == "table") and (nil ~= (_183_)[1]) and (nil ~= (_183_)[2])) then
        local label_offset = (_183_)[1]
        local virttext = (_183_)[2]
        local col0 = (col + label_offset)
        local k = (bufnr .. " " .. winid .. " " .. lnum .. " " .. col0)
        local _187_ = (match_hl_positions[k] or label_positions[k])
        if (_187_ == true) then
        elseif (nil ~= _187_) then
          local id = _187_
          api.nvim_buf_del_extmark(bufnr, hl.ns, id)
        elseif true then
          local _ = _187_
          label_positions[k] = api.nvim_buf_set_extmark(bufnr, hl.ns, lnum, col0, {virt_text = virttext, virt_text_pos = "overlay", priority = hl.priority.label})
        else
        end
      else
      end
    else
    end
  end
  return nil
end
local state = {["dot-repeat"] = {in1 = nil, in2 = nil, ["target-idx"] = nil}, ["repeat"] = {in1 = nil, in2 = nil}}
local function leap(_191_)
  local _arg_192_ = _191_
  local reverse_3f = _arg_192_["reverse?"]
  local x_mode_3f = _arg_192_["x-mode?"]
  local omni_3f = _arg_192_["omni?"]
  local cross_window_3f = _arg_192_["cross-window?"]
  local dot_repeat_3f = _arg_192_["dot-repeat?"]
  local traversal_state = _arg_192_["traversal-state"]
  local omni_3f0 = (cross_window_3f or omni_3f)
  local mode = api.nvim_get_mode().mode
  local visual_mode_3f = ((mode == _3cctrl_v_3e) or (mode == "V") or (mode == "v"))
  local op_mode_3f = mode:match("o")
  local change_op_3f = (op_mode_3f and (vim.v.operator == "c"))
  local dot_repeatable_op_3f = (op_mode_3f and not omni_3f0 and (vim.v.operator ~= "y"))
  local doing_traversal_3f = traversal_state
  local force_no_autojump_3f = (op_mode_3f or (omni_3f0 and visual_mode_3f) or cross_window_3f)
  local force_no_labels_3f = (doing_traversal_3f and not traversal_state.sublist["autojump?"])
  local _3ftarget_windows
  if cross_window_3f then
    _3ftarget_windows = get_targetable_windows()
  elseif omni_3f0 then
    _3ftarget_windows = {vim.fn.getwininfo(vim.fn.win_getid())[1]}
  else
    _3ftarget_windows = nil
  end
  local spec_keys
  local function _194_(_, k)
    return replace_keycodes(opts.special_keys[k])
  end
  spec_keys = setmetatable({}, {__index = _194_})
  local new_search_3f = not (dot_repeat_3f or doing_traversal_3f)
  local function get_first_input()
    if doing_traversal_3f then
      return state["repeat"].in1
    elseif dot_repeat_3f then
      return state["dot-repeat"].in1
    else
      local _195_
      local function _196_()
        local res_2_auto
        do
          res_2_auto = get_input()
        end
        hl:cleanup(_3ftarget_windows)
        return res_2_auto
      end
      local function _197_()
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
        end
        doau_when_exists("LeapLeave")
        return nil
      end
      _195_ = (_196_() or _197_())
      if (_195_ == spec_keys["repeat"]) then
        new_search_3f = false
        local function _199_()
          if change_op_3f then
            handle_interrupted_change_op_21()
          else
          end
          do
            echo_no_prev_search()
          end
          doau_when_exists("LeapLeave")
          return nil
        end
        return (state["repeat"].in1 or _199_())
      elseif (nil ~= _195_) then
        local _in = _195_
        return _in
      else
        return nil
      end
    end
  end
  local function update_state_2a(in1)
    local function _205_(_203_)
      local _arg_204_ = _203_
      local _repeat = _arg_204_["repeat"]
      local dot_repeat = _arg_204_["dot-repeat"]
      if new_search_3f then
        if _repeat then
          local _206_ = _repeat
          _206_["in1"] = in1
          state["repeat"] = _206_
        else
        end
        if (dot_repeat and dot_repeatable_op_3f) then
          do
            local _208_ = dot_repeat
            _208_["in1"] = in1
            state["dot-repeat"] = _208_
          end
          return nil
        else
          return nil
        end
      else
        return nil
      end
    end
    return _205_
  end
  local jump_to_21
  do
    local first_jump_3f = true
    local function _211_(target)
      if target.wininfo then
        api.nvim_set_current_win(target.wininfo.winid)
      else
      end
      local function _213_()
        if x_mode_3f then
          push_cursor_21("fwd")
          if reverse_3f then
            return push_cursor_21("fwd")
          else
            return nil
          end
        else
          return nil
        end
      end
      jump_to_21_2a(target.pos, {mode = mode, ["reverse?"] = reverse_3f, ["inclusive-motion?"] = (x_mode_3f and not reverse_3f), ["add-to-jumplist?"] = (first_jump_3f and not doing_traversal_3f), adjust = _213_})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _211_
  end
  local function get_last_input(sublist, _216_)
    local _arg_217_ = _216_
    local display_targets_from = _arg_217_["display-targets-from"]
    local function recur(group_offset, initial_invoc_3f)
      set_beacons(sublist, {["force-no-labels?"] = force_no_labels_3f})
      do
        if new_search_3f then
          apply_backdrop(reverse_3f, _3ftarget_windows)
        else
        end
        do
          light_up_beacons(sublist, display_targets_from)
        end
        highlight_cursor()
        vim.cmd("redraw")
      end
      local _219_
      do
        local res_2_auto
        do
          res_2_auto = get_input()
        end
        hl:cleanup(_3ftarget_windows)
        _219_ = res_2_auto
      end
      if (nil ~= _219_) then
        local input = _219_
        if (sublist["autojump?"] and not user_forced_autojump_3f()) then
          return {input, 0}
        else
          local _220_
          if not initial_invoc_3f then
            _220_ = spec_keys.prev_match_group
          else
            _220_ = nil
          end
          if (not doing_traversal_3f and ((input == spec_keys.next_match_group) or (input == _220_))) then
            local labels0 = sublist["label-set"]
            local num_of_groups = ceil((#sublist / #labels0))
            local max_offset = dec(num_of_groups)
            local new_group_offset
            local _223_
            do
              local _222_ = input
              if (_222_ == spec_keys.next_match_group) then
                _223_ = inc
              elseif true then
                local _ = _222_
                _223_ = dec
              else
                _223_ = nil
              end
            end
            new_group_offset = clamp(_223_(group_offset), 0, max_offset)
            set_label_states(sublist, {["group-offset"] = new_group_offset})
            return recur(new_group_offset)
          else
            return {input, group_offset}
          end
        end
      else
        return nil
      end
    end
    return recur(0, true)
  end
  local function get_traversal_action(_in)
    if (_in == spec_keys["repeat"]) then
      return "to-next"
    elseif (doing_traversal_3f and (_in == spec_keys.revert)) then
      return "to-prev"
    else
      return nil
    end
  end
  local function get_target_with_active_primary_label(target_list, input)
    local res = nil
    for idx, _230_ in ipairs(target_list) do
      local _each_231_ = _230_
      local label = _each_231_["label"]
      local label_state = _each_231_["label-state"]
      local target = _each_231_
      if res then break end
      if ((label == input) and (label_state == "active-primary")) then
        res = {idx, target}
      else
      end
    end
    return res
  end
  if not (dot_repeat_3f or doing_traversal_3f) then
    doau_when_exists("LeapEnter")
    echo("")
    if new_search_3f then
      apply_backdrop(reverse_3f, _3ftarget_windows)
    else
    end
    do
    end
    highlight_cursor()
    vim.cmd("redraw")
  else
  end
  local _235_ = get_first_input()
  if (nil ~= _235_) then
    local in1 = _235_
    local update_state = update_state_2a(in1)
    local prev_in2
    if not new_search_3f then
      if dot_repeat_3f then
        prev_in2 = state["dot-repeat"].in2
      else
        prev_in2 = state["repeat"].in2
      end
    else
      prev_in2 = nil
    end
    local _238_
    local function _240_()
      local t_239_ = traversal_state
      if (nil ~= t_239_) then
        t_239_ = (t_239_).sublist
      else
      end
      return t_239_
    end
    local function _242_()
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      do
        echo_not_found((in1 .. (prev_in2 or "")))
      end
      doau_when_exists("LeapLeave")
      return nil
    end
    _238_ = (_240_() or get_targets(in1, {["reverse?"] = reverse_3f, ["target-windows"] = _3ftarget_windows}) or _242_())
    if (nil ~= _238_) then
      local targets = _238_
      if not doing_traversal_3f then
        local _244_ = targets
        populate_sublists(_244_)
        set_sublist_attributes(_244_, {["force-no-autojump?"] = force_no_autojump_3f})
        set_labels(_244_)
        set_initial_label_states(_244_)
      else
      end
      if new_search_3f then
        set_beacons(targets, {})
        if new_search_3f then
          apply_backdrop(reverse_3f, _3ftarget_windows)
        else
        end
        do
          light_up_beacons(targets)
        end
        highlight_cursor()
        vim.cmd("redraw")
      else
      end
      local _248_
      local function _249_()
        local res_2_auto
        do
          res_2_auto = get_input()
        end
        hl:cleanup(_3ftarget_windows)
        return res_2_auto
      end
      local function _250_()
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
        end
        doau_when_exists("LeapLeave")
        return nil
      end
      _248_ = (prev_in2 or _249_() or _250_())
      if (nil ~= _248_) then
        local in2 = _248_
        update_state({["repeat"] = {in2 = in2}})
        local _252_
        local function _254_()
          local t_253_ = traversal_state
          if (nil ~= t_253_) then
            t_253_ = (t_253_).sublist
          else
          end
          return t_253_
        end
        local function _256_()
          if change_op_3f then
            handle_interrupted_change_op_21()
          else
          end
          do
            echo_not_found((in1 .. in2))
          end
          doau_when_exists("LeapLeave")
          return nil
        end
        _252_ = (_254_() or targets.sublists[in2] or _256_())
        if ((_G.type(_252_) == "table") and (nil ~= (_252_)[1]) and ((_252_)[2] == nil)) then
          local only = (_252_)[1]
          if (dot_repeat_3f and (state["dot-repeat"]["target-idx"] ~= 1)) then
            if change_op_3f then
              handle_interrupted_change_op_21()
            else
            end
            do
            end
            doau_when_exists("LeapLeave")
            return nil
          else
            if dot_repeatable_op_3f then
              set_dot_repeat(replace_keycodes(get_plug_key(reverse_3f, x_mode_3f, true)))
            else
            end
            do
              update_state({["dot-repeat"] = {in2 = in2, ["target-idx"] = 1}})
              jump_to_21(only)
            end
            doau_when_exists("LeapLeave")
            return nil
          end
        elseif ((_G.type(_252_) == "table") and (nil ~= (_252_)[1])) then
          local first = (_252_)[1]
          local sublist = _252_
          if dot_repeat_3f then
            local _261_ = sublist[state["dot-repeat"]["target-idx"]]
            if (nil ~= _261_) then
              local target = _261_
              if dot_repeatable_op_3f then
                set_dot_repeat(replace_keycodes(get_plug_key(reverse_3f, x_mode_3f, true)))
              else
              end
              do
                jump_to_21(target)
              end
              doau_when_exists("LeapLeave")
              return nil
            elseif true then
              local _ = _261_
              if change_op_3f then
                handle_interrupted_change_op_21()
              else
              end
              do
              end
              doau_when_exists("LeapLeave")
              return nil
            else
              return nil
            end
          else
            local curr_idx
            local function _266_()
              local t_265_ = traversal_state
              if (nil ~= t_265_) then
                t_265_ = (t_265_).idx
              else
              end
              return t_265_
            end
            curr_idx = (_266_() or 0)
            if not doing_traversal_3f then
              if sublist["autojump?"] then
                jump_to_21(first)
                curr_idx = 1
              else
              end
            else
            end
            local _270_
            local function _271_()
              if change_op_3f then
                handle_interrupted_change_op_21()
              else
              end
              do
              end
              doau_when_exists("LeapLeave")
              return nil
            end
            _270_ = (get_last_input(sublist, {["display-targets-from"] = inc(curr_idx)}) or _271_())
            if ((_G.type(_270_) == "table") and (nil ~= (_270_)[1]) and (nil ~= (_270_)[2])) then
              local in3 = (_270_)[1]
              local group_offset = (_270_)[2]
              local _273_
              if not (op_mode_3f or omni_3f0 or (group_offset > 0)) then
                _273_ = get_traversal_action(in3)
              else
                _273_ = nil
              end
              if (nil ~= _273_) then
                local action = _273_
                local new_idx
                do
                  local _275_ = action
                  if (_275_ == "to-next") then
                    new_idx = min(inc(curr_idx), #targets)
                  elseif (_275_ == "to-prev") then
                    new_idx = max(dec(curr_idx), 1)
                  else
                    new_idx = nil
                  end
                end
                jump_to_21(sublist[new_idx])
                return leap({["reverse?"] = reverse_3f, ["x-mode?"] = x_mode_3f, ["traversal-state"] = {sublist = sublist, idx = new_idx}})
              elseif true then
                local _ = _273_
                local _277_
                if not force_no_labels_3f then
                  _277_ = get_target_with_active_primary_label(sublist, in3)
                else
                  _277_ = nil
                end
                if ((_G.type(_277_) == "table") and (nil ~= (_277_)[1]) and (nil ~= (_277_)[2])) then
                  local idx = (_277_)[1]
                  local target = (_277_)[2]
                  if dot_repeatable_op_3f then
                    set_dot_repeat(replace_keycodes(get_plug_key(reverse_3f, x_mode_3f, true)))
                  else
                  end
                  do
                    update_state({["dot-repeat"] = {in2 = in2, ["target-idx"] = idx}})
                    jump_to_21(target)
                  end
                  doau_when_exists("LeapLeave")
                  return nil
                elseif true then
                  local _0 = _277_
                  if (sublist["autojump?"] or doing_traversal_3f) then
                    if dot_repeatable_op_3f then
                      set_dot_repeat(replace_keycodes(get_plug_key(reverse_3f, x_mode_3f, true)))
                    else
                    end
                    do
                      vim.fn.feedkeys(in3, "i")
                    end
                    doau_when_exists("LeapLeave")
                    return nil
                  else
                    if change_op_3f then
                      handle_interrupted_change_op_21()
                    else
                    end
                    do
                    end
                    doau_when_exists("LeapLeave")
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
        else
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
local function set_default_keymaps(force_3f)
  for _, _291_ in ipairs({{"n", "s", "<Plug>(leap-forward)"}, {"n", "S", "<Plug>(leap-backward)"}, {"x", "s", "<Plug>(leap-forward)"}, {"x", "S", "<Plug>(leap-backward)"}, {"o", "z", "<Plug>(leap-forward)"}, {"o", "Z", "<Plug>(leap-backward)"}, {"o", "x", "<Plug>(leap-forward-x)"}, {"o", "X", "<Plug>(leap-backward-x)"}, {"n", "gs", "<Plug>(leap-cross-window)"}, {"x", "gs", "<Plug>(leap-cross-window)"}, {"o", "gs", "<Plug>(leap-cross-window)"}}) do
    local _each_292_ = _291_
    local mode = _each_292_[1]
    local lhs = _each_292_[2]
    local rhs = _each_292_[3]
    if (force_3f or ((vim.fn.mapcheck(lhs, mode) == "") and (vim.fn.hasmapto(rhs, mode) == 0))) then
      vim.keymap.set(mode, lhs, rhs, {silent = true})
    else
    end
  end
  return nil
end
local function _294_()
  return leap({["dot-repeat?"] = true})
end
local function _295_()
  return leap({["dot-repeat?"] = true, ["reverse?"] = true})
end
local function _296_()
  return leap({["dot-repeat?"] = true, ["x-mode?"] = true})
end
local function _297_()
  return leap({["dot-repeat?"] = true, ["reverse?"] = true, ["x-mode?"] = true})
end
for lhs, rhs in pairs({["<Plug>(leap-dotrepeat-forward)"] = _294_, ["<Plug>(leap-dotrepeat-backward)"] = _295_, ["<Plug>(leap-dotrepeat-forward-x)"] = _296_, ["<Plug>(leap-dotrepeat-backward-x)"] = _297_}) do
  vim.keymap.set("o", lhs, rhs, {silent = true})
end
local temporary_editor_opts = {["vim.bo.modeline"] = false}
local saved_editor_opts = {}
local function save_editor_opts()
  for opt, _ in pairs(temporary_editor_opts) do
    local _let_298_ = vim.split(opt, ".", true)
    local _0 = _let_298_[1]
    local scope = _let_298_[2]
    local name = _let_298_[3]
    saved_editor_opts[opt] = _G.vim[scope][name]
  end
  return nil
end
local function set_editor_opts(opts0)
  for opt, val in pairs(opts0) do
    local _let_299_ = vim.split(opt, ".", true)
    local _ = _let_299_[1]
    local scope = _let_299_[2]
    local name = _let_299_[3]
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
api.nvim_create_autocmd("ColorScheme", {group = "LeapDefault", callback = init_highlight})
local function _300_()
  save_editor_opts()
  return set_temporary_editor_opts()
end
api.nvim_create_autocmd("User", {group = "LeapDefault", pattern = "LeapEnter", callback = _300_})
api.nvim_create_autocmd("User", {group = "LeapDefault", pattern = "LeapLeave", callback = restore_editor_opts})
return {opts = opts, setup = setup, state = state, leap = leap, init_highlight = init_highlight, set_default_keymaps = set_default_keymaps}
