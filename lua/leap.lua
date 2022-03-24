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
    end
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
  end
end
local safe_labels = {"s", "f", "n", "u", "t", "/", "F", "L", "N", "H", "G", "M", "U", "T", "?", "Z"}
local labels = {"s", "f", "n", "j", "k", "l", "o", "d", "w", "e", "h", "m", "v", "g", "u", "t", "c", ".", "z", "/", "F", "L", "N", "H", "G", "M", "U", "T", "?", "Z"}
local opts = {case_insensitive = true, labels = labels, safe_labels = safe_labels, special_keys = {["repeat"] = "<enter>", next_match_group = "<space>", prev_match_group = "<tab>", revert = "<tab>"}}
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
  end
  return api.nvim_buf_clear_namespace(0, self.ns, dec(vim.fn.line("w0")), vim.fn.line("w$"))
end
hl = {cleanup = _16_, group = {["label-primary"] = "LeapLabelPrimary", ["label-secondary"] = "LeapLabelSecondary", backdrop = "LeapBackdrop", match = "LeapMatch"}, ns = api.nvim_create_namespace(""), priority = {backdrop = 65533, cursor = 65534, label = 65535}}
local function init_highlight(force_3f)
  local bg = vim.o.background
  local _19_
  do
    local _18_ = bg
    if (_18_ == "light") then
      _19_ = "#222222"
    else
      local _ = _18_
      _19_ = "#ccff88"
    end
  end
  local _24_
  do
    local _23_ = bg
    if (_23_ == "light") then
      _24_ = "#ff8877"
    else
      local _ = _23_
      _24_ = "#ccff88"
    end
  end
  local _29_
  do
    local _28_ = bg
    if (_28_ == "light") then
      _29_ = "#77aaff"
    else
      local _ = _28_
      _29_ = "#99ccff"
    end
  end
  for name, def_map in pairs({[hl.group.backdrop] = {cterm = "none", gui = "none"}, [hl.group.match] = {cterm = "underline,nocombine", ctermbg = "none", ctermfg = "red", gui = "underline,nocombine", guibg = "none", guifg = _19_}, [hl.group["label-primary"]] = {cterm = "none", ctermbg = "red", ctermfg = "black", gui = "none", guibg = _24_, guifg = "black"}, [hl.group["label-secondary"]] = {cterm = "none", ctermbg = "blue", ctermfg = "black", gui = "none", guibg = _29_, guifg = "black"}}) do
    local attr_str
    local _33_
    do
      local tbl_12_auto = {}
      for k, v in pairs(def_map) do
        tbl_12_auto[(#tbl_12_auto + 1)] = (k .. "=" .. v)
      end
      _33_ = tbl_12_auto
    end
    attr_str = table.concat(_33_, " ")
    local _34_
    if force_3f then
      _34_ = ""
    else
      _34_ = "default "
    end
    vim.cmd(("highlight " .. _34_ .. name .. " " .. attr_str))
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
    end
  end
  return vim.fn.search("\\_.", _42_())
end
local function force_matchparen_refresh()
  pcall(api.nvim_do_autocmd, "CursorMoved", {group = "matchparen"})
  return pcall(api.nvim_do_autocmd, "CursorMoved", {group = "matchup_matchparen"})
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
  local add_to_jumplist_3f = _arg_46_["add-to-jumplist?"]
  local adjust = _arg_46_["adjust"]
  local inclusive_motion_3f = _arg_46_["inclusive-motion?"]
  local mode = _arg_46_["mode"]
  local reverse_3f = _arg_46_["reverse?"]
  local op_mode_3f = string.match(mode, "o")
  local motion_force = get_motion_force(mode)
  local virtualedit_saved = vim.o.virtualedit
  if add_to_jumplist_3f then
    vim.cmd("norm! m`")
  end
  vim.fn.cursor(target)
  adjust()
  if not op_mode_3f then
    force_matchparen_refresh()
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
    end
  end
end
local function highlight_cursor(_3fpos)
  local _let_53_ = (_3fpos or get_cursor_pos())
  local line = _let_53_[1]
  local col = _let_53_[2]
  local pos = _let_53_
  local ch_at_curpos = (char_at_pos(pos, {}) or " ")
  return api.nvim_buf_set_extmark(0, hl.ns, dec(line), dec(col), {hl_mode = "combine", priority = hl.priority.cursor, virt_text = {{ch_at_curpos, "Cursor"}}, virt_text_pos = "overlay"})
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
    return api.nvim_do_autocmd("User", {modeline = false, pattern = pattern})
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
  local _61_
  if dot_repeat_3f then
    _61_ = "dotrepeat-"
  else
    _61_ = ""
  end
  local _64_
  do
    local _63_ = {not not reverse_3f, not not x_mode_3f}
    if ((type(_63_) == "table") and ((_63_)[1] == false) and ((_63_)[2] == false)) then
      _64_ = "forward)"
    elseif ((type(_63_) == "table") and ((_63_)[1] == true) and ((_63_)[2] == false)) then
      _64_ = "backward)"
    elseif ((type(_63_) == "table") and ((_63_)[1] == false) and ((_63_)[2] == true)) then
      _64_ = "forward-x)"
    elseif ((type(_63_) == "table") and ((_63_)[1] == true) and ((_63_)[2] == true)) then
      _64_ = "backward-x)"
    else
    _64_ = nil
    end
  end
  return ("<Plug>(leap-" .. _61_ .. _64_)
end
local function get_targetable_windows()
  local visual_or_OP_mode_3f = (vim.fn.mode() ~= "n")
  local get_wininfo
  local function _70_(_241)
    return (vim.fn.getwininfo(_241))[1]
  end
  get_wininfo = _70_
  local get_buf = api.nvim_win_get_buf
  local curr_winid = vim.fn.win_getid()
  local ids = string.gmatch(vim.fn.string(vim.fn.winlayout()), "%d+")
  local ids0
  do
    local tbl_12_auto = {}
    for id in ids do
      local _71_
      if not ((tonumber(id) == curr_winid) or (visual_or_OP_mode_3f and (get_buf(tonumber(id)) ~= get_buf(curr_winid)))) then
        _71_ = id
      else
      _71_ = nil
      end
      tbl_12_auto[(#tbl_12_auto + 1)] = _71_
    end
    ids0 = tbl_12_auto
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
local function get_match_positions(pattern, _73_)
  local _arg_74_ = _73_
  local _arg_75_ = _arg_74_["bounds"]
  local left_bound = _arg_75_[1]
  local right_bound = _arg_75_[2]
  local reverse_3f = _arg_74_["reverse?"]
  local source_winid = _arg_74_["source-winid"]
  local whole_window_3f = _arg_74_["whole-window?"]
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
  local function _79_()
    vim.fn.winrestview(view)
    vim.o.cpo = cpo
    return nil
  end
  cleanup = _79_
  local function reach_right_bound()
    while ((vim.fn.virtcol(".") < right_bound) and not (vim.fn.col(".") >= dec(vim.fn.col("$")))) do
      vim.cmd("norm! l")
    end
    return nil
  end
  local function skip_to_fold_edge_21()
    local _80_
    local _81_
    if reverse_3f0 then
      _81_ = vim.fn.foldclosed
    else
      _81_ = vim.fn.foldclosedend
    end
    _80_ = _81_(vim.fn.line("."))
    if (_80_ == -1) then
      return "not-in-fold"
    elseif (nil ~= _80_) then
      local fold_edge = _80_
      vim.fn.cursor(fold_edge, 0)
      local function _83_()
        if reverse_3f0 then
          return 1
        else
          return vim.fn.col("$")
        end
      end
      vim.fn.cursor(0, _83_())
      return "moved-the-cursor"
    end
  end
  local function skip_to_next_in_window_pos_21()
    local _local_85_ = {vim.fn.line("."), vim.fn.virtcol(".")}
    local line = _local_85_[1]
    local virtcol = _local_85_[2]
    local from_pos = _local_85_
    local _86_
    if (virtcol < left_bound) then
      if reverse_3f0 then
        if (dec(line) >= stopline) then
          _86_ = {dec(line), right_bound}
        else
        _86_ = nil
        end
      else
        _86_ = {line, left_bound}
      end
    elseif (virtcol > right_bound) then
      if reverse_3f0 then
        _86_ = {line, right_bound}
      else
        if (inc(line) <= stopline) then
          _86_ = {inc(line), left_bound}
        else
        _86_ = nil
        end
      end
    else
    _86_ = nil
    end
    if (nil ~= _86_) then
      local to_pos = _86_
      if (from_pos ~= to_pos) then
        vim.fn.cursor(to_pos)
        if reverse_3f0 then
          reach_right_bound()
        end
        return "moved-the-cursor"
      end
    end
  end
  vim.o.cpo = cpo:gsub("c", "")
  local win_enter_3f = nil
  local match_count = 0
  local orig_curpos = get_cursor_pos()
  if whole_window_3f then
    win_enter_3f = true
    vim.fn.cursor({wintop, left_bound})
  end
  local function recur(match_at_curpos_3f)
    local match_at_curpos_3f0
    local function _96_()
      if win_enter_3f then
        win_enter_3f = false
        return true
      end
    end
    match_at_curpos_3f0 = (match_at_curpos_3f or _96_())
    local _97_
    local _98_
    if match_at_curpos_3f0 then
      _98_ = "c"
    else
      _98_ = ""
    end
    _97_ = vim.fn.searchpos(pattern, (opts0 .. _98_), stopline)
    if ((type(_97_) == "table") and ((_97_)[1] == 0) and true) then
      local _ = (_97_)[2]
      return cleanup()
    elseif ((type(_97_) == "table") and (nil ~= (_97_)[1]) and (nil ~= (_97_)[2])) then
      local line = (_97_)[1]
      local col = (_97_)[2]
      local pos = _97_
      local _100_ = skip_to_fold_edge_21()
      if (_100_ == "moved-the-cursor") then
        return recur(false)
      elseif (_100_ == "not-in-fold") then
        if ((curr_winid == source_winid) and (view.lnum == line) and (inc(view.col) == col)) then
          push_cursor_21("fwd")
          return recur(true)
        elseif ((function(_101_,_102_,_103_) return (_101_ <= _102_) and (_102_ <= _103_) end)(left_bound,col,right_bound) or vim.wo.wrap) then
          match_count = (match_count + 1)
          return pos
        else
          local _104_ = skip_to_next_in_window_pos_21()
          if (_104_ == "moved-the-cursor") then
            return recur(true)
          else
            local _ = _104_
            return cleanup()
          end
        end
      end
    end
  end
  return recur
end
local function get_targets_2a(input, _109_)
  local _arg_110_ = _109_
  local reverse_3f = _arg_110_["reverse?"]
  local source_winid = _arg_110_["source-winid"]
  local targets = _arg_110_["targets"]
  local wininfo = _arg_110_["wininfo"]
  local targets0 = (targets or {})
  local prev_match = {}
  local _let_111_ = get_horizontal_bounds()
  local _ = _let_111_[1]
  local right_bound = _let_111_[2]
  local bounds = _let_111_
  local pattern
  local _112_
  if opts.case_insensitive then
    _112_ = "\\c"
  else
    _112_ = "\\C"
  end
  pattern = ("\\V" .. _112_ .. input:gsub("\\", "\\\\") .. "\\_.")
  for _114_ in get_match_positions(pattern, {["reverse?"] = reverse_3f, ["source-winid"] = source_winid, ["whole-window?"] = wininfo, bounds = bounds}) do
    local _each_115_ = _114_
    local line = _each_115_[1]
    local col = _each_115_[2]
    local pos = _each_115_
    local ch1 = char_at_pos(pos, {})
    local ch2 = (char_at_pos(pos, {["char-offset"] = 1}) or "\13")
    local same_char_triplet_3f
    local _116_
    if reverse_3f then
      _116_ = dec
    else
      _116_ = inc
    end
    same_char_triplet_3f = ((ch2 == prev_match.ch2) and (line == prev_match.line) and (col == _116_(prev_match.col)))
    prev_match = {ch2 = ch2, col = col, line = line}
    if not same_char_triplet_3f then
      table.insert(targets0, {["edge-pos?"] = ((ch2 == "\13") or (col == right_bound)), pair = {ch1, ch2}, pos = pos, wininfo = wininfo})
    end
  end
  if next(targets0) then
    return targets0
  end
end
local function distance(_120_, _122_)
  local _arg_121_ = _120_
  local l1 = _arg_121_[1]
  local c1 = _arg_121_[2]
  local _arg_123_ = _122_
  local l2 = _arg_123_[1]
  local c2 = _arg_123_[2]
  local editor_grid_aspect_ratio = 0.3
  local _let_124_ = {abs((c1 - c2)), abs((l1 - l2))}
  local dx = _let_124_[1]
  local dy = _let_124_[2]
  local dx0 = (dx * editor_grid_aspect_ratio)
  return pow((pow(dx0, 2) + pow(dy, 2)), 0.5)
end
local function get_targets(input, _125_)
  local _arg_126_ = _125_
  local reverse_3f = _arg_126_["reverse?"]
  local target_windows = _arg_126_["target-windows"]
  if target_windows then
    local targets = {}
    local cursor_positions = {}
    local cross_win_3f = not ((#target_windows == 1) and (target_windows[1].winid == vim.fn.win_getid()))
    local source_winid = vim.fn.win_getid()
    for _, w in ipairs(target_windows) do
      if cross_win_3f then
        api.nvim_set_current_win(w.winid)
      end
      cursor_positions[w.winid] = get_cursor_pos()
      get_targets_2a(input, {["source-winid"] = source_winid, targets = targets, wininfo = w})
    end
    if cross_win_3f then
      api.nvim_set_current_win(source_winid)
    end
    if not empty_3f(targets) then
      local by_screen_pos_3f = (vim.o.wrap and (#targets < 200))
      if by_screen_pos_3f then
        for winid, _129_ in pairs(cursor_positions) do
          local _each_130_ = _129_
          local line = _each_130_[1]
          local col = _each_130_[2]
          local _131_ = vim.fn.screenpos(winid, line, col)
          if ((type(_131_) == "table") and ((_131_).col == col) and (nil ~= (_131_).row)) then
            local row = (_131_).row
            cursor_positions[winid] = {row, col}
          end
        end
      end
      for _, _134_ in ipairs(targets) do
        local _each_135_ = _134_
        local t = _each_135_
        local _each_136_ = _each_135_["pos"]
        local line = _each_136_[1]
        local col = _each_136_[2]
        local _each_137_ = _each_135_["wininfo"]
        local winid = _each_137_["winid"]
        if by_screen_pos_3f then
          local _138_ = vim.fn.screenpos(winid, line, col)
          if ((type(_138_) == "table") and ((_138_).col == col) and (nil ~= (_138_).row)) then
            local row = (_138_).row
            t["screenpos"] = {row, col}
          end
        end
        t["rank"] = distance((t.screenpos or t.pos), cursor_positions[winid])
      end
      local function _141_(_241, _242)
        return ((_241).rank < (_242).rank)
      end
      table.sort(targets, _141_)
      return targets
    end
  else
    return get_targets_2a(input, {["reverse?"] = reverse_3f})
  end
end
local function populate_sublists(targets)
  targets["sublists"] = {}
  if opts.case_insensitive then
    local function _144_(self, k)
      return rawget(self, k:lower())
    end
    local function _145_(self, k, v)
      return rawset(self, k:lower(), v)
    end
    setmetatable(targets.sublists, {__index = _144_, __newindex = _145_})
  end
  for _, _147_ in ipairs(targets) do
    local _each_148_ = _147_
    local target = _each_148_
    local _each_149_ = _each_148_["pair"]
    local _0 = _each_149_[1]
    local ch2 = _each_149_[2]
    if not targets.sublists[ch2] then
      targets["sublists"][ch2] = {}
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
  local _151_
  if user_forced_autojump_3f() then
    _151_ = opts.safe_labels
  elseif user_forced_no_autojump_3f() then
    _151_ = opts.labels
  elseif sublist["autojump?"] then
    _151_ = opts.safe_labels
  else
    _151_ = opts.labels
  end
  sublist["label-set"] = _151_
  return nil
end
local function set_sublist_attributes(targets, _153_)
  local _arg_154_ = _153_
  local force_no_autojump_3f = _arg_154_["force-no-autojump?"]
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
        local _155_
        if not (autojump_3f and (i == 1)) then
          local _156_
          local _158_
          if autojump_3f then
            _158_ = dec(i)
          else
            _158_ = i
          end
          _156_ = (_158_ % #labels0)
          if (_156_ == 0) then
            _155_ = (labels0)[#labels0]
          elseif (nil ~= _156_) then
            local n = _156_
            _155_ = (labels0)[n]
          else
          _155_ = nil
          end
        else
        _155_ = nil
        end
        target["label"] = _155_
      end
    end
  end
  return nil
end
local function set_label_states(sublist, _165_)
  local _arg_166_ = _165_
  local group_offset = _arg_166_["group-offset"]
  local labels0 = sublist["label-set"]
  local _7clabels_7c = #labels0
  local offset = (group_offset * _7clabels_7c)
  local primary_start
  local _167_
  if sublist["autojump?"] then
    _167_ = 2
  else
    _167_ = 1
  end
  primary_start = (offset + _167_)
  local primary_end = (primary_start + dec(_7clabels_7c))
  local secondary_end = (primary_end + _7clabels_7c)
  for i, target in ipairs(sublist) do
    if target.label then
      local _169_
      if ((i < primary_start) or (i > secondary_end)) then
        _169_ = "inactive"
      elseif (i <= primary_end) then
        _169_ = "active-primary"
      else
        _169_ = "active-secondary"
      end
      target["label-state"] = _169_
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
  local _let_172_ = target
  local edge_pos_3f = _let_172_["edge-pos?"]
  local label = _let_172_["label"]
  local label_state = _let_172_["label-state"]
  local _let_173_ = _let_172_["pair"]
  local ch1 = _let_173_[1]
  local ch2 = _let_173_[2]
  local offset
  local _174_
  if edge_pos_3f then
    _174_ = 0
  else
    _174_ = ch2:len()
  end
  offset = (ch1:len() + _174_)
  local _176_
  if (not label_state or force_no_labels_3f) then
    _176_ = "match-highlight"
  else
    local _177_ = label_state
    if (_177_ == "active-primary") then
      _176_ = {offset, {{label, hl.group["label-primary"]}}}
    elseif (_177_ == "active-secondary") then
      _176_ = {offset, {{label, hl.group["label-secondary"]}}}
    elseif (_177_ == "inactive") then
      _176_ = nil
    else
    _176_ = nil
    end
  end
  target["beacon"] = _176_
  return nil
end
local function set_beacons(target_list, _184_)
  local _arg_185_ = _184_
  local force_no_labels_3f = _arg_185_["force-no-labels?"]
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
      local _let_186_ = map(dec, target.pos)
      local lnum = _let_186_[1]
      local col = _let_186_[2]
      local bufnr
      local function _188_()
        local t_187_ = target.wininfo
        if (nil ~= t_187_) then
          t_187_ = (t_187_).bufnr
        end
        return t_187_
      end
      bufnr = (_188_() or 0)
      local winid
      local function _191_()
        local t_190_ = target.wininfo
        if (nil ~= t_190_) then
          t_190_ = (t_190_).winid
        end
        return t_190_
      end
      winid = (_191_() or 0)
      local _193_ = target.beacon
      if (_193_ == "match-highlight") then
        local _let_194_ = target.pair
        local ch1 = _let_194_[1]
        local ch2 = _let_194_[2]
        local k1 = table.concat({bufnr, " ", winid, " ", lnum, " ", col})
        local k2 = table.concat({bufnr, " ", winid, " ", lnum, " ", (col + ch1:len())})
        for _, k in ipairs({k1, k2}) do
          match_hl_positions[k] = true
          local _195_ = label_positions[k]
          if (nil ~= _195_) then
            local id = _195_
            api.nvim_buf_del_extmark(bufnr, hl.ns, id)
          end
        end
        api.nvim_buf_add_highlight(bufnr, hl.ns, hl.group.match, lnum, col, (col + ch1:len() + ch2:len()))
      elseif ((type(_193_) == "table") and (nil ~= (_193_)[1]) and (nil ~= (_193_)[2])) then
        local label_offset = (_193_)[1]
        local virttext = (_193_)[2]
        local col0 = (col + label_offset)
        local k = table.concat({bufnr, " ", winid, " ", lnum, " ", col0})
        local _197_ = (match_hl_positions[k] or label_positions[k])
        if (_197_ == true) then
        elseif (nil ~= _197_) then
          local id = _197_
          api.nvim_buf_del_extmark(bufnr, hl.ns, id)
        else
          local _ = _197_
          label_positions[k] = api.nvim_buf_set_extmark(bufnr, hl.ns, lnum, col0, {priority = hl.priority.label, virt_text = virttext, virt_text_pos = "overlay"})
        end
      end
    end
  end
  return nil
end
local state = {["dot-repeat"] = {["target-idx"] = nil, in1 = nil, in2 = nil}, ["repeat"] = {in1 = nil, in2 = nil}}
local function leap(_201_)
  local _arg_202_ = _201_
  local cross_window_3f = _arg_202_["cross-window?"]
  local dot_repeat_3f = _arg_202_["dot-repeat?"]
  local omni_3f = _arg_202_["omni?"]
  local reverse_3f = _arg_202_["reverse?"]
  local traversal_state = _arg_202_["traversal-state"]
  local x_mode_3f = _arg_202_["x-mode?"]
  local mode = api.nvim_get_mode().mode
  local visual_mode_3f = ((mode == _3cctrl_v_3e) or (mode == "V") or (mode == "v"))
  local op_mode_3f = mode:match("o")
  local change_op_3f = (op_mode_3f and (vim.v.operator == "c"))
  local dot_repeatable_op_3f = (op_mode_3f and not omni_3f and (vim.v.operator ~= "y"))
  local doing_traversal_3f = traversal_state
  local force_no_autojump_3f = (op_mode_3f or (omni_3f and visual_mode_3f) or cross_window_3f)
  local force_no_labels_3f = (doing_traversal_3f and not traversal_state.sublist["autojump?"])
  local _3ftarget_windows
  if cross_window_3f then
    _3ftarget_windows = get_targetable_windows()
  elseif omni_3f then
    _3ftarget_windows = {vim.fn.getwininfo(vim.fn.win_getid())[1]}
  else
  _3ftarget_windows = nil
  end
  local spec_keys
  local function _204_(_, k)
    return replace_keycodes(opts.special_keys[k])
  end
  spec_keys = setmetatable({}, {__index = _204_})
  local new_search_3f = not (dot_repeat_3f or doing_traversal_3f)
  local function get_first_input()
    if doing_traversal_3f then
      return state["repeat"].in1
    elseif dot_repeat_3f then
      return state["dot-repeat"].in1
    else
      local _205_
      local function _206_()
        local res_2_auto
        do
          res_2_auto = get_input()
        end
        hl:cleanup(_3ftarget_windows)
        return res_2_auto
      end
      local function _207_()
        if change_op_3f then
          handle_interrupted_change_op_21()
        end
        do
        end
        doau_when_exists("LeapLeave")
        return nil
      end
      _205_ = (_206_() or _207_())
      if (_205_ == spec_keys["repeat"]) then
        new_search_3f = false
        local function _209_()
          if change_op_3f then
            handle_interrupted_change_op_21()
          end
          do
            echo_no_prev_search()
          end
          doau_when_exists("LeapLeave")
          return nil
        end
        return (state["repeat"].in1 or _209_())
      elseif (nil ~= _205_) then
        local _in = _205_
        return _in
      end
    end
  end
  local function update_state_2a(in1)
    local function _215_(_213_)
      local _arg_214_ = _213_
      local dot_repeat = _arg_214_["dot-repeat"]
      local _repeat = _arg_214_["repeat"]
      if new_search_3f then
        if _repeat then
          local _216_ = _repeat
          _216_["in1"] = in1
          state["repeat"] = _216_
        end
        if (dot_repeat and dot_repeatable_op_3f) then
          do
            local _218_ = dot_repeat
            _218_["in1"] = in1
            state["dot-repeat"] = _218_
          end
          return nil
        end
      end
    end
    return _215_
  end
  local jump_to_21
  do
    local first_jump_3f = true
    local function _221_(target)
      if target.wininfo then
        api.nvim_set_current_win(target.wininfo.winid)
      end
      local function _223_()
        if x_mode_3f then
          push_cursor_21("fwd")
          if reverse_3f then
            return push_cursor_21("fwd")
          end
        end
      end
      jump_to_21_2a(target.pos, {["add-to-jumplist?"] = (first_jump_3f and not doing_traversal_3f), ["inclusive-motion?"] = (x_mode_3f and not reverse_3f), ["reverse?"] = reverse_3f, adjust = _223_, mode = mode})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _221_
  end
  local function get_last_input(sublist, _226_)
    local _arg_227_ = _226_
    local display_targets_from = _arg_227_["display-targets-from"]
    local function recur(group_offset, initial_invoc_3f)
      set_beacons(sublist, {["force-no-labels?"] = force_no_labels_3f})
      do
        if new_search_3f then
          apply_backdrop(reverse_3f, _3ftarget_windows)
        end
        do
          light_up_beacons(sublist, display_targets_from)
        end
        highlight_cursor()
        vim.cmd("redraw")
      end
      local _229_
      do
        local res_2_auto
        do
          res_2_auto = get_input()
        end
        hl:cleanup(_3ftarget_windows)
        _229_ = res_2_auto
      end
      if (nil ~= _229_) then
        local input = _229_
        if (sublist["autojump?"] and not user_forced_autojump_3f()) then
          return {input, 0}
        else
          local _230_
          if not initial_invoc_3f then
            _230_ = spec_keys.prev_match_group
          else
          _230_ = nil
          end
          if (not doing_traversal_3f and ((input == spec_keys.next_match_group) or (input == _230_))) then
            local labels0 = sublist["label-set"]
            local num_of_groups = ceil((#sublist / #labels0))
            local max_offset = dec(num_of_groups)
            local new_group_offset
            local _233_
            do
              local _232_ = input
              if (_232_ == spec_keys.next_match_group) then
                _233_ = inc
              else
                local _ = _232_
                _233_ = dec
              end
            end
            new_group_offset = clamp(_233_(group_offset), 0, max_offset)
            set_label_states(sublist, {["group-offset"] = new_group_offset})
            return recur(new_group_offset)
          else
            return {input, group_offset}
          end
        end
      end
    end
    return recur(0, true)
  end
  local function get_traversal_action(_in)
    if (_in == spec_keys["repeat"]) then
      return "to-next"
    elseif (doing_traversal_3f and (_in == spec_keys.revert)) then
      return "to-prev"
    end
  end
  local function get_target_with_active_primary_label(target_list, input)
    local res = nil
    for idx, _240_ in ipairs(target_list) do
      local _each_241_ = _240_
      local target = _each_241_
      local label = _each_241_["label"]
      local label_state = _each_241_["label-state"]
      if res then break end
      if ((label == input) and (label_state == "active-primary")) then
        res = {idx, target}
      end
    end
    return res
  end
  if not (dot_repeat_3f or doing_traversal_3f) then
    doau_when_exists("LeapEnter")
    echo("")
    if new_search_3f then
      apply_backdrop(reverse_3f, _3ftarget_windows)
    end
    do
    end
    highlight_cursor()
    vim.cmd("redraw")
  end
  local _245_ = get_first_input()
  if (nil ~= _245_) then
    local in1 = _245_
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
    local _248_
    local function _250_()
      local t_249_ = traversal_state
      if (nil ~= t_249_) then
        t_249_ = (t_249_).sublist
      end
      return t_249_
    end
    local function _252_()
      if change_op_3f then
        handle_interrupted_change_op_21()
      end
      do
        echo_not_found((in1 .. (prev_in2 or "")))
      end
      doau_when_exists("LeapLeave")
      return nil
    end
    _248_ = (_250_() or get_targets(in1, {["reverse?"] = reverse_3f, ["target-windows"] = _3ftarget_windows}) or _252_())
    if (nil ~= _248_) then
      local targets = _248_
      if not doing_traversal_3f then
        local _254_ = targets
        populate_sublists(_254_)
        set_sublist_attributes(_254_, {["force-no-autojump?"] = force_no_autojump_3f})
        set_labels(_254_)
        set_initial_label_states(_254_)
      end
      if new_search_3f then
        set_beacons(targets, {})
        if new_search_3f then
          apply_backdrop(reverse_3f, _3ftarget_windows)
        end
        do
          light_up_beacons(targets)
        end
        highlight_cursor()
        vim.cmd("redraw")
      end
      local _258_
      local function _259_()
        local res_2_auto
        do
          res_2_auto = get_input()
        end
        hl:cleanup(_3ftarget_windows)
        return res_2_auto
      end
      local function _260_()
        if change_op_3f then
          handle_interrupted_change_op_21()
        end
        do
        end
        doau_when_exists("LeapLeave")
        return nil
      end
      _258_ = (prev_in2 or _259_() or _260_())
      if (nil ~= _258_) then
        local in2 = _258_
        update_state({["repeat"] = {in2 = in2}})
        local _262_
        local function _264_()
          local t_263_ = traversal_state
          if (nil ~= t_263_) then
            t_263_ = (t_263_).sublist
          end
          return t_263_
        end
        local function _266_()
          if change_op_3f then
            handle_interrupted_change_op_21()
          end
          do
            echo_not_found((in1 .. in2))
          end
          doau_when_exists("LeapLeave")
          return nil
        end
        _262_ = (_264_() or targets.sublists[in2] or _266_())
        if ((type(_262_) == "table") and (nil ~= (_262_)[1]) and ((_262_)[2] == nil)) then
          local only = (_262_)[1]
          if (dot_repeat_3f and (state["dot-repeat"]["target-idx"] ~= 1)) then
            if change_op_3f then
              handle_interrupted_change_op_21()
            end
            do
            end
            doau_when_exists("LeapLeave")
            return nil
          else
            if dot_repeatable_op_3f then
              set_dot_repeat(replace_keycodes(get_plug_key(reverse_3f, x_mode_3f, true)))
            end
            do
              update_state({["dot-repeat"] = {["target-idx"] = 1, in2 = in2}})
              jump_to_21(only)
            end
            doau_when_exists("LeapLeave")
            return nil
          end
        elseif ((type(_262_) == "table") and (nil ~= (_262_)[1])) then
          local first = (_262_)[1]
          local sublist = _262_
          if dot_repeat_3f then
            local _271_ = sublist[state["dot-repeat"]["target-idx"]]
            if (nil ~= _271_) then
              local target = _271_
              if dot_repeatable_op_3f then
                set_dot_repeat(replace_keycodes(get_plug_key(reverse_3f, x_mode_3f, true)))
              end
              do
                jump_to_21(target)
              end
              doau_when_exists("LeapLeave")
              return nil
            else
              local _ = _271_
              if change_op_3f then
                handle_interrupted_change_op_21()
              end
              do
              end
              doau_when_exists("LeapLeave")
              return nil
            end
          else
            local curr_idx
            local function _276_()
              local t_275_ = traversal_state
              if (nil ~= t_275_) then
                t_275_ = (t_275_).idx
              end
              return t_275_
            end
            curr_idx = (_276_() or 0)
            if not doing_traversal_3f then
              if sublist["autojump?"] then
                jump_to_21(first)
                curr_idx = 1
              end
            end
            local _280_
            local function _281_()
              if change_op_3f then
                handle_interrupted_change_op_21()
              end
              do
              end
              doau_when_exists("LeapLeave")
              return nil
            end
            _280_ = (get_last_input(sublist, {["display-targets-from"] = inc(curr_idx)}) or _281_())
            if ((type(_280_) == "table") and (nil ~= (_280_)[1]) and (nil ~= (_280_)[2])) then
              local in3 = (_280_)[1]
              local group_offset = (_280_)[2]
              local _283_
              if not ((group_offset > 0) or op_mode_3f or omni_3f or cross_window_3f) then
                _283_ = get_traversal_action(in3)
              else
              _283_ = nil
              end
              if (nil ~= _283_) then
                local action = _283_
                local new_idx
                do
                  local _285_ = action
                  if (_285_ == "to-next") then
                    new_idx = min(inc(curr_idx), #targets)
                  elseif (_285_ == "to-prev") then
                    new_idx = max(dec(curr_idx), 1)
                  else
                  new_idx = nil
                  end
                end
                jump_to_21(sublist[new_idx])
                return leap({["reverse?"] = reverse_3f, ["traversal-state"] = {idx = new_idx, sublist = sublist}, ["x-mode?"] = x_mode_3f})
              else
                local _ = _283_
                local _287_
                if not force_no_labels_3f then
                  _287_ = get_target_with_active_primary_label(sublist, in3)
                else
                _287_ = nil
                end
                if ((type(_287_) == "table") and (nil ~= (_287_)[1]) and (nil ~= (_287_)[2])) then
                  local idx = (_287_)[1]
                  local target = (_287_)[2]
                  if dot_repeatable_op_3f then
                    set_dot_repeat(replace_keycodes(get_plug_key(reverse_3f, x_mode_3f, true)))
                  end
                  do
                    update_state({["dot-repeat"] = {["target-idx"] = idx, in2 = in2}})
                    jump_to_21(target)
                  end
                  doau_when_exists("LeapLeave")
                  return nil
                else
                  local _0 = _287_
                  if (sublist["autojump?"] or doing_traversal_3f) then
                    if dot_repeatable_op_3f then
                      set_dot_repeat(replace_keycodes(get_plug_key(reverse_3f, x_mode_3f, true)))
                    end
                    do
                      vim.fn.feedkeys(in3, "i")
                    end
                    doau_when_exists("LeapLeave")
                    return nil
                  else
                    if change_op_3f then
                      handle_interrupted_change_op_21()
                    end
                    do
                    end
                    doau_when_exists("LeapLeave")
                    return nil
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
local function set_default_keymaps(force_3f)
  for _, _301_ in ipairs({{"n", "s", "<Plug>(leap-forward)"}, {"n", "S", "<Plug>(leap-backward)"}, {"x", "s", "<Plug>(leap-forward)"}, {"x", "S", "<Plug>(leap-backward)"}, {"o", "z", "<Plug>(leap-forward)"}, {"o", "Z", "<Plug>(leap-backward)"}, {"o", "x", "<Plug>(leap-forward-x)"}, {"o", "X", "<Plug>(leap-backward-x)"}, {"n", "gs", "<Plug>(leap-cross-window)"}, {"x", "gs", "<Plug>(leap-cross-window)"}, {"o", "gs", "<Plug>(leap-cross-window)"}}) do
    local _each_302_ = _301_
    local mode = _each_302_[1]
    local lhs = _each_302_[2]
    local rhs = _each_302_[3]
    if (force_3f or ((vim.fn.mapcheck(lhs, mode) == "") and (vim.fn.hasmapto(rhs, mode) == 0))) then
      vim.keymap.set(mode, lhs, rhs, {silent = true})
    end
  end
  return nil
end
local function _304_()
  return leap({["dot-repeat?"] = true, ["reverse?"] = true})
end
local function _305_()
  return leap({["dot-repeat?"] = true, ["reverse?"] = true, ["x-mode?"] = true})
end
local function _306_()
  return leap({["dot-repeat?"] = true})
end
local function _307_()
  return leap({["dot-repeat?"] = true, ["x-mode?"] = true})
end
for lhs, rhs in pairs({["<Plug>(leap-dotrepeat-backward)"] = _304_, ["<Plug>(leap-dotrepeat-backward-x)"] = _305_, ["<Plug>(leap-dotrepeat-forward)"] = _306_, ["<Plug>(leap-dotrepeat-forward-x)"] = _307_}) do
  vim.keymap.set("o", lhs, rhs, {silent = true})
end
local temporary_editor_opts = {["vim.bo.modeline"] = false}
local saved_editor_opts = {}
local function save_editor_opts()
  for opt, _ in pairs(temporary_editor_opts) do
    local _let_308_ = vim.split(opt, ".", true)
    local _0 = _let_308_[1]
    local scope = _let_308_[2]
    local name = _let_308_[3]
    saved_editor_opts[opt] = _G.vim[scope][name]
  end
  return nil
end
local function set_editor_opts(opts0)
  for opt, val in pairs(opts0) do
    local _let_309_ = vim.split(opt, ".", true)
    local _ = _let_309_[1]
    local scope = _let_309_[2]
    local name = _let_309_[3]
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
local function _310_()
  save_editor_opts()
  return set_temporary_editor_opts()
end
api.nvim_create_autocmd("User", {callback = _310_, group = "LeapDefault", pattern = "LeapEnter"})
api.nvim_create_autocmd("User", {callback = restore_editor_opts, group = "LeapDefault", pattern = "LeapLeave"})
return {init_highlight = init_highlight, leap = leap, opts = opts, set_default_keymaps = set_default_keymaps, setup = setup, state = state}
