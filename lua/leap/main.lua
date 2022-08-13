local hl = require("leap.highlight")
local opts = require("leap.opts")
local _local_1_ = require("leap.util")
local inc = _local_1_["inc"]
local dec = _local_1_["dec"]
local clamp = _local_1_["clamp"]
local echo = _local_1_["echo"]
local replace_keycodes = _local_1_["replace-keycodes"]
local get_cursor_pos = _local_1_["get-cursor-pos"]
local push_cursor_21 = _local_1_["push-cursor!"]
local api = vim.api
local contains_3f = vim.tbl_contains
local empty_3f = vim.tbl_isempty
local map = vim.tbl_map
local _local_2_ = math
local abs = _local_2_["abs"]
local ceil = _local_2_["ceil"]
local max = _local_2_["max"]
local min = _local_2_["min"]
local pow = _local_2_["pow"]
local _3cbs_3e = replace_keycodes("<bs>")
local _3ccr_3e = replace_keycodes("<cr>")
local _3cesc_3e = replace_keycodes("<esc>")
local function user_forced_autojump_3f()
  return (not opts.labels or empty_3f(opts.labels))
end
local function user_forced_noautojump_3f()
  return (not opts.safe_labels or empty_3f(opts.safe_labels))
end
local function exec_user_autocmds(pattern)
  return api.nvim_exec_autocmds("User", {pattern = pattern, modeline = false})
end
local function handle_interrupted_change_op_21()
  local seq
  local function _3_()
    if (vim.fn.col(".") > 1) then
      return "<RIGHT>"
    else
      return ""
    end
  end
  seq = ("<C-\\><C-G>" .. _3_())
  return api.nvim_feedkeys(replace_keycodes(seq), "n", true)
end
local function set_dot_repeat_2a()
  local op = vim.v.operator
  local cmd = replace_keycodes("<cmd>lua require'leap'.leap { dot_repeat = true }<cr>")
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
    if (function(_6_,_7_,_8_) return (_6_ <= _7_) and (_7_ <= _8_) end)(1,_7cseq_7c,5) then
      echo_prompt(seq)
      local rhs_candidate = vim.fn.mapcheck(seq, "l")
      local rhs = vim.fn.maparg(seq, "l")
      if (rhs_candidate == "") then
        return accept(seq)
      elseif (rhs == rhs_candidate) then
        return accept(rhs)
      else
        local _9_ = get_input()
        if (_9_ == _3cbs_3e) then
          local function _10_()
            if (_7cseq_7c >= 2) then
              return seq:sub(1, dec(_7cseq_7c))
            else
              return seq
            end
          end
          return loop(_10_())
        elseif (_9_ == _3ccr_3e) then
          if (rhs ~= "") then
            return accept(rhs)
          elseif (_7cseq_7c == 1) then
            return accept(seq)
          else
            return loop(seq)
          end
        elseif (nil ~= _9_) then
          local ch = _9_
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
    local _15_ = loop(get_input())
    if (nil ~= _15_) then
      local _in = _15_
      return _in
    elseif true then
      local _ = _15_
      return echo("")
    else
      return nil
    end
  end
