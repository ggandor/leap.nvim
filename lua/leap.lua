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
  pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchparen"})
  return pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchup_matchparen"})
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
local function exec_autocmds(pattern)
  return api.nvim_exec_autocmds("User", {pattern = pattern, modeline = false})
end
local function get_input()
  local _55_, _56_ = pcall(vim.fn.getcharstr)
  local function _57_()
    local ch = _56_
    return (ch ~= _3cesc_3e)
  end
  if (((_55_ == true) and (nil ~= _56_)) and _57_()) then
    local ch = _56_
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
  local function _60_(_241)
    return (vim.fn.getwininfo(_241))[1]
  end
  get_wininfo = _60_
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
local function get_match_positions(pattern, _63_)
  local _arg_64_ = _63_
  local reverse_3f = _arg_64_["reverse?"]
  local whole_window_3f = _arg_64_["whole-window?"]
  local source_winid = _arg_64_["source-winid"]
  local _arg_65_ = _arg_64_["bounds"]
  local left_bound = _arg_65_[1]
  local right_bound = _arg_65_[2]
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
  local function _69_()
    vim.fn.winrestview(view)
    vim.o.cpo = cpo
    return nil
  end
  cleanup = _69_
  local function reach_right_bound()
    while ((vim.fn.virtcol(".") < right_bound) and not (vim.fn.col(".") >= dec(vim.fn.col("$")))) do
      vim.cmd("norm! l")
    end
    return nil
  end
  local function skip_to_fold_edge_21()
    local _70_
    local _71_
    if reverse_3f0 then
      _71_ = vim.fn.foldclosed
    else
      _71_ = vim.fn.foldclosedend
    end
    _70_ = _71_(vim.fn.line("."))
    if (_70_ == -1) then
      return "not-in-fold"
    elseif (nil ~= _70_) then
      local fold_edge = _70_
      vim.fn.cursor(fold_edge, 0)
      local function _73_()
        if reverse_3f0 then
          return 1
        else
          return vim.fn.col("$")
        end
      end
      vim.fn.cursor(0, _73_())
      return "moved-the-cursor"
    else
      return nil
    end
  end
  local function skip_to_next_in_window_pos_21()
    local _local_75_ = {vim.fn.line("."), vim.fn.virtcol(".")}
    local line = _local_75_[1]
    local virtcol = _local_75_[2]
    local from_pos = _local_75_
    local _76_
    if (virtcol < left_bound) then
      if reverse_3f0 then
        if (dec(line) >= stopline) then
          _76_ = {dec(line), right_bound}
        else
          _76_ = nil
        end
      else
        _76_ = {line, left_bound}
      end
    elseif (virtcol > right_bound) then
      if reverse_3f0 then
        _76_ = {line, right_bound}
      else
        if (inc(line) <= stopline) then
          _76_ = {inc(line), left_bound}
        else
          _76_ = nil
        end
      end
    else
      _76_ = nil
    end
    if (nil ~= _76_) then
      local to_pos = _76_
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
    local function _86_()
      if win_enter_3f then
        win_enter_3f = false
        return true
      else
        return nil
      end
    end
    match_at_curpos_3f0 = (match_at_curpos_3f or _86_())
    local _88_
    local function _89_()
      if match_at_curpos_3f0 then
        return "c"
      else
        return ""
      end
    end
    _88_ = vim.fn.searchpos(pattern, (opts0 .. _89_()), stopline)
    if ((_G.type(_88_) == "table") and ((_88_)[1] == 0) and true) then
      local _ = (_88_)[2]
      return cleanup()
    elseif ((_G.type(_88_) == "table") and (nil ~= (_88_)[1]) and (nil ~= (_88_)[2])) then
      local line = (_88_)[1]
      local col = (_88_)[2]
      local pos = _88_
      local _90_ = skip_to_fold_edge_21()
      if (_90_ == "moved-the-cursor") then
        return recur(false)
      elseif (_90_ == "not-in-fold") then
        if ((curr_winid == source_winid) and (view.lnum == line) and (inc(view.col) == col)) then
          push_cursor_21("fwd")
          return recur(true)
        elseif ((function(_91_,_92_,_93_) return (_91_ <= _92_) and (_92_ <= _93_) end)(left_bound,col,right_bound) or vim.wo.wrap) then
          match_count = (match_count + 1)
          return pos
        else
          local _94_ = skip_to_next_in_window_pos_21()
          if (_94_ == "moved-the-cursor") then
            return recur(true)
          elseif true then
            local _ = _94_
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
local function get_targets_2a(input, _99_)
  local _arg_100_ = _99_
  local reverse_3f = _arg_100_["reverse?"]
  local wininfo = _arg_100_["wininfo"]
  local targets = _arg_100_["targets"]
  local source_winid = _arg_100_["source-winid"]
  local targets0 = (targets or {})
  local prev_match = {}
  local _let_101_ = get_horizontal_bounds()
  local _ = _let_101_[1]
  local right_bound = _let_101_[2]
  local bounds = _let_101_
  local pattern
  local function _102_()
    if opts.case_insensitive then
      return "\\c"
    else
      return "\\C"
    end
  end
  pattern = ("\\V" .. _102_() .. input:gsub("\\", "\\\\") .. "\\_.")
  for _103_ in get_match_positions(pattern, {bounds = bounds, ["reverse?"] = reverse_3f, ["source-winid"] = source_winid, ["whole-window?"] = wininfo}) do
    local _each_104_ = _103_
    local line = _each_104_[1]
    local col = _each_104_[2]
    local pos = _each_104_
    local ch1 = char_at_pos(pos, {})
    local ch2, eol_3f = nil, nil
    do
      local _105_ = char_at_pos(pos, {["char-offset"] = 1})
      if (nil ~= _105_) then
        local char = _105_
        ch2, eol_3f = char
      elseif true then
        local _0 = _105_
        ch2, eol_3f = replace_keycodes(opts.special_keys.eol), true
      else
        ch2, eol_3f = nil
      end
    end
    local same_char_triplet_3f
    local _107_
    if reverse_3f then
      _107_ = dec
    else
      _107_ = inc
    end
    same_char_triplet_3f = ((ch2 == prev_match.ch2) and (line == prev_match.line) and (col == _107_(prev_match.col)))
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
local function distance(_111_, _113_)
  local _arg_112_ = _111_
  local l1 = _arg_112_[1]
  local c1 = _arg_112_[2]
  local _arg_114_ = _113_
  local l2 = _arg_114_[1]
  local c2 = _arg_114_[2]
  local editor_grid_aspect_ratio = 0.3
  local _let_115_ = {abs((c1 - c2)), abs((l1 - l2))}
  local dx = _let_115_[1]
  local dy = _let_115_[2]
  local dx0 = (dx * editor_grid_aspect_ratio)
  return pow((pow(dx0, 2) + pow(dy, 2)), 0.5)
