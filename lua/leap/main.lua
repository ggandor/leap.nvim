-- Code generated from fnl/leap/main.fnl - do not edit directly.

local hl = require("leap.highlight")
local opts = require("leap.opts")
local _local_1_ = require("leap.beacons")
local set_beacons = _local_1_["set-beacons"]
local resolve_conflicts = _local_1_["resolve-conflicts"]
local light_up_beacons = _local_1_["light-up-beacons"]
local _local_2_ = require("leap.util")
local clamp = _local_2_["clamp"]
local echo = _local_2_["echo"]
local get_char = _local_2_["get-char"]
local get_char_keymapped = _local_2_["get-char-keymapped"]
local api = vim.api
local lower = vim.fn.tolower
local upper = vim.fn.toupper
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
local function to_membership_lookup(eqv_classes)
  local res = {}
  for _, cl in ipairs(eqv_classes) do
    local cl_2a
    if (type(cl) == "string") then
      cl_2a = vim.fn.split(cl, "\\zs")
    else
      cl_2a = cl
    end
    for _0, ch in ipairs(cl_2a) do
      res[ch] = cl_2a
    end
  end
  return res
end
local function get_equivalence_class(ch)
  if opts.case_sensitive then
    return opts.eqv_class_of[ch]
  else
    return (opts.eqv_class_of[lower(ch)] or opts.eqv_class_of[upper(ch)])
  end
end
local function get_representative_char(ch)
  local ch_2a
  local _9_
  do
    local t_8_ = get_equivalence_class(ch)
    if (nil ~= t_8_) then
      t_8_ = t_8_[1]
    else
    end
    _9_ = t_8_
  end
  ch_2a = (_9_ or ch)
  if opts.case_sensitive then
    return ch_2a
  else
    return lower(ch_2a)
  end
end
local function char_list_to_collection(chars)
  local prepare
  local function _12_(_241)
    if (_241 == "\7") then
      return "\\a"
    elseif (_241 == "\8") then
      return "\\b"
    elseif (_241 == "\f") then
      return "\\f"
    elseif (_241 == "\n") then
      return "\\n"
    elseif (_241 == "\r") then
      return "\\r"
    elseif (_241 == "\9") then
      return "\\t"
    elseif (_241 == "\v") then
      return "\\v"
    elseif (_241 == "\\") then
      return "\\\\"
    elseif (_241 == "]") then
      return "\\]"
    elseif (_241 == "^") then
      return "\\^"
    elseif (_241 == "-") then
      return "\\-"
    elseif (nil ~= _241) then
      local ch = _241
      return ch
    else
      return nil
    end
  end
  prepare = _12_
  return table.concat(vim.tbl_map(prepare, chars))
end
local function expand_to_eqv_coll(char)
  return char_list_to_collection((get_equivalence_class(char) or {char}))
end
local function prepare_pattern(in1, _3fin2, inputlen)
  local prefix
  local _14_
  if opts.case_sensitive then
    _14_ = "\\C"
  else
    _14_ = "\\c"
  end
  local _16_
  if string.match(vim.fn.mode(true), "V") then
    local cl = vim.fn.line(".")
    _16_ = ("\\(\\%<" .. cl .. "l\\|\\%>" .. cl .. "l\\)")
  else
    _16_ = ""
  end
  prefix = ("\\V" .. _14_ .. _16_)
  local in1_2a = expand_to_eqv_coll(in1)
  local pat1 = ("\\[" .. in1_2a .. "]")
  local _5epat1 = ("\\[^" .. in1_2a .. "]")
  local _3fpat2 = (_3fin2 and ("\\[" .. expand_to_eqv_coll(_3fin2) .. "]"))
  local pattern
  if _3fpat2 then
    if (pat1 ~= _3fpat2) then
      pattern = (pat1 .. _3fpat2)
    else
      local _19_
      if pat1:match("\\n") then
        _19_ = "\\|\\$"
      else
        _19_ = ""
      end
      pattern = ("\\(\\^\\|" .. _5epat1 .. "\\)" .. "\\zs" .. pat1 .. pat1 .. _19_)
    end
  else
    local _22_
    if (inputlen == 1) then
      _22_ = ""
    else
      _22_ = pat1
    end
    local _24_
    if (inputlen == 1) then
      _24_ = "\\ze"
    else
      _24_ = ""
    end
    pattern = ("\\(\\^\\|" .. _5epat1 .. "\\)" .. "\\zs" .. pat1 .. _22_ .. "\\|" .. pat1 .. _24_ .. "\\(" .. _5epat1 .. "\\|\\$\\)")
  end
  return (prefix .. "\\(" .. pattern .. "\\)")
