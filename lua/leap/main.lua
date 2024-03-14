local hl = require("leap.highlight")
local opts = require("leap.opts")
local _local_1_ = require("leap.beacons")
local set_beacons = _local_1_["set-beacons"]
local resolve_conflicts = _local_1_["resolve-conflicts"]
local light_up_beacons = _local_1_["light-up-beacons"]
local _local_2_ = require("leap.util")
local inc = _local_2_["inc"]
local dec = _local_2_["dec"]
local clamp = _local_2_["clamp"]
local echo = _local_2_["echo"]
local replace_keycodes = _local_2_["replace-keycodes"]
local __3erepresentative_char = _local_2_["->representative-char"]
local get_input = _local_2_["get-input"]
local get_input_by_keymap = _local_2_["get-input-by-keymap"]
local api = vim.api
local contains_3f = vim.tbl_contains
local empty_3f = vim.tbl_isempty
local map = vim.tbl_map
local _local_3_ = math
local ceil = _local_3_["ceil"]
local floor = _local_3_["floor"]
local max = _local_3_["max"]
local min = _local_3_["min"]
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
  local force = string.sub(vim.fn.mode(true), 3)
  local cmd = replace_keycodes("<cmd>lua require'leap'.leap { dot_repeat = true }<cr>")
  local change
  if (op == "c") then
    change = replace_keycodes("<c-r>.<esc>")
  else
    change = nil
  end
  local seq = (op .. force .. cmd .. (change or ""))
  pcall(vim.fn["repeat#setreg"], seq, vim.v.register)
  return pcall(vim.fn["repeat#set"], seq, -1)
end
local function eq_classes__3emembership_lookup(eqcls)
  local res = {}
  for _, eqcl in ipairs(eqcls) do
    local eqcl_2a
    if (type(eqcl) == "string") then
      eqcl_2a = vim.fn.split(eqcl, "\\zs")
    else
      eqcl_2a = eqcl
    end
    for _0, ch in ipairs(eqcl_2a) do
      res[ch] = eqcl_2a
    end
  end
  return res
end
local function populate_sublists(targets, multi_window_search_3f)
  local function _7_(self, ch)
    return rawget(self, __3erepresentative_char(ch))
  end
  local function _8_(self, ch, sublist)
    return rawset(self, __3erepresentative_char(ch), sublist)
  end
  targets.sublists = setmetatable({}, {__index = _7_, __newindex = _8_})
  if not multi_window_search_3f then
    for _, _9_ in ipairs(targets) do
      local _each_10_ = _9_
      local _each_11_ = _each_10_["chars"]
      local _0 = _each_11_[1]
      local ch2 = _each_11_[2]
      local target = _each_10_
      if not targets.sublists[ch2] then
        targets.sublists[ch2] = {}
      else
      end
      table.insert(targets.sublists[ch2], target)
    end
    return nil
  else
    for _, _13_ in ipairs(targets) do
      local _each_14_ = _13_
      local _each_15_ = _each_14_["chars"]
      local _0 = _each_15_[1]
      local ch2 = _each_15_[2]
      local _each_16_ = _each_14_["wininfo"]
      local winid = _each_16_["winid"]
      local target = _each_14_
      if not targets.sublists[ch2] then
        targets.sublists[ch2] = {["shared-window?"] = winid}
      else
      end
      local sublist = targets.sublists[ch2]
      table.insert(sublist, target)
      if (sublist["shared-window?"] and (winid ~= sublist["shared-window?"])) then
        sublist["shared-window?"] = nil
        sublist["in-multiple-windows?"] = true
      else
      end
    end
    return nil
  end
