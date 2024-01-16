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
    for i, target in ipairs(targets) do
      local i_2a
      if autojump_3f then
        i_2a = dec(i)
      else
        i_2a = i
      end
      if (i_2a > 0) then
        local _13_ = (i_2a % #label_set)
        if (_13_ == 0) then
          target.label = label_set[#label_set]
        elseif (nil ~= _13_) then
          local n = _13_
          target.label = label_set[n]
        else
          target.label = nil
        end
      else
      end
    end
    return nil
  else
    return nil
  end
end
local function set_label_states(targets, _17_)
  local _arg_18_ = _17_
  local group_offset = _arg_18_["group-offset"]
  local _7clabel_set_7c = #targets["label-set"]
  local offset = (group_offset * _7clabel_set_7c)
  local primary_start
  local function _19_()
    if targets["autojump?"] then
      return 2
    else
      return 1
    end
  end
  primary_start = (offset + _19_())
  local primary_end = (primary_start + dec(_7clabel_set_7c))
  local secondary_start = inc(primary_end)
  local secondary_end = (primary_end + _7clabel_set_7c)
  for i, target in ipairs(targets) do
    if (target.label and (target["label-state"] ~= "selected")) then
      if ((primary_start <= i) and (i <= primary_end)) then
        target["label-state"] = "active-primary"
      elseif ((secondary_start <= i) and (i <= secondary_end)) then
        target["label-state"] = "active-secondary"
      elseif (i > secondary_end) then
        target["label-state"] = "inactive"
      else
        target["label-state"] = nil
      end
    else
    end
  end
  return nil
end
local function populate_sublists(targets, multi_window_3f)
  targets.sublists = {}
  local function _22_(self, ch, sublist)
    return rawset(self, __3erepresentative_char(ch), sublist)
  end
  local function _23_(self, ch)
    return rawget(self, __3erepresentative_char(ch))
  end
  setmetatable(targets.sublists, {__newindex = _22_, __index = _23_})
  if not multi_window_3f then
    for _, _24_ in ipairs(targets) do
      local _each_25_ = _24_
      local _each_26_ = _each_25_["chars"]
      local _0 = _each_26_[1]
      local ch2 = _each_26_[2]
      local target = _each_25_
      if not targets.sublists[ch2] then
        targets.sublists[ch2] = {}
      else
      end
      table.insert(targets.sublists[ch2], target)
    end
    return nil
  else
    for _, _28_ in ipairs(targets) do
      local _each_29_ = _28_
      local _each_30_ = _each_29_["chars"]
      local _0 = _each_30_[1]
      local ch2 = _each_30_[2]
      local _each_31_ = _each_29_["wininfo"]
      local winid = _each_31_["winid"]
      local target = _each_29_
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
local function set_initial_label_states(targets)
  for _, sublist in pairs(targets.sublists) do
    set_label_states(sublist, {["group-offset"] = 0})
  end
  return nil
end
local function get_label_offset(target)
  local _let_35_ = target
  local _let_36_ = _let_35_["chars"]
  local ch1 = _let_36_[1]
  local ch2 = _let_36_[2]
  if (ch1 == "\n") then
    return 0
  elseif (target["edge-pos?"] or (ch2 == "\n")) then
    return ch1:len()
  else
    return (ch1:len() + ch2:len())
  end
end
local function set_beacon_for_labeled(target, _38_)
  local _arg_39_ = _38_
  local user_given_targets_3f = _arg_39_["user-given-targets?"]
  local phase = _arg_39_["phase"]
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
  local virttext
  do
    local _42_ = target["label-state"]
    if (_42_ == "selected") then
      virttext = {{text, hl.group["label-selected"]}}
    elseif (_42_ == "active-primary") then
      virttext = {{text, hl.group["label-primary"]}}
    elseif (_42_ == "active-secondary") then
      virttext = {{text, hl.group["label-secondary"]}}
    elseif (_42_ == "inactive") then
      if (phase and not opts.highlight_unlabeled_phase_one_targets) then
        virttext = {{(opts.concealed_label .. pad), hl.group["label-secondary"]}}
      elseif "else" then
        virttext = nil
      else
        virttext = nil
      end
    else
      virttext = nil
    end
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
  local function _46_(_241)
    return (opts.substitute_chars[_241] or _241)
  end
  virttext = table.concat(map(_46_, target.chars))
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
      local _let_48_ = target.wininfo
      local bufnr = _let_48_["bufnr"]
      local winid = _let_48_["winid"]
      local _let_49_ = target.pos
      local lnum = _let_49_[1]
      local col_ch1 = _let_49_[2]
      local col_ch2 = (col_ch1 + string.len(target.chars[1]))
      local key_prefix = (bufnr .. " " .. winid .. " " .. lnum .. " ")
      if (target.label and target.beacon) then
        local label_offset = target.beacon[1]
        local col_label = (col_ch1 + label_offset)
        local shifted_label_3f = (col_label == col_ch2)
        do
          local _50_
          local function _51_(...)
            if shifted_label_3f then
              return unlabeled_match_positions[(key_prefix .. col_ch1)]
            else
              return nil
            end
          end
          _50_ = (label_positions[(key_prefix .. col_label)] or _51_() or unlabeled_match_positions[(key_prefix .. col_label)])
          if (nil ~= _50_) then
            local other = _50_
            other.beacon = nil
            set_beacon_to_empty_label(target)
          else
          end
        end
        label_positions[(key_prefix .. col_label)] = target
      else
        local col_ch3 = (col_ch2 + string.len(target.chars[2]))
        do
          local _54_ = (label_positions[(key_prefix .. col_ch1)] or label_positions[(key_prefix .. col_ch2)] or label_positions[(key_prefix .. col_ch3)])
          if (nil ~= _54_) then
            local other = _54_
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
local function set_beacons(targets, _58_)
  local _arg_59_ = _58_
  local no_labels_3f = _arg_59_["no-labels?"]
  local user_given_targets_3f = _arg_59_["user-given-targets?"]
  local phase = _arg_59_["phase"]
  if (no_labels_3f and targets[1].chars) then
    for _, target in ipairs(targets) do
      set_beacon_to_match_hl(target)
    end
    return nil
  else
    for _, target in ipairs(targets) do
      if target.label then
        set_beacon_for_labeled(target, {["user-given-targets?"] = user_given_targets_3f, phase = phase})
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
      local _62_ = target.beacon
      if ((_G.type(_62_) == "table") and (nil ~= _62_[1]) and (nil ~= _62_[2])) then
        local offset = _62_[1]
        local virttext = _62_[2]
        local bufnr = target.wininfo.bufnr
        local _let_63_ = map(dec, target.pos)
        local lnum = _let_63_[1]
        local col = _let_63_[2]
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
  local _local_66_ = kwargs
  local repeat_3f = _local_66_["repeat"]
  local dot_repeat_3f = _local_66_["dot_repeat"]
  local target_windows = _local_66_["target_windows"]
  local user_given_opts = _local_66_["opts"]
  local user_given_targets = _local_66_["targets"]
  local user_given_action = _local_66_["action"]
  local multi_select_3f = _local_66_["multiselect"]
  local function _68_()
    if dot_repeat_3f then
      return state.dot_repeat
    else
      return kwargs
    end
  end
  local _local_67_ = _68_()
  local backward_3f = _local_67_["backward"]
  local function _70_()
    if dot_repeat_3f then
      return state.dot_repeat
    elseif repeat_3f then
      return state["repeat"]
    else
      return kwargs
    end
  end
  local _local_69_ = _70_()
  local inclusive_op_3f = _local_69_["inclusive_op"]
  local offset = _local_69_["offset"]
  local match_same_char_seq_at_end_3f = _local_69_["match_same_char_seq_at_end"]
  opts.current_call = (user_given_opts or {})
  do
    local _71_ = opts.current_call.equivalence_classes
    if (nil ~= _71_) then
      opts.current_call.eq_class_of = eq_classes__3emembership_lookup(_71_)
    else
      opts.current_call.eq_class_of = _71_
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
      local _79_ = opts.special_keys[k]
      if (nil ~= _79_) then
        local v = _79_
        if ((k == "next_target") or (k == "prev_target")) then
          local _80_ = type(v)
          if (_80_ == "table") then
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
          elseif (_80_ == "string") then
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
  local _85_
  if not (repeat_3f or (max_phase_one_targets == 0) or empty_label_lists_3f or multi_select_3f or user_given_targets_3f) then
    _85_ = 1
  else
    _85_ = nil
  end
  vars = {phase = _85_, ["curr-idx"] = 0, errmsg = nil, ["partial-pattern?"] = false}
  local function get_number_of_highlighted_targets()
    local _87_ = opts.max_highlighted_traversal_targets
    if (nil ~= _87_) then
      local group_size = _87_
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
        local _90_ = get_number_of_highlighted_targets()
        if (nil ~= _90_) then
          local _91_ = (_90_ + dec(start))
          if (nil ~= _91_) then
            _end = min(_91_, #targets)
          else
            _end = _91_
          end
        else
          _end = _90_
        end
      else
        _end = nil
      end
      return start, _end
    end
  end
  local function get_target_with_active_primary_label(sublist, input)
    local res = {}
    for idx, _96_ in ipairs(sublist) do
      local _each_97_ = _96_
      local label = _each_97_["label"]
      local label_state = _each_97_["label-state"]
      local target = _each_97_
      if (next(res) or (label_state == "inactive")) then break end
      if ((label == input) and (label_state == "active-primary")) then
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
    local _102_ = get_input_by_keymap(prompt)
    if (nil ~= _102_) then
      local in1 = _102_
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
    local _109_, _110_ = get_first_pattern_input()
    if ((nil ~= _109_) and (nil ~= _110_)) then
      local in1 = _109_
      local in2 = _110_
      return in1, in2
    elseif ((nil ~= _109_) and (_110_ == nil)) then
      local in1 = _109_
      local _111_ = get_input_by_keymap(prompt)
      if (nil ~= _111_) then
        local in2 = _111_
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
    local function _115_()
      if opts.case_sensitive then
        return "\\C"
      else
        return "\\c"
      end
    end
    return ("\\V" .. _115_() .. pat)
  end
  local function get_targets(in1, _3fin2)
    local search = require("leap.search")
    local pattern = prepare_pattern(in1, _3fin2)
    local kwargs0 = {["backward?"] = backward_3f, ["match-same-char-seq-at-end?"] = match_same_char_seq_at_end_3f, ["target-windows"] = _3ftarget_windows}
    local targets = search["get-targets"](pattern, kwargs0)
    local function _116_(...)
      vars.errmsg = ("not found: " .. in1 .. (_3fin2 or ""))
      return nil
    end
    return (targets or _116_())
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
    local function _120_(...)
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
    funny_edge_case_3f = (backward_3f and _120_())
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
    local function _124_(target)
      local jump = require("leap.jump")
      jump["jump-to!"](target.pos, {winid = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["backward?"] = backward_3f, ["inclusive-op?"] = inclusive_op_3f})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _124_
  end
  local function post_pattern_input_loop(targets, _3fgroup_offset, first_invoc_3f)
    local _7cgroups_7c
    if not targets["label-set"] then
      _7cgroups_7c = 0
    else
      _7cgroups_7c = ceil((#targets / #targets["label-set"]))
    end
    local function display(group_offset)
      local no_labels_3f = (empty_label_lists_3f or vars["partial-pattern?"])
      if targets["label-set"] then
        set_label_states(targets, {["group-offset"] = group_offset})
      else
      end
      set_beacons(targets, {["no-labels?"] = no_labels_3f, ["user-given-targets?"] = user_given_targets_3f, phase = vars.phase})
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
    local function loop(group_offset, first_invoc_3f0)
      display(group_offset)
      if first_iter_3f then
        exec_user_autocmds("LeapSelectPre")
        first_iter_3f = false
      else
      end
      local _129_ = get_input()
      if (nil ~= _129_) then
        local input = _129_
        local switch_group_3f = ((_7cgroups_7c > 1) and ((input == spec_keys.next_group) or ((input == spec_keys.prev_group) and not first_invoc_3f0)))
        if switch_group_3f then
          local inc_2fdec
          if (input == spec_keys.next_group) then
            inc_2fdec = inc
          else
            inc_2fdec = dec
          end
          local max_offset = dec(_7cgroups_7c)
          local group_offset_2a = clamp(inc_2fdec(group_offset), 0, max_offset)
          return loop(group_offset_2a, false)
        else
          return input, group_offset
        end
      else
        return nil
      end
    end
    return loop((_3fgroup_offset or 0), (first_invoc_3f ~= false))
  end
  local multi_select_loop
  do
    local selection = {}
    local group_offset = 0
    local first_invoc_3f = true
    local function loop(targets)
      local _133_, _134_ = post_pattern_input_loop(targets, group_offset, first_invoc_3f)
      if (_133_ == spec_keys.multi_accept) then
        if not empty_3f(selection) then
          return selection
        else
          return loop(targets)
        end
      elseif (_133_ == spec_keys.multi_revert) then
        do
          local _136_ = table.remove(selection)
          if (nil ~= _136_) then
            _136_["label-state"] = nil
          else
          end
        end
        return loop(targets)
      elseif ((nil ~= _133_) and (nil ~= _134_)) then
        local _in = _133_
        local group_offset_2a = _134_
        group_offset = group_offset_2a
        first_invoc_3f = false
        do
          local _138_ = get_target_with_active_primary_label(targets, _in)
          if ((_G.type(_138_) == "table") and true and (nil ~= _138_[2])) then
            local _ = _138_[1]
            local target = _138_[2]
            if not contains_3f(selection, target) then
              table.insert(selection, target)
              target["label-state"] = "selected"
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
  local function traversal_loop(targets, start_idx, _142_)
    local _arg_143_ = _142_
    local no_labels_3f = _arg_143_["no-labels?"]
    local function on_first_invoc()
      if no_labels_3f then
        for _, t in ipairs(targets) do
          t["label-state"] = "inactive"
        end
        return nil
      elseif not empty_3f(opts.safe_labels) then
        local last_labeled = inc(#opts.safe_labels)
        for i = inc(last_labeled), #targets do
          local _144_ = targets[i]
          _144_["label"] = nil
          _144_["beacon"] = nil
        end
        return nil
      else
        return nil
      end
    end
    local function display()
      set_beacons(targets, {["no-labels?"] = no_labels_3f, ["user-given-targets?"] = user_given_targets_3f, phase = vars.phase})
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
      local _149_ = get_input()
      if (nil ~= _149_) then
        local _in = _149_
        if ((idx == 1) and contains_3f(spec_keys.prev_target, _in)) then
          return vim.fn.feedkeys(_in, "i")
        else
          local _150_ = get_new_idx(idx, _in)
          if (nil ~= _150_) then
            local new_idx = _150_
            jump_to_21(targets[new_idx])
            return loop(new_idx, false)
          else
            local _ = _150_
            local _151_ = get_target_with_active_primary_label(targets, _in)
            if ((_G.type(_151_) == "table") and true and (nil ~= _151_[2])) then
              local _0 = _151_[1]
              local target = _151_[2]
              return jump_to_21(target)
            else
              local _0 = _151_
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
    local _165_ = targets[state.dot_repeat.target_idx]
    if (nil ~= _165_) then
      local target = _165_
      do_action(target)
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    else
      local _ = _165_
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
    do
      set_initial_label_states(targets)
      set_beacons(targets, {phase = vars.phase})
    end
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
      local _187_ = multi_select_loop(targets_2a)
      if (nil ~= _187_) then
        local targets_2a_2a = _187_
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
  local _local_203_ = get_target_with_active_primary_label(targets_2a, in_final)
  local idx = _local_203_[1]
  local _ = _local_203_[2]
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
  local _205_ = opts.default.equivalence_classes
  if (nil ~= _205_) then
    opts.default.eq_class_of = eq_classes__3emembership_lookup(_205_)
  else
    opts.default.eq_class_of = _205_
  end
end
api.nvim_create_augroup("LeapDefault", {})
hl["init-highlight"](hl)
local function _207_()
  return hl["init-highlight"](hl)
end
api.nvim_create_autocmd("ColorScheme", {callback = _207_, group = "LeapDefault"})
local function set_editor_opts(t)
  state.saved_editor_opts = {}
  local wins = (state.args.target_windows or {state.source_window})
  for opt, val in pairs(t) do
    local _let_208_ = vim.split(opt, ".", {plain = true})
    local scope = _let_208_[1]
    local name = _let_208_[2]
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
local function _212_()
  set_editor_opts(temporary_editor_opts)
  return set_concealed_label()
end
api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _212_, group = "LeapDefault"})
local function _213_()
  return restore_editor_opts()
end
api.nvim_create_autocmd("User", {pattern = "LeapLeave", callback = _213_, group = "LeapDefault"})
return {state = state, leap = leap}