end
local function populate_sublists(targets)
  local function _27_(self, ch)
    return rawget(self, get_representative_char(ch))
  end
  local function _28_(self, ch, sublist)
    return rawset(self, get_representative_char(ch), sublist)
  end
  targets.sublists = setmetatable({}, {__index = _27_, __newindex = _28_})
  for _, _29_ in ipairs(targets) do
    local _each_30_ = _29_["chars"]
    local ch1 = _each_30_[1]
    local ch2 = _each_30_[2]
    local target = _29_
    local key
    if ((ch1 == "") or (ch2 == "")) then
      key = "\n"
    else
      key = ch2
    end
    if not targets.sublists[key] then
      targets.sublists[key] = {}
    else
    end
    table.insert(targets.sublists[key], target)
  end
  return nil
end
local prepare_labeled_targets
do
  local function all_in_the_same_window_3f(targets)
    local same_win_3f = true
    local win = targets[1].wininfo.winid
    for _, target in ipairs(targets) do
      if (same_win_3f == false) then break end
      if (target.wininfo.winid ~= win) then
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
    if (opts.safe_labels ~= "") then
      local or_35_ = (opts.labels == "")
      if not or_35_ then
        or_35_ = (#opts.safe_labels >= (#targets - 1))
      end
      targets["autojump?"] = or_35_
      return nil
    else
      return nil
    end
  end
  local function attach_label_set(targets)
    if (opts.labels == "") then
      targets["label-set"] = opts.safe_labels
    elseif (opts.safe_labels == "") then
      targets["label-set"] = opts.labels
    elseif targets["autojump?"] then
      targets["label-set"] = opts.safe_labels
    else
      targets["label-set"] = opts.labels
    end
    return nil
  end
  local function set_labels(targets)
    local autojump_3f = targets["autojump?"]
    local label_set = targets["label-set"]
    local _7clabel_set_7c = #label_set
    local skipped = 0
    local _38_
    if autojump_3f then
      _38_ = 0
    else
      _38_ = 1
    end
    for i_2a = _38_, #targets do
      local target = targets[i_2a]
      if target then
        local i = (i_2a - skipped)
        if target["offscreen?"] then
          skipped = (skipped + 1)
        else
          local _40_ = (i % _7clabel_set_7c)
          if (_40_ == 0) then
            target.label = label_set:sub(_7clabel_set_7c, _7clabel_set_7c)
            target.group = floor((i / _7clabel_set_7c))
          elseif (nil ~= _40_) then
            local n = _40_
            target.label = label_set:sub(n, n)
            target.group = (floor((i / _7clabel_set_7c)) + 1)
          else
          end
        end
      else
      end
    end
    return nil
  end
  local function _44_(targets, force_noautojump_3f, multi_window_3f)
    if not (force_noautojump_3f or (multi_window_3f and not all_in_the_same_window_3f(targets)) or first_target_covers_label_of_second_3f(targets)) then
      set_autojump(targets)
    else
    end
    attach_label_set(targets)
    return set_labels(targets)
  end
  prepare_labeled_targets = _44_
end
local function normalize_directional_indexes(targets)
  local bwd = {}
  local fwd = {}
  for _, t in ipairs(targets) do
    if (t.idx < 0) then
      table.insert(bwd, t.idx)
    else
      table.insert(fwd, t.idx)
    end
  end
  local function _47_(_241, _242)
    return (_241 > _242)
  end
  table.sort(bwd, _47_)
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
local state = {["repeat"] = {in1 = nil, in2 = nil, pattern = nil, backward = nil, inclusive = nil, offset = nil, inputlen = nil, opts = nil}, dot_repeat = {targets = nil, pattern = nil, in1 = nil, in2 = nil, target_idx = nil, backward = nil, inclusive = nil, offset = nil, inputlen = nil, opts = nil}, args = nil}
local function leap(kwargs)
  if kwargs.target_windows then
    kwargs.windows = kwargs.target_windows
  else
  end
  if kwargs.inclusive_op then
    kwargs.inclusive = kwargs.inclusive_op
  else
  end
  local invoked_repeat_3f = kwargs["repeat"]
  local invoked_dot_repeat_3f = kwargs["dot_repeat"]
  local windows = kwargs["windows"]
  local user_given_opts = kwargs["opts"]
  local user_given_targets = kwargs["targets"]
  local user_given_action = kwargs["action"]
  local action_can_traverse_3f = kwargs["traversal"]
  local function _52_()
    if invoked_dot_repeat_3f then
      return state.dot_repeat
    else
      return kwargs
    end
  end
  local _local_53_ = _52_()
  local backward_3f = _local_53_["backward"]
  local function _54_()
    if invoked_dot_repeat_3f then
      return state.dot_repeat
    elseif invoked_repeat_3f then
      return state["repeat"]
    else
      return kwargs
    end
  end
  local _local_55_ = _54_()
  local inclusive_3f = _local_55_["inclusive"]
  local offset = _local_55_["offset"]
  local inputlen = _local_55_["inputlen"]
  local user_given_pattern = _local_55_["pattern"]
  state.args = kwargs
  local opts_current_call
  if user_given_opts then
    if invoked_repeat_3f then
      opts_current_call = vim.tbl_deep_extend("keep", user_given_opts, (state["repeat"].opts or {}))
    elseif invoked_dot_repeat_3f then
      opts_current_call = vim.tbl_deep_extend("keep", user_given_opts, (state["dot-repeat"].opts or {}))
    else
      opts_current_call = user_given_opts
    end
  else
    opts_current_call = {}
  end
  opts.current_call = opts_current_call
  do
    local tmp_3_ = opts.current_call.equivalence_classes
    if (nil ~= tmp_3_) then
      local tmp_3_0 = to_membership_lookup(tmp_3_)
      if (nil ~= tmp_3_0) then
        opts.current_call.eqv_class_of = setmetatable(tmp_3_0, {merge = false})
      else
        opts.current_call.eqv_class_of = nil
      end
    else
      opts.current_call.eqv_class_of = nil
    end
  end
  for _, t in ipairs({"default", "current_call"}) do
    for _0, k in ipairs({"labels", "safe_labels"}) do
      if (type(opts[t][k]) == "table") then
        opts[t][k] = table.concat(opts[t][k])
      else
      end
    end
  end
  local directional_3f = not windows
  local no_labels_to_use_3f = ((opts.labels == "") and (opts.safe_labels == ""))
  if (not directional_3f and no_labels_to_use_3f) then
    echo("no labels to use")
    return
  else
  end
  if (windows and (#windows == 0)) then
    echo("no targetable windows")
    return
  else
  end
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
  local keyboard_input_3f = not (invoked_repeat_3f or invoked_dot_repeat_3f or (inputlen == 0) or (type(user_given_pattern) == "string") or user_given_targets)
  local inputlen0
  if inputlen then
    inputlen0 = inputlen
  elseif keyboard_input_3f then
    inputlen0 = 2
  else
    inputlen0 = 0
  end
  local keys
  local function _66_(_, k)
    local _67_ = opts.keys[k]
    if (nil ~= _67_) then
      local v = _67_
      local function _68_()
        if (type(v) == "string") then
          return {v}
        else
          return v
        end
      end
      return vim.tbl_map(vim.keycode, _68_())
    else
      return nil
    end
  end
  keys = setmetatable({}, {__index = _66_})
  local contains_3f = vim.list_contains
  local contains_safe_3f
  local function _70_(t, v)
    return (t[1] == v)
  end
  contains_safe_3f = _70_
  local st
  local _71_
  if (keyboard_input_3f and (inputlen0 == 2) and not no_labels_to_use_3f) then
    _71_ = 1
  else
    _71_ = nil
  end
  st = {phase = _71_, ["curr-idx"] = 0, ["group-offset"] = 0, prompt = nil, errmsg = nil, ["repeating-shortcut?"] = false}
  local function exec_user_autocmds(pattern)
    return api.nvim_exec_autocmds("User", {pattern = pattern, modeline = false})
  end
  local function exit_2a()
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
  local function redraw(callback)
    exec_user_autocmds("LeapRedraw")
    if callback then
      callback()
    else
    end
    return vim.cmd("redraw")
  end
  local function can_traverse_3f(targets)
    return (action_can_traverse_3f or (directional_3f and not (count or op_mode_3f or user_given_action) and (#targets >= 2)))
  end
  local function get_number_of_highlighted_traversal_targets()
    local _76_ = opts.max_highlighted_traversal_targets
    if (nil ~= _76_) then
      local group_size = _76_
      local consumed = ((st["curr-idx"] - 1) % group_size)
      local remaining = (group_size - consumed)
      if (remaining == 1) then
        return (group_size + 1)
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
      local start = (st["curr-idx"] + 1)
      local _end
      if use_no_labels_3f then
        local _79_ = get_number_of_highlighted_traversal_targets()
        if (nil ~= _79_) then
          local n = _79_
          _end = min(((start - 1) + n), #targets)
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
          st["repeating-shortcut?"] = true
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
    redraw()
    local _89_, _90_ = get_char_keymapped(st.prompt)
    if ((nil ~= _89_) and true) then
      local in1 = _89_
      local _3fprompt = _90_
      if contains_safe_3f(keys.next_target, in1) then
        st.phase = nil
        return get_repeat_input()
      else
        st.prompt = _3fprompt
        return in1
      end
    else
      return nil
    end
  end
  local function get_second_pattern_input(targets)
    if not count then
      local function _93_()
        return light_up_beacons(targets)
      end
      redraw(_93_)
    else
    end
    return get_char_keymapped(st.prompt)
  end
  local function get_full_pattern_input()
    local _95_, _96_ = get_first_pattern_input()
    if ((nil ~= _95_) and (nil ~= _96_)) then
      local in1 = _95_
      local in2 = _96_
      return in1, in2
    elseif ((nil ~= _95_) and (_96_ == nil)) then
      local in1 = _95_
      if (inputlen0 == 1) then
        return in1
      else
        local _97_ = get_char_keymapped(st.prompt)
        if (nil ~= _97_) then
          local in2 = _97_
          return in1, in2
        else
          return nil
        end
      end
    else
      return nil
    end
  end
  local function get_targets(pattern, in1, _3fin2)
    local errmsg
    if in1 then
      errmsg = ("not found: " .. in1 .. (_3fin2 or ""))
    else
      errmsg = "no targets"
    end
    local search = require("leap.search")
    local kwargs0 = {["backward?"] = backward_3f, windows = windows, offset = offset, ["op-mode?"] = op_mode_3f, inputlen = inputlen0}
    local targets = search["get-targets"](pattern, kwargs0)
    local or_102_ = targets
    if not or_102_ then
      st.errmsg = errmsg
      or_102_ = nil
    end
    return or_102_
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
        local wininfo = vim.fn.getwininfo(api.nvim_get_current_win())[1]
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
    local multi_window_3f = (windows and (#windows > 1))
    return prepare_labeled_targets(targets, force_noautojump_3f, multi_window_3f)
  end
  local repeat_state = {offset = kwargs.offset, backward = kwargs.backward, inclusive = kwargs.inclusive, pattern = kwargs.pattern, inputlen = inputlen0, opts = opts_current_call}
  local function update_repeat_state(in1, in2)
    if (not invoked_repeat_3f and (keyboard_input_3f or user_given_pattern)) then
      state["repeat"] = vim.tbl_extend("error", repeat_state, {in1 = (keyboard_input_3f and in1), in2 = (keyboard_input_3f and in2)})
      return nil
    else
      return nil
    end
  end
  local function set_dot_repeat(in1, in2, target_idx)
    local dot_repeatable_op_3f = (op_mode_3f and (vim.o.cpo:match("y") or (vim.v.operator ~= "y")))
    local dot_repeatable_call_3f = (dot_repeatable_op_3f and not invoked_dot_repeat_3f and (type(user_given_targets) ~= "table"))
    local function update_dot_repeat_state()
      state.dot_repeat = vim.tbl_extend("error", repeat_state, {target_idx = target_idx, targets = user_given_targets, in1 = (keyboard_input_3f and in1), in2 = (keyboard_input_3f and in2)})
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
  local jump_to_21
  do
    local first_jump_3f = true
    local function _109_(target)
      local jump = require("leap.jump")
      jump["jump-to!"](target.pos, {win = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["backward?"] = (backward_3f or (target.idx and (target.idx < 0))), ["inclusive?"] = inclusive_3f})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _109_
  end
  local do_action = (user_given_action or jump_to_21)
  local function select(targets)
    local _7cgroups_7c
    if not targets["label-set"] then
      _7cgroups_7c = 0
    else
      _7cgroups_7c = ceil((#targets / #targets["label-set"]))
    end
    local function display()
      local use_no_labels_3f = (no_labels_to_use_3f or st["repeating-shortcut?"])
      set_beacons(targets, {["group-offset"] = st["group-offset"], phase = st.phase, ["use-no-labels?"] = use_no_labels_3f})
      local start, _end = get_highlighted_idx_range(targets, use_no_labels_3f)
      local function _111_()
        return light_up_beacons(targets, start, _end)
      end
      return redraw(_111_)
    end
    local function loop(first_invoc_3f)
      display()
      if first_invoc_3f then
        exec_user_autocmds("LeapSelectPre")
      else
      end
      local _113_ = get_char()
      if (nil ~= _113_) then
        local input = _113_
        local switch_group_3f = (contains_3f(keys.next_group, input) or (contains_3f(keys.prev_group, input) and not first_invoc_3f))
        if (switch_group_3f and (_7cgroups_7c > 1)) then
          local shift
          if contains_3f(keys.next_group, input) then
            shift = 1
          else
            shift = -1
          end
          local max_offset = (_7cgroups_7c - 1)
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
      return min((idx + 1), #targets)
    elseif contains_3f(keys.prev_target, _in) then
      if (idx <= 1) then
        return #targets
      else
        return (idx - 1)
      end
    else
      return nil
    end
  end
  local function traverse(targets, start_idx, _119_)
    local use_no_labels_3f = _119_["use-no-labels?"]
    local function on_first_invoc()
      if use_no_labels_3f then
        for _, t in ipairs(targets) do
          t.label = nil
        end
        return nil
      elseif (opts.safe_labels ~= "") then
        local last_labeled = (#opts.safe_labels + 1)
        for i = (last_labeled + 1), #targets do
          targets[i]["label"] = nil
          targets[i]["beacon"] = nil
        end
        return nil
      else
        return nil
      end
    end
    local function display()
      set_beacons(targets, {["group-offset"] = st["group-offset"], phase = st.phase, ["use-no-labels?"] = use_no_labels_3f})
      local start, _end = get_highlighted_idx_range(targets, use_no_labels_3f)
      local function _121_()
        return light_up_beacons(targets, start, _end)
      end
      return redraw(_121_)
    end
    local function loop(idx, first_invoc_3f)
      if first_invoc_3f then
        on_first_invoc()
      else
      end
      st["curr-idx"] = idx
      display()
      local _123_ = get_char()
      if (nil ~= _123_) then
        local _in = _123_
        local _124_ = traversal_get_new_idx(idx, _in, targets)
        if (nil ~= _124_) then
          local new_idx = _124_
          do_action(targets[new_idx])
          return loop(new_idx, false)
        else
          local _ = _124_
          local _125_ = get_target_with_active_label(targets, _in)
          if (nil ~= _125_) then
            local target = _125_
            return do_action(target)
          else
            local _0 = _125_
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
  local need_in1_3f = (keyboard_input_3f or (invoked_repeat_3f and not ((type(state["repeat"].pattern) == "string") or (state["repeat"].inputlen == 0))) or (invoked_dot_repeat_3f and not ((type(state.dot_repeat.pattern) == "string") or (state.dot_repeat.inputlen == 0) or state.dot_repeat.targets)))
  local in1, _3fin2 = nil, nil
  if need_in1_3f then
    if keyboard_input_3f then
      if st.phase then
        in1, _3fin2 = get_first_pattern_input()
      else
        in1, _3fin2 = get_full_pattern_input()
      end
    elseif invoked_repeat_3f then
      in1, _3fin2 = get_repeat_input()
    elseif invoked_dot_repeat_3f then
      in1, _3fin2 = state.dot_repeat.in1, state.dot_repeat.in2
    else
      in1, _3fin2 = nil
    end
  else
    in1, _3fin2 = nil
  end
  if (need_in1_3f and not in1) then
    exit_early_2a()
    return
  else
  end
  local user_given_targets_2a = (user_given_targets or (invoked_dot_repeat_3f and state.dot_repeat.targets))
  local targets
  if user_given_targets_2a then
    targets = get_user_given_targets(user_given_targets_2a)
  else
    local pattern_2a = (user_given_pattern or (invoked_repeat_3f and state["repeat"].pattern) or (invoked_dot_repeat_3f and state.dot_repeat.pattern))
    local pattern
    if (type(pattern_2a) == "string") then
      pattern = pattern_2a
    elseif (type(pattern_2a) == "function") then
      local _133_
      if in1 then
        _133_ = prepare_pattern(in1, _3fin2, st.inputlen)
      else
        _133_ = ""
      end
      pattern = pattern_2a(_133_, {in1, _3fin2})
    else
      pattern = prepare_pattern(in1, _3fin2, st.inputlen)
    end
    targets = get_targets(pattern, in1, _3fin2)
  end
  if not targets then
    exit_early_2a()
    return
  else
  end
  if invoked_dot_repeat_3f then
    local _138_ = targets[state.dot_repeat.target_idx]
    if (nil ~= _138_) then
      local target = _138_
      do_action(target)
      exit_2a()
      return
    else
      local _ = _138_
      exit_early_2a()
      return
    end
  else
  end
  local need_in2_3f = ((inputlen0 == 2) and not (_3fin2 or st["repeating-shortcut?"]))
  do
    local preview_3f = need_in2_3f
    local use_no_labels_3f = (no_labels_to_use_3f or st["repeating-shortcut?"])
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
  local shortcut_3f = (st["repeating-shortcut?"] or contains_safe_3f(keys.next_target, _3fin20))
  local function _146_()
    if not shortcut_3f then
      return _3fin20
    else
      return nil
    end
  end
  update_repeat_state(in1, _146_())
  if shortcut_3f then
    local n = (count or 1)
    local target = targets[n]
    if not target then
      exit_early_2a()
      return
    else
    end
    local function _148_()
      if target.idx then
        return target.idx
      else
        return n
      end
    end
    set_dot_repeat(in1, nil, _148_())
    do_action(target)
    if can_traverse_3f(targets) then
      traverse(targets, 1, {["use-no-labels?"] = true})
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
    normalize_directional_indexes(targets_2a)
  else
  end
  local function exit_with_action_on_2a(idx)
    local target = targets_2a[idx]
    local function _154_()
      if target.idx then
        return target.idx
      else
        return idx
      end
    end
    set_dot_repeat(in1, _3fin20, _154_())
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
  local in_final = select(targets_2a)
  if not in_final then
    exit_early_2a()
    return
  elseif (can_traverse_3f(targets_2a) and (contains_3f(keys.next_target, in_final) or contains_3f(keys.prev_target, in_final))) then
    local use_no_labels_3f = (no_labels_to_use_3f or st["repeating-shortcut?"] or not targets_2a["autojump?"])
    local new_idx = traversal_get_new_idx(st["curr-idx"], in_final, targets_2a)
    do_action(targets_2a[new_idx])
    traverse(targets_2a, new_idx, {["use-no-labels?"] = use_no_labels_3f})
    exit_2a()
    return
  elseif (contains_3f(keys.next_target, in_final) and (st["curr-idx"] == 0)) then
    exit_with_action_on_2a(1)
    return
  else
    local _159_, _160_ = get_target_with_active_label(targets_2a, in_final)
    if ((nil ~= _159_) and (nil ~= _160_)) then
      local target = _159_
      local idx = _160_
      exit_with_action_on_2a(idx)
      return
    else
      local _ = _159_
      vim.fn.feedkeys(in_final, "i")
      exit_2a()
      return
    end
  end
  return nil
end
local function init_highlight()
  hl:init()
  local function _163_(_)
    return hl:init()
  end
  return api.nvim_create_autocmd("ColorScheme", {group = "LeapDefault", callback = _163_})
end
local function manage_vim_opts()
  local get_opt = api.nvim_get_option_value
  local set_opt = api.nvim_set_option_value
  local saved_vim_opts = {}
  local function set_vim_opts(t)
    local wins = (state.args.windows or state.args.target_windows or {api.nvim_get_current_win()})
    saved_vim_opts = {}
    for opt, val in pairs(t) do
      local _let_164_ = vim.split(opt, ".", {plain = true})
      local scope = _let_164_[1]
      local name = _let_164_[2]
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
  local function _169_(_)
    return set_vim_opts(opts.vim_opts)
  end
  api.nvim_create_autocmd("User", {pattern = "LeapEnter", group = "LeapDefault", callback = _169_})
  local function _170_(_)
    return restore_vim_opts()
  end
  return api.nvim_create_autocmd("User", {pattern = "LeapLeave", group = "LeapDefault", callback = _170_})
end
local function init()
  opts.default.eqv_class_of = to_membership_lookup(opts.default.equivalence_classes)
  api.nvim_create_augroup("LeapDefault", {})
  init_highlight()
  return manage_vim_opts()
end
init()
return {state = state, leap = leap}
