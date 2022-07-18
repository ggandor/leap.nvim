local hl = require("leap.highlight")
local opts = require("leap.opts")
local jump = require("leap.jump")
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
            if (_7cseq_7c >= 2) then
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
local function set_autojump(targets, force_noautojump_3f)
  targets["autojump?"] = (not (force_noautojump_3f or user_forced_noautojump_3f()) and (user_forced_autojump_3f() or (#opts.safe_labels >= dec(#targets))))
  return nil
end
local function attach_label_set(targets)
  local _19_
  if user_forced_autojump_3f() then
    _19_ = opts.safe_labels
  elseif user_forced_noautojump_3f() then
    _19_ = opts.labels
  elseif targets["autojump?"] then
    _19_ = opts.safe_labels
  else
    _19_ = opts.labels
  end
  targets["label-set"] = _19_
  return nil
end
local function set_labels(targets)
  if (#targets > 1) then
    local _local_21_ = targets
    local autojump_3f = _local_21_["autojump?"]
    local label_set = _local_21_["label-set"]
    for i, target in ipairs(targets) do
      local i_2a
      if autojump_3f then
        i_2a = dec(i)
      else
        i_2a = i
      end
      if (i_2a > 0) then
        local _24_
        do
          local _23_ = (i_2a % #label_set)
          if (_23_ == 0) then
            _24_ = label_set[#label_set]
          elseif (nil ~= _23_) then
            local n = _23_
            _24_ = label_set[n]
          else
            _24_ = nil
          end
        end
        target["label"] = _24_
      else
      end
    end
    return nil
  else
    return nil
  end
end
local function set_label_states(targets, _30_)
  local _arg_31_ = _30_
  local group_offset = _arg_31_["group-offset"]
  local _7clabel_set_7c = #targets["label-set"]
  local offset = (group_offset * _7clabel_set_7c)
  local primary_start
  local function _32_()
    if targets["autojump?"] then
      return 2
    else
      return 1
    end
  end
  primary_start = (offset + _32_())
  local primary_end = (primary_start + dec(_7clabel_set_7c))
  local secondary_start = inc(primary_end)
  local secondary_end = (primary_end + _7clabel_set_7c)
  for i, target in ipairs(targets) do
    if target.label then
      local _33_
      if (function(_34_,_35_,_36_) return (_34_ <= _35_) and (_35_ <= _36_) end)(primary_start,i,primary_end) then
        _33_ = "active-primary"
      elseif (function(_37_,_38_,_39_) return (_37_ <= _38_) and (_38_ <= _39_) end)(secondary_start,i,secondary_end) then
        _33_ = "active-secondary"
      elseif (i > secondary_end) then
        _33_ = "inactive"
      else
        _33_ = nil
      end
      target["label-state"] = _33_
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
  local function _45_()
    local __3ecommon_key
    local function _42_(_241)
      local function _43_()
        if not opts.case_sensitive then
          return _241:lower()
        else
          return nil
        end
      end
      return (opts.character_class_of[_241] or _43_() or _241)
    end
    __3ecommon_key = _42_
    local function _46_(t, k)
      return rawget(t, __3ecommon_key(k))
    end
    local function _47_(t, k, v)
      return rawset(t, __3ecommon_key(k), v)
    end
    return {__index = _46_, __newindex = _47_}
  end
  setmetatable(targets.sublists, _45_())
  for _, _48_ in ipairs(targets) do
    local _each_49_ = _48_
    local _each_50_ = _each_49_["pair"]
    local _0 = _each_50_[1]
    local ch2 = _each_50_[2]
    local target = _each_49_
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
local function resolve_conflicts(targets)
  local unlabeled_match_positions = {}
  local label_positions = {}
  for i, target in ipairs(targets) do
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
local function set_beacons(targets, _74_)
  local _arg_75_ = _74_
  local force_no_labels_3f = _arg_75_["force-no-labels?"]
  local user_given_targets_3f = _arg_75_["user-given-targets?"]
  if (force_no_labels_3f and not user_given_targets_3f) then
    for _, target in ipairs(targets) do
      set_beacon_to_match_hl(target)
    end
    return nil
  else
    for _, target in ipairs(targets) do
      if target.label then
        set_beacon_for_labeled(target, user_given_targets_3f)
      elseif (opts.highlight_unlabeled and not user_given_targets_3f) then
        set_beacon_to_match_hl(target)
      else
      end
    end
    if not user_given_targets_3f then
      return resolve_conflicts(targets)
    else
      return nil
    end
  end
end
local function light_up_beacons(targets, _3fstart)
  for i = (_3fstart or 1), #targets do
    local target = targets[i]
    local _79_ = target.beacon
    if ((_G.type(_79_) == "table") and (nil ~= (_79_)[1]) and (nil ~= (_79_)[2])) then
      local offset = (_79_)[1]
      local virttext = (_79_)[2]
      local bufnr = target.wininfo.bufnr
      local _let_80_ = map(dec, target.pos)
      local lnum = _let_80_[1]
      local col = _let_80_[2]
      local id = api.nvim_buf_set_extmark(bufnr, hl.ns, lnum, (col + offset), {virt_text = virttext, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.label})
      table.insert(hl.extmarks, {bufnr, id})
    else
    end
  end
  return nil
end
local state = {["repeat"] = {in1 = nil, in2 = nil}, dot_repeat = {in1 = nil, in2 = nil, target_idx = nil, backward = nil, inclusive_op = nil, offset = nil}, args = nil}
local function leap(kwargs)
  do
    local _82_ = kwargs.target_windows
    if ((_G.type(_82_) == "table") and ((_82_)[1] == nil)) then
      echo("no targetable windows")
      return
    else
    end
  end
  local _let_84_ = kwargs
  local dot_repeat_3f = _let_84_["dot_repeat"]
  local target_windows = _let_84_["target_windows"]
  local user_given_targets = _let_84_["targets"]
  local user_given_action = _let_84_["action"]
  local function _86_()
    if dot_repeat_3f then
      return state.dot_repeat
    else
      return kwargs
    end
  end
  local _let_85_ = _86_()
  local backward_3f = _let_85_["backward"]
  local inclusive_op_3f = _let_85_["inclusive_op"]
  local offset = _let_85_["offset"]
  local _
  state.args = kwargs
  _ = nil
  local __3ewininfo
  local function _87_(_241)
    return (vim.fn.getwininfo(_241))[1]
  end
  __3ewininfo = _87_
  local current_window = __3ewininfo(vim.fn.win_getid())
  local _0
  if (user_given_targets and not user_given_targets[1].wininfo) then
    local function _88_(t)
      t.wininfo = current_window
      return nil
    end
    _0 = map(_88_, user_given_targets)
  else
    _0 = nil
  end
  local _3ftarget_windows
  do
    local _90_ = target_windows
    if (_90_ ~= nil) then
      _3ftarget_windows = map(__3ewininfo, _90_)
    else
      _3ftarget_windows = _90_
    end
  end
  local hl_affected_windows = {current_window}
  local _1
  for _2, w in ipairs((_3ftarget_windows or {})) do
    table.insert(hl_affected_windows, w)
  end
  _1 = nil
  local directional_3f = not target_windows
  local mode = api.nvim_get_mode().mode
  local op_mode_3f = mode:match("o")
  local change_op_3f = (op_mode_3f and (vim.v.operator == "c"))
  local dot_repeatable_op_3f = (op_mode_3f and directional_3f and (vim.v.operator ~= "y"))
  local force_noautojump_3f = (user_given_action or op_mode_3f or not directional_3f)
  local prompt = {str = ">"}
  local spec_keys
  local function _92_(_2, k)
    return replace_keycodes(opts.special_keys[k])
  end
  spec_keys = setmetatable({}, {__index = _92_})
  local function echo_not_found(s)
    return echo(("not found: " .. s))
  end
  local function expand_to_user_defined_character_class(_in)
    local _93_ = opts.character_class_of[_in]
    if (nil ~= _93_) then
      local chars = _93_
      return ("\\(" .. table.concat(chars, "\\|") .. "\\)")
    else
      return nil
    end
  end
  local function prepare_pattern(in1, _3fin2)
    local function _95_()
      if opts.case_sensitive then
        return "\\C"
      else
        return "\\c"
      end
    end
    return ("\\V" .. _95_() .. (expand_to_user_defined_character_class(in1) or in1:gsub("\\", "\\\\")) .. (expand_to_user_defined_character_class(_3fin2) or _3fin2 or "\\_."))
  end
  local function get_target_with_active_primary_label(sublist, input)
    local res = nil
    for idx, _96_ in ipairs(sublist) do
      local _each_97_ = _96_
      local label = _each_97_["label"]
      local label_state = _each_97_["label-state"]
      local target = _each_97_
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
    local function _103_(target)
      jump["jump-to!"](target.pos, {winid = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["backward?"] = backward_3f, ["inclusive-op?"] = inclusive_op_3f})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _103_
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
    local _105_
    local function _106_()
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
    _105_ = (get_input_by_keymap(prompt) or _106_())
    if (_105_ == spec_keys.repeat_search) then
      if state["repeat"].in1 then
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
    elseif (nil ~= _105_) then
      local in1 = _105_
      return in1
    else
      return nil
    end
  end
  local function get_second_pattern_input(targets)
    if (#targets <= (opts.max_aot_targets or math.huge)) then
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
    return (get_input_by_keymap(prompt) or _113_())
  end
  local function get_full_pattern_input()
    local _115_, _116_ = get_first_pattern_input()
    if ((nil ~= _115_) and (nil ~= _116_)) then
      local in1 = _115_
      local in2 = _116_
      return in1, in2
    elseif ((nil ~= _115_) and (_116_ == nil)) then
      local in1 = _115_
      local _117_ = get_input_by_keymap(prompt)
      if (nil ~= _117_) then
        local in2 = _117_
        return in1, in2
      elseif true then
        local _2 = _117_
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
        local _121_ = sublist
        set_label_states(_121_, {["group-offset"] = group_offset})
        set_beacons(_121_, {["user-given-targets?"] = user_given_targets})
      end
      do
        hl:cleanup(hl_affected_windows)
        if not (user_given_targets and not _3ftarget_windows) then
          hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
        else
        end
        do
          local function _123_()
            if sublist["autojump?"] then
              return 2
            else
              return nil
            end
          end
          light_up_beacons(sublist, _123_())
        end
        hl["highlight-cursor"](hl)
        vim.cmd("redraw")
      end
      local _124_
      local function _125_()
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
      _124_ = (get_input() or _125_())
      if (nil ~= _124_) then
        local input = _124_
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
  local function traversal_loop(targets, idx, _130_)
    local _arg_131_ = _130_
    local force_no_labels_3f = _arg_131_["force-no-labels?"]
    if force_no_labels_3f then
      inactivate_labels(targets)
    else
    end
    set_beacons(targets, {["force-no-labels?"] = force_no_labels_3f, ["user-given-targets?"] = user_given_targets})
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
    local _134_
    local function _135_()
      do
      end
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return nil
    end
    _134_ = (get_input() or _135_())
    if (nil ~= _134_) then
      local input = _134_
      if ((input == spec_keys.next_match) or (input == spec_keys.prev_match)) then
        local new_idx
        do
          local _136_ = input
          if (_136_ == spec_keys.next_match) then
            new_idx = min(inc(idx), #targets)
          elseif (_136_ == spec_keys.prev_match) then
            new_idx = max(dec(idx), 1)
          else
            new_idx = nil
          end
        end
        local _139_
        do
          local t_138_ = targets
          if (nil ~= t_138_) then
            t_138_ = (t_138_)[new_idx]
          else
          end
          if (nil ~= t_138_) then
            t_138_ = (t_138_).pair
          else
          end
          if (nil ~= t_138_) then
            t_138_ = (t_138_)[2]
          else
          end
          _139_ = t_138_
        end
        update_state({["repeat"] = {in1 = state["repeat"].in1, in2 = _139_}})
        jump_to_21(targets[new_idx])
        return traversal_loop(targets, new_idx, {["force-no-labels?"] = force_no_labels_3f})
      else
        local _143_ = get_target_with_active_primary_label(targets, input)
        if ((_G.type(_143_) == "table") and true and (nil ~= (_143_)[2])) then
          local _2 = (_143_)[1]
          local target = (_143_)[2]
          do
            jump_to_21(target)
          end
          hl:cleanup(hl_affected_windows)
          exec_user_autocmds("LeapLeave")
          return nil
        elseif true then
          local _2 = _143_
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
  local function _147_(...)
    local _148_, _149_ = ...
    if ((nil ~= _148_) and true) then
      local in1 = _148_
      local _3fin2 = _149_
      local function _150_(...)
        local _151_ = ...
        if (nil ~= _151_) then
          local targets = _151_
          local function _152_(...)
            local _153_ = ...
            if (nil ~= _153_) then
              local in2 = _153_
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
                local _155_
                local function _156_(...)
                  if targets.sublists then
                    return targets.sublists[in2]
                  else
                    return targets
                  end
                end
                local function _157_(...)
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
                _155_ = (_156_(...) or _157_(...))
                if (nil ~= _155_) then
                  local targets_2a = _155_
                  local exit_with_action
                  local function _159_(idx)
                    do
                      set_dot_repeat(in1, in2, idx)
                      do_action((targets_2a)[idx])
                    end
                    hl:cleanup(hl_affected_windows)
                    exec_user_autocmds("LeapLeave")
                    return nil
                  end
                  exit_with_action = _159_
                  if (#targets_2a == 1) then
                    return exit_with_action(1)
                  else
                    if targets_2a["autojump?"] then
                      do_action((targets_2a)[1])
                    else
                    end
                    local _161_ = post_pattern_input_loop(targets_2a)
                    if (nil ~= _161_) then
                      local in_final = _161_
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
                        local _164_ = get_target_with_active_primary_label(targets_2a, in_final)
                        if ((_G.type(_164_) == "table") and (nil ~= (_164_)[1]) and true) then
                          local idx = (_164_)[1]
                          local _2 = (_164_)[2]
                          return exit_with_action(idx)
                        elseif true then
                          local _2 = _164_
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
                else
                  return nil
                end
              end
            elseif true then
              local __60_auto = _153_
              return ...
            else
              return nil
            end
          end
          local function _182_(...)
            if dot_repeat_3f then
              local _174_ = targets[state.dot_repeat.target_idx]
              if (nil ~= _174_) then
                local target = _174_
                do
                  do_action(target)
                end
                hl:cleanup(hl_affected_windows)
                exec_user_autocmds("LeapLeave")
                return nil
              elseif true then
                local _2 = _174_
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
              local function _177_(_241)
                local _178_ = _241
                set_autojump(_178_, force_noautojump_3f)
                attach_label_set(_178_)
                set_labels(_178_)
                return _178_
              end
              prepare_targets = _177_
              if _3fin2 then
                prepare_targets(targets)
              else
                populate_sublists(targets)
                for _2, sublist in pairs(targets.sublists) do
                  prepare_targets(sublist)
                end
              end
              local function _180_(...)
                do
                  local _181_ = targets
                  set_initial_label_states(_181_)
                  set_beacons(_181_, {})
                end
                return get_second_pattern_input(targets)
              end
              return (_3fin2 or _180_(...))
            end
          end
          return _152_(_182_(...))
        elseif true then
          local __60_auto = _151_
          return ...
        else
          return nil
        end
      end
      local function _184_(...)
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
      return _150_((user_given_targets or get_targets(prepare_pattern(in1, _3fin2), {["backward?"] = backward_3f, ["target-windows"] = _3ftarget_windows}) or _184_(...)))
    elseif true then
      local __60_auto = _148_
      return ...
    else
      return nil
    end
  end
  local function _187_()
    if user_given_targets then
      return true, true
    elseif dot_repeat_3f then
      return state.dot_repeat.in1, state.dot_repeat.in2
    elseif (opts.max_aot_targets == 0) then
      return get_full_pattern_input()
    else
      return get_first_pattern_input()
    end
  end
  return _147_(_187_())
end
local temporary_editor_opts = {["vim.bo.modeline"] = false}
local saved_editor_opts = {}
local function save_editor_opts()
  for opt, _ in pairs(temporary_editor_opts) do
    local _let_188_ = vim.split(opt, ".", true)
    local _0 = _let_188_[1]
    local scope = _let_188_[2]
    local name = _let_188_[3]
    saved_editor_opts[opt] = _G.vim[scope][name]
  end
  return nil
end
local function set_editor_opts(opts0)
  for opt, val in pairs(opts0) do
    local _let_189_ = vim.split(opt, ".", true)
    local _ = _let_189_[1]
    local scope = _let_189_[2]
    local name = _let_189_[3]
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
local _190_
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
  _190_ = t
end
opts["character_class_of"] = _190_
hl["init-highlight"](hl)
api.nvim_create_augroup("LeapDefault", {})
local function _193_()
  return hl["init-highlight"](hl)
end
api.nvim_create_autocmd("ColorScheme", {callback = _193_, group = "LeapDefault"})
local function _194_()
  save_editor_opts()
  return set_temporary_editor_opts()
end
api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _194_, group = "LeapDefault"})
api.nvim_create_autocmd("User", {pattern = "LeapLeave", callback = restore_editor_opts, group = "LeapDefault"})
return {state = state, leap = leap}
