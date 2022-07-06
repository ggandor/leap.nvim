local hl = require("leap.highlight")
local opts = require("leap.opts")
local _local_1_ = require("leap.search")
local get_targets = _local_1_["get-targets"]
local _local_2_ = require("leap.util")
local inc = _local_2_["inc"]
local dec = _local_2_["dec"]
local clamp = _local_2_["clamp"]
local echo = _local_2_["echo"]
local replace_keycodes = _local_2_["replace-keycodes"]
local get_cursor_pos = _local_2_["get-cursor-pos"]
local push_cursor_21 = _local_2_["push-cursor!"]
local api = vim.api
local empty_3f = vim.tbl_isempty
local map = vim.tbl_map
local _local_3_ = math
local abs = _local_3_["abs"]
local ceil = _local_3_["ceil"]
local max = _local_3_["max"]
local min = _local_3_["min"]
local pow = _local_3_["pow"]
local _3cbs_3e = replace_keycodes("<bs>")
local _3ccr_3e = replace_keycodes("<cr>")
local _3cesc_3e = replace_keycodes("<esc>")
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
local function exec_user_autocmds(pattern)
  return api.nvim_exec_autocmds("User", {pattern = pattern, modeline = false})
end
local function handle_interrupted_change_op_21()
  local seq
  local function _4_()
    if (vim.fn.col(".") > 1) then
      return "<RIGHT>"
    else
      return ""
    end
  end
  seq = ("<C-\\><C-G>" .. _4_())
  return api.nvim_feedkeys(replace_keycodes(seq), "n", true)
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
local function get_input()
  local ok_3f, ch = pcall(vim.fn.getcharstr)
  if (ok_3f and (ch ~= _3cesc_3e)) then
    return ch
  else
    return nil
  end
end
local function get_input_by_keymap(prompt)
  local function echo_prompt(seq)
    return api.nvim_echo({{prompt.str}, {(seq or ""), "ErrorMsg"}}, false, {})
  end
  local function accept(ch)
    prompt.str = (prompt.str .. ch)
    echo_prompt()
    return ch
  end
  local function loop(seq)
    local _7cseq_7c = #(seq or "")
    if (function(_7_,_8_,_9_) return (_7_ <= _8_) and (_8_ <= _9_) end)(1,_7cseq_7c,5) then
      echo_prompt(seq)
      local rhs_candidate = vim.fn.mapcheck(seq, "l")
      local rhs = vim.fn.maparg(seq, "l")
      if (rhs_candidate == "") then
        return accept(seq)
      elseif (rhs == rhs_candidate) then
        return accept(rhs)
      else
        local _10_ = get_input()
        if (_10_ == _3cbs_3e) then
          local function _11_()
            if (_7cseq_7c > 1) then
              return seq:sub(1, dec(_7cseq_7c))
            else
              return seq
            end
          end
          return loop(_11_())
        elseif (_10_ == _3ccr_3e) then
          if (rhs ~= "") then
            return accept(rhs)
          elseif (_7cseq_7c == 1) then
            return accept(seq)
          else
            return loop(seq)
          end
        elseif (nil ~= _10_) then
          local ch = _10_
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
    echo_prompt()
    local _16_ = loop(get_input())
    if (nil ~= _16_) then
      local _in = _16_
      return _in
    elseif true then
      local _ = _16_
      return echo("")
    else
      return nil
    end
  end
end
local function populate_sublists(targets)
  targets.sublists = {}
  local function __3ecommon_key(k)
    local function _19_()
      if not opts.case_sensitive then
        return k:lower()
      else
        return nil
      end
    end
    return (opts.character_class_of[k] or _19_() or k)
  end
  local function _21_(t, k)
    return rawget(t, __3ecommon_key(k))
  end
  local function _22_(t, k, v)
    return rawset(t, __3ecommon_key(k), v)
  end
  setmetatable(targets.sublists, {__index = _21_, __newindex = _22_})
  for _, _23_ in ipairs(targets) do
    local _each_24_ = _23_
    local _each_25_ = _each_24_["pair"]
    local _0 = _each_25_[1]
    local ch2 = _each_25_[2]
    local target = _each_24_
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
  local _27_
  if user_forced_autojump_3f() then
    _27_ = opts.safe_labels
  elseif user_forced_noautojump_3f() then
    _27_ = opts.labels
  elseif sublist["autojump?"] then
    _27_ = opts.safe_labels
  else
    _27_ = opts.labels
  end
  sublist["label-set"] = _27_
  return nil