end
local prepare_labeled_targets
do
  local function first_target_covers_label_of_second_3f(targets)
    if ((_G.type(targets) == "table") and ((_G.type(targets[1]) == "table") and ((_G.type(targets[1].pos) == "table") and (nil ~= targets[1].pos[1]) and (nil ~= targets[1].pos[2]))) and ((_G.type(targets[2]) == "table") and ((_G.type(targets[2].pos) == "table") and (nil ~= targets[2].pos[1]) and (nil ~= targets[2].pos[2])) and ((_G.type(targets[2].chars) == "table") and (nil ~= targets[2].chars[1]) and (nil ~= targets[2].chars[2])))) then
      local l1 = targets[1].pos[1]
      local c1 = targets[1].pos[2]
      local l2 = targets[2].pos[1]
      local c2 = targets[2].pos[2]
      local char1 = targets[2].chars[1]
      local char2 = targets[2].chars[2]
      return ((l1 == l2) and (c1 == (c2 + char1:len() + char2:len())))
    else
      return nil
    end
  end
  local function set_autojump(targets)
    if not empty_3f(opts.safe_labels) then
      targets["autojump?"] = (empty_3f(opts.labels) or (#opts.safe_labels >= dec(#targets)))
      return nil
    else
      return nil
    end
  end
  local function attach_label_set(targets)
    if empty_3f(opts.labels) then
      targets["label-set"] = opts.safe_labels
    elseif empty_3f(opts.safe_labels) then
      targets["label-set"] = opts.labels
    elseif targets["autojump?"] then
      targets["label-set"] = opts.safe_labels
    else
      targets["label-set"] = opts.labels
    end
    return nil
  end
  local function set_labels(targets)
    if not ((#targets == 1) and targets["autojump?"]) then
      local _local_23_ = targets
      local autojump_3f = _local_23_["autojump?"]
      local label_set = _local_23_["label-set"]
      local _7clabel_set_7c = #label_set
      for i_2a, target in ipairs(targets) do
        local i
        if autojump_3f then
          i = dec(i_2a)
        else
          i = i_2a
        end
        if (i >= 1) then
          local _25_ = (i % _7clabel_set_7c)
          if (_25_ == 0) then
            target.label = label_set[_7clabel_set_7c]
            target.group = floor((i / _7clabel_set_7c))
          elseif (nil ~= _25_) then
            local n = _25_
            target.label = label_set[n]
            target.group = inc(floor((i / _7clabel_set_7c)))
          else
          end
        else
        end
      end
      return nil
    else
      return nil
    end
  end
  local function _29_(targets, force_noautojump_3f)
    if not (force_noautojump_3f or targets["in-multiple-windows?"] or first_target_covers_label_of_second_3f(targets)) then
      set_autojump(targets)
    else
    end
    attach_label_set(targets)
    return set_labels(targets)
  end
  prepare_labeled_targets = _29_
end
local state = {["repeat"] = {in1 = nil, in2 = nil, backward = nil, inclusive_op = nil, offset = nil, match_same_char_seq_at_end = nil}, dot_repeat = {callback = nil, in1 = nil, in2 = nil, target_idx = nil, backward = nil, inclusive_op = nil, offset = nil, match_same_char_seq_at_end = nil}, args = nil}
local function leap(kwargs)
  local _local_31_ = kwargs
  local invoked_repeat_3f = _local_31_["repeat"]
  local invoked_dot_repeat_3f = _local_31_["dot_repeat"]
  local target_windows = _local_31_["target_windows"]
  local user_given_opts = _local_31_["opts"]
  local user_given_targets = _local_31_["targets"]
  local user_given_action = _local_31_["action"]
  local function _33_()
    if invoked_dot_repeat_3f then
      return state.dot_repeat
    else
      return kwargs
    end
  end
  local _local_32_ = _33_()
  local backward_3f = _local_32_["backward"]
  local function _35_()
    if invoked_dot_repeat_3f then
      return state.dot_repeat
    elseif invoked_repeat_3f then
      return state["repeat"]
    else
      return kwargs
    end
  end
  local _local_34_ = _35_()
  local inclusive_op_3f = _local_34_["inclusive_op"]
  local offset = _local_34_["offset"]
  local match_same_char_seq_at_end_3f = _local_34_["match_same_char_seq_at_end"]
  state.args = kwargs
  opts.current_call = (user_given_opts or {})
  do
    local _36_ = opts.current_call.equivalence_classes
    if (nil ~= _36_) then
      opts.current_call.eq_class_of = eq_classes__3emembership_lookup(_36_)
    else
      opts.current_call.eq_class_of = _36_
    end
  end
  for _, t in ipairs({"default", "current_call"}) do
    for _0, k in ipairs({"labels", "safe_labels"}) do
      if (type(opts[t][k]) == "string") then
        opts[t][k] = vim.fn.split(opts[t][k], "\\zs")
      else
      end
    end
  end
  local directional_3f = not target_windows
  local no_labels_to_use_3f = (empty_3f(opts.labels) and empty_3f(opts.safe_labels))
  if (not directional_3f and no_labels_to_use_3f) then
    echo("no labels to use")
    return
  else
  end
  if (target_windows and empty_3f(target_windows)) then
    echo("no targetable windows")
    return
  else
  end
  local _3ftarget_windows = target_windows
  local multi_window_search_3f = (_3ftarget_windows and (#_3ftarget_windows > 1))
  local curr_winid = api.nvim_get_current_win()
  local hl_affected_windows = vim.list_extend({curr_winid}, (_3ftarget_windows or {}))
  local mode = api.nvim_get_mode().mode
  local op_mode_3f = mode:match("o")
  local change_op_3f = (op_mode_3f and (vim.v.operator == "c"))
  local count
  if not directional_3f then
    count = nil
  elseif (vim.v.count == 0) then
    if (op_mode_3f and no_labels_to_use_3f) then
      count = 1
    else
      count = nil
    end
  else
    count = vim.v.count
  end
  local max_phase_one_targets = (opts.max_phase_one_targets or math.huge)
  local user_given_targets_3f = user_given_targets
  local prompt = {str = ">"}
  local spec_keys
  local function _43_(_, k)
    local _44_ = opts.special_keys[k]
    if (nil ~= _44_) then
      local v = _44_
      if ((k == "next_target") or (k == "prev_target")) then
        local function _45_()
          if (type(v) == "string") then
            return {v}
          else
            return v
          end
        end
        return map(replace_keycodes, _45_())
      else
        return replace_keycodes(v)
      end
    else
      return nil
    end
  end
  spec_keys = setmetatable({}, {__index = _43_})
  local _state
  local _48_
  if (invoked_repeat_3f or (max_phase_one_targets == 0) or no_labels_to_use_3f or user_given_targets_3f) then
    _48_ = nil
  else
    _48_ = 1
  end
  _state = {phase = _48_, ["curr-idx"] = 0, ["group-offset"] = 0, errmsg = nil, ["repeating-partial-pattern?"] = false}
  local function exec_user_autocmds(pattern)
    return api.nvim_exec_autocmds("User", {pattern = pattern, modeline = false})
  end
  local function can_traverse_3f(targets)
    return (directional_3f and not (count or op_mode_3f or user_given_action) and (#targets >= 2))
  end
  local function get_number_of_highlighted_traversal_targets()
    local _50_ = opts.max_highlighted_traversal_targets
    if (nil ~= _50_) then
      local group_size = _50_
      local consumed = (dec(_state["curr-idx"]) % group_size)
      local remaining = (group_size - consumed)
      if (remaining == 1) then
        return inc(group_size)
      elseif (remaining == 0) then
        return group_size
      else
        return remaining
      end
    else
      return nil
    end
  end
  local function get_highlighted_idx_range(targets, use_no_labels_3f)
    if (use_no_labels_3f and (opts.max_highlighted_traversal_targets == 0)) then
      return 0, -1
    else
      local start = inc(_state["curr-idx"])
      local _end
      if use_no_labels_3f then
        local _53_ = get_number_of_highlighted_traversal_targets()
        if (nil ~= _53_) then
          local n = _53_
          _end = min((dec(start) + n), #targets)
        else
          _end = nil
        end
      else
        _end = nil
      end
      return start, _end
    end
  end
  local function get_target_with_active_label(targets, input)
    local target_2a = nil
    local idx_2a = nil
    local break_3f = false
    for idx, target in ipairs(targets) do
      if (target_2a or break_3f) then break end
      if target.label then
        local relative_group = (target.group - _state["group-offset"])
        if (relative_group > 1) then
          break_3f = true
        elseif (relative_group == 1) then
          if (target.label == input) then
            target_2a = target
            idx_2a = idx
          else
          end
        else
        end
      else
      end
    end
    return target_2a, idx_2a
  end
  local function get_repeat_input()
    if state["repeat"].in1 then
      if not state["repeat"].in2 then
        _state["repeating-partial-pattern?"] = true
      else
      end
      return state["repeat"].in1, state["repeat"].in2
    else
      _state.errmsg = "no previous search"
      return nil
    end
  end
  local function get_first_pattern_input()
    do
      hl:cleanup(hl_affected_windows)
      if not count then
        hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
      else
      end
      do
        echo("")
      end
      hl["highlight-cursor"](hl)
      vim.cmd("redraw")
    end
    local _63_ = get_input_by_keymap(prompt)
    if (nil ~= _63_) then
      local in1 = _63_
      if contains_3f(spec_keys.next_target, in1) then
        if state["repeat"].in1 then
          _state.phase = nil
          if not state["repeat"].in2 then
            _state["repeating-partial-pattern?"] = true
          else
          end
          return state["repeat"].in1, state["repeat"].in2
        else
          _state.errmsg = "no previous search"
          return nil
        end
      else
        return in1
      end
    else
      return nil
    end
  end
  local function get_second_pattern_input(targets)
    if ((#targets <= max_phase_one_targets) and not count) then
      hl:cleanup(hl_affected_windows)
      if not count then
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
    return get_input_by_keymap(prompt)
  end
  local function get_full_pattern_input()
    local _70_, _71_ = get_first_pattern_input()
    if ((nil ~= _70_) and (nil ~= _71_)) then
      local in1 = _70_
      local in2 = _71_
      return in1, in2
    elseif ((nil ~= _70_) and (_71_ == nil)) then
      local in1 = _70_
      local _72_ = get_input_by_keymap(prompt)
      if (nil ~= _72_) then
        local in2 = _72_
        return in1, in2
      else
        return nil
      end
    else
      return nil
    end
  end
  local function get_targets(in1, _3fin2)
    local search = require("leap.search")
    local pattern = search["prepare-pattern"](in1, _3fin2)
    local kwargs0 = {["backward?"] = backward_3f, ["match-same-char-seq-at-end?"] = match_same_char_seq_at_end_3f, ["target-windows"] = _3ftarget_windows}
    local targets = search["get-targets"](pattern, kwargs0)
    local function _75_(...)
      _state.errmsg = ("not found: " .. in1 .. (_3fin2 or ""))
      return nil
    end
    return (targets or _75_())
  end
  local function get_user_given_targets(targets)
    local targets_2a
    if (type(targets) == "function") then
      targets_2a = targets()
    else
      targets_2a = targets
    end
    if (targets_2a and (#targets_2a > 0)) then
      local wininfo = vim.fn.getwininfo(curr_winid)[1]
      if not targets_2a[1].wininfo then
        for _, t in ipairs(targets_2a) do
          t.wininfo = wininfo
        end
      else
      end
      return targets_2a
    else
      _state.errmsg = "no targets"
      return nil
    end
  end
  local function prepare_labeled_targets_2a(targets)
    local force_noautojump_3f = (user_given_action or (op_mode_3f and (#targets > 1)))
    return prepare_labeled_targets(targets, force_noautojump_3f)
  end
  local from_kwargs = {offset = offset, match_same_char_seq_at_end = match_same_char_seq_at_end_3f, backward = backward_3f, inclusive_op = inclusive_op_3f}
  local function update_repeat_state(in1, in2)
    if not (invoked_repeat_3f or user_given_targets_3f) then
      state["repeat"] = vim.tbl_extend("error", from_kwargs, {in1 = in1, in2 = in2})
      return nil
    else
      return nil
    end
  end
  local function set_dot_repeat(in1, in2, target_idx)
    local dot_repeatable_op_3f = (op_mode_3f and ((vim.o.cpo):match("y") or (vim.v.operator ~= "y")))
    local dot_repeatable_call_3f = (dot_repeatable_op_3f and not invoked_dot_repeat_3f and directional_3f and (type(user_given_targets) ~= "table"))
    local function update_dot_repeat_state()
      state.dot_repeat = vim.tbl_extend("error", from_kwargs, {callback = user_given_targets, in1 = (not user_given_targets and in1), in2 = (not user_given_targets and in2), target_idx = target_idx})
      return nil
    end
    if dot_repeatable_call_3f then
      update_dot_repeat_state()
      return set_dot_repeat_2a()
    else
      return nil
    end
  end
  local jump_to_21
  do
    local first_jump_3f = true
    local function _81_(target)
      local jump = require("leap.jump")
      jump["jump-to!"](target.pos, {winid = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["backward?"] = backward_3f, ["inclusive-op?"] = inclusive_op_3f})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _81_
  end
  local function post_pattern_input_loop(targets)
    local _7cgroups_7c
    if not targets["label-set"] then
      _7cgroups_7c = 0
    else
      _7cgroups_7c = ceil((#targets / #targets["label-set"]))
    end
    local function display()
      local use_no_labels_3f = (no_labels_to_use_3f or _state["repeating-partial-pattern?"])
      set_beacons(targets, {["group-offset"] = _state["group-offset"], ["use-no-labels?"] = use_no_labels_3f, ["user-given-targets?"] = user_given_targets_3f, phase = _state.phase})
      hl:cleanup(hl_affected_windows)
      if not count then
        hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
      else
      end
      do
        local start, _end = get_highlighted_idx_range(targets, use_no_labels_3f)
        light_up_beacons(targets, start, _end)
      end
      hl["highlight-cursor"](hl)
      return vim.cmd("redraw")
    end
    local function loop(first_invoc_3f)
      display()
      if first_invoc_3f then
        exec_user_autocmds("LeapSelectPre")
      else
      end
      local _85_ = get_input()
      if (nil ~= _85_) then
        local input = _85_
        local switch_group_3f = ((input == spec_keys.next_group) or ((input == spec_keys.prev_group) and not first_invoc_3f))
        if (switch_group_3f and (_7cgroups_7c > 1)) then
          local shift
          if (input == spec_keys.next_group) then
            shift = 1
          else
            shift = -1
          end
          local max_offset = dec(_7cgroups_7c)
          _state["group-offset"] = clamp((_state["group-offset"] + shift), 0, max_offset)
          return loop(false)
        else
          return input
        end
      else
        return nil
      end
    end
    return loop(true)
  end
  local function traversal_loop(targets, start_idx, _89_)
    local _arg_90_ = _89_
    local use_no_labels_3f = _arg_90_["use-no-labels?"]
    local function on_first_invoc()
      if use_no_labels_3f then
        for _, t in ipairs(targets) do
          t.label = nil
        end
        return nil
      elseif not empty_3f(opts.safe_labels) then
        local last_labeled = inc(#opts.safe_labels)
        for i = inc(last_labeled), #targets do
          local _91_ = targets[i]
          _91_["label"] = nil
          _91_["beacon"] = nil
        end
        return nil
      else
        return nil
      end
    end
    local function display()
      set_beacons(targets, {["group-offset"] = _state["group-offset"], ["use-no-labels?"] = use_no_labels_3f, ["user-given-targets?"] = user_given_targets_3f, phase = _state.phase})
      hl:cleanup(hl_affected_windows)
      if not count then
        hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
      else
      end
      do
        local start, _end = get_highlighted_idx_range(targets, use_no_labels_3f)
        light_up_beacons(targets, start, _end)
      end
      hl["highlight-cursor"](hl)
      return vim.cmd("redraw")
    end
    local function get_new_idx(idx, _in)
      if contains_3f(spec_keys.next_target, _in) then
        return min(inc(idx), #targets)
      elseif contains_3f(spec_keys.prev_target, _in) then
        return max(dec(idx), 1)
      else
        return nil
      end
    end
    local function loop(idx, first_invoc_3f)
      if first_invoc_3f then
        on_first_invoc()
      else
      end
      _state["curr-idx"] = idx
      display()
      local _96_ = get_input()
      if (nil ~= _96_) then
        local _in = _96_
        if ((idx == 1) and contains_3f(spec_keys.prev_target, _in)) then
          return vim.fn.feedkeys(_in, "i")
        else
          local _97_ = get_new_idx(idx, _in)
          if (nil ~= _97_) then
            local new_idx = _97_
            jump_to_21(targets[new_idx])
            return loop(new_idx, false)
          else
            local _ = _97_
            local _98_ = get_target_with_active_label(targets, _in)
            if (nil ~= _98_) then
              local target = _98_
              return jump_to_21(target)
            else
              local _0 = _98_
              return vim.fn.feedkeys(_in, "i")
            end
          end
        end
      else
        return nil
      end
    end
    return loop(start_idx, true)
  end
  local do_action = (user_given_action or jump_to_21)
  exec_user_autocmds("LeapEnter")
  local in1, _3fin2 = nil, nil
  if invoked_repeat_3f then
    in1, _3fin2 = get_repeat_input()
  elseif invoked_dot_repeat_3f then
    if state.dot_repeat.callback then
      in1, _3fin2 = true, true
    else
      in1, _3fin2 = state.dot_repeat.in1, state.dot_repeat.in2
    end
  elseif user_given_targets_3f then
    in1, _3fin2 = true, true
  elseif not _state.phase then
    in1, _3fin2 = get_full_pattern_input()
  else
    in1, _3fin2 = get_first_pattern_input()
  end
  if not in1 then
    if change_op_3f then
      handle_interrupted_change_op_21()
    else
    end
    if _state.errmsg then
      echo(_state.errmsg)
    else
    end
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  local targets
  if (invoked_dot_repeat_3f and state.dot_repeat.callback) then
    targets = get_user_given_targets(state.dot_repeat.callback)
  elseif user_given_targets_3f then
    targets = get_user_given_targets(user_given_targets)
  else
    targets = get_targets(in1, _3fin2)
  end
  if not targets then
    if change_op_3f then
      handle_interrupted_change_op_21()
    else
    end
    if _state.errmsg then
      echo(_state.errmsg)
    else
    end
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  if invoked_dot_repeat_3f then
    local _112_ = targets[state.dot_repeat.target_idx]
    if (nil ~= _112_) then
      local target = _112_
      do_action(target)
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    else
      local _ = _112_
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      if _state.errmsg then
        echo(_state.errmsg)
      else
      end
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    end
  else
  end
  if (_3fin2 or _state["repeating-partial-pattern?"]) then
    if (no_labels_to_use_3f or _state["repeating-partial-pattern?"]) then
      targets["autojump?"] = true
    else
      prepare_labeled_targets_2a(targets)
    end
  else
    if (#targets > max_phase_one_targets) then
      _state.phase = nil
    else
    end
    populate_sublists(targets, multi_window_search_3f)
    for _, sublist in pairs(targets.sublists) do
      prepare_labeled_targets_2a(sublist)
      set_beacons(targets, {phase = _state.phase})
    end
    if (_state.phase == 1) then
      resolve_conflicts(targets)
    else
    end
  end
  local _3fin20 = (_3fin2 or (not _state["repeating-partial-pattern?"] and get_second_pattern_input(targets)))
  if not (_state["repeating-partial-pattern?"] or _3fin20) then
    if change_op_3f then
      handle_interrupted_change_op_21()
    else
    end
    if _state.errmsg then
      echo(_state.errmsg)
    else
    end
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  if _state.phase then
    _state.phase = 2
  else
  end
  local partial_pattern_3f = (_state["repeating-partial-pattern?"] or contains_3f(spec_keys.next_target, _3fin20))
  local function _125_()
    if not partial_pattern_3f then
      return _3fin20
    else
      return nil
    end
  end
  update_repeat_state(in1, _125_())
  if partial_pattern_3f then
    local n = (count or 1)
    local target = targets[n]
    if not target then
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      if _state.errmsg then
        echo(_state.errmsg)
      else
      end
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    else
    end
    set_dot_repeat(in1, nil, n)
    do_action(target)
    if can_traverse_3f(targets) then
      traversal_loop(targets, 1, {["use-no-labels?"] = true})
    else
    end
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  exec_user_autocmds("LeapPatternPost")
  local targets_2a
  if targets.sublists then
    targets_2a = targets.sublists[_3fin20]
  else
    targets_2a = targets
  end
  if not targets_2a then
    _state.errmsg = ("not found: " .. in1 .. _3fin20)
    if change_op_3f then
      handle_interrupted_change_op_21()
    else
    end
    if _state.errmsg then
      echo(_state.errmsg)
    else
    end
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  if count then
    if (count > #targets_2a) then
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      if _state.errmsg then
        echo(_state.errmsg)
      else
      end
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    else
      set_dot_repeat(in1, _3fin20, count)
      do_action(targets_2a[count])
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    end
  elseif (invoked_repeat_3f and not can_traverse_3f(targets_2a)) then
    set_dot_repeat(in1, _3fin20, 1)
    do_action(targets_2a[1])
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  if targets_2a["autojump?"] then
    do_action(targets_2a[1])
    if (#targets_2a > 1) then
      _state["curr-idx"] = 1
    else
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    end
  else
  end
  local in_final = post_pattern_input_loop(targets_2a)
  if not in_final then
    if change_op_3f then
      handle_interrupted_change_op_21()
    else
    end
    if _state.errmsg then
      echo(_state.errmsg)
    else
    end
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  if contains_3f(spec_keys.next_target, in_final) then
    if can_traverse_3f(targets_2a) then
      local new_idx = inc(_state["curr-idx"])
      do_action(targets_2a[new_idx])
      traversal_loop(targets_2a, new_idx, {["use-no-labels?"] = (no_labels_to_use_3f or _state["repeating-partial-pattern?"] or not targets_2a["autojump?"])})
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    elseif (_state["curr-idx"] == 0) then
      set_dot_repeat(in1, _3fin20, 1)
      do_action(targets_2a[1])
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    elseif (_state["curr-idx"] == 1) then
      vim.fn.feedkeys(in_final, "i")
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    else
    end
  else
  end
  local _, idx = get_target_with_active_label(targets_2a, in_final)
  if idx then
    set_dot_repeat(in1, _3fin20, idx)
    do_action(targets_2a[idx])
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
    vim.fn.feedkeys(in_final, "i")
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  end
  return nil
end
local function init()
  api.nvim_create_augroup("LeapDefault", {})
  do
    local _147_ = opts.default.equivalence_classes
    if (nil ~= _147_) then
      opts.default.eq_class_of = eq_classes__3emembership_lookup(_147_)
    else
      opts.default.eq_class_of = _147_
    end
  end
  local function set_concealed_label()
    if ((vim.fn.has("nvim-0.9.1") == 1) and api.nvim_get_hl(0, {name = "LeapLabelPrimary"}).bg and api.nvim_get_hl(0, {name = "LeapLabelSecondary"}).bg) then
      opts.concealed_label = " "
    else
      opts.concealed_label = "\194\183"
    end
    return nil
  end
  local function _150_(_)
    return set_concealed_label()
  end
  api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _150_, group = "LeapDefault"})
  hl["init-highlight"](hl)
  local function _151_(_)
    return hl["init-highlight"](hl)
  end
  api.nvim_create_autocmd("ColorScheme", {callback = _151_, group = "LeapDefault"})
  local saved_editor_opts = {}
  local temporary_editor_opts = {["w.conceallevel"] = 0, ["g.scrolloff"] = 0, ["w.scrolloff"] = 0, ["g.sidescrolloff"] = 0, ["w.sidescrolloff"] = 0, ["b.modeline"] = false}
  local function set_editor_opts(t)
    saved_editor_opts = {}
    local wins = (state.args.target_windows or {api.nvim_get_current_win()})
    for opt, val in pairs(t) do
      local _let_152_ = vim.split(opt, ".", {plain = true})
      local scope = _let_152_[1]
      local name = _let_152_[2]
      if (scope == "w") then
        for _, win in ipairs(wins) do
          local saved_val = api.nvim_win_get_option(win, name)
          do end (saved_editor_opts)[{"w", win, name}] = saved_val
          api.nvim_win_set_option(win, name, val)
        end
      elseif (scope == "b") then
        for _, win in ipairs(wins) do
          local buf = api.nvim_win_get_buf(win)
          local saved_val = api.nvim_buf_get_option(buf, name)
          do end (saved_editor_opts)[{"b", buf, name}] = saved_val
          api.nvim_buf_set_option(buf, name, val)
        end
      else
        local _ = scope
        local saved_val = api.nvim_get_option(name)
        do end (saved_editor_opts)[name] = saved_val
        api.nvim_set_option(name, val)
      end
    end
    return nil
  end
  local function restore_editor_opts()
    for key, val in pairs(saved_editor_opts) do
      if ((_G.type(key) == "table") and (key[1] == "w") and (nil ~= key[2]) and (nil ~= key[3])) then
        local win = key[2]
        local name = key[3]
        api.nvim_win_set_option(win, name, val)
      elseif ((_G.type(key) == "table") and (key[1] == "b") and (nil ~= key[2]) and (nil ~= key[3])) then
        local buf = key[2]
        local name = key[3]
        api.nvim_buf_set_option(buf, name, val)
      elseif (nil ~= key) then
        local name = key
        api.nvim_set_option(name, val)
      else
      end
    end
    return nil
  end
  local function _155_(_)
    return set_editor_opts(temporary_editor_opts)
  end
  api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _155_, group = "LeapDefault"})
  local function _156_(_)
    return restore_editor_opts()
  end
  return api.nvim_create_autocmd("User", {pattern = "LeapLeave", callback = _156_, group = "LeapDefault"})
end
init()
return {state = state, leap = leap}