end
local function get_targets(input, _116_)
  local _arg_117_ = _116_
  local reverse_3f = _arg_117_["reverse?"]
  local target_windows = _arg_117_["target-windows"]
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
        for winid, _120_ in pairs(cursor_positions) do
          local _each_121_ = _120_
          local line = _each_121_[1]
          local col = _each_121_[2]
          local _122_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_122_) == "table") and (nil ~= (_122_).row) and ((_122_).col == col)) then
            local row = (_122_).row
            cursor_positions[winid] = {row, col}
          else
          end
        end
      else
      end
      for _, _125_ in ipairs(targets) do
        local _each_126_ = _125_
        local _each_127_ = _each_126_["pos"]
        local line = _each_127_[1]
        local col = _each_127_[2]
        local _each_128_ = _each_126_["wininfo"]
        local winid = _each_128_["winid"]
        local t = _each_126_
        if by_screen_pos_3f then
          local _129_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_129_) == "table") and (nil ~= (_129_).row) and ((_129_).col == col)) then
            local row = (_129_).row
            t["screenpos"] = {row, col}
          else
          end
        else
        end
        t["rank"] = distance((t.screenpos or t.pos), cursor_positions[winid])
      end
      local function _132_(_241, _242)
        return ((_241).rank < (_242).rank)
      end
      table.sort(targets, _132_)
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
    local function _135_(self, k)
      return rawget(self, k:lower())
    end
    local function _136_(self, k, v)
      return rawset(self, k:lower(), v)
    end
    setmetatable(targets.sublists, {__index = _135_, __newindex = _136_})
  else
  end
  for _, _138_ in ipairs(targets) do
    local _each_139_ = _138_
    local _each_140_ = _each_139_["pair"]
    local _0 = _each_140_[1]
    local ch2 = _each_140_[2]
    local target = _each_139_
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
  local _142_
  if user_forced_autojump_3f() then
    _142_ = opts.safe_labels
  elseif user_forced_no_autojump_3f() then
    _142_ = opts.labels
  elseif sublist["autojump?"] then
    _142_ = opts.safe_labels
  else
    _142_ = opts.labels
  end
  sublist["label-set"] = _142_
  return nil