end
local function set_sublist_attributes(sublist, _29_)
  local _arg_30_ = _29_
  local force_noautojump_3f = _arg_30_["force-noautojump?"]
  set_autojump(sublist, force_noautojump_3f)
  return attach_label_set(sublist)
end
local function set_labels(sublist)
  if (#sublist > 1) then
    local _local_31_ = sublist
    local autojump_3f = _local_31_["autojump?"]
    local label_set = _local_31_["label-set"]
    for i, target in ipairs(sublist) do
      local i_2a
      if autojump_3f then
        i_2a = dec(i)
      else
        i_2a = i
      end
      if (i_2a > 0) then
        local _34_
        do
          local _33_ = (i_2a % #label_set)
          if (_33_ == 0) then
            _34_ = label_set[#label_set]
          elseif (nil ~= _33_) then
            local n = _33_
            _34_ = label_set[n]
          else
            _34_ = nil
          end
        end
        target["label"] = _34_
      else
      end
    end
    return nil
  else
    return nil
  end
end
local function set_label_states(sublist, _40_)
  local _arg_41_ = _40_
  local group_offset = _arg_41_["group-offset"]
  local _7clabel_set_7c = #sublist["label-set"]
  local offset = (group_offset * _7clabel_set_7c)
  local primary_start
  local function _42_()
    if sublist["autojump?"] then
      return 2
    else
      return 1
    end
  end
  primary_start = (offset + _42_())
  local primary_end = (primary_start + dec(_7clabel_set_7c))
  local secondary_start = inc(primary_end)
  local secondary_end = (primary_end + _7clabel_set_7c)
  for i, target in ipairs(sublist) do
    if target.label then
      local _43_
      if (function(_44_,_45_,_46_) return (_44_ <= _45_) and (_45_ <= _46_) end)(primary_start,i,primary_end) then
        _43_ = "active-primary"
      elseif (function(_47_,_48_,_49_) return (_47_ <= _48_) and (_48_ <= _49_) end)(secondary_start,i,secondary_end) then
        _43_ = "active-secondary"
      elseif (i > secondary_end) then
        _43_ = "inactive"
      else
        _43_ = nil
      end
      target["label-state"] = _43_
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
local function get_label_offset(target)
  local _let_52_ = target
  local _let_53_ = _let_52_["pair"]
  local ch1 = _let_53_[1]
  local ch2 = _let_53_[2]
  local edge_pos_3f = _let_52_["edge-pos?"]
  local function _54_()
    if edge_pos_3f then
      return 0
    else
      return ch2:len()
    end
  end
  return (ch1:len() + _54_())
end
local function set_beacon_for_labeled(target, user_given_targets_3f)
  local offset
  if user_given_targets_3f then
    offset = 0
  else
    offset = get_label_offset(target)
  end
  local virttext
  do
    local _56_ = target["label-state"]
    if (_56_ == "active-primary") then
      virttext = {{target.label, hl.group["label-primary"]}}
    elseif (_56_ == "active-secondary") then
      virttext = {{target.label, hl.group["label-secondary"]}}
    elseif (_56_ == "inactive") then
      if not opts.highlight_unlabeled then
        virttext = {{" ", hl.group["label-secondary"]}}
      else
        virttext = nil
      end
    else
      virttext = nil
    end
  end
  local _59_
  if virttext then
    _59_ = {offset, virttext}
  else
    _59_ = nil
  end
  target["beacon"] = _59_
  return nil
end
local function set_beacon_to_match_hl(target)
  local _let_61_ = target
  local _let_62_ = _let_61_["pair"]
  local ch1 = _let_62_[1]
  local ch2 = _let_62_[2]
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
    local _let_63_ = target
    local _let_64_ = _let_63_["pos"]
    local lnum = _let_64_[1]
    local col = _let_64_[2]
    local _let_65_ = _let_63_["pair"]
    local ch1 = _let_65_[1]
    local _ = _let_65_[2]
    local _let_66_ = _let_63_["wininfo"]
    local bufnr = _let_66_["bufnr"]
    local winid = _let_66_["winid"]
    if (not target.beacon or (opts.highlight_unlabeled and (target.beacon[2][1][2] == hl.group.match))) then
      local keys = {(bufnr .. " " .. winid .. " " .. lnum .. " " .. col), (bufnr .. " " .. winid .. " " .. lnum .. " " .. (col + ch1:len()))}
      for _0, k in ipairs(keys) do
        do
          local _67_ = label_positions[k]
          if (nil ~= _67_) then
            local other = _67_
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
        local _69_ = unlabeled_match_positions[k]
        if (nil ~= _69_) then
          local other = _69_
          target.beacon = nil
          set_beacon_to_match_hl(other)
        elseif true then
          local _0 = _69_
          local _70_ = label_positions[k]
          if (nil ~= _70_) then
            local other = _70_
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
local function set_beacons(target_list, _74_)
  local _arg_75_ = _74_
  local force_no_labels_3f = _arg_75_["force-no-labels?"]
  local user_given_targets_3f = _arg_75_["user-given-targets?"]
  if (force_no_labels_3f and not user_given_targets_3f) then
    for _, target in ipairs(target_list) do
      set_beacon_to_match_hl(target)
    end
    return nil
  else
    for _, target in ipairs(target_list) do
      if target.label then
        set_beacon_for_labeled(target, user_given_targets_3f)
      elseif (opts.highlight_unlabeled and not user_given_targets_3f) then
        set_beacon_to_match_hl(target)
      else
      end
    end
    if not user_given_targets_3f then
      return resolve_conflicts(target_list)
    else
      return nil
    end
  end
end
local function light_up_beacons(target_list, _3fstart)
  for i = (_3fstart or 1), #target_list do
    local target = target_list[i]
    local _79_ = target.beacon
    if ((_G.type(_79_) == "table") and (nil ~= (_79_)[1]) and (nil ~= (_79_)[2])) then
      local offset = (_79_)[1]
      local virttext = (_79_)[2]
      local _let_80_ = map(dec, target.pos)
      local lnum = _let_80_[1]
      local col = _let_80_[2]
      api.nvim_buf_set_extmark(target.wininfo.bufnr, hl.ns, lnum, (col + offset), {virt_text = virttext, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.label})
    else
    end
  end
  return nil
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
  local function _85_()
    vim.o.virtualedit = saved
    return nil
  end
  return api.nvim_create_autocmd({"CursorMoved", "WinLeave", "BufLeave", "InsertEnter", "CmdlineEnter", "CmdwinEnter"}, {callback = _85_, once = true})
end
local function simulate_inclusive_op_21(mode)
  local _86_ = vim.fn.matchstr(mode, "^no\\zs.")
  if (_86_ == "") then
    if cursor_before_eof_3f() then
      return push_beyond_eof_21()
    else
      return push_cursor_21("fwd")
    end
  elseif (_86_ == "v") then
    return push_cursor_21("bwd")
  else
    return nil
  end
end
local function force_matchparen_refresh()
  pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchparen"})
  return pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchup_matchparen"})
end
local function jump_to_21_2a(pos, _89_)
  local _arg_90_ = _89_
  local winid = _arg_90_["winid"]
  local add_to_jumplist_3f = _arg_90_["add-to-jumplist?"]
  local mode = _arg_90_["mode"]
  local offset = _arg_90_["offset"]
  local backward_3f = _arg_90_["backward?"]
  local inclusive_op_3f = _arg_90_["inclusive-op?"]
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
local state = {["repeat"] = {in1 = nil, in2 = nil}, ["dot-repeat"] = {in1 = nil, in2 = nil, ["target-idx"] = nil, ["backward?"] = nil, ["inclusive-op?"] = nil, ["offset?"] = nil}}
local function leap(_96_)
  local _arg_97_ = _96_
  local dot_repeat_3f = _arg_97_["dot-repeat?"]
  local target_windows = _arg_97_["target-windows"]
  local user_given_targets = _arg_97_["targets"]
  local user_given_action = _arg_97_["action"]
  local kwargs = _arg_97_
  local function _99_()
    if dot_repeat_3f then
      return state["dot-repeat"]
    else
      return kwargs
    end
  end
  local _let_98_ = _99_()
  local backward_3f = _let_98_["backward?"]
  local inclusive_op_3f = _let_98_["inclusive-op?"]
  local offset = _let_98_["offset"]
  local directional_3f = not target_windows
  local __3ewininfo
  local function _100_(_241)
    return (vim.fn.getwininfo(_241))[1]
  end
  __3ewininfo = _100_
  local _3ftarget_windows
  do
    local _101_ = target_windows
    if (_101_ ~= nil) then
      _3ftarget_windows = map(__3ewininfo, _101_)
    else
      _3ftarget_windows = _101_
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
  local _
  if (user_given_targets and not user_given_targets[1].wininfo) then
    local function _103_(t)
      t.wininfo = current_window
      return nil
    end
    _ = map(_103_, user_given_targets)
  else
    _ = nil
  end
  local mode = api.nvim_get_mode().mode
  local op_mode_3f = mode:match("o")
  local change_op_3f = (op_mode_3f and (vim.v.operator == "c"))
  local dot_repeatable_op_3f = (op_mode_3f and directional_3f and (vim.v.operator ~= "y"))
  local force_noautojump_3f = (user_given_action or op_mode_3f or not directional_3f)
  local prompt = {str = ">"}
  local spec_keys
  local function _105_(_0, k)
    return replace_keycodes(opts.special_keys[k])
  end
  spec_keys = setmetatable({}, {__index = _105_})
  local function expand_to_user_defined_character_class(_in)
    local _106_ = opts.character_class_of[_in]
    if (nil ~= _106_) then
      local chars = _106_
      return ("\\(" .. table.concat(chars, "\\|") .. "\\)")
    else
      return nil
    end
  end
  local function prepare_pattern(in1, _3fin2)
    local function _108_()
      if opts.case_sensitive then
        return "\\C"
      else
        return "\\c"
      end
    end
    return ("\\V" .. _108_() .. (expand_to_user_defined_character_class(in1) or string.gsub(in1, "\\", "\\\\")) .. (expand_to_user_defined_character_class(_3fin2) or _3fin2 or "\\_."))
  end
  local function get_target_with_active_primary_label(sublist, input)
    local res = nil
    for idx, _109_ in ipairs(sublist) do
      local _each_110_ = _109_
      local label = _each_110_["label"]
      local label_state = _each_110_["label-state"]
      local target = _each_110_
      if (res or (label_state == "inactive")) then break end
      if ((label == input) and (label_state == "active-primary")) then
        res = {idx, target}
      else
      end
    end
    return res
  end
  local function update_state(state_2a)
    if not (dot_repeat_3f or user_given_targets) then
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
    local function _115_(target)
      jump_to_21_2a(target.pos, {winid = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["backward?"] = backward_3f, ["inclusive-op?"] = inclusive_op_3f})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _115_
  end
  local function traverse(targets, idx, _116_)
    local _arg_117_ = _116_
    local force_no_labels_3f = _arg_117_["force-no-labels?"]
    if force_no_labels_3f then
      inactivate_labels(targets)
    else
    end
    set_beacons(targets, {["force-no-labels?"] = force_no_labels_3f, ["user-given-targets?"] = user_given_targets})
    do
      hl:cleanup(hl_affected_windows)
      hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
      do
        light_up_beacons(targets, inc(idx))
      end
      hl["highlight-cursor"](hl)
      vim.cmd("redraw")
    end
    local _119_
    local function _120_()
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
    _119_ = (get_input() or _120_())
    if (nil ~= _119_) then
      local input = _119_
      if ((input == spec_keys.next_match) or (input == spec_keys.prev_match)) then
        local new_idx
        do
          local _122_ = input
          if (_122_ == spec_keys.next_match) then
            new_idx = min(inc(idx), #targets)
          elseif (_122_ == spec_keys.prev_match) then
            new_idx = max(dec(idx), 1)
          else
            new_idx = nil
          end
        end
        local _125_
        do
          local t_124_ = targets
          if (nil ~= t_124_) then
            t_124_ = (t_124_)[new_idx]
          else
          end
          if (nil ~= t_124_) then
            t_124_ = (t_124_).pair
          else
          end
          if (nil ~= t_124_) then
            t_124_ = (t_124_)[2]
          else
          end
          _125_ = t_124_
        end
        update_state({["repeat"] = {in1 = state["repeat"].in1, in2 = _125_}})
        jump_to_21(targets[new_idx])
        return traverse(targets, new_idx, {["force-no-labels?"] = force_no_labels_3f})
      else
        local _129_ = get_target_with_active_primary_label(targets, input)
        if ((_G.type(_129_) == "table") and true and (nil ~= (_129_)[2])) then
          local _0 = (_129_)[1]
          local target = (_129_)[2]
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
          local _0 = _129_
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
      hl["highlight-cursor"](hl)
      vim.cmd("redraw")
    end
    local _135_
    local function _136_()
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
    _135_ = (get_input_by_keymap(prompt) or _136_())
    if (_135_ == spec_keys.repeat_search) then
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
    elseif (nil ~= _135_) then
      local in1 = _135_
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
      hl["highlight-cursor"](hl)
      vim.cmd("redraw")
    end
    local function _141_()
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
    return (get_input_by_keymap(prompt) or _141_())
  end
  local function get_full_pattern_input()
    local _143_, _144_ = get_first_pattern_input()
    if ((nil ~= _143_) and (nil ~= _144_)) then
      local in1 = _143_
      local in2 = _144_
      return in1, in2
    elseif ((nil ~= _143_) and (_144_ == nil)) then
      local in1 = _143_
      local _145_ = get_input_by_keymap(prompt)
      if (nil ~= _145_) then
        local in2 = _145_
        return in1, in2
      elseif true then
        local _0 = _145_
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
        local _149_ = sublist
        set_label_states(_149_, {["group-offset"] = group_offset})
        set_beacons(_149_, {["user-given-targets?"] = user_given_targets})
      end
      do
        hl:cleanup(hl_affected_windows)
        hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
        do
          local function _150_()
            if sublist["autojump?"] then
              return 2
            else
              return nil
            end
          end
          light_up_beacons(sublist, _150_())
        end
        hl["highlight-cursor"](hl)
        vim.cmd("redraw")
      end
      local _151_
      local function _152_()
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
      _151_ = (get_input() or _152_())
      if (nil ~= _151_) then
        local input = _151_
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
  local do_action = (user_given_action or jump_to_21)
  local function _157_(...)
    local _158_, _159_ = ...
    if ((nil ~= _158_) and true) then
      local in1 = _158_
      local _3fin2 = _159_
      local function _160_(...)
        local _161_ = ...
        if (nil ~= _161_) then
          local targets = _161_
          local function _162_(...)
            local _163_ = ...
            if (nil ~= _163_) then
              local in2 = _163_
              if (directional_3f and (in2 == spec_keys.next_match)) then
                local in20 = targets[1].pair[2]
                update_state({["repeat"] = {in1 = in1, in2 = in20}})
                do_action(targets[1])
                if ((#targets == 1) or op_mode_3f or user_given_action) then
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
                local function update_dot_repeat_state(target_idx)
                  return update_state({["dot-repeat"] = {in1 = in1, in2 = in2, ["target-idx"] = target_idx}})
                end
                update_state({["repeat"] = {in1 = in1, in2 = in2}})
                local _166_
                local function _167_(...)
                  if _3fin2 then
                    return targets
                  else
                    return targets.sublists[in2]
                  end
                end
                local function _168_(...)
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
                _166_ = (_167_(...) or _168_(...))
                if ((_G.type(_166_) == "table") and (nil ~= (_166_)[1]) and ((_166_)[2] == nil)) then
                  local only = (_166_)[1]
                  if dot_repeatable_op_3f then
                    set_dot_repeat()
                  else
                  end
                  do
                    update_dot_repeat_state(1)
                    do_action(only)
                  end
                  hl:cleanup(hl_affected_windows)
                  exec_user_autocmds("LeapLeave")
                  return nil
                elseif (nil ~= _166_) then
                  local targets_2a = _166_
                  if targets_2a["autojump?"] then
                    do_action((targets_2a)[1])
                  else
                  end
                  local _172_ = post_pattern_input_loop(targets_2a)
                  if (nil ~= _172_) then
                    local in_final = _172_
                    if (directional_3f and (in_final == spec_keys.next_match)) then
                      local new_idx
                      if targets_2a["autojump?"] then
                        new_idx = 2
                      else
                        new_idx = 1
                      end
                      do_action((targets_2a)[new_idx])
                      if (op_mode_3f or user_given_action) then
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
                        return traverse(targets_2a, new_idx, {["force-no-labels?"] = not targets_2a["autojump?"]})
                      end
                    else
                      local _176_ = get_target_with_active_primary_label(targets_2a, in_final)
                      if ((_G.type(_176_) == "table") and (nil ~= (_176_)[1]) and (nil ~= (_176_)[2])) then
                        local idx = (_176_)[1]
                        local target = (_176_)[2]
                        if dot_repeatable_op_3f then
                          set_dot_repeat()
                        else
                        end
                        do
                          update_dot_repeat_state(idx)
                          do_action(target)
                        end
                        hl:cleanup(hl_affected_windows)
                        exec_user_autocmds("LeapLeave")
                        return nil
                      elseif true then
                        local _0 = _176_
                        if targets_2a["autojump?"] then
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
              local __60_auto = _163_
              return ...
            else
              return nil
            end
          end
          local function _196_(...)
            if dot_repeat_3f then
              local _187_ = targets[state["dot-repeat"]["target-idx"]]
              if (nil ~= _187_) then
                local target = _187_
                if dot_repeatable_op_3f then
                  set_dot_repeat()
                else
                end
                do
                  do_action(target)
                end
                hl:cleanup(hl_affected_windows)
                exec_user_autocmds("LeapLeave")
                return nil
              elseif true then
                local _0 = _187_
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
              if _3fin2 then
                local _191_ = targets
                set_sublist_attributes(_191_, {["force-noautojump?"] = force_noautojump_3f})
                set_labels(_191_)
              else
                populate_sublists(targets)
                for _0, sublist in pairs(targets.sublists) do
                  local _192_ = sublist
                  set_sublist_attributes(_192_, {["force-noautojump?"] = force_noautojump_3f})
                  set_labels(_192_)
                end
              end
              local function _194_(...)
                do
                  local _195_ = targets
                  set_initial_label_states(_195_)
                  set_beacons(_195_, {})
                end
                return get_second_pattern_input(targets)
              end
              return (_3fin2 or _194_(...))
            end
          end
          return _162_(_196_(...))
        elseif true then
          local __60_auto = _161_
          return ...
        else
          return nil
        end
      end
      local function _198_(...)
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
      return _160_((user_given_targets or get_targets(prepare_pattern(in1, _3fin2), {["backward?"] = backward_3f, ["target-windows"] = _3ftarget_windows}) or _198_(...)))
    elseif true then
      local __60_auto = _158_
      return ...
    else
      return nil
    end
  end
  local function _201_()
    if user_given_targets then
      return true, true
    elseif dot_repeat_3f then
      return state["dot-repeat"].in1, state["dot-repeat"].in2
    elseif opts.highlight_ahead_of_time then
      return get_first_pattern_input()
    else
      return get_full_pattern_input()
    end
  end
  return _157_(_201_())
end
local temporary_editor_opts = {["vim.bo.modeline"] = false}
local saved_editor_opts = {}
local function save_editor_opts()
  for opt, _ in pairs(temporary_editor_opts) do
    local _let_202_ = vim.split(opt, ".", true)
    local _0 = _let_202_[1]
    local scope = _let_202_[2]
    local name = _let_202_[3]
    saved_editor_opts[opt] = _G.vim[scope][name]
  end
  return nil
end
local function set_editor_opts(opts0)
  for opt, val in pairs(opts0) do
    local _let_203_ = vim.split(opt, ".", true)
    local _ = _let_203_[1]
    local scope = _let_203_[2]
    local name = _let_203_[3]
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
local _204_
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
  _204_ = t
end
opts["character_class_of"] = _204_
hl["init-highlight"](hl)
api.nvim_create_augroup("LeapDefault", {})
local function _207_()
  return hl["init-highlight"](hl)
end
api.nvim_create_autocmd("ColorScheme", {callback = _207_, group = "LeapDefault"})
local function _208_()
  save_editor_opts()
  return set_temporary_editor_opts()
end
api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _208_, group = "LeapDefault"})
api.nvim_create_autocmd("User", {pattern = "LeapLeave", callback = restore_editor_opts, group = "LeapDefault"})
return {state = state, leap = leap}