end
local function set_autojump(targets, force_noautojump_3f)
  targets["autojump?"] = (not (force_noautojump_3f or user_forced_noautojump_3f()) and (user_forced_autojump_3f() or (#opts.safe_labels >= dec(#targets))))
  return nil
end
local function attach_label_set(targets)
  local _18_
  if user_forced_autojump_3f() then
    _18_ = opts.safe_labels
  elseif user_forced_noautojump_3f() then
    _18_ = opts.labels
  elseif targets["autojump?"] then
    _18_ = opts.safe_labels
  else
    _18_ = opts.labels
  end
  targets["label-set"] = _18_
  return nil
end
local function set_labels(targets, multi_select_3f)
  if ((#targets > 1) or multi_select_3f) then
    local _local_20_ = targets
    local autojump_3f = _local_20_["autojump?"]
    local label_set = _local_20_["label-set"]
    for i, target in ipairs(targets) do
      local i_2a
      if autojump_3f then
        i_2a = dec(i)
      else
        i_2a = i
      end
      if (i_2a > 0) then
        local _23_
        do
          local _22_ = (i_2a % #label_set)
          if (_22_ == 0) then
            _23_ = label_set[#label_set]
          elseif (nil ~= _22_) then
            local n = _22_
            _23_ = label_set[n]
          else
            _23_ = nil
          end
        end
        target["label"] = _23_
      else
      end
    end
    return nil
  else
    return nil
  end
end
local function set_label_states(targets, _29_)
  local _arg_30_ = _29_
  local group_offset = _arg_30_["group-offset"]
  local _7clabel_set_7c = #targets["label-set"]
  local offset = (group_offset * _7clabel_set_7c)
  local primary_start
  local function _31_()
    if targets["autojump?"] then
      return 2
    else
      return 1
    end
  end
  primary_start = (offset + _31_())
  local primary_end = (primary_start + dec(_7clabel_set_7c))
  local secondary_start = inc(primary_end)
  local secondary_end = (primary_end + _7clabel_set_7c)
  for i, target in ipairs(targets) do
    if (target.label and (target["label-state"] ~= "selected")) then
      local _32_
      if (function(_33_,_34_,_35_) return (_33_ <= _34_) and (_34_ <= _35_) end)(primary_start,i,primary_end) then
        _32_ = "active-primary"
      elseif (function(_36_,_37_,_38_) return (_36_ <= _37_) and (_37_ <= _38_) end)(secondary_start,i,secondary_end) then
        _32_ = "active-secondary"
      elseif (i > secondary_end) then
        _32_ = "inactive"
      else
        _32_ = nil
      end
      target["label-state"] = _32_
    else
    end
  end
  return nil
end
local function inactivate_labels(targets)
  for _, target in ipairs(targets) do
    target["label-state"] = "inactive"
  end
  return nil
end
local function populate_sublists(targets)
  targets.sublists = {}
  local function _44_()
    local __3ecommon_key
    local function _41_(_241)
      local function _42_()
        if not opts.case_sensitive then
          return _241:lower()
        else
          return nil
        end
      end
      return (opts.character_class_of[_241] or _42_() or _241)
    end
    __3ecommon_key = _41_
    local function _45_(t, k)
      return rawget(t, __3ecommon_key(k))
    end
    local function _46_(t, k, v)
      return rawset(t, __3ecommon_key(k), v)
    end
    return {__index = _45_, __newindex = _46_}
  end
  setmetatable(targets.sublists, _44_())
  for _, _47_ in ipairs(targets) do
    local _each_48_ = _47_
    local _each_49_ = _each_48_["pair"]
    local _0 = _each_49_[1]
    local ch2 = _each_49_[2]
    local target = _each_48_
    if not targets.sublists[ch2] then
      targets["sublists"][ch2] = {}
    else
    end
    table.insert(targets.sublists[ch2], target)
  end
  return nil
end
local function set_initial_label_states(targets)
  for _, sublist in pairs(targets.sublists) do
    set_label_states(sublist, {["group-offset"] = 0})
  end
  return nil
end
local function get_label_offset(target)
  local _let_51_ = target
  local _let_52_ = _let_51_["pair"]
  local ch1 = _let_52_[1]
  local ch2 = _let_52_[2]
  local edge_pos_3f = _let_51_["edge-pos?"]
  local function _53_()
    if edge_pos_3f then
      return 0
    else
      return ch2:len()
    end
  end
  return (ch1:len() + _53_())
end
local function set_beacon_for_labeled(target, _54_)
  local _arg_55_ = _54_
  local user_given_targets_3f = _arg_55_["user-given-targets?"]
  local aot_3f = _arg_55_["aot?"]
  local offset
  if aot_3f then
    offset = get_label_offset(target)
  else
    offset = 0
  end
  local pad
  if (user_given_targets_3f or aot_3f) then
    pad = ""
  else
    pad = " "
  end
  local text = (target.label .. pad)
  local virttext
  do
    local _58_ = target["label-state"]
    if (_58_ == "selected") then
      virttext = {{text, hl.group["label-selected"]}}
    elseif (_58_ == "active-primary") then
      virttext = {{text, hl.group["label-primary"]}}
    elseif (_58_ == "active-secondary") then
      virttext = {{text, hl.group["label-secondary"]}}
    elseif (_58_ == "inactive") then
      if not opts.highlight_unlabeled then
        virttext = {{(" " .. pad), hl.group["label-secondary"]}}
      else
        virttext = nil
      end
    else
      virttext = nil
    end
  end
  local _61_
  if virttext then
    _61_ = {offset, virttext}
  else
    _61_ = nil
  end
  target["beacon"] = _61_
  return nil
end
local function set_beacon_to_match_hl(target)
  local _let_63_ = target
  local _let_64_ = _let_63_["pair"]
  local ch1 = _let_64_[1]
  local ch2 = _let_64_[2]
  local virttext = {{(ch1 .. ch2), hl.group.match}}
  target["beacon"] = {0, virttext}
  return nil
end
local function set_beacon_to_empty_label(target)
  target["beacon"][2][1][1] = " "
  return nil
end
local function resolve_conflicts(targets)
  local unlabeled_match_positions = {}
  local label_positions = {}
  for i, target in ipairs(targets) do
    local _let_65_ = target
    local _let_66_ = _let_65_["pos"]
    local lnum = _let_66_[1]
    local col = _let_66_[2]
    local _let_67_ = _let_65_["pair"]
    local ch1 = _let_67_[1]
    local _ = _let_67_[2]
    local _let_68_ = _let_65_["wininfo"]
    local bufnr = _let_68_["bufnr"]
    local winid = _let_68_["winid"]
    if (not target.beacon or (opts.highlight_unlabeled and (target.beacon[2][1][2] == hl.group.match))) then
      local keys = {(bufnr .. " " .. winid .. " " .. lnum .. " " .. col), (bufnr .. " " .. winid .. " " .. lnum .. " " .. (col + ch1:len()))}
      for _0, k in ipairs(keys) do
        do
          local _69_ = label_positions[k]
          if (nil ~= _69_) then
            local other = _69_
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
        local _71_ = unlabeled_match_positions[k]
        if (nil ~= _71_) then
          local other = _71_
          target.beacon = nil
          set_beacon_to_match_hl(other)
        elseif true then
          local _0 = _71_
          local _72_ = label_positions[k]
          if (nil ~= _72_) then
            local other = _72_
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
local function set_beacons(targets, _76_)
  local _arg_77_ = _76_
  local force_no_labels_3f = _arg_77_["force-no-labels?"]
  local user_given_targets_3f = _arg_77_["user-given-targets?"]
  local aot_3f = _arg_77_["aot?"]
  if (force_no_labels_3f and not user_given_targets_3f) then
    for _, target in ipairs(targets) do
      set_beacon_to_match_hl(target)
    end
    return nil
  else
    for _, target in ipairs(targets) do
      if target.label then
        set_beacon_for_labeled(target, {["user-given-targets?"] = user_given_targets_3f, ["aot?"] = aot_3f})
      elseif (aot_3f and opts.highlight_unlabeled) then
        set_beacon_to_match_hl(target)
      else
      end
    end
    if aot_3f then
      return resolve_conflicts(targets)
    else
      return nil
    end
  end
end
local function light_up_beacons(targets, _3fstart)
  for i = (_3fstart or 1), #targets do
    local target = targets[i]
    local _81_ = target.beacon
    if ((_G.type(_81_) == "table") and (nil ~= (_81_)[1]) and (nil ~= (_81_)[2])) then
      local offset = (_81_)[1]
      local virttext = (_81_)[2]
      local bufnr = target.wininfo.bufnr
      local _let_82_ = map(dec, target.pos)
      local lnum = _let_82_[1]
      local col = _let_82_[2]
      local id = api.nvim_buf_set_extmark(bufnr, hl.ns, lnum, (col + offset), {virt_text = virttext, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.label})
      table.insert(hl.extmarks, {bufnr, id})
    else
    end
  end
  return nil
end
local state = {args = nil, source_window = nil, ["repeat"] = {in1 = nil, in2 = nil}, dot_repeat = {in1 = nil, in2 = nil, target_idx = nil, backward = nil, inclusive_op = nil, offset = nil}, saved_editor_opts = {}}
local function leap(kwargs)
  do
    local _84_ = kwargs.target_windows
    if ((_G.type(_84_) == "table") and ((_84_)[1] == nil)) then
      echo("no targetable windows")
      return
    else
    end
  end
  local _let_86_ = kwargs
  local dot_repeat_3f = _let_86_["dot_repeat"]
  local target_windows = _let_86_["target_windows"]
  local user_given_targets = _let_86_["targets"]
  local user_given_action = _let_86_["action"]
  local multi_select_3f = _let_86_["multiselect"]
  local function _88_()
    if dot_repeat_3f then
      return state.dot_repeat
    else
      return kwargs
    end
  end
  local _let_87_ = _88_()
  local backward_3f = _let_87_["backward"]
  local inclusive_op_3f = _let_87_["inclusive_op"]
  local offset = _let_87_["offset"]
  local _
  state.args = kwargs
  _ = nil
  local __3ewininfo
  local function _89_(_241)
    return (vim.fn.getwininfo(_241))[1]
  end
  __3ewininfo = _89_
  local curr_winid = vim.fn.win_getid()
  local _0
  state.source_window = curr_winid
  _0 = nil
  local curr_win = __3ewininfo(curr_winid)
  local _1
  if (user_given_targets and not user_given_targets[1].wininfo) then
    local function _90_(t)
      t.wininfo = curr_win
      return nil
    end
    _1 = map(_90_, user_given_targets)
  else
    _1 = nil
  end
  local _3ftarget_windows
  do
    local _92_ = target_windows
    if (_92_ ~= nil) then
      _3ftarget_windows = map(__3ewininfo, _92_)
    else
      _3ftarget_windows = _92_
    end
  end
  local hl_affected_windows = {curr_win}
  local _2
  for _3, w in ipairs((_3ftarget_windows or {})) do
    table.insert(hl_affected_windows, w)
  end
  _2 = nil
  local directional_3f = not target_windows
  local mode = api.nvim_get_mode().mode
  local op_mode_3f = mode:match("o")
  local change_op_3f = (op_mode_3f and (vim.v.operator == "c"))
  local dot_repeatable_op_3f = (op_mode_3f and directional_3f and (vim.v.operator ~= "y"))
  local force_noautojump_3f = (multi_select_3f or user_given_action or op_mode_3f or not directional_3f)
  local max_aot_targets = (opts.max_aot_targets or math.huge)
  local prompt = {str = ">"}
  local spec_keys
  local function _94_(_3, k)
    local _95_ = opts.special_keys[k]
    if (nil ~= _95_) then
      return replace_keycodes(_95_)
    else
      return _95_
    end
  end
  spec_keys = setmetatable({}, {__index = _94_})
  local aot_3f = not (multi_select_3f or user_given_targets or (max_aot_targets == 0))
  local function echo_not_found(s)
    return echo(("not found: " .. s))
  end
  local function expand_to_user_defined_character_class(_in)
    local _97_ = opts.character_class_of[_in]
    if (nil ~= _97_) then
      local chars = _97_
      local chars_2a
      local function _98_(_241)
        local _99_ = _241
        if (_99_ == "\n") then
          return "\\n"
        elseif (_99_ == "\\") then
          return "\\\\"
        elseif true then
          local _3 = _99_
          return _241
        else
          return nil
        end
      end
      chars_2a = map(_98_, chars)
      return ("\\(" .. table.concat(chars_2a, "\\|") .. "\\)")
    else
      return nil
    end
  end
  local function prepare_pattern(in1, _3fin2)
    local function _102_()
      if opts.case_sensitive then
        return "\\C"
      else
        return "\\c"
      end
    end
    return ("\\V" .. _102_() .. (expand_to_user_defined_character_class(in1) or in1:gsub("\\", "\\\\")) .. (expand_to_user_defined_character_class(_3fin2) or _3fin2 or "\\_."))
  end
  local function get_target_with_active_primary_label(sublist, input)
    local res = nil
    for idx, _103_ in ipairs(sublist) do
      local _each_104_ = _103_
      local label = _each_104_["label"]
      local label_state = _each_104_["label-state"]
      local target = _each_104_
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
      if state_2a.dot_repeat then
        state.dot_repeat = vim.tbl_extend("error", state_2a.dot_repeat, {["backward?"] = backward_3f, offset = offset, ["inclusive-op?"] = inclusive_op_3f})
        return nil
      else
        return nil
      end
    else
      return nil
    end
  end
  local function set_dot_repeat(in1, in2, target_idx)
    if dot_repeatable_op_3f then
      update_state({dot_repeat = {in1 = in1, in2 = in2, target_idx = target_idx}})
      return set_dot_repeat_2a()
    else
      return nil
    end
  end
  local jump_to_21
  do
    local first_jump_3f = true
    local function _110_(target)
      local jump = require("leap.jump")
      jump["jump-to!"](target.pos, {winid = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["backward?"] = backward_3f, ["inclusive-op?"] = inclusive_op_3f})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _110_
  end
  local function get_first_pattern_input()
    do
      hl:cleanup(hl_affected_windows)
      if not (user_given_targets and not _3ftarget_windows) then
        hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
      else
      end
      do
        echo("")
      end
      hl["highlight-cursor"](hl)
      vim.cmd("redraw")
    end
    local _112_
    local function _113_()
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
    _112_ = (get_input_by_keymap(prompt) or _113_())
    if (_112_ == spec_keys.repeat_search) then
      if state["repeat"].in1 then
        aot_3f = false
        return state["repeat"].in1, state["repeat"].in2
      else
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
          echo("no previous search")
        end
        hl:cleanup(hl_affected_windows)
        exec_user_autocmds("LeapLeave")
        return nil
      end
    elseif (nil ~= _112_) then
      local in1 = _112_
      return in1
    else
      return nil
    end
  end
  local function get_second_pattern_input(targets)
    if (#targets <= max_aot_targets) then
      hl:cleanup(hl_affected_windows)
      if not (user_given_targets and not _3ftarget_windows) then
        hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
      else
      end
      do
        light_up_beacons(targets)
      end
      hl["highlight-cursor"](hl)
      vim.cmd("redraw")
    else
    end
    local function _120_()
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
    return (get_input_by_keymap(prompt) or _120_())
  end
  local function get_full_pattern_input()
    local _122_, _123_ = get_first_pattern_input()
    if ((nil ~= _122_) and (nil ~= _123_)) then
      local in1 = _122_
      local in2 = _123_
      return in1, in2
    elseif ((nil ~= _122_) and (_123_ == nil)) then
      local in1 = _122_
      local _124_ = get_input_by_keymap(prompt)
      if (nil ~= _124_) then
        local in2 = _124_
        return in1, in2
      elseif true then
        local _3 = _124_
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
  local function post_pattern_input_loop(sublist, _3fgroup_offset, first_invoc_3f)
    local function loop(group_offset, first_invoc_3f0)
      do
        local _128_ = sublist
        set_label_states(_128_, {["group-offset"] = group_offset})
        set_beacons(_128_, {["user-given-targets?"] = user_given_targets, ["aot?"] = aot_3f})
      end
      do
        hl:cleanup(hl_affected_windows)
        if not (user_given_targets and not _3ftarget_windows) then
          hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
        else
        end
        do
          local function _130_()
            if sublist["autojump?"] then
              return 2
            else
              return nil
            end
          end
          light_up_beacons(sublist, _130_())
        end
        hl["highlight-cursor"](hl)
        vim.cmd("redraw")
      end
      local _131_
      local function _132_()
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
      _131_ = (get_input() or _132_())
      if (nil ~= _131_) then
        local input = _131_
        if (((input == spec_keys.next_group) or ((input == spec_keys.prev_group) and not first_invoc_3f0)) and (not sublist["autojump?"] or user_forced_autojump_3f())) then
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
        elseif "else" then
          return input, group_offset
        else
          return nil
        end
      else
        return nil
      end
    end
    local function _137_()
      if (nil == first_invoc_3f) then
        return true
      else
        return first_invoc_3f
      end
    end
    return loop((_3fgroup_offset or 0), _137_())
  end
  local multi_select_loop
  do
    local res = {}
    local group_offset = 0
    local first_invoc_3f = true
    local function loop(targets)
      local _138_, _139_ = post_pattern_input_loop(targets, group_offset, first_invoc_3f)
      if (_138_ == spec_keys.multi_accept) then
        if next(res) then
          return res
        else
          return loop(targets)
        end
      elseif (_138_ == spec_keys.multi_revert) then
        do
          local _141_ = table.remove(res)
          if (nil ~= _141_) then
            _141_["label-state"] = nil
          else
          end
        end
        return loop(targets)
      elseif ((nil ~= _138_) and (nil ~= _139_)) then
        local _in = _138_
        local group_offset_2a = _139_
        group_offset = group_offset_2a
        first_invoc_3f = false
        do
          local _143_ = get_target_with_active_primary_label(targets, _in)
          if ((_G.type(_143_) == "table") and (nil ~= (_143_)[1]) and (nil ~= (_143_)[2])) then
            local idx = (_143_)[1]
            local target = (_143_)[2]
            if not contains_3f(res, target) then
              table.insert(res, target)
              do end (target)["label-state"] = "selected"
            else
            end
          else
          end
        end
        return loop(targets)
      else
        return nil
      end
    end
    multi_select_loop = loop
  end
  local function traversal_loop(targets, idx, _147_)
    local _arg_148_ = _147_
    local force_no_labels_3f = _arg_148_["force-no-labels?"]
    if force_no_labels_3f then
      inactivate_labels(targets)
    else
    end
    set_beacons(targets, {["force-no-labels?"] = force_no_labels_3f, ["aot?"] = aot_3f, ["user-given-targets?"] = user_given_targets})
    do
      hl:cleanup(hl_affected_windows)
      if not (user_given_targets and not _3ftarget_windows) then
        hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
      else
      end
      do
        light_up_beacons(targets, inc(idx))
      end
      hl["highlight-cursor"](hl)
      vim.cmd("redraw")
    end
    local _151_
    local function _152_()
      do
      end
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return nil
    end
    _151_ = (get_input() or _152_())
    if (nil ~= _151_) then
      local input = _151_
      if ((input == spec_keys.next_match) or (input == spec_keys.prev_match)) then
        local new_idx
        do
          local _153_ = input
          if (_153_ == spec_keys.next_match) then
            new_idx = min(inc(idx), #targets)
          elseif (_153_ == spec_keys.prev_match) then
            new_idx = max(dec(idx), 1)
          else
            new_idx = nil
          end
        end
        local _156_
        do
          local t_155_ = targets
          if (nil ~= t_155_) then
            t_155_ = (t_155_)[new_idx]
          else
          end
          if (nil ~= t_155_) then
            t_155_ = (t_155_).pair
          else
          end
          if (nil ~= t_155_) then
            t_155_ = (t_155_)[2]
          else
          end
          _156_ = t_155_
        end
        update_state({["repeat"] = {in1 = state["repeat"].in1, in2 = _156_}})
        jump_to_21(targets[new_idx])
        return traversal_loop(targets, new_idx, {["force-no-labels?"] = force_no_labels_3f})
      else
        local _160_ = get_target_with_active_primary_label(targets, input)
        if ((_G.type(_160_) == "table") and true and (nil ~= (_160_)[2])) then
          local _3 = (_160_)[1]
          local target = (_160_)[2]
          do
            jump_to_21(target)
          end
          hl:cleanup(hl_affected_windows)
          exec_user_autocmds("LeapLeave")
          return nil
        elseif true then
          local _3 = _160_
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
  local do_action = (user_given_action or jump_to_21)
  exec_user_autocmds("LeapEnter")
  local function _164_(...)
    local _165_, _166_ = ...
    if ((nil ~= _165_) and true) then
      local in1 = _165_
      local _3fin2 = _166_
      local function _167_(...)
        local _168_ = ...
        if (nil ~= _168_) then
          local targets = _168_
          local function _169_(...)
            local _170_ = ...
            if (nil ~= _170_) then
              local in2 = _170_
              if ((in2 == spec_keys.next_match) and directional_3f) then
                local in20 = targets[1].pair[2]
                update_state({["repeat"] = {in1 = in1, in2 = in20}})
                do_action(targets[1])
                if ((#targets == 1) or op_mode_3f or user_given_action) then
                  do
                    set_dot_repeat(in1, in20, 1)
                  end
                  hl:cleanup(hl_affected_windows)
                  exec_user_autocmds("LeapLeave")
                  return nil
                else
                  return traversal_loop(targets, 1, {["force-no-labels?"] = true})
                end
              else
                update_state({["repeat"] = {in1 = in1, in2 = in2}})
                local _172_
                local function _173_(...)
                  if targets.sublists then
                    return targets.sublists[in2]
                  else
                    return targets
                  end
                end
                local function _174_(...)
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
                _172_ = (_173_(...) or _174_(...))
                if (nil ~= _172_) then
                  local targets_2a = _172_
                  if multi_select_3f then
                    local _176_ = multi_select_loop(targets_2a)
                    if (nil ~= _176_) then
                      local targets_2a_2a = _176_
                      do
                        do
                          hl:cleanup(hl_affected_windows)
                          if not (user_given_targets and not _3ftarget_windows) then
                            hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
                          else
                          end
                          do
                            light_up_beacons(targets_2a_2a)
                          end
                          hl["highlight-cursor"](hl)
                          vim.cmd("redraw")
                        end
                        do_action(targets_2a_2a)
                      end
                      hl:cleanup(hl_affected_windows)
                      exec_user_autocmds("LeapLeave")
                      return nil
                    else
                      return nil
                    end
                  else
                    local exit_with_action
                    local function _179_(idx)
                      do
                        set_dot_repeat(in1, in2, idx)
                        do_action((targets_2a)[idx])
                      end
                      hl:cleanup(hl_affected_windows)
                      exec_user_autocmds("LeapLeave")
                      return nil
                    end
                    exit_with_action = _179_
                    if (#targets_2a == 1) then
                      return exit_with_action(1)
                    else
                      if targets_2a["autojump?"] then
                        do_action((targets_2a)[1])
                      else
                      end
                      local _181_ = post_pattern_input_loop(targets_2a)
                      if (nil ~= _181_) then
                        local in_final = _181_
                        if ((in_final == spec_keys.next_match) and directional_3f) then
                          if (op_mode_3f or user_given_action) then
                            return exit_with_action(1)
                          else
                            local new_idx
                            if targets_2a["autojump?"] then
                              new_idx = 2
                            else
                              new_idx = 1
                            end
                            do_action((targets_2a)[new_idx])
                            return traversal_loop(targets_2a, new_idx, {["force-no-labels?"] = not targets_2a["autojump?"]})
                          end
                        else
                          local _184_ = get_target_with_active_primary_label(targets_2a, in_final)
                          if ((_G.type(_184_) == "table") and (nil ~= (_184_)[1]) and true) then
                            local idx = (_184_)[1]
                            local _3 = (_184_)[2]
                            return exit_with_action(idx)
                          elseif true then
                            local _3 = _184_
                            if targets_2a["autojump?"] then
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
                    end
                  end
                else
                  return nil
                end
              end
            elseif true then
              local __60_auto = _170_
              return ...
            else
              return nil
            end
          end
          local function _204_(...)
            if dot_repeat_3f then
              local _195_ = targets[state.dot_repeat.target_idx]
              if (nil ~= _195_) then
                local target = _195_
                do
                  do_action(target)
                end
                hl:cleanup(hl_affected_windows)
                exec_user_autocmds("LeapLeave")
                return nil
              elseif true then
                local _3 = _195_
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
              local prepare_targets
              local function _198_(_241)
                local _199_ = _241
                set_autojump(_199_, force_noautojump_3f)
                attach_label_set(_199_)
                set_labels(_199_, multi_select_3f)
                return _199_
              end
              prepare_targets = _198_
              if _3fin2 then
                prepare_targets(targets)
              else
                populate_sublists(targets)
                for _3, sublist in pairs(targets.sublists) do
                  prepare_targets(sublist)
                end
              end
              if (#targets > max_aot_targets) then
                aot_3f = false
              else
              end
              local function _202_(...)
                do
                  local _203_ = targets
                  set_initial_label_states(_203_)
                  set_beacons(_203_, {["aot?"] = aot_3f})
                end
                return get_second_pattern_input(targets)
              end
              return (_3fin2 or _202_(...))
            end
          end
          return _169_(_204_(...))
        elseif true then
          local __60_auto = _168_
          return ...
        else
          return nil
        end
      end
      local function _206_(...)
        local search = require("leap.search")
        local pattern = prepare_pattern(in1, _3fin2)
        local kwargs0 = {["backward?"] = backward_3f, ["target-windows"] = _3ftarget_windows}
        return search["get-targets"](pattern, kwargs0)
      end
      local function _207_(...)
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
      return _167_((user_given_targets or _206_(...) or _207_(...)))
    elseif true then
      local __60_auto = _165_
      return ...
    else
      return nil
    end
  end
  local function _210_()
    if dot_repeat_3f then
      return state.dot_repeat.in1, state.dot_repeat.in2
    elseif user_given_targets then
      return true, true
    elseif aot_3f then
      return get_first_pattern_input()
    else
      return get_full_pattern_input()
    end
  end
  return _164_(_210_())
end
local _211_
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
  _211_ = t
end
opts["character_class_of"] = _211_
api.nvim_create_augroup("LeapDefault", {})
hl["init-highlight"](hl)
local function _214_()
  return hl["init-highlight"](hl)
end
api.nvim_create_autocmd("ColorScheme", {callback = _214_, group = "LeapDefault"})
local function set_editor_opts(t)
  state.saved_editor_opts = {}
  local wins = (state.args.target_windows or {state.source_window})
  for opt, val in pairs(t) do
    local _let_215_ = vim.split(opt, ".", {plain = true})
    local scope = _let_215_[1]
    local name = _let_215_[2]
    local _216_ = scope
    if (_216_ == "w") then
      for _, w in ipairs(wins) do
        state.saved_editor_opts[{"w", w, name}] = api.nvim_win_get_option(w, name)
        api.nvim_win_set_option(w, name, val)
      end
    elseif (_216_ == "b") then
      for _, w in ipairs(wins) do
        local b = api.nvim_win_get_buf(w)
        do end (state.saved_editor_opts)[{"b", b, name}] = api.nvim_buf_get_option(b, name)
        api.nvim_buf_set_option(b, name, val)
      end
    elseif true then
      local _ = _216_
      state.saved_editor_opts[name] = api.nvim_get_option(name)
      api.nvim_set_option(name, val)
    else
    end
  end
  return nil
end
local function restore_editor_opts()
  for key, val in pairs(state.saved_editor_opts) do
    local _218_ = key
    if ((_G.type(_218_) == "table") and ((_218_)[1] == "w") and (nil ~= (_218_)[2]) and (nil ~= (_218_)[3])) then
      local w = (_218_)[2]
      local name = (_218_)[3]
      api.nvim_win_set_option(w, name, val)
    elseif ((_G.type(_218_) == "table") and ((_218_)[1] == "b") and (nil ~= (_218_)[2]) and (nil ~= (_218_)[3])) then
      local b = (_218_)[2]
      local name = (_218_)[3]
      api.nvim_buf_set_option(b, name, val)
    elseif (nil ~= _218_) then
      local name = _218_
      api.nvim_set_option(name, val)
    else
    end
  end
  return nil
end
local temporary_editor_opts = {["w.conceallevel"] = 0, ["g.scrolloff"] = 0, ["w.scrolloff"] = 0, ["g.sidescrolloff"] = 0, ["w.sidescrolloff"] = 0, ["b.modeline"] = false}
local function _220_()
  return set_editor_opts(temporary_editor_opts)
end
api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _220_, group = "LeapDefault"})
local function _221_()
  return restore_editor_opts()
end
api.nvim_create_autocmd("User", {pattern = "LeapLeave", callback = _221_, group = "LeapDefault"})
return {state = state, leap = leap}
