local hl = require("leap.highlight")
local opts = require("leap.opts")
local _local_1_ = require("leap.util")
local inc = _local_1_["inc"]
local dec = _local_1_["dec"]
local clamp = _local_1_["clamp"]
local echo = _local_1_["echo"]
local replace_keycodes = _local_1_["replace-keycodes"]
local get_eq_class_of = _local_1_["get-eq-class-of"]
local __3erepresentative_char = _local_1_["->representative-char"]
local get_input = _local_1_["get-input"]
local get_input_by_keymap = _local_1_["get-input-by-keymap"]
local api = vim.api
local contains_3f = vim.tbl_contains
local empty_3f = vim.tbl_isempty
local map = vim.tbl_map
local _local_2_ = math
local ceil = _local_2_["ceil"]
local max = _local_2_["max"]
local min = _local_2_["min"]
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
local function expand_to_equivalence_class(ch)
  local chars = get_eq_class_of(ch)
  if chars then
    for i, ch0 in ipairs(chars) do
      if (ch0 == "\n") then
        chars[i] = "\\n"
      elseif (ch0 == "\\") then
        chars[i] = "\\\\"
      else
      end
    end
    return ("\\(" .. table.concat(chars, "\\|") .. "\\)")
  else
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
local function set_labels(targets, _9_)
  local _arg_10_ = _9_
  local force_3f = _arg_10_["force?"]
  if ((#targets > 1) or empty_3f(opts.safe_labels) or force_3f) then
    local _local_11_ = targets
    local autojump_3f = _local_11_["autojump?"]
    local label_set = _local_11_["label-set"]
    local _7clabel_set_7c = #label_set
    for i_2a, target in ipairs(targets) do
      local i
      if autojump_3f then
        i = dec(i_2a)
      else
        i = i_2a
      end
      if (i >= 1) then
        local _13_ = (i % _7clabel_set_7c)
        if (_13_ == 0) then
          target.label = label_set[_7clabel_set_7c]
          target.group = math.floor((i / _7clabel_set_7c))
        elseif (nil ~= _13_) then
          local n = _13_
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
local function populate_sublists(targets, multi_window_3f)
  targets.sublists = {}
  local function _17_(self, ch, sublist)
    return rawset(self, __3erepresentative_char(ch), sublist)
  end
  local function _18_(self, ch)
    return rawget(self, __3erepresentative_char(ch))
  end
  setmetatable(targets.sublists, {__newindex = _17_, __index = _18_})
  if not multi_window_3f then
    for _, _19_ in ipairs(targets) do
      local _each_20_ = _19_
      local _each_21_ = _each_20_["chars"]
      local _0 = _each_21_[1]
      local ch2 = _each_21_[2]
      local target = _each_20_
      if not targets.sublists[ch2] then
        targets.sublists[ch2] = {}
      else
      end
      table.insert(targets.sublists[ch2], target)
    end
    return nil
  else
    for _, _23_ in ipairs(targets) do
      local _each_24_ = _23_
      local _each_25_ = _each_24_["chars"]
      local _0 = _each_25_[1]
      local ch2 = _each_25_[2]
      local _each_26_ = _each_24_["wininfo"]
      local winid = _each_26_["winid"]
      local target = _each_24_
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
local function get_label_offset(target)
  local _let_30_ = target
  local _let_31_ = _let_30_["chars"]
  local ch1 = _let_31_[1]
  local ch2 = _let_31_[2]
  if (ch1 == "\n") then
    return 0
  elseif (target["edge-pos?"] or (ch2 == "\n")) then
    return ch1:len()
  else
    return (ch1:len() + ch2:len())
  end
end
local function set_beacon_for_labeled(target, group_offset, _33_)
  local _arg_34_ = _33_
  local user_given_targets_3f = _arg_34_["user-given-targets?"]
  local phase = _arg_34_["phase"]
  local offset
  if phase then
    offset = get_label_offset(target)
  else
    offset = 0
  end
  local pad
  if (phase or user_given_targets_3f) then
    pad = ""
  else
    pad = " "
  end
  local label = (opts.substitute_chars[target.label] or target.label)
  local text = (label .. pad)
  local group_2a = (target.group - group_offset)
  local virttext
  if target.selected then
    virttext = {{text, hl.group["label-selected"]}}
  elseif (group_2a == 1) then
    virttext = {{text, hl.group["label-primary"]}}
  elseif (group_2a == 2) then
    virttext = {{text, hl.group["label-secondary"]}}
  elseif (group_2a > 2) then
    if (phase and not opts.highlight_unlabeled_phase_one_targets) then
      virttext = {{(opts.concealed_label .. pad), hl.group["label-secondary"]}}
    else
      virttext = nil
    end
  else
    virttext = nil
  end
  if virttext then
    target.beacon = {offset, virttext}
  else
    target.beacon = nil
  end
  return nil
end
local function set_beacon_to_match_hl(target)
  local virttext
  local function _40_(_241)
    return (opts.substitute_chars[_241] or _241)
  end
  virttext = table.concat(map(_40_, target.chars))
  target.beacon = {0, {{virttext, hl.group.match}}}
  return nil
end
local function set_beacon_to_empty_label(target)
  if target.beacon then
    target["beacon"][2][1][1] = opts.concealed_label
    return nil
  else
    return nil
  end
end
local function resolve_conflicts(targets)
  local unlabeled_match_positions = {}
  local label_positions = {}
  for _, target in ipairs(targets) do
    local empty_line_3f = ((target.chars[1] == "\n") and (target.pos[2] == 0))
    if not empty_line_3f then
      local _let_42_ = target.wininfo
      local bufnr = _let_42_["bufnr"]
      local winid = _let_42_["winid"]
      local _let_43_ = target.pos
      local lnum = _let_43_[1]
      local col_ch1 = _let_43_[2]
      local col_ch2 = (col_ch1 + string.len(target.chars[1]))
      local key_prefix = (bufnr .. " " .. winid .. " " .. lnum .. " ")
      if (target.label and target.beacon) then
        local label_offset = target.beacon[1]
        local col_label = (col_ch1 + label_offset)
        local shifted_label_3f = (col_label == col_ch2)
        do
          local _44_
          local function _45_(...)
            if shifted_label_3f then
              return unlabeled_match_positions[(key_prefix .. col_ch1)]
            else
              return nil
            end
          end
          _44_ = (label_positions[(key_prefix .. col_label)] or _45_() or unlabeled_match_positions[(key_prefix .. col_label)])
          if (nil ~= _44_) then
            local other = _44_
            other.beacon = nil
            set_beacon_to_empty_label(target)
          else
          end
        end
        label_positions[(key_prefix .. col_label)] = target
      else
        local col_ch3 = (col_ch2 + string.len(target.chars[2]))
        do
          local _48_ = (label_positions[(key_prefix .. col_ch1)] or label_positions[(key_prefix .. col_ch2)] or label_positions[(key_prefix .. col_ch3)])
          if (nil ~= _48_) then
            local other = _48_
            target.beacon = nil
            set_beacon_to_empty_label(other)
          else
          end
        end
        unlabeled_match_positions[(key_prefix .. col_ch1)] = target
        unlabeled_match_positions[(key_prefix .. col_ch2)] = target
      end
    else
    end
  end
  return nil
end
local function set_beacons(targets, _52_)
  local _arg_53_ = _52_
  local group_offset = _arg_53_["group-offset"]
  local no_labels_3f = _arg_53_["no-labels?"]
  local user_given_targets_3f = _arg_53_["user-given-targets?"]
  local phase = _arg_53_["phase"]
  if (no_labels_3f and targets[1].chars) then
    for _, target in ipairs(targets) do
      set_beacon_to_match_hl(target)
    end
    return nil
  else
    for _, target in ipairs(targets) do
      if target.label then
        set_beacon_for_labeled(target, (group_offset or 0), {["user-given-targets?"] = user_given_targets_3f, phase = phase})
      elseif ((phase == 1) and opts.highlight_unlabeled_phase_one_targets) then
        set_beacon_to_match_hl(target)
      else
      end
    end
    return nil
  end
end
local function light_up_beacons(targets, _3fstart, _3fend)
  if (not opts.on_beacons or opts.on_beacons(targets, _3fstart, _3fend)) then
    for i = (_3fstart or 1), (_3fend or #targets) do
      local target = targets[i]
      local _56_ = target.beacon
      if ((_G.type(_56_) == "table") and (nil ~= _56_[1]) and (nil ~= _56_[2])) then
        local offset = _56_[1]
        local virttext = _56_[2]
        local bufnr = target.wininfo.bufnr
        local _let_57_ = map(dec, target.pos)
        local lnum = _let_57_[1]
        local col = _let_57_[2]
        local id = api.nvim_buf_set_extmark(bufnr, hl.ns, lnum, (col + offset), {virt_text = virttext, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.label})
        table.insert(hl.extmarks, {bufnr, id})
      else
      end
    end
    return nil
  else
    return nil
  end
end
local state = {args = nil, source_window = nil, ["repeat"] = {in1 = nil, in2 = nil, inclusive_op = nil, offset = nil, backward = nil}, dot_repeat = {in1 = nil, in2 = nil, target_idx = nil, backward = nil, inclusive_op = nil, offset = nil}, saved_editor_opts = {}}
local function leap(kwargs)
  local _local_60_ = kwargs
  local repeat_3f = _local_60_["repeat"]
  local dot_repeat_3f = _local_60_["dot_repeat"]
  local target_windows = _local_60_["target_windows"]
  local user_given_opts = _local_60_["opts"]
  local user_given_targets = _local_60_["targets"]
  local user_given_action = _local_60_["action"]
  local multi_select_3f = _local_60_["multiselect"]
  local function _62_()
    if dot_repeat_3f then
      return state.dot_repeat
    else
      return kwargs
    end
  end
  local _local_61_ = _62_()
  local backward_3f = _local_61_["backward"]
  local function _64_()
    if dot_repeat_3f then
      return state.dot_repeat
    elseif repeat_3f then
      return state["repeat"]
    else
      return kwargs
    end
  end
  local _local_63_ = _64_()
  local inclusive_op_3f = _local_63_["inclusive_op"]
  local offset = _local_63_["offset"]
  local match_same_char_seq_at_end_3f = _local_63_["match_same_char_seq_at_end"]
  opts.current_call = (user_given_opts or {})
  do
    local _65_ = opts.current_call.equivalence_classes
    if (nil ~= _65_) then
      opts.current_call.eq_class_of = eq_classes__3emembership_lookup(_65_)
    else
      opts.current_call.eq_class_of = _65_
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
  local curr_winid = vim.fn.win_getid()
  state.args = kwargs
  state.source_window = curr_winid
  local _3ftarget_windows = target_windows
  local multi_window_3f = (_3ftarget_windows and (#_3ftarget_windows > 1))
  local hl_affected_windows
  do
    local tbl_17_auto = {curr_winid}
    for _, winid in ipairs((_3ftarget_windows or {})) do
      table.insert(tbl_17_auto, winid)
    end
    hl_affected_windows = tbl_17_auto
  end
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
  do
    local function __index(_, k)
      local _73_ = opts.special_keys[k]
      if (nil ~= _73_) then
        local v = _73_
        if ((k == "next_target") or (k == "prev_target")) then
          local _74_ = type(v)
          if (_74_ == "table") then
            local tbl_18_auto = {}
            local i_19_auto = 0
            for _0, str in ipairs(v) do
              local val_20_auto = replace_keycodes(str)
              if (nil ~= val_20_auto) then
                i_19_auto = (i_19_auto + 1)
                do end (tbl_18_auto)[i_19_auto] = val_20_auto
              else
              end
            end
            return tbl_18_auto
          elseif (_74_ == "string") then
            return {replace_keycodes(v)}
          else
            return nil
          end
        else
          return replace_keycodes(v)
        end
      else
        return nil
      end
    end
    spec_keys = setmetatable({}, {__index = __index})
  end
  local vars
  local _79_
  if not (repeat_3f or (max_phase_one_targets == 0) or empty_label_lists_3f or multi_select_3f or user_given_targets_3f) then
    _79_ = 1
  else
    _79_ = nil
  end
  vars = {phase = _79_, ["curr-idx"] = 0, ["group-offset"] = 0, errmsg = nil, ["partial-pattern?"] = false}
  local function get_number_of_highlighted_targets()
    local _81_ = opts.max_highlighted_traversal_targets
    if (nil ~= _81_) then
      local group_size = _81_
      local consumed = (dec(vars["curr-idx"]) % group_size)
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
      local start = inc(vars["curr-idx"])
      local _end
      if no_labels_3f then
        local _84_ = get_number_of_highlighted_targets()
        if (nil ~= _84_) then
          local _85_ = (_84_ + dec(start))
          if (nil ~= _85_) then
            _end = min(_85_, #targets)
          else
            _end = _85_
          end
        else
          _end = _84_
        end
      else
        _end = nil
      end
      return start, _end
    end
  end
  local function get_target_with_active_label(sublist, input)
    local res = {}
    for idx, _90_ in ipairs(sublist) do
      local _each_91_ = _90_
      local label = _each_91_["label"]
      local group = _each_91_["group"]
      local target = _each_91_
      if (next(res) or (((group or 0) - vars["group-offset"]) > 1)) then break end
      if ((label == input) and ((group - vars["group-offset"]) == 1)) then
        res = {idx, target}
      else
      end
    end
    return res
  end
  local function get_repeat_input()
    if state["repeat"].in1 then
      if not state["repeat"].in2 then
        vars["partial-pattern?"] = true
      else
      end
      return state["repeat"].in1, state["repeat"].in2
    else
      vars.errmsg = "no previous search"
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
    local _96_ = get_input_by_keymap(prompt)
    if (nil ~= _96_) then
      local in1 = _96_
      if contains_3f(spec_keys.next_target, in1) then
        if state["repeat"].in1 then
          vars.phase = nil
          if not state["repeat"].in2 then
            vars["partial-pattern?"] = true
          else
          end
          return state["repeat"].in1, state["repeat"].in2
        else
          vars.errmsg = "no previous search"
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
    local _103_, _104_ = get_first_pattern_input()
    if ((nil ~= _103_) and (nil ~= _104_)) then
      local in1 = _103_
      local in2 = _104_
      return in1, in2
    elseif ((nil ~= _103_) and (_104_ == nil)) then
      local in1 = _103_
      local _105_ = get_input_by_keymap(prompt)
      if (nil ~= _105_) then
        local in2 = _105_
        return in1, in2
      else
        return nil
      end
    else
      return nil
    end
  end
  local function prepare_pattern(in1, _3fin2)
    local pat1 = (expand_to_equivalence_class(in1) or in1:gsub("\\", "\\\\"))
    local pat2 = ((_3fin2 and expand_to_equivalence_class(_3fin2)) or _3fin2 or "\\_.")
    local potential__5cn_5cn_3f = (pat1:match("\\n") and (not _3fin2 or pat2:match("\\n")))
    local pat
    if potential__5cn_5cn_3f then
      pat = (pat1 .. pat2 .. "\\|\\n")
    else
      pat = (pat1 .. pat2)
    end
    local function _109_()
      if opts.case_sensitive then
        return "\\C"
      else
        return "\\c"
      end
    end
    return ("\\V" .. _109_() .. pat)
  end
  local function get_targets(in1, _3fin2)
    local search = require("leap.search")
    local pattern = prepare_pattern(in1, _3fin2)
    local kwargs0 = {["backward?"] = backward_3f, ["match-same-char-seq-at-end?"] = match_same_char_seq_at_end_3f, ["target-windows"] = _3ftarget_windows}
    local targets = search["get-targets"](pattern, kwargs0)
    local function _110_(...)
      vars.errmsg = ("not found: " .. in1 .. (_3fin2 or ""))
      return nil
    end
    return (targets or _110_())
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
      vars.errmsg = "no targets"
      return nil
    end
  end
  local function prepare_targets(targets)
    local funny_edge_case_3f
    local function _114_(...)
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
    funny_edge_case_3f = (backward_3f and _114_())
    local force_noautojump_3f = (op_mode_3f or multi_select_3f or (multi_window_3f and not targets["shared-window?"]) or user_given_action or funny_edge_case_3f)
    set_autojump(targets, force_noautojump_3f)
    attach_label_set(targets)
    set_labels(targets, {["force?"] = multi_select_3f})
    return targets
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
    local function _118_(target)
      local jump = require("leap.jump")
      jump["jump-to!"](target.pos, {winid = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["backward?"] = backward_3f, ["inclusive-op?"] = inclusive_op_3f})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _118_
  end
  local function post_pattern_input_loop(targets, first_invoc_3f)
    local _7cgroups_7c
    if not targets["label-set"] then
      _7cgroups_7c = 0
    else
      _7cgroups_7c = ceil((#targets / #targets["label-set"]))
    end
    local function display()
      local no_labels_3f = (empty_label_lists_3f or vars["partial-pattern?"])
      set_beacons(targets, {["group-offset"] = vars["group-offset"], ["no-labels?"] = no_labels_3f, ["user-given-targets?"] = user_given_targets_3f, phase = vars.phase})
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
      local _122_ = get_input()
      if (nil ~= _122_) then
        local input = _122_
        local switch_group_3f = ((_7cgroups_7c > 1) and ((input == spec_keys.next_group) or ((input == spec_keys.prev_group) and not first_invoc_3f0)))
        if switch_group_3f then
          local inc_2fdec
          if (input == spec_keys.next_group) then
            inc_2fdec = inc
          else
            inc_2fdec = dec
          end
          local max_offset = dec(_7cgroups_7c)
          vars["group-offset"] = clamp(inc_2fdec(vars["group-offset"]), 0, max_offset)
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
      local _126_, _127_ = post_pattern_input_loop(targets, first_invoc_3f)
      if (_126_ == spec_keys.multi_accept) then
        if not empty_3f(selection) then
          return selection
        else
          return loop(targets)
        end
      elseif (_126_ == spec_keys.multi_revert) then
        local removed = table.remove(selection)
        if removed then
          removed.selected = nil
        else
        end
        return loop(targets)
      elseif (nil ~= _126_) then
        local _in = _126_
        first_invoc_3f = false
        do
          local _130_ = get_target_with_active_label(targets, _in)
          if ((_G.type(_130_) == "table") and true and (nil ~= _130_[2])) then
            local _ = _130_[1]
            local target = _130_[2]
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
  local function traversal_loop(targets, start_idx, _134_)
    local _arg_135_ = _134_
    local no_labels_3f = _arg_135_["no-labels?"]
    local function on_first_invoc()
      if no_labels_3f then
        for _, t in ipairs(targets) do
          t.label = nil
        end
        return nil
      elseif not empty_3f(opts.safe_labels) then
        local last_labeled = inc(#opts.safe_labels)
        for i = inc(last_labeled), #targets do
          local _136_ = targets[i]
          _136_["label"] = nil
          _136_["beacon"] = nil
        end
        return nil
      else
        return nil
      end
    end
    local function display()
      set_beacons(targets, {["group-offset"] = vars["group-offset"], ["no-labels?"] = no_labels_3f, ["user-given-targets?"] = user_given_targets_3f, phase = vars.phase})
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
      vars["curr-idx"] = idx
      display()
      local _141_ = get_input()
      if (nil ~= _141_) then
        local _in = _141_
        if ((idx == 1) and contains_3f(spec_keys.prev_target, _in)) then
          return vim.fn.feedkeys(_in, "i")
        else
          local _142_ = get_new_idx(idx, _in)
          if (nil ~= _142_) then
            local new_idx = _142_
            jump_to_21(targets[new_idx])
            return loop(new_idx, false)
          else
            local _ = _142_
            local _143_ = get_target_with_active_label(targets, _in)
            if ((_G.type(_143_) == "table") and true and (nil ~= _143_[2])) then
              local _0 = _143_[1]
              local target = _143_[2]
              return jump_to_21(target)
            else
              local _0 = _143_
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
  elseif (vars.phase == 1) then
    in1, _3fin2 = get_first_pattern_input()
  else
    in1, _3fin2 = get_full_pattern_input()
  end
  if not in1 then
    if change_op_3f then
      handle_interrupted_change_op_21()
    else
    end
    if vars.errmsg then
      echo(vars.errmsg)
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
    if vars.errmsg then
      echo(vars.errmsg)
    else
    end
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  if dot_repeat_3f then
    local _157_ = targets[state.dot_repeat.target_idx]
    if (nil ~= _157_) then
      local target = _157_
      do_action(target)
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    else
      local _ = _157_
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      if vars.errmsg then
        echo(vars.errmsg)
      else
      end
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    end
  else
  end
  if (_3fin2 or vars["partial-pattern?"]) then
    if (empty_label_lists_3f or vars["partial-pattern?"]) then
      targets["autojump?"] = true
    else
      prepare_targets(targets)
    end
  else
    if (#targets > max_phase_one_targets) then
      vars.phase = nil
    else
    end
    populate_sublists(targets, multi_window_3f)
    for _, sublist in pairs(targets.sublists) do
      prepare_targets(sublist)
    end
    set_beacons(targets, {phase = vars.phase})
    if (vars.phase == 1) then
      resolve_conflicts(targets)
    else
    end
  end
  local _3fin20 = (_3fin2 or (not vars["partial-pattern?"] and get_second_pattern_input(targets)))
  if not (vars["partial-pattern?"] or _3fin20) then
    if change_op_3f then
      handle_interrupted_change_op_21()
    else
    end
    if vars.errmsg then
      echo(vars.errmsg)
    else
    end
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  if vars.phase then
    vars.phase = 2
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
      if vars.errmsg then
        echo(vars.errmsg)
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
    vars.errmsg = ("not found: " .. in1 .. _3fin20)
    if change_op_3f then
      handle_interrupted_change_op_21()
    else
    end
    if vars.errmsg then
      echo(vars.errmsg)
    else
    end
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  if multi_select_3f then
    do
      local _179_ = multi_select_loop(targets_2a)
      if (nil ~= _179_) then
        local targets_2a_2a = _179_
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
      if vars.errmsg then
        echo(vars.errmsg)
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
  elseif (((repeat_3f or vars["partial-pattern?"]) and (op_mode_3f or not directional_3f)) or (#targets_2a == 1)) then
    set_dot_repeat(in1, _3fin20, 1)
    do_action(targets_2a[1])
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  if targets_2a["autojump?"] then
    vars["curr-idx"] = 1
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
    if vars.errmsg then
      echo(vars.errmsg)
    else
    end
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  if contains_3f(spec_keys.next_target, in_final) then
    if (can_traverse_3f and (#targets_2a > 1)) then
      local new_idx = inc(vars["curr-idx"])
      do_action(targets_2a[new_idx])
      traversal_loop(targets_2a, new_idx, {["no-labels?"] = (empty_label_lists_3f or vars["partial-pattern?"] or not targets_2a["autojump?"])})
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
  local _local_195_ = get_target_with_active_label(targets_2a, in_final)
  local idx = _local_195_[1]
  local _ = _local_195_[2]
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
  local _197_ = opts.default.equivalence_classes
  if (nil ~= _197_) then
    opts.default.eq_class_of = eq_classes__3emembership_lookup(_197_)
  else
    opts.default.eq_class_of = _197_
  end
end
api.nvim_create_augroup("LeapDefault", {})
hl["init-highlight"](hl)
local function _199_()
  return hl["init-highlight"](hl)
end
api.nvim_create_autocmd("ColorScheme", {callback = _199_, group = "LeapDefault"})
local function set_editor_opts(t)
  state.saved_editor_opts = {}
  local wins = (state.args.target_windows or {state.source_window})
  for opt, val in pairs(t) do
    local _let_200_ = vim.split(opt, ".", {plain = true})
    local scope = _let_200_[1]
    local name = _let_200_[2]
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
local function _204_()
  set_editor_opts(temporary_editor_opts)
  return set_concealed_label()
end
api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _204_, group = "LeapDefault"})
local function _205_()
  return restore_editor_opts()
end
api.nvim_create_autocmd("User", {pattern = "LeapLeave", callback = _205_, group = "LeapDefault"})
return {state = state, leap = leap}
