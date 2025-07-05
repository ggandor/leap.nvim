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
local get_eq_class_of = _local_2_["get-eq-class-of"]
local __3erepresentative_char = _local_2_["->representative-char"]
local get_input = _local_2_["get-input"]
local get_input_by_keymap = _local_2_["get-input-by-keymap"]
local api = vim.api
local empty_3f = vim.tbl_isempty
local map = vim.tbl_map
local abs = math["abs"]
local ceil = math["ceil"]
local floor = math["floor"]
local min = math["min"]
local function handle_interrupted_change_op_21()
  local _3_
  if (vim.fn.col(".") > 1) then
    _3_ = "<RIGHT>"
  else
    _3_ = ""
  end
  return api.nvim_feedkeys(vim.keycode(("<C-\\><C-N>" .. _3_)), "n", true)
end
local function set_dot_repeat_2a()
  local op = vim.v.operator
  local force = string.sub(vim.fn.mode(true), 3)
  local cmd = vim.keycode("<cmd>lua require'leap'.leap { dot_repeat = true }<cr>")
  local change
  if (op == "c") then
    change = vim.keycode("<c-r>.<esc>")
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
local function populate_sublists(targets)
  local function _7_(self, ch)
    return rawget(self, __3erepresentative_char(ch))
  end
  local function _8_(self, ch, sublist)
    return rawset(self, __3erepresentative_char(ch), sublist)
  end
  targets.sublists = setmetatable({}, {__index = _7_, __newindex = _8_})
  for _, _9_ in ipairs(targets) do
    local _each_10_ = _9_["chars"]
    local _0 = _each_10_[1]
    local ch2 = _each_10_[2]
    local target = _9_
    if not targets.sublists[ch2] then
      targets.sublists[ch2] = {}
    else
    end
    table.insert(targets.sublists[ch2], target)
  end
  return nil
end
local prepare_labeled_targets
do
  local function all_in_the_same_window_3f(targets)
    local same_win_3f = true
    local winid = targets[1].wininfo.winid
    for _, target in ipairs(targets) do
      if (same_win_3f == false) then break end
      if (target.wininfo.winid ~= winid) then
        same_win_3f = false
      else
      end
    end
    return same_win_3f
  end
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
      local autojump_3f = targets["autojump?"]
      local label_set = targets["label-set"]
      local _7clabel_set_7c = #label_set
      for i_2a, target in ipairs(targets) do
        local i
        if autojump_3f then
          i = dec(i_2a)
        else
          i = i_2a
        end
        if (i >= 1) then
          local _17_ = (i % _7clabel_set_7c)
          if (_17_ == 0) then
            target.label = label_set[_7clabel_set_7c]
            target.group = floor((i / _7clabel_set_7c))
          elseif (nil ~= _17_) then
            local n = _17_
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
  local function _21_(targets, force_noautojump_3f, multi_window_search_3f)
    if not (force_noautojump_3f or (multi_window_search_3f and not all_in_the_same_window_3f(targets)) or first_target_covers_label_of_second_3f(targets)) then
      set_autojump(targets)
    else
    end
    attach_label_set(targets)
    return set_labels(targets)
  end
  prepare_labeled_targets = _21_
