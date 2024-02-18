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
local max = _local_3_["max"]
local min = _local_3_["min"]
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
local function populate_sublists(targets, multi_window_3f)
  targets.sublists = {}
  local function _7_(self, ch, sublist)
    return rawset(self, __3erepresentative_char(ch), sublist)
  end
  local function _8_(self, ch)
    return rawget(self, __3erepresentative_char(ch))
  end
  setmetatable(targets.sublists, {__newindex = _7_, __index = _8_})
  if not multi_window_3f then
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
      else
      end
    end
    return nil
  end
end
local function set_autojump(targets, force_noautojump_3f)
  targets["autojump?"] = (not (force_noautojump_3f or empty_3f(opts.safe_labels)) and (empty_3f(opts.labels) or (#opts.safe_labels >= dec(#targets))))
  return nil
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
local function set_labels(targets, force_labels_3f)
  if ((#targets > 1) or empty_3f(opts.safe_labels) or force_labels_3f) then
    local _local_21_ = targets
    local autojump_3f = _local_21_["autojump?"]
    local label_set = _local_21_["label-set"]
    local _7clabel_set_7c = #label_set
    for i_2a, target in ipairs(targets) do
      local i
      if autojump_3f then
        i = dec(i_2a)
      else
        i = i_2a
      end
      if (i >= 1) then
        local _23_ = (i % _7clabel_set_7c)
        if (_23_ == 0) then
          target.label = label_set[_7clabel_set_7c]
          target.group = math.floor((i / _7clabel_set_7c))
        elseif (nil ~= _23_) then
          local n = _23_
          target.label = label_set[n]
          target.group = inc(math.floor((i / _7clabel_set_7c)))
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
local function prepare_targets(targets, _27_)
  local _arg_28_ = _27_
  local force_noautojump_3f = _arg_28_["force-noautojump?"]
  local force_labels_3f = _arg_28_["force-labels?"]
  set_autojump(targets, force_noautojump_3f)
  attach_label_set(targets)
  set_labels(targets, force_labels_3f)
  return targets
end
local state = {args = nil, source_window = nil, ["repeat"] = {in1 = nil, in2 = nil, inclusive_op = nil, offset = nil, backward = nil}, dot_repeat = {in1 = nil, in2 = nil, target_idx = nil, backward = nil, inclusive_op = nil, offset = nil}, saved_editor_opts = {}}
local function leap(kwargs)
  local _local_29_ = kwargs
  local repeat_3f = _local_29_["repeat"]
  local dot_repeat_3f = _local_29_["dot_repeat"]
  local target_windows = _local_29_["target_windows"]
  local user_given_opts = _local_29_["opts"]
  local user_given_targets = _local_29_["targets"]
  local user_given_action = _local_29_["action"]
  local multi_select_3f = _local_29_["multiselect"]
  local function _31_()
    if dot_repeat_3f then
      return state.dot_repeat
    else
      return kwargs
    end
  end
  local _local_30_ = _31_()
  local backward_3f = _local_30_["backward"]
  local function _33_()
    if dot_repeat_3f then
      return state.dot_repeat
    elseif repeat_3f then
      return state["repeat"]
    else
      return kwargs
    end
  end
  local _local_32_ = _33_()
  local inclusive_op_3f = _local_32_["inclusive_op"]
  local offset = _local_32_["offset"]
  local match_same_char_seq_at_end_3f = _local_32_["match_same_char_seq_at_end"]
  opts.current_call = (user_given_opts or {})
  do
    local _34_ = opts.current_call.equivalence_classes
    if (nil ~= _34_) then
      opts.current_call.eq_class_of = eq_classes__3emembership_lookup(_34_)
    else
      opts.current_call.eq_class_of = _34_
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
  local empty_label_lists_3f = (empty_3f(opts.labels) and empty_3f(opts.safe_labels))
  if (not directional_3f and empty_label_lists_3f) then
    echo("no labels to use")
    return
  else
  end
  if (target_windows and empty_3f(target_windows)) then
    echo("no targetable windows")
    return
  else
  end
  if (multi_select_3f and not user_given_action) then
    echo("error: multiselect mode requires user-provided `action` callback")
    return
  else
  end
  local curr_winid = api.nvim_get_current_win()
  state.args = kwargs
  state.source_window = curr_winid
  local _3ftarget_windows = target_windows
  local multi_window_3f = (_3ftarget_windows and (#_3ftarget_windows > 1))
  local hl_affected_windows = vim.list_extend({curr_winid}, (_3ftarget_windows or {}))
  local mode = api.nvim_get_mode().mode
  local op_mode_3f = mode:match("o")
  local change_op_3f = (op_mode_3f and (vim.v.operator == "c"))
  local dot_repeatable_op_3f = (op_mode_3f and directional_3f and ((vim.o.cpo):match("y") or (vim.v.operator ~= "y")))
  local count
  if not directional_3f then
    count = nil
  elseif (vim.v.count == 0) then
    if (op_mode_3f and empty_label_lists_3f) then
      count = 1
    else
      count = nil
    end
  else
    count = vim.v.count
  end
  local max_phase_one_targets = (opts.max_phase_one_targets or math.huge)
  local user_given_targets_3f = user_given_targets
  local can_traverse_3f = (directional_3f and not (count or op_mode_3f or user_given_action))
  local prompt = {str = ">"}
  local spec_keys
  local function _42_(_, k)
    local _43_ = opts.special_keys[k]
    if (nil ~= _43_) then
      local v = _43_
      if ((k == "next_target") or (k == "prev_target")) then
        local function _44_()
          if (type(v) == "string") then
            return {v}
          else
            return v
          end
        end
        return map(replace_keycodes, _44_())
      else
        return replace_keycodes(v)
      end
    else
      return nil
    end
  end
  spec_keys = setmetatable({}, {__index = _42_})
  local _state
  local _47_
  if (repeat_3f or (max_phase_one_targets == 0) or empty_label_lists_3f or multi_select_3f or user_given_targets_3f) then
    _47_ = nil
  else
    _47_ = 1
  end
  _state = {phase = _47_, ["curr-idx"] = 0, ["group-offset"] = 0, errmsg = nil, ["partial-pattern?"] = false}
  local function get_number_of_highlighted_traversal_targets()
    local _49_ = opts.max_highlighted_traversal_targets
    if (nil ~= _49_) then
      local group_size = _49_
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
  local function get_highlighted_idx_range(targets, no_labels_3f)
    if (no_labels_3f and (opts.max_highlighted_traversal_targets == 0)) then
      return 0, -1
    else
      local start = inc(_state["curr-idx"])
      local _end
      if no_labels_3f then
        local _52_ = get_number_of_highlighted_traversal_targets()
        if (nil ~= _52_) then
          local n = _52_
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
  local function get_target_with_active_label(sublist, input)
    local res = {}
    for idx, _56_ in ipairs(sublist) do
      local _each_57_ = _56_
      local label = _each_57_["label"]
      local group = _each_57_["group"]
      local target = _each_57_
      if (next(res) or (((group or 0) - _state["group-offset"]) > 1)) then break end
      if ((label == input) and ((group - _state["group-offset"]) == 1)) then
        res = {idx, target}
      else
      end
    end
    return res
  end
  local function get_repeat_input()
    if state["repeat"].in1 then
      if not state["repeat"].in2 then
        _state["partial-pattern?"] = true
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
    local _62_ = get_input_by_keymap(prompt)
    if (nil ~= _62_) then
      local in1 = _62_
      if contains_3f(spec_keys.next_target, in1) then
        if state["repeat"].in1 then
          _state.phase = nil
          if not state["repeat"].in2 then
            _state["partial-pattern?"] = true
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
    local _69_, _70_ = get_first_pattern_input()
    if ((nil ~= _69_) and (nil ~= _70_)) then
      local in1 = _69_
      local in2 = _70_
      return in1, in2
    elseif ((nil ~= _69_) and (_70_ == nil)) then
      local in1 = _69_
      local _71_ = get_input_by_keymap(prompt)
      if (nil ~= _71_) then
        local in2 = _71_
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
    local function _74_(...)
      _state.errmsg = ("not found: " .. in1 .. (_3fin2 or ""))
      return nil
    end
    return (targets or _74_())
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
  local function prepare_targets_2a(targets)
    local funny_edge_case_3f
    local function _78_(...)
      if ((_G.type(targets) == "table") and ((_G.type(targets[1]) == "table") and ((_G.type(targets[1].pos) == "table") and (nil ~= targets[1].pos[1]) and (nil ~= targets[1].pos[2]))) and ((_G.type(targets[2]) == "table") and ((_G.type(targets[2].pos) == "table") and (nil ~= targets[2].pos[1]) and (nil ~= targets[2].pos[2])) and ((_G.type(targets[2].chars) == "table") and (nil ~= targets[2].chars[1]) and (nil ~= targets[2].chars[2])))) then
        local l1 = targets[1].pos[1]
        local c1 = targets[1].pos[2]
        local l2 = targets[2].pos[1]
        local c2 = targets[2].pos[2]
        local ch1 = targets[2].chars[1]
        local ch2 = targets[2].chars[2]
        return ((l1 == l2) and (c1 == (c2 + ch1:len() + ch2:len())))
      else
        return nil
      end
    end
    funny_edge_case_3f = (backward_3f and _78_())
    local force_noautojump_3f = (funny_edge_case_3f or op_mode_3f or multi_select_3f or (multi_window_3f and not targets["shared-window?"]) or user_given_action)
    return prepare_targets(targets, {["force-noautojump?"] = force_noautojump_3f, ["force-labels?"] = multi_select_3f})
  end
  local function update_repeat_state(state_2a)
    if not (repeat_3f or user_given_targets_3f) then
      state["repeat"] = state_2a
      return nil
    else
      return nil
    end
  end
  local function set_dot_repeat(in1, in2, target_idx)
    if (dot_repeatable_op_3f and not (dot_repeat_3f or (type(user_given_targets) == "table"))) then
      state.dot_repeat = {in1 = (not user_given_targets and in1), in2 = (not user_given_targets and in2), callback = user_given_targets, target_idx = target_idx, offset = offset, match_same_char_seq_at_end = match_same_char_seq_at_end_3f, backward = backward_3f, inclusive_op = inclusive_op_3f}
      return set_dot_repeat_2a()
    else
      return nil
    end
  end
  local jump_to_21
  do
    local first_jump_3f = true
    local function _82_(target)
      local jump = require("leap.jump")
      jump["jump-to!"](target.pos, {winid = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["backward?"] = backward_3f, ["inclusive-op?"] = inclusive_op_3f})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _82_
  end
  local function post_pattern_input_loop(targets, first_invoc_3f)
    local _7cgroups_7c
    if not targets["label-set"] then
      _7cgroups_7c = 0
    else
      _7cgroups_7c = ceil((#targets / #targets["label-set"]))
    end
    local function display()
      local no_labels_3f = (empty_label_lists_3f or _state["partial-pattern?"])
      set_beacons(targets, {["group-offset"] = _state["group-offset"], ["no-labels?"] = no_labels_3f, ["user-given-targets?"] = user_given_targets_3f, phase = _state.phase})
      hl:cleanup(hl_affected_windows)
      if not count then
        hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
      else
      end
      do
        local start, _end = get_highlighted_idx_range(targets, no_labels_3f)
        light_up_beacons(targets, start, _end)
      end
      hl["highlight-cursor"](hl)
      return vim.cmd("redraw")
    end
    local first_iter_3f = true
    local function loop(first_invoc_3f0)
      display()
      if first_iter_3f then
        exec_user_autocmds("LeapSelectPre")
        first_iter_3f = false
      else
      end
      local _86_ = get_input()
      if (nil ~= _86_) then
        local input = _86_
        local switch_group_3f = ((input == spec_keys.next_group) or ((input == spec_keys.prev_group) and not first_invoc_3f0))
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
    return loop((first_invoc_3f ~= false))
  end
  local multi_select_loop
  do
    local selection = {}
    local first_invoc_3f = true
    local function loop(targets)
      local _90_, _91_ = post_pattern_input_loop(targets, first_invoc_3f)
      if (_90_ == spec_keys.multi_accept) then
        if not empty_3f(selection) then
          return selection
        else
          return loop(targets)
        end
      elseif (_90_ == spec_keys.multi_revert) then
        local removed = table.remove(selection)
        if removed then
          removed.selected = nil
        else
        end
        return loop(targets)
      elseif (nil ~= _90_) then
        local _in = _90_
        first_invoc_3f = false
        do
          local _94_ = get_target_with_active_label(targets, _in)
          if ((_G.type(_94_) == "table") and true and (nil ~= _94_[2])) then
            local _ = _94_[1]
            local target = _94_[2]
            if not contains_3f(selection, target) then
              table.insert(selection, target)
              target.selected = true
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
  local function traversal_loop(targets, start_idx, _98_)
    local _arg_99_ = _98_
    local no_labels_3f = _arg_99_["no-labels?"]
    local function on_first_invoc()
      if no_labels_3f then
        for _, t in ipairs(targets) do
          t.label = nil
        end
        return nil
      elseif not empty_3f(opts.safe_labels) then
        local last_labeled = inc(#opts.safe_labels)
        for i = inc(last_labeled), #targets do
          local _100_ = targets[i]
          _100_["label"] = nil
          _100_["beacon"] = nil
        end
        return nil
      else
        return nil
      end
    end
    local function display()
      set_beacons(targets, {["group-offset"] = _state["group-offset"], ["no-labels?"] = no_labels_3f, ["user-given-targets?"] = user_given_targets_3f, phase = _state.phase})
      hl:cleanup(hl_affected_windows)
      if not count then
        hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
      else
      end
      do
        local start, _end = get_highlighted_idx_range(targets, no_labels_3f)
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
      local _105_ = get_input()
      if (nil ~= _105_) then
        local _in = _105_
        if ((idx == 1) and contains_3f(spec_keys.prev_target, _in)) then
          return vim.fn.feedkeys(_in, "i")
        else
          local _106_ = get_new_idx(idx, _in)
          if (nil ~= _106_) then
            local new_idx = _106_
            jump_to_21(targets[new_idx])
            return loop(new_idx, false)
          else
            local _ = _106_
            local _107_ = get_target_with_active_label(targets, _in)
            if ((_G.type(_107_) == "table") and true and (nil ~= _107_[2])) then
              local _0 = _107_[1]
              local target = _107_[2]
              return jump_to_21(target)
            else
              local _0 = _107_
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
  if repeat_3f then
    in1, _3fin2 = get_repeat_input()
  elseif dot_repeat_3f then
    if state.dot_repeat.callback then
      in1, _3fin2 = true, true
    else
      in1, _3fin2 = state.dot_repeat.in1, state.dot_repeat.in2
    end
  elseif user_given_targets_3f then
    in1, _3fin2 = true, true
  elseif (_state.phase == 1) then
    in1, _3fin2 = get_first_pattern_input()
  else
    in1, _3fin2 = get_full_pattern_input()
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
  if (dot_repeat_3f and state.dot_repeat.callback) then
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
  if dot_repeat_3f then
    local _121_ = targets[state.dot_repeat.target_idx]
    if (nil ~= _121_) then
      local target = _121_
      do_action(target)
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    else
      local _ = _121_
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
  if (_3fin2 or _state["partial-pattern?"]) then
    if (empty_label_lists_3f or _state["partial-pattern?"]) then
      targets["autojump?"] = true
    else
      prepare_targets_2a(targets)
    end
  else
    if (#targets > max_phase_one_targets) then
      _state.phase = nil
    else
    end
    populate_sublists(targets, multi_window_3f)
    for _, sublist in pairs(targets.sublists) do
      prepare_targets_2a(sublist)
    end
    set_beacons(targets, {phase = _state.phase})
    if (_state.phase == 1) then
      resolve_conflicts(targets)
    else
    end
  end
  local _3fin20 = (_3fin2 or (not _state["partial-pattern?"] and get_second_pattern_input(targets)))
  if not (_state["partial-pattern?"] or _3fin20) then
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
  if contains_3f(spec_keys.next_target, _3fin20) then
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
    update_repeat_state({in1 = in1, offset = offset, backward = backward_3f, inclusive_op = inclusive_op_3f, match_same_char_seq_at_end = match_same_char_seq_at_end_3f})
    set_dot_repeat(in1, nil, n)
    do_action(target)
    if (can_traverse_3f and (#targets > 1)) then
      traversal_loop(targets, 1, {["no-labels?"] = true})
    else
    end
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  exec_user_autocmds("LeapPatternPost")
  update_repeat_state({in1 = in1, in2 = _3fin20, offset = offset, backward = backward_3f, inclusive_op = inclusive_op_3f, match_same_char_seq_at_end = match_same_char_seq_at_end_3f})
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
  if multi_select_3f then
    do
      local _143_ = multi_select_loop(targets_2a)
      if (nil ~= _143_) then
        local targets_2a_2a = _143_
        do
          hl:cleanup(hl_affected_windows)
          if not count then
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
      else
      end
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
  elseif (((repeat_3f or _state["partial-pattern?"]) and (op_mode_3f or not directional_3f)) or (#targets_2a == 1)) then
    set_dot_repeat(in1, _3fin20, 1)
    do_action(targets_2a[1])
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  if targets_2a["autojump?"] then
    _state["curr-idx"] = 1
    do_action(targets_2a[1])
    if (#targets_2a == 1) then
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    else
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
    if (can_traverse_3f and (#targets_2a > 1)) then
      local new_idx = inc(_state["curr-idx"])
      do_action(targets_2a[new_idx])
      traversal_loop(targets_2a, new_idx, {["no-labels?"] = (empty_label_lists_3f or _state["partial-pattern?"] or not targets_2a["autojump?"])})
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    else
      if not targets_2a["autojump?"] then
        set_dot_repeat(in1, _3fin20, 1)
        do_action(targets_2a[1])
        hl:cleanup(hl_affected_windows)
        exec_user_autocmds("LeapLeave")
        return
      else
        vim.fn.feedkeys(in_final, "i")
        hl:cleanup(hl_affected_windows)
        exec_user_autocmds("LeapLeave")
        return
      end
    end
  else
  end
  local _local_159_ = get_target_with_active_label(targets_2a, in_final)
  local idx = _local_159_[1]
  local _ = _local_159_[2]
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
do
  local _161_ = opts.default.equivalence_classes
  if (nil ~= _161_) then
    opts.default.eq_class_of = eq_classes__3emembership_lookup(_161_)
  else
    opts.default.eq_class_of = _161_
  end
end
api.nvim_create_augroup("LeapDefault", {})
hl["init-highlight"](hl)
local function _163_()
  return hl["init-highlight"](hl)
end
api.nvim_create_autocmd("ColorScheme", {callback = _163_, group = "LeapDefault"})
local function set_editor_opts(t)
  state.saved_editor_opts = {}
  local wins = (state.args.target_windows or {state.source_window})
  for opt, val in pairs(t) do
    local _let_164_ = vim.split(opt, ".", {plain = true})
    local scope = _let_164_[1]
    local name = _let_164_[2]
    if (scope == "w") then
      for _, w in ipairs(wins) do
        state.saved_editor_opts[{"w", w, name}] = api.nvim_win_get_option(w, name)
        api.nvim_win_set_option(w, name, val)
      end
    elseif (scope == "b") then
      for _, w in ipairs(wins) do
        local b = api.nvim_win_get_buf(w)
        do end (state.saved_editor_opts)[{"b", b, name}] = api.nvim_buf_get_option(b, name)
        api.nvim_buf_set_option(b, name, val)
      end
    else
      local _ = scope
      state.saved_editor_opts[name] = api.nvim_get_option(name)
      api.nvim_set_option(name, val)
    end
  end
  return nil
end
local function restore_editor_opts()
  for key, val in pairs(state.saved_editor_opts) do
    if ((_G.type(key) == "table") and (key[1] == "w") and (nil ~= key[2]) and (nil ~= key[3])) then
      local w = key[2]
      local name = key[3]
      api.nvim_win_set_option(w, name, val)
    elseif ((_G.type(key) == "table") and (key[1] == "b") and (nil ~= key[2]) and (nil ~= key[3])) then
      local b = key[2]
      local name = key[3]
      api.nvim_buf_set_option(b, name, val)
    elseif (nil ~= key) then
      local name = key
      api.nvim_set_option(name, val)
    else
    end
  end
  return nil
end
local temporary_editor_opts = {["w.conceallevel"] = 0, ["g.scrolloff"] = 0, ["w.scrolloff"] = 0, ["g.sidescrolloff"] = 0, ["w.sidescrolloff"] = 0, ["b.modeline"] = false}
local function set_concealed_label()
  if ((vim.fn.has("nvim-0.9.1") == 1) and api.nvim_get_hl(0, {name = "LeapLabelPrimary"}).bg and api.nvim_get_hl(0, {name = "LeapLabelSecondary"}).bg) then
    opts.concealed_label = " "
  else
    opts.concealed_label = "\194\183"
  end
  return nil
end
local function _168_()
  set_editor_opts(temporary_editor_opts)
  return set_concealed_label()
end
api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _168_, group = "LeapDefault"})
local function _169_()
  return restore_editor_opts()
end
api.nvim_create_autocmd("User", {pattern = "LeapLeave", callback = _169_, group = "LeapDefault"})
return {state = state, leap = leap}