end
local function set_sublist_attributes(targets, _144_)
  local _arg_145_ = _144_
  local force_no_autojump_3f = _arg_145_["force-no-autojump?"]
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
          local _148_
          do
            local _147_ = (i0 % #labels0)
            if (_147_ == 0) then
              _148_ = (labels0)[#labels0]
            elseif (nil ~= _147_) then
              local n = _147_
              _148_ = (labels0)[n]
            else
              _148_ = nil
            end
          end
          target["label"] = _148_
        else
        end
      end
    else
    end
  end
  return nil
end
local function set_label_states(sublist, _154_)
  local _arg_155_ = _154_
  local group_offset = _arg_155_["group-offset"]
  local labels0 = sublist["label-set"]
  local _7clabels_7c = #labels0
  local offset = (group_offset * _7clabels_7c)
  local primary_start
  local function _156_()
    if sublist["autojump?"] then
      return 2
    else
      return 1
    end
  end
  primary_start = (offset + _156_())
  local primary_end = (primary_start + dec(_7clabels_7c))
  local secondary_start = inc(primary_end)
  local secondary_end = (primary_end + _7clabels_7c)
  for i, target in ipairs(sublist) do
    if target.label then
      local _157_
      if (function(_158_,_159_,_160_) return (_158_ <= _159_) and (_159_ <= _160_) end)(primary_start,i,primary_end) then
        _157_ = "active-primary"
      elseif (function(_161_,_162_,_163_) return (_161_ <= _162_) and (_162_ <= _163_) end)(secondary_start,i,secondary_end) then
        _157_ = "active-secondary"
      elseif (i > secondary_end) then
        _157_ = "inactive"
      else
        _157_ = nil
      end
      target["label-state"] = _157_
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
local function set_beacons(target_list, _166_)
  local _arg_167_ = _166_
  local force_no_labels_3f = _arg_167_["force-no-labels?"]
  local function set_match_highlight(_168_)
    local _arg_169_ = _168_
    local _arg_170_ = _arg_169_["pair"]
    local ch1 = _arg_170_[1]
    local ch2 = _arg_170_[2]
    local target = _arg_169_
    target["beacon"] = {0, {{(ch1 .. ch2), hl.group.match}}}
    return nil
  end
  if force_no_labels_3f then
    for _, target in ipairs(target_list) do
      set_match_highlight(target)
    end
    return
  else
  end
  for _, target in ipairs(target_list) do
    local _local_172_ = target
    local _local_173_ = _local_172_["pair"]
    local ch1 = _local_173_[1]
    local ch2 = _local_173_[2]
    local label = _local_172_["label"]
    local label_state = _local_172_["label-state"]
    local edge_pos_3f = _local_172_["edge-pos?"]
    local offset
    local function _174_()
      if edge_pos_3f then
        return 0
      else
        return ch2:len()
      end
    end
    offset = (ch1:len() + _174_())
    local virttext
    do
      local _175_ = label_state
      if (_175_ == "active-primary") then
        virttext = {{label, hl.group["label-primary"]}}
      elseif (_175_ == "active-secondary") then
        virttext = {{label, hl.group["label-secondary"]}}
      elseif (_175_ == "inactive") then
        virttext = {{" ", hl.group["label-secondary"]}}
      else
        virttext = nil
      end
    end
    local beacon
    if virttext then
      beacon = {offset, virttext}
    else
      beacon = nil
    end
    target["beacon"] = beacon
  end
  local unlabeled_match_positions = {}
  local label_positions = {}
  for i, target in ipairs(target_list) do
    local _let_178_ = target
    local _let_179_ = _let_178_["pos"]
    local lnum = _let_179_[1]
    local col = _let_179_[2]
    local _let_180_ = _let_178_["pair"]
    local ch1 = _let_180_[1]
    local _ = _let_180_[2]
    local bufnr
    local function _181_()
      local t_182_ = target.wininfo
      if (nil ~= t_182_) then
        t_182_ = (t_182_).bufnr
      else
      end
      return t_182_
    end
    bufnr = (_181_() or 0)
    local winid
    local function _184_()
      local t_185_ = target.wininfo
      if (nil ~= t_185_) then
        t_185_ = (t_185_).winid
      else
      end
      return t_185_
    end
    winid = (_184_() or 0)
    local _187_ = target.beacon
    if (_187_ == nil) then
      local k1 = (bufnr .. " " .. winid .. " " .. lnum .. " " .. col)
      local k2 = (bufnr .. " " .. winid .. " " .. lnum .. " " .. (col + ch1:len()))
      for _0, k in ipairs({k1, k2}) do
        do
          local _188_ = label_positions[k]
          if (nil ~= _188_) then
            local other = _188_
            other["beacon"] = nil
            set_match_highlight(target)
          else
          end
        end
        unlabeled_match_positions[k] = target
      end
    elseif ((_G.type(_187_) == "table") and (nil ~= (_187_)[1]) and true) then
      local offset = (_187_)[1]
      local _0 = (_187_)[2]
      local set_empty_label
      local function _190_(_241)
        _241["beacon"][2][1][1] = " "
        return nil
      end
      set_empty_label = _190_
      local col0 = (col + offset)
      local k = (bufnr .. " " .. winid .. " " .. lnum .. " " .. col0)
      do
        local _191_ = unlabeled_match_positions[k]
        if (nil ~= _191_) then
          local other = _191_
          target["beacon"] = nil
          set_match_highlight(other)
        elseif true then
          local _1 = _191_
          local _192_ = label_positions[k]
          if (nil ~= _192_) then
            local other = _192_
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
local function light_up_beacons(target_list, _3fstart_from)
  for i = (_3fstart_from or 1), #target_list do
    local target = target_list[i]
    local _196_ = target.beacon
    if ((_G.type(_196_) == "table") and (nil ~= (_196_)[1]) and (nil ~= (_196_)[2])) then
      local offset = (_196_)[1]
      local virttext = (_196_)[2]
      local _let_197_ = map(dec, target.pos)
      local lnum = _let_197_[1]
      local col = _let_197_[2]
      local bufnr
      local function _198_()
        local t_199_ = target.wininfo
        if (nil ~= t_199_) then
          t_199_ = (t_199_).bufnr
        else
        end
        return t_199_
      end
      bufnr = (_198_() or 0)
      api.nvim_buf_set_extmark(bufnr, hl.ns, lnum, (col + offset), {virt_text = virttext, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.label})
    else
    end
  end
  return nil
end
local state = {["repeat"] = {in1 = nil, in2 = nil}, ["dot-repeat"] = {in1 = nil, in2 = nil, ["reverse?"] = nil, ["x-mode?"] = nil, ["target-idx"] = nil}}
local function leap(_202_)
  local _arg_203_ = _202_
  local reverse_3f = _arg_203_["reverse?"]
  local x_mode_3f = _arg_203_["x-mode?"]
  local dot_repeat_3f = _arg_203_["dot-repeat?"]
  local target_windows = _arg_203_["target-windows"]
  local traversal_state = _arg_203_["traversal-state"]
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
    local _206_ = target_windows
    if (_G.type(_206_) == "table") then
      local t = _206_
      _3ftarget_windows = t
    elseif (_206_ == true) then
      _3ftarget_windows = get_other_windows_on_tabpage()
    else
      _3ftarget_windows = nil
    end
  end
  local bidirectional_3f = _3ftarget_windows
  local traversal_3f = traversal_state
  local mode = api.nvim_get_mode().mode
  local visual_mode_3f = ((mode == _3cctrl_v_3e) or (mode == "V") or (mode == "v"))
  local op_mode_3f = mode:match("o")
  local change_op_3f = (op_mode_3f and (vim.v.operator == "c"))
  local dot_repeatable_op_3f = (op_mode_3f and not bidirectional_3f and (vim.v.operator ~= "y"))
  local force_no_autojump_3f = (op_mode_3f or bidirectional_3f)
  local force_no_labels_3f = (traversal_3f and not traversal_state.targets["autojump?"])
  local spec_keys
  local function _208_(_, k)
    return replace_keycodes(opts.special_keys[k])
  end
  spec_keys = setmetatable({}, {__index = _208_})
  local new_search_3f = not (dot_repeat_3f or traversal_3f)
  local function get_first_pattern_input()
    if dot_repeat_3f then
      return state["dot-repeat"].in1
    else
      local _209_
      local function _210_()
        local res_2_auto
        do
          res_2_auto = get_input()
        end
        hl:cleanup(_3ftarget_windows)
        return res_2_auto
      end
      local function _211_()
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
        end
        exec_autocmds("LeapLeave")
        return nil
      end
      _209_ = (_210_() or _211_())
      if (_209_ == spec_keys.repeat_search) then
        new_search_3f = false
        local function _213_()
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
        return (state["repeat"].in1 or _213_())
      elseif (nil ~= _209_) then
        local _in = _209_
        return _in
      else
        return nil
      end
    end
  end
  local function get_prev_in2()
    if not new_search_3f then
      local _217_
      if dot_repeat_3f then
        _217_ = "dot-repeat"
      else
        _217_ = "repeat"
      end
      return state[_217_].in2
    else
      return nil
    end
  end
  local function update_state_2a(in1)
    local function _222_(_220_)
      local _arg_221_ = _220_
      local _repeat = _arg_221_["repeat"]
      local dot_repeat = _arg_221_["dot-repeat"]
      if not dot_repeat_3f then
        if _repeat then
          local _223_ = _repeat
          _223_["in1"] = in1
          state["repeat"] = _223_
        else
        end
        if (dot_repeat and dot_repeatable_op_3f) then
          do
            local _225_ = dot_repeat
            _225_["in1"] = in1
            _225_["reverse?"] = reverse_3f0
            _225_["x-mode?"] = x_mode_3f0
            state["dot-repeat"] = _225_
          end
          return nil
        else
          return nil
        end
      else
        return nil
      end
    end
    return _222_
  end
  local jump_to_21
  do
    local first_jump_3f = true
    local function _228_(target)
      if target.wininfo then
        api.nvim_set_current_win(target.wininfo.winid)
      else
      end
      local function _230_()
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
      jump_to_21_2a(target.pos, {mode = mode, ["reverse?"] = reverse_3f0, ["inclusive-motion?"] = (x_mode_3f0 and not reverse_3f0), ["add-to-jumplist?"] = (first_jump_3f and not traversal_3f), adjust = _230_})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _228_
  end
  local function post_pattern_input_loop(sublist, _233_)
    local _arg_234_ = _233_
    local display_targets_from = _arg_234_["display-targets-from"]
    local function recur(group_offset, initial_invoc_3f)
      if not initial_invoc_3f then
        set_label_states(sublist, {["group-offset"] = group_offset})
      else
      end
      set_beacons(sublist, {["force-no-labels?"] = force_no_labels_3f})
      do
        if new_search_3f then
          apply_backdrop(reverse_3f0, _3ftarget_windows)
        else
        end
        do
          light_up_beacons(sublist, display_targets_from)
        end
        highlight_cursor()
        vim.cmd("redraw")
      end
      local _237_
      local function _238_()
        local res_2_auto
        do
          res_2_auto = get_input()
        end
        hl:cleanup(_3ftarget_windows)
        return res_2_auto
      end
      local function _239_()
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
        end
        exec_autocmds("LeapLeave")
        return nil
      end
      _237_ = (_238_() or _239_())
      if (nil ~= _237_) then
        local input = _237_
        if (traversal_3f or (sublist["autojump?"] and not user_forced_autojump_3f())) then
          return {input, 0}
        else
          local _241_
          if not initial_invoc_3f then
            _241_ = spec_keys.prev_group
          else
            _241_ = nil
          end
          if ((input == spec_keys.next_group) or (input == _241_)) then
            local _7cgroups_7c = ceil((#sublist / #sublist["label-set"]))
            local max_offset = dec(_7cgroups_7c)
            local _243_
            if (input == spec_keys.next_group) then
              _243_ = inc
            else
              _243_ = dec
            end
            return recur(clamp(_243_(group_offset), 0, max_offset))
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
    if (_in == spec_keys.next_match) then
      return "to-next"
    elseif (traversal_3f and (_in == spec_keys.prev_match)) then
      return "to-prev"
    else
      return nil
    end
  end
  local function get_target_with_active_primary_label(target_list, input)
    local res = nil
    for idx, _248_ in ipairs(target_list) do
      local _each_249_ = _248_
      local label = _each_249_["label"]
      local label_state = _each_249_["label-state"]
      local target = _each_249_
      if res then break end
      if ((label == input) and (label_state == "active-primary")) then
        res = {idx, target}
      else
      end
    end
    return res
  end
  if not (dot_repeat_3f or traversal_3f) then
    exec_autocmds("LeapEnter")
    echo("")
    if new_search_3f then
      apply_backdrop(reverse_3f0, _3ftarget_windows)
    else
    end
    do
    end
    highlight_cursor()
    vim.cmd("redraw")
  else
  end
  local _253_
  if traversal_3f then
    _253_ = {state["repeat"].in1, state["repeat"].in2, traversal_state.targets}
  else
    local function _254_(...)
      local _255_ = ...
      if (nil ~= _255_) then
        local in1 = _255_
        local function _256_(...)
          local _257_ = ...
          if (nil ~= _257_) then
            local targets = _257_
            local function _258_(...)
              local _259_ = ...
              if (nil ~= _259_) then
                local in2 = _259_
                return {in1, in2, targets}
              elseif true then
                local __60_auto = _259_
                return ...
              else
                return nil
              end
            end
            local function _261_(...)
              do
                local _262_ = targets
                populate_sublists(_262_)
                set_sublist_attributes(_262_, {["force-no-autojump?"] = force_no_autojump_3f})
                set_labels(_262_)
                set_initial_label_states(_262_)
              end
              if new_search_3f then
                set_beacons(targets, {})
                if new_search_3f then
                  apply_backdrop(reverse_3f0, _3ftarget_windows)
                else
                end
                do
                  light_up_beacons(targets)
                end
                highlight_cursor()
                vim.cmd("redraw")
              else
              end
              local function _265_(...)
                local res_2_auto
                do
                  res_2_auto = get_input()
                end
                hl:cleanup(_3ftarget_windows)
                return res_2_auto
              end
              local function _266_(...)
                if change_op_3f then
                  handle_interrupted_change_op_21()
                else
                end
                do
                end
                exec_autocmds("LeapLeave")
                return nil
              end
              return (get_prev_in2() or _265_(...) or _266_(...))
            end
            return _258_(_261_(...))
          elseif true then
            local __60_auto = _257_
            return ...
          else
            return nil
          end
        end
        local function _269_(...)
          if change_op_3f then
            handle_interrupted_change_op_21()
          else
          end
          do
            echo_not_found((in1 .. (get_prev_in2() or "")))
          end
          exec_autocmds("LeapLeave")
          return nil
        end
        return _256_((get_targets(in1, {["reverse?"] = reverse_3f0, ["target-windows"] = _3ftarget_windows}) or _269_(...)))
      elseif true then
        local __60_auto = _255_
        return ...
      else
        return nil
      end
    end
    _253_ = _254_(get_first_pattern_input())
  end
  if ((_G.type(_253_) == "table") and (nil ~= (_253_)[1]) and (nil ~= (_253_)[2]) and (nil ~= (_253_)[3])) then
    local in1 = (_253_)[1]
    local in2 = (_253_)[2]
    local targets = (_253_)[3]
    local update_state = update_state_2a(in1)
    if dot_repeat_3f then
      local _273_ = targets.sublists[in2][state["dot-repeat"]["target-idx"]]
      if (nil ~= _273_) then
        local target = _273_
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
        local _ = _273_
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
    elseif ((in2 == spec_keys.next_match) and not traversal_3f and not bidirectional_3f) then
      jump_to_21(targets[1])
      if op_mode_3f then
        if dot_repeatable_op_3f then
          set_dot_repeat()
        else
        end
        do
          update_state({["dot-repeat"] = {in2 = targets[1].pair[2], ["target-idx"] = 1}})
        end
        exec_autocmds("LeapLeave")
        return nil
      else
        set_beacons(targets, {["force-no-labels?"] = true})
        return leap({["reverse?"] = reverse_3f0, ["x-mode?"] = x_mode_3f0, ["traversal-state"] = {targets = targets, idx = 1}})
      end
    else
      local _279_
      if traversal_3f then
        _279_ = targets[traversal_state.idx].pair[2]
      else
        _279_ = in2
      end
      update_state({["repeat"] = {in2 = _279_}})
      local _281_
      local function _282_()
        local t_283_ = traversal_state
        if (nil ~= t_283_) then
          t_283_ = (t_283_).targets
        else
        end
        return t_283_
      end
      local function _285_()
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
      _281_ = (_282_() or targets.sublists[in2] or _285_())
      if ((_G.type(_281_) == "table") and (nil ~= (_281_)[1]) and ((_281_)[2] == nil)) then
        local only = (_281_)[1]
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
      elseif (nil ~= _281_) then
        local sublist = _281_
        local curr_idx
        local function _288_()
          local t_289_ = traversal_state
          if (nil ~= t_289_) then
            t_289_ = (t_289_).idx
          else
          end
          return t_289_
        end
        curr_idx = (_288_() or 0)
        if not traversal_3f then
          if sublist["autojump?"] then
            jump_to_21(sublist[1])
            curr_idx = 1
          else
          end
        else
        end
        local _293_ = post_pattern_input_loop(sublist, {["display-targets-from"] = inc(curr_idx)})
        if ((_G.type(_293_) == "table") and (nil ~= (_293_)[1]) and (nil ~= (_293_)[2])) then
          local in3 = (_293_)[1]
          local group_offset = (_293_)[2]
          local _294_
          if not (bidirectional_3f or (group_offset > 0)) then
            _294_ = get_traversal_action(in3)
          else
            _294_ = nil
          end
          if (nil ~= _294_) then
            local action = _294_
            local new_idx
            do
              local _296_ = action
              if (_296_ == "to-next") then
                new_idx = min(inc(curr_idx), #targets)
              elseif (_296_ == "to-prev") then
                new_idx = max(dec(curr_idx), 1)
              else
                new_idx = nil
              end
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
              return nil
            else
              return leap({["reverse?"] = reverse_3f0, ["x-mode?"] = x_mode_3f0, ["traversal-state"] = {targets = sublist, idx = new_idx}})
            end
          elseif true then
            local _ = _294_
            local _300_
            if not force_no_labels_3f then
              _300_ = get_target_with_active_primary_label(sublist, in3)
            else
              _300_ = nil
            end
            if ((_G.type(_300_) == "table") and (nil ~= (_300_)[1]) and (nil ~= (_300_)[2])) then
              local idx = (_300_)[1]
              local target = (_300_)[2]
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
              local _0 = _300_
              if (sublist["autojump?"] or traversal_3f) then
                if dot_repeatable_op_3f then
                  set_dot_repeat()
                else
                end
                do
                  vim.fn.feedkeys(in3, "i")
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
      else
        return nil
      end
    end
  else
    return nil
  end
end
local function set_default_keymaps(force_3f)
  for _, _312_ in ipairs({{"n", "s", "<Plug>(leap-forward)"}, {"n", "S", "<Plug>(leap-backward)"}, {"x", "s", "<Plug>(leap-forward)"}, {"x", "S", "<Plug>(leap-backward)"}, {"o", "z", "<Plug>(leap-forward)"}, {"o", "Z", "<Plug>(leap-backward)"}, {"o", "x", "<Plug>(leap-forward-x)"}, {"o", "X", "<Plug>(leap-backward-x)"}, {"n", "gs", "<Plug>(leap-cross-window)"}, {"x", "gs", "<Plug>(leap-cross-window)"}, {"o", "gs", "<Plug>(leap-cross-window)"}}) do
    local _each_313_ = _312_
    local mode = _each_313_[1]
    local lhs = _each_313_[2]
    local rhs = _each_313_[3]
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
    local _let_315_ = vim.split(opt, ".", true)
    local _0 = _let_315_[1]
    local scope = _let_315_[2]
    local name = _let_315_[3]
    saved_editor_opts[opt] = _G.vim[scope][name]
  end
  return nil
end
local function set_editor_opts(opts0)
  for opt, val in pairs(opts0) do
    local _let_316_ = vim.split(opt, ".", true)
    local _ = _let_316_[1]
    local scope = _let_316_[2]
    local name = _let_316_[3]
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
local function _317_()
  save_editor_opts()
  return set_temporary_editor_opts()
end
api.nvim_create_autocmd("User", {group = "LeapDefault", pattern = "LeapEnter", callback = _317_})
api.nvim_create_autocmd("User", {group = "LeapDefault", pattern = "LeapLeave", callback = restore_editor_opts})
return {opts = opts, setup = setup, state = state, leap = leap, init_highlight = init_highlight, set_default_keymaps = set_default_keymaps}