end
local state = {["repeat"] = {in1 = nil, in2 = nil, pattern = nil, backward = nil, inclusive_op = nil, offset = nil, inputlen = nil}, dot_repeat = {callback = nil, pattern = nil, in1 = nil, in2 = nil, target_idx = nil, backward = nil, inclusive_op = nil, offset = nil, inputlen = nil}, args = nil}
local function leap(kwargs)
  local invoked_repeat_3f = kwargs["repeat"]
  local invoked_dot_repeat_3f = kwargs["dot_repeat"]
  local target_windows = kwargs["target_windows"]
  local user_given_opts = kwargs["opts"]
  local user_given_targets = kwargs["targets"]
  local user_given_action = kwargs["action"]
  local action_can_traverse_3f = kwargs["traversal"]
  local function _23_()
    if invoked_dot_repeat_3f then
      return state.dot_repeat
    else
      return kwargs
    end
  end
  local _local_24_ = _23_()
  local backward_3f = _local_24_["backward"]
  local function _25_()
    if invoked_dot_repeat_3f then
      return state.dot_repeat
    elseif invoked_repeat_3f then
      return state["repeat"]
    else
      return kwargs
    end
  end
  local _local_26_ = _25_()
  local inclusive_op_3f = _local_26_["inclusive_op"]
  local offset = _local_26_["offset"]
  local inputlen = _local_26_["inputlen"]
  local user_given_pattern = _local_26_["pattern"]
  state.args = kwargs
  opts.current_call = (user_given_opts or {})
  do
    local tmp_3_ = opts.current_call.equivalence_classes
    if (nil ~= tmp_3_) then
      local tmp_3_0 = eq_classes__3emembership_lookup(tmp_3_)
      if (nil ~= tmp_3_0) then
        opts.current_call.eq_class_of = setmetatable(tmp_3_0, {merge = false})
      else
        opts.current_call.eq_class_of = nil
      end
    else
      opts.current_call.eq_class_of = nil
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
  local hl_affected_windows = (_3ftarget_windows or {curr_winid})
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
  local keyboard_input_3f = not (invoked_repeat_3f or invoked_dot_repeat_3f or user_given_pattern or user_given_targets)
  local inputlen0
  if inputlen then
    inputlen0 = inputlen
  elseif keyboard_input_3f then
    inputlen0 = 2
  else
    inputlen0 = 0
  end
  local prompt = {str = ">"}
  local keys
  local function _35_(_, k)
    local _36_ = opts.keys[k]
    if (nil ~= _36_) then
      local v = _36_
      local function _37_()
        if (type(v) == "string") then
          return {v}
        else
          return v
        end
      end
      return map(vim.keycode, _37_())
    else
      return nil
    end
  end
  keys = setmetatable({}, {__index = _35_})
  local contains_3f = vim.list_contains
  local contains_safe_3f
  local function _39_(t, v)
    return (t[1] == v)
  end
  contains_safe_3f = _39_
  local st
  local _40_
  if (keyboard_input_3f and (inputlen0 == 2) and not no_labels_to_use_3f) then
    _40_ = 1
  else
    _40_ = nil
  end
  st = {phase = _40_, ["curr-idx"] = 0, ["group-offset"] = 0, errmsg = nil, ["repeating-partial-input?"] = false}
  local function exec_user_autocmds(pattern)
    return api.nvim_exec_autocmds("User", {pattern = pattern, modeline = false})
  end
  local function exit_2a()
    hl:cleanup(hl_affected_windows)
    return exec_user_autocmds("LeapLeave")
  end
  local function exit_early_2a()
    if change_op_3f then
      handle_interrupted_change_op_21()
    else
    end
    if st.errmsg then
      echo(st.errmsg)
    else
    end
    return exit_2a()
  end
  local function with_highlight_chores(f)
    hl:cleanup(hl_affected_windows)
    if not count then
      hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
    else
    end
    if f then
      f()
    else
    end
    return vim.cmd("redraw")
  end
  local function can_traverse_3f(targets)
    return (action_can_traverse_3f or (directional_3f and not (count or op_mode_3f or user_given_action) and (#targets >= 2)))
  end
  local function get_number_of_highlighted_traversal_targets()
    local _46_ = opts.max_highlighted_traversal_targets
    if (nil ~= _46_) then
      local group_size = _46_
      local consumed = (dec(st["curr-idx"]) % group_size)
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
      local start = inc(st["curr-idx"])
      local _end
      if use_no_labels_3f then
        local _49_ = get_number_of_highlighted_traversal_targets()
        if (nil ~= _49_) then
          local n = _49_
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
        local relative_group = (target.group - st["group-offset"])
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
      if (inputlen0 == 1) then
        return state["repeat"].in1
      elseif (inputlen0 == 2) then
        if not state["repeat"].in2 then
          st["repeating-partial-input?"] = true
        else
        end
        return state["repeat"].in1, state["repeat"].in2
      else
        return nil
      end
    else
      st.errmsg = "no previous search"
      return nil
    end
  end
  local function get_first_pattern_input()
    with_highlight_chores(nil)
    local _59_ = get_input_by_keymap(prompt)
    if (nil ~= _59_) then
      local in1 = _59_
      if contains_safe_3f(keys.next_target, in1) then
        st.phase = nil
        return get_repeat_input()
      else
        return in1
      end
    else
      return nil
    end
  end
  local function get_second_pattern_input(targets)
    if not count then
      local function _62_()
        return light_up_beacons(targets)
      end
      with_highlight_chores(_62_)
    else
    end
    return get_input_by_keymap(prompt)
  end
  local function get_full_pattern_input()
    local _64_, _65_ = get_first_pattern_input()
    if ((nil ~= _64_) and (nil ~= _65_)) then
      local in1 = _64_
      local in2 = _65_
      return in1, in2
    elseif ((nil ~= _64_) and (_65_ == nil)) then
      local in1 = _64_
      if (inputlen0 == 1) then
        return in1
      else
        local _66_ = get_input_by_keymap(prompt)
        if (nil ~= _66_) then
          local in2 = _66_
          return in1, in2
        else
          return nil
        end
      end
    else
      return nil
    end
  end
  local function char_list_to_branching_regexp(chars)
    local branches
    local function _70_(_241)
      if (_241 == "\n") then
        return "\\n"
      elseif (_241 == "\\") then
        return "\\\\"
      elseif (nil ~= _241) then
        local ch = _241
        return ch
      else
        return nil
      end
    end
    branches = vim.tbl_map(_70_, chars)
    local pattern = table.concat(branches, "\\|")
    return ("\\(" .. pattern .. "\\)")
  end
  local function expand_to_equivalence_class(char)
    local tmp_3_ = get_eq_class_of(char)
    if (nil ~= tmp_3_) then
      return char_list_to_branching_regexp(tmp_3_)
    else
      return nil
    end
  end
  local function prepare_pattern(in1, _3fin2)
    local pat1 = (expand_to_equivalence_class(in1) or in1:gsub("\\", "\\\\"))
    local pat2 = ((_3fin2 and expand_to_equivalence_class(_3fin2)) or _3fin2 or (((inputlen0 == 1) and "") or "\\_."))
    local potential_nl_nl_3f = (pat1:match("\\n") and (pat2:match("\\n") or not _3fin2))
    local pattern
    local _73_
    if potential_nl_nl_3f then
      _73_ = "\\|\\n"
    else
      _73_ = ""
    end
    pattern = (pat1 .. pat2 .. _73_)
    local _75_
    if opts.case_sensitive then
      _75_ = "\\C"
    else
      _75_ = "\\c"
    end
    return (_75_ .. "\\V" .. pattern)
  end
  local function get_targets(pattern, in1, _3fin2)
    local errmsg
    if in1 then
      errmsg = ("not found: " .. in1 .. (_3fin2 or ""))
    else
      errmsg = "no targets"
    end
    local search = require("leap.search")
    local kwargs0 = {["backward?"] = backward_3f, offset = offset, ["op-mode?"] = op_mode_3f, inputlen = inputlen0, ["target-windows"] = _3ftarget_windows}
    local targets = search["get-targets"](pattern, kwargs0)
    local or_78_ = targets
    if not or_78_ then
      st.errmsg = errmsg
      or_78_ = nil
    end
    return or_78_
  end
  local function get_user_given_targets(targets)
    local default_errmsg = "no targets"
    local targets_2a, errmsg = nil, nil
    if (type(targets) == "function") then
      targets_2a, errmsg = targets()
    else
      targets_2a, errmsg = targets
    end
    if not targets_2a then
      st.errmsg = (errmsg or default_errmsg)
      return nil
    elseif (#targets_2a == 0) then
      st.errmsg = default_errmsg
      return nil
    else
      if not targets_2a[1].wininfo then
        local wininfo = vim.fn.getwininfo(curr_winid)[1]
        for _, t in ipairs(targets_2a) do
          t.wininfo = wininfo
        end
      else
      end
      return targets_2a
    end
  end
  local function prepare_labeled_targets_2a(targets)
    local force_noautojump_3f = (not action_can_traverse_3f and (user_given_action or (op_mode_3f and (#targets > 1))))
    return prepare_labeled_targets(targets, force_noautojump_3f, multi_window_search_3f)
  end
  local from_kwargs = {offset = offset, inputlen = inputlen0, backward = backward_3f, inclusive_op = inclusive_op_3f}
  local function update_repeat_state(in1, in2)
    if (keyboard_input_3f or user_given_pattern) then
      state["repeat"] = vim.tbl_extend("error", from_kwargs, {pattern = user_given_pattern, in1 = (keyboard_input_3f and in1), in2 = (keyboard_input_3f and in2)})
      return nil
    else
      return nil
    end
  end
  local function set_dot_repeat(in1, in2, target_idx)
    local dot_repeatable_op_3f = (op_mode_3f and (vim.o.cpo:match("y") or (vim.v.operator ~= "y")))
    local dot_repeatable_call_3f = (dot_repeatable_op_3f and not invoked_dot_repeat_3f and (type(user_given_targets) ~= "table"))
    local function update_dot_repeat_state()
      state.dot_repeat = vim.tbl_extend("error", from_kwargs, {target_idx = target_idx, callback = user_given_targets, pattern = user_given_pattern, in1 = (keyboard_input_3f and in1), in2 = (keyboard_input_3f and in2)})
      if not directional_3f then
        state.dot_repeat.backward = (target_idx < 0)
        state.dot_repeat.target_idx = abs(target_idx)
        return nil
      else
        return nil
      end
    end
    if dot_repeatable_call_3f then
      update_dot_repeat_state()
      return set_dot_repeat_2a()
    else
      return nil
    end
  end
  local function normalize_indexes_for_dot_repeat(targets)
    local bwd = {}
    local fwd = {}
    for _, t in ipairs(targets) do
      if (t.idx < 0) then
        table.insert(bwd, t.idx)
      else
        table.insert(fwd, t.idx)
      end
    end
    local function _86_(_241, _242)
      return (_241 > _242)
    end
    table.sort(bwd, _86_)
    table.sort(fwd)
    local new_idx = {}
    do
      local tbl_16_ = new_idx
      for i, idx in ipairs(bwd) do
        local k_17_, v_18_ = idx, ( - i)
        if ((k_17_ ~= nil) and (v_18_ ~= nil)) then
          tbl_16_[k_17_] = v_18_
        else
        end
      end
    end
    do
      local tbl_16_ = new_idx
      for i, idx in ipairs(fwd) do
        local k_17_, v_18_ = idx, i
        if ((k_17_ ~= nil) and (v_18_ ~= nil)) then
          tbl_16_[k_17_] = v_18_
        else
        end
      end
    end
    for _, t in ipairs(targets) do
      t.idx = new_idx[t.idx]
    end
    return nil
  end
  local jump_to_21
  do
    local first_jump_3f = true
    local function _89_(target)
      local jump = require("leap.jump")
      jump["jump-to!"](target.pos, {winid = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["backward?"] = backward_3f, ["inclusive-op?"] = inclusive_op_3f})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _89_
  end
  local do_action = (user_given_action or jump_to_21)
  local function post_pattern_input_loop(targets)
    local _7cgroups_7c
    if not targets["label-set"] then
      _7cgroups_7c = 0
    else
      _7cgroups_7c = ceil((#targets / #targets["label-set"]))
    end
    local function display()
      local use_no_labels_3f = (no_labels_to_use_3f or st["repeating-partial-input?"])
      set_beacons(targets, {["group-offset"] = st["group-offset"], phase = st.phase, ["use-no-labels?"] = use_no_labels_3f})
      local start, _end = get_highlighted_idx_range(targets, use_no_labels_3f)
      local function _91_()
        return light_up_beacons(targets, start, _end)
      end
      return with_highlight_chores(_91_)
    end
    local function loop(first_invoc_3f)
      display()
      if first_invoc_3f then
        exec_user_autocmds("LeapSelectPre")
      else
      end
      local _93_ = get_input()
      if (nil ~= _93_) then
        local input = _93_
        local switch_group_3f = (contains_3f(keys.next_group, input) or (contains_3f(keys.prev_group, input) and not first_invoc_3f))
        if (switch_group_3f and (_7cgroups_7c > 1)) then
          local shift
          if contains_3f(keys.next_group, input) then
            shift = 1
          else
            shift = -1
          end
          local max_offset = dec(_7cgroups_7c)
          st["group-offset"] = clamp((st["group-offset"] + shift), 0, max_offset)
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
  local function traversal_get_new_idx(idx, _in, targets)
    if contains_3f(keys.next_target, _in) then
      return min(inc(idx), #targets)
    elseif contains_3f(keys.prev_target, _in) then
      if (idx <= 1) then
        return #targets
      else
        return dec(idx)
      end
    else
      return nil
    end
  end
  local function traversal_loop(targets, start_idx, _99_)
    local use_no_labels_3f = _99_["use-no-labels?"]
    local function on_first_invoc()
      if use_no_labels_3f then
        for _, t in ipairs(targets) do
          t.label = nil
        end
        return nil
      elseif not empty_3f(opts.safe_labels) then
        local last_labeled = inc(#opts.safe_labels)
        for i = inc(last_labeled), #targets do
          local tmp_9_ = targets[i]
          tmp_9_["label"] = nil
          tmp_9_["beacon"] = nil
        end
        return nil
      else
        return nil
      end
    end
    local function display()
      set_beacons(targets, {["group-offset"] = st["group-offset"], phase = st.phase, ["use-no-labels?"] = use_no_labels_3f})
      local start, _end = get_highlighted_idx_range(targets, use_no_labels_3f)
      local function _101_()
        return light_up_beacons(targets, start, _end)
      end
      return with_highlight_chores(_101_)
    end
    local function loop(idx, first_invoc_3f)
      if first_invoc_3f then
        on_first_invoc()
      else
      end
      st["curr-idx"] = idx
      display()
      local _103_ = get_input()
      if (nil ~= _103_) then
        local _in = _103_
        local _104_ = traversal_get_new_idx(idx, _in, targets)
        if (nil ~= _104_) then
          local new_idx = _104_
          do_action(targets[new_idx])
          return loop(new_idx, false)
        else
          local _ = _104_
          local _105_ = get_target_with_active_label(targets, _in)
          if (nil ~= _105_) then
            local target = _105_
            return do_action(target)
          else
            local _0 = _105_
            return vim.fn.feedkeys(_in, "i")
          end
        end
      else
        return nil
      end
    end
    return loop(start_idx, true)
  end
  exec_user_autocmds("LeapEnter")
  local need_in1_3f = (keyboard_input_3f or (invoked_repeat_3f and not state["repeat"].pattern) or (invoked_dot_repeat_3f and not state.dot_repeat.callback))
  local in1, _3fin2 = nil, nil
  if keyboard_input_3f then
    if st.phase then
      in1, _3fin2 = get_first_pattern_input()
    else
      in1, _3fin2 = get_full_pattern_input()
    end
  elseif (invoked_repeat_3f and not state["repeat"].pattern) then
    in1, _3fin2 = get_repeat_input()
  elseif (invoked_dot_repeat_3f and not state.dot_repeat.callback) then
    in1, _3fin2 = state.dot_repeat.in1, state.dot_repeat.in2
  else
    in1, _3fin2 = nil
  end
  if (need_in1_3f and not in1) then
    exit_early_2a()
    return
  else
  end
  local targets
  if (user_given_targets or (invoked_dot_repeat_3f and state.dot_repeat.callback)) then
    targets = get_user_given_targets((user_given_targets or state.dot_repeat.callback))
  else
    targets = get_targets((user_given_pattern or (invoked_repeat_3f and state["repeat"].pattern) or (invoked_dot_repeat_3f and state.dot_repeat.pattern) or prepare_pattern(in1, _3fin2)), in1, _3fin2)
  end
  if not targets then
    exit_early_2a()
    return
  else
  end
  if invoked_dot_repeat_3f then
    local _114_ = targets[state.dot_repeat.target_idx]
    if (nil ~= _114_) then
      local target = _114_
      do_action(target)
      exit_2a()
      return
    else
      local _ = _114_
      exit_early_2a()
      return
    end
  else
  end
  local need_in2_3f = ((inputlen0 == 2) and not (_3fin2 or st["repeating-partial-input?"]))
  do
    local preview_3f = need_in2_3f
    local use_no_labels_3f = (no_labels_to_use_3f or st["repeating-partial-input?"])
    if preview_3f then
      populate_sublists(targets)
      for _, sublist in pairs(targets.sublists) do
        prepare_labeled_targets_2a(sublist)
        set_beacons(targets, {phase = st.phase})
      end
      if (st.phase == 1) then
        resolve_conflicts(targets)
      else
      end
    else
      if use_no_labels_3f then
        targets["autojump?"] = true
      else
        prepare_labeled_targets_2a(targets)
      end
    end
  end
  local _3fin20 = (_3fin2 or (need_in2_3f and get_second_pattern_input(targets)))
  if (need_in2_3f and not _3fin20) then
    exit_early_2a()
    return
  else
  end
  if st.phase then
    st.phase = 2
  else
  end
  local partial_input_3f = (st["repeating-partial-input?"] or contains_safe_3f(keys.next_target, _3fin20))
  local function _122_()
    if not partial_input_3f then
      return _3fin20
    else
      return nil
    end
  end
  update_repeat_state(in1, _122_())
  if partial_input_3f then
    local n = (count or 1)
    local target = targets[n]
    if not target then
      exit_early_2a()
      return
    else
    end
    local function _124_()
      if target.idx then
        return target.idx
      else
        return n
      end
    end
    set_dot_repeat(in1, nil, _124_())
    do_action(target)
    if can_traverse_3f(targets) then
      traversal_loop(targets, 1, {["use-no-labels?"] = true})
    else
    end
    exit_2a()
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
    st.errmsg = ("not found: " .. in1 .. _3fin20)
    exit_early_2a()
    return
  else
  end
  if ((targets_2a ~= targets) and targets_2a[1].idx) then
    normalize_indexes_for_dot_repeat(targets_2a)
  else
  end
  local function exit_with_action_on_2a(idx)
    local target = targets_2a[idx]
    local function _130_()
      if target.idx then
        return target.idx
      else
        return idx
      end
    end
    set_dot_repeat(in1, _3fin20, _130_())
    do_action(target)
    return exit_2a()
  end
  if count then
    if (count > #targets_2a) then
      exit_early_2a()
      return
    else
      exit_with_action_on_2a(count)
      return
    end
  elseif (invoked_repeat_3f and not can_traverse_3f(targets_2a)) then
    exit_with_action_on_2a(1)
    return
  else
  end
  if targets_2a["autojump?"] then
    if (#targets_2a == 1) then
      exit_with_action_on_2a(1)
      return
    else
      do_action(targets_2a[1])
      st["curr-idx"] = 1
    end
  else
  end
  local in_final = post_pattern_input_loop(targets_2a)
  if not in_final then
    exit_early_2a()
    return
  elseif (can_traverse_3f(targets_2a) and (contains_3f(keys.next_target, in_final) or contains_3f(keys.prev_target, in_final))) then
    local use_no_labels_3f = (no_labels_to_use_3f or st["repeating-partial-input?"] or not targets_2a["autojump?"])
    local new_idx = traversal_get_new_idx(st["curr-idx"], in_final, targets_2a)
    do_action(targets_2a[new_idx])
    traversal_loop(targets_2a, new_idx, {["use-no-labels?"] = use_no_labels_3f})
    exit_2a()
    return
  elseif (contains_3f(keys.next_target, in_final) and (st["curr-idx"] == 0)) then
    exit_with_action_on_2a(1)
    return
  else
    local _135_, _136_ = get_target_with_active_label(targets_2a, in_final)
    if ((nil ~= _135_) and (nil ~= _136_)) then
      local target = _135_
      local idx = _136_
      exit_with_action_on_2a(idx)
      return
    else
      local _ = _135_
      vim.fn.feedkeys(in_final, "i")
      exit_2a()
      return
    end
  end
  return nil
end
local function init_highlight()
  hl:init()
  local function _139_(_)
    return hl:init()
  end
  return api.nvim_create_autocmd("ColorScheme", {group = "LeapDefault", callback = _139_})
end
local function manage_vim_opts()
  local get_opt = api.nvim_get_option_value
  local set_opt = api.nvim_set_option_value
  local saved_vim_opts = {}
  local function set_vim_opts(t)
    local wins = (state.args.target_windows or {api.nvim_get_current_win()})
    saved_vim_opts = {}
    for opt, val in pairs(t) do
      local _let_140_ = vim.split(opt, ".", {plain = true})
      local scope = _let_140_[1]
      local name = _let_140_[2]
      if (scope == "wo") then
        for _, win in ipairs(wins) do
          local saved_val = get_opt(name, {scope = "local", win = win})
          saved_vim_opts[{"wo", win, name}] = saved_val
          set_opt(name, val, {scope = "local", win = win})
        end
      elseif (scope == "bo") then
        for _, win in ipairs(wins) do
          local buf = api.nvim_win_get_buf(win)
          local saved_val = get_opt(name, {buf = buf})
          saved_vim_opts[{"bo", buf, name}] = saved_val
          set_opt(name, val, {buf = buf})
        end
      elseif (scope == "go") then
        local saved_val = get_opt(name, {scope = "global"})
        saved_vim_opts[name] = saved_val
        set_opt(name, val, {scope = "global"})
      else
      end
    end
    return nil
  end
  local function restore_vim_opts()
    for key, val in pairs(saved_vim_opts) do
      if ((_G.type(key) == "table") and (key[1] == "wo") and (nil ~= key[2]) and (nil ~= key[3])) then
        local win = key[2]
        local name = key[3]
        if api.nvim_win_is_valid(win) then
          set_opt(name, val, {scope = "local", win = win})
        else
        end
      elseif ((_G.type(key) == "table") and (key[1] == "bo") and (nil ~= key[2]) and (nil ~= key[3])) then
        local buf = key[2]
        local name = key[3]
        if api.nvim_buf_is_valid(buf) then
          set_opt(name, val, {buf = buf})
        else
        end
      elseif (nil ~= key) then
        local name = key
        set_opt(name, val, {scope = "global"})
      else
      end
    end
    return nil
  end
  local function _145_(_)
    return set_vim_opts(opts.vim_opts)
  end
  api.nvim_create_autocmd("User", {pattern = "LeapEnter", group = "LeapDefault", callback = _145_})
  local function _146_(_)
    return restore_vim_opts()
  end
  return api.nvim_create_autocmd("User", {pattern = "LeapLeave", group = "LeapDefault", callback = _146_})
end
local function init()
  do
    local tmp_3_ = opts.default.equivalence_classes
    if (nil ~= tmp_3_) then
      opts.default.eq_class_of = eq_classes__3emembership_lookup(tmp_3_)
    else
      opts.default.eq_class_of = nil
    end
  end
  api.nvim_create_augroup("LeapDefault", {})
  init_highlight()
  return manage_vim_opts()
end
init()
return {state = state, leap = leap}
