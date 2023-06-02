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
local function set_labels(targets, multi_select_3f)
  if ((#targets > 1) or multi_select_3f) then
    local _local_7_ = targets
    local autojump_3f = _local_7_["autojump?"]
    local label_set = _local_7_["label-set"]
    for i, target in ipairs(targets) do
      local i_2a
      if autojump_3f then
        i_2a = dec(i)
      else
        i_2a = i
      end
      if (i_2a > 0) then
        local _9_ = (i_2a % #label_set)
        if (_9_ == 0) then
          target.label = label_set[#label_set]
        elseif (nil ~= _9_) then
          local n = _9_
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
local function set_label_states(targets, _13_)
  local _arg_14_ = _13_
  local group_offset = _arg_14_["group-offset"]
  local _7clabel_set_7c = #targets["label-set"]
  local offset = (group_offset * _7clabel_set_7c)
  local primary_start
  local function _15_()
    if targets["autojump?"] then
      return 2
    else
      return 1
    end
  end
  primary_start = (offset + _15_())
  local primary_end = (primary_start + dec(_7clabel_set_7c))
  local secondary_start = inc(primary_end)
  local secondary_end = (primary_end + _7clabel_set_7c)
  for i, target in ipairs(targets) do
    if (target.label and (target["label-state"] ~= "selected")) then
      if (primary_start <= i) and (i <= primary_end) then
        target["label-state"] = "active-primary"
      elseif (secondary_start <= i) and (i <= secondary_end) then
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
local function populate_sublists(targets)
  targets.sublists = {}
  local function _18_(self, ch, sublist)
    return rawset(self, __3erepresentative_char(ch), sublist)
  end
  local function _19_(self, ch)
    return rawget(self, __3erepresentative_char(ch))
  end
  setmetatable(targets.sublists, {__newindex = _18_, __index = _19_})
  for _, _20_ in ipairs(targets) do
    local _each_21_ = _20_
    local _each_22_ = _each_21_["chars"]
    local _0 = _each_22_[1]
    local ch2 = _each_22_[2]
    local target = _each_21_
    local ch20 = (ch2 or "\n")
    if not targets.sublists[ch20] then
      targets.sublists[ch20] = {}
    else
    end
    table.insert(targets.sublists[ch20], target)
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
  local _let_24_ = target
  local _let_25_ = _let_24_["chars"]
  local ch1 = _let_25_[1]
  local ch2 = _let_25_[2]
  if target["empty-line?"] then
    return 0
  elseif target["edge-pos?"] then
    return ch1:len()
  else
    return (ch1:len() + ch2:len())
  end
end
local function set_beacon_for_labeled(target, _27_)
  local _arg_28_ = _27_
  local user_given_targets_3f = _arg_28_["user-given-targets?"]
  local aot_3f = _arg_28_["aot?"]
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
  local label = (opts.substitute_chars[target.label] or target.label)
  local text = (label .. pad)
  local virttext
  do
    local _31_ = target["label-state"]
    if (_31_ == "selected") then
      virttext = {{text, hl.group["label-selected"]}}
    elseif (_31_ == "active-primary") then
      virttext = {{text, hl.group["label-primary"]}}
    elseif (_31_ == "active-secondary") then
      virttext = {{text, hl.group["label-secondary"]}}
    elseif (_31_ == "inactive") then
      if (aot_3f and not opts.highlight_unlabeled_phase_one_targets) then
        virttext = {{(" " .. pad), hl.group["label-secondary"]}}
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
  local function _35_(_241)
    return (opts.substitute_chars[_241] or _241)
  end
  virttext = table.concat(map(_35_, target.chars))
  target.beacon = {0, {{virttext, hl.group.match}}}
  return nil
end
local function set_beacon_to_empty_label(target)
  target["beacon"][2][1][1] = " "
  return nil
end
local function resolve_conflicts(targets)
  local unlabeled_match_positions = {}
  local labeled_match_positions = {}
  local label_positions = {}
  for _, target in ipairs(targets) do
    if not target["empty-line?"] then
      local _let_36_ = target.wininfo
      local bufnr = _let_36_["bufnr"]
      local winid = _let_36_["winid"]
      local _let_37_ = target.pos
      local lnum = _let_37_[1]
      local col_ch1 = _let_37_[2]
      local col_ch2 = (col_ch1 + string.len(target.chars[1]))
      if (target.label and target.beacon) then
        local label_offset = target.beacon[1]
        local col_label = (col_ch1 + label_offset)
        local shifted_label_3f = (col_label == col_ch2)
        do
          local _38_ = unlabeled_match_positions[(bufnr .. " " .. winid .. " " .. lnum .. " " .. col_label)]
          if (nil ~= _38_) then
            local other = _38_
            target.beacon = nil
            set_beacon_to_match_hl(other)
          else
          end
        end
        if shifted_label_3f then
          local _40_ = unlabeled_match_positions[(bufnr .. " " .. winid .. " " .. lnum .. " " .. col_ch1)]
          if (nil ~= _40_) then
            local other = _40_
            set_beacon_to_match_hl(other)
          else
          end
        else
        end
        do
          local _43_ = label_positions[(bufnr .. " " .. winid .. " " .. lnum .. " " .. col_label)]
          if (nil ~= _43_) then
            local other = _43_
            target.beacon = nil
            set_beacon_to_empty_label(other)
          else
          end
        end
        label_positions[(bufnr .. " " .. winid .. " " .. lnum .. " " .. col_label)] = target
        labeled_match_positions[(bufnr .. " " .. winid .. " " .. lnum .. " " .. col_ch1)] = target
        if not shifted_label_3f then
          labeled_match_positions[(bufnr .. " " .. winid .. " " .. lnum .. " " .. col_ch2)] = target
        else
        end
      elseif not target.label then
        for _0, key in ipairs({(bufnr .. " " .. winid .. " " .. lnum .. " " .. col_ch1), (bufnr .. " " .. winid .. " " .. lnum .. " " .. col_ch2)}) do
          unlabeled_match_positions[key] = target
          local _46_ = label_positions[key]
          if (nil ~= _46_) then
            local other = _46_
            other.beacon = nil
            set_beacon_to_match_hl(target)
          else
          end
        end
        local col_after = (col_ch2 + string.len(target.chars[2]))
        local _48_ = label_positions[(bufnr .. " " .. winid .. " " .. lnum .. " " .. col_after)]
        if (nil ~= _48_) then
          local other = _48_
          set_beacon_to_match_hl(target)
        else
        end
      else
      end
    else
    end
  end
  return nil
end
local function set_beacons(targets, _52_)
  local _arg_53_ = _52_
  local no_labels_3f = _arg_53_["no-labels?"]
  local user_given_targets_3f = _arg_53_["user-given-targets?"]
  local aot_3f = _arg_53_["aot?"]
  if (no_labels_3f and targets[1].chars) then
    for _, target in ipairs(targets) do
      set_beacon_to_match_hl(target)
    end
    return nil
  else
    for _, target in ipairs(targets) do
      if target.label then
        set_beacon_for_labeled(target, {["user-given-targets?"] = user_given_targets_3f, ["aot?"] = aot_3f})
      elseif (aot_3f and opts.highlight_unlabeled_phase_one_targets) then
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
local function light_up_beacons(targets, _3fstart, _3fend)
  for i = (_3fstart or 1), (_3fend or #targets) do
    local target = targets[i]
    local _57_ = target.beacon
    if ((_G.type(_57_) == "table") and (nil ~= (_57_)[1]) and (nil ~= (_57_)[2])) then
      local offset = (_57_)[1]
      local virttext = (_57_)[2]
      local bufnr = target.wininfo.bufnr
      local _let_58_ = map(dec, target.pos)
      local lnum = _let_58_[1]
      local col = _let_58_[2]
      local id = api.nvim_buf_set_extmark(bufnr, hl.ns, lnum, (col + offset), {virt_text = virttext, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.label})
      table.insert(hl.extmarks, {bufnr, id})
    else
    end
  end
  return nil
end
local state = {args = nil, source_window = nil, ["repeat"] = {in1 = nil, in2 = nil}, dot_repeat = {in1 = nil, in2 = nil, target_idx = nil, backward = nil, inclusive_op = nil, offset = nil}, saved_editor_opts = {}}
local function leap(kwargs)
  local _local_60_ = kwargs
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
  local match_xxx_2a_at_the_end_3f = _local_61_["match-xxx*-at-the-end?"]
  local inclusive_op_3f = _local_61_["inclusive_op"]
  local offset = _local_61_["offset"]
  opts.current_call = (user_given_opts or {})
  do
    local _63_ = opts.current_call.equivalence_classes
    if (nil ~= _63_) then
      opts.current_call.eq_class_of = eq_classes__3emembership_lookup(_63_)
    else
      opts.current_call.eq_class_of = _63_
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
  local hl_affected_windows
  do
    local tbl_17_auto = {curr_winid}
    local i_18_auto = #tbl_17_auto
    for _, winid in ipairs((_3ftarget_windows or {})) do
      local val_19_auto = winid
      if (nil ~= val_19_auto) then
        i_18_auto = (i_18_auto + 1)
        do end (tbl_17_auto)[i_18_auto] = val_19_auto
      else
      end
    end
    hl_affected_windows = tbl_17_auto
  end
  local mode = api.nvim_get_mode().mode
  local op_mode_3f = mode:match("o")
  local change_op_3f = (op_mode_3f and (vim.v.operator == "c"))
  local dot_repeatable_op_3f = (op_mode_3f and directional_3f and (vim.v.operator ~= "y"))
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
  local prompt = {str = ">"}
  local spec_keys
  do
    local function __index(_, k)
      local _71_ = opts.special_keys[k]
      if (nil ~= _71_) then
        local v = _71_
        if ((k == "next_target") or (k == "prev_target")) then
          local _72_ = type(v)
          if (_72_ == "table") then
            local tbl_17_auto = {}
            local i_18_auto = #tbl_17_auto
            for _0, str in ipairs(v) do
              local val_19_auto = replace_keycodes(str)
              if (nil ~= val_19_auto) then
                i_18_auto = (i_18_auto + 1)
                do end (tbl_17_auto)[i_18_auto] = val_19_auto
              else
              end
            end
            return tbl_17_auto
          elseif (_72_ == "string") then
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
  local vars = {["aot?"] = not ((max_phase_one_targets == 0) or empty_label_lists_3f or multi_select_3f or user_given_targets_3f), ["curr-idx"] = 0, errmsg = nil}
  local function get_user_given_targets(targets)
    local targets_2a
    if (type(targets) == "function") then
      targets_2a = targets()
    else
      targets_2a = targets
    end
    if (targets_2a and (#targets_2a > 0)) then
      local wininfo = vim.fn.getwininfo(curr_winid)[1]
      if not (targets_2a)[1].wininfo then
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
  local function expand_to_equivalence_class(_in)
    local chars = get_eq_class_of(_in)
    if chars then
      for i, ch in ipairs(chars) do
        if (ch == "\n") then
          chars[i] = "\\n"
        elseif (ch == "\\") then
          chars[i] = "\\\\"
        else
        end
      end
      return ("\\(" .. table.concat(chars, "\\|") .. "\\)")
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
      pat = (pat1 .. pat2 .. "\\|\\^\\n")
    else
      pat = (pat1 .. pat2)
    end
    local function _83_()
      if opts.case_sensitive then
        return "\\C"
      else
        return "\\c"
      end
    end
    return ("\\V" .. _83_() .. pat)
  end
  local function get_targets(in1, _3fin2)
    local search = require("leap.search")
    local pattern = prepare_pattern(in1, _3fin2)
    local kwargs0 = {["backward?"] = backward_3f, ["match-xxx*-at-the-end?"] = match_xxx_2a_at_the_end_3f, ["target-windows"] = _3ftarget_windows}
    local targets = search["get-targets"](pattern, kwargs0)
    local function _84_()
      vars.errmsg = ("not found: " .. in1 .. (_3fin2 or ""))
      return nil
    end
    return (targets or _84_())
  end
  local function prepare_targets(targets)
    local funny_edge_case_3f
    local function _85_()
      local _86_ = targets
      if ((_G.type(_86_) == "table") and ((_G.type((_86_)[1]) == "table") and ((_G.type(((_86_)[1]).pos) == "table") and (nil ~= (((_86_)[1]).pos)[1]) and (nil ~= (((_86_)[1]).pos)[2]))) and ((_G.type((_86_)[2]) == "table") and ((_G.type(((_86_)[2]).pos) == "table") and (nil ~= (((_86_)[2]).pos)[1]) and (nil ~= (((_86_)[2]).pos)[2])))) then
        local l1 = (((_86_)[1]).pos)[1]
        local c1 = (((_86_)[1]).pos)[2]
        local l2 = (((_86_)[2]).pos)[1]
        local c2 = (((_86_)[2]).pos)[2]
        return ((l1 == l2) and (c1 == (c2 + 2)))
      else
        return nil
      end
    end
    funny_edge_case_3f = (backward_3f and _85_())
    local force_noautojump_3f = (op_mode_3f or multi_select_3f or not directional_3f or user_given_action or funny_edge_case_3f)
    set_autojump(targets, force_noautojump_3f)
    attach_label_set(targets)
    set_labels(targets, multi_select_3f)
    return targets
  end
  local function get_target_with_active_primary_label(sublist, input)
    local res = {}
    for idx, _88_ in ipairs(sublist) do
      local _each_89_ = _88_
      local label = _each_89_["label"]
      local label_state = _each_89_["label-state"]
      local target = _each_89_
      if (next(res) or (label_state == "inactive")) then break end
      if ((label == input) and (label_state == "active-primary")) then
        res = {idx, target}
      else
      end
    end
    return res
  end
  local function update_repeat_state(state_2a)
    if not user_given_targets_3f then
      state["repeat"] = state_2a
      return nil
    else
      return nil
    end
  end
  local function set_dot_repeat(in1, in2, target_idx)
    if (dot_repeatable_op_3f and not (dot_repeat_3f or (type(user_given_targets) == "table"))) then
      state.dot_repeat = {in1 = (not user_given_targets and in1), in2 = (not user_given_targets and in2), callback = user_given_targets, target_idx = target_idx, offset = offset, ["match-xxx*-at-the-end?"] = match_xxx_2a_at_the_end_3f, backward = backward_3f, inclusive_op = inclusive_op_3f}
      return set_dot_repeat_2a()
    else
      return nil
    end
  end
  local jump_to_21
  do
    local first_jump_3f = true
    local function _93_(target)
      local jump = require("leap.jump")
      jump["jump-to!"](target.pos, {winid = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["backward?"] = backward_3f, ["inclusive-op?"] = inclusive_op_3f})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _93_
  end
  local function get_number_of_highlighted_targets()
    local _94_ = opts.max_highlighted_traversal_targets
    if (nil ~= _94_) then
      local group_size = _94_
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
        local _97_ = get_number_of_highlighted_targets()
        if (nil ~= _97_) then
          local _98_ = (_97_ + dec(start))
          if (nil ~= _98_) then
            _end = min(_98_, #targets)
          else
            _end = _98_
          end
        else
          _end = _97_
        end
      else
        _end = nil
      end
      return start, _end
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
    local _104_, _105_ = get_input_by_keymap(prompt)
    if (_104_ == spec_keys.repeat_search) then
      if state["repeat"].in1 then
        vars["aot?"] = false
        return state["repeat"].in1, state["repeat"].in2
      else
        vars.errmsg = "no previous search"
        return nil
      end
    elseif (nil ~= _104_) then
      local in1 = _104_
      return in1
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
    local _110_, _111_ = get_first_pattern_input()
    if ((nil ~= _110_) and (nil ~= _111_)) then
      local in1 = _110_
      local in2 = _111_
      return in1, in2
    elseif ((nil ~= _110_) and (_111_ == nil)) then
      local in1 = _110_
      local _112_ = get_input_by_keymap(prompt)
      if (nil ~= _112_) then
        local in2 = _112_
        return in1, in2
      else
        return nil
      end
    else
      return nil
    end
  end
  local function post_pattern_input_loop(targets, _3fgroup_offset, first_invoc_3f)
    local _7cgroups_7c
    if not targets["label-set"] then
      _7cgroups_7c = 0
    else
      _7cgroups_7c = ceil((#targets / #targets["label-set"]))
    end
    local function display(group_offset)
      local no_labels_3f = empty_label_lists_3f
      if targets["label-set"] then
        set_label_states(targets, {["group-offset"] = group_offset})
      else
      end
      set_beacons(targets, {["aot?"] = vars["aot?"], ["no-labels?"] = no_labels_3f, ["user-given-targets?"] = user_given_targets_3f})
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
    local function loop(group_offset, first_invoc_3f0)
      display(group_offset)
      local _118_ = get_input()
      if (nil ~= _118_) then
        local input = _118_
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
      local _122_, _123_ = post_pattern_input_loop(targets, group_offset, first_invoc_3f)
      if (_122_ == spec_keys.multi_accept) then
        if not empty_3f(selection) then
          return selection
        else
          return loop(targets)
        end
      elseif (_122_ == spec_keys.multi_revert) then
        do
          local _125_ = table.remove(selection)
          if (nil ~= _125_) then
            _125_["label-state"] = nil
          else
          end
        end
        return loop(targets)
      elseif ((nil ~= _122_) and (nil ~= _123_)) then
        local _in = _122_
        local group_offset_2a = _123_
        group_offset = group_offset_2a
        first_invoc_3f = false
        do
          local _127_ = get_target_with_active_primary_label(targets, _in)
          if ((_G.type(_127_) == "table") and true and (nil ~= (_127_)[2])) then
            local _ = (_127_)[1]
            local target = (_127_)[2]
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
  local function traversal_loop(targets, start_idx, _131_)
    local _arg_132_ = _131_
    local no_labels_3f = _arg_132_["no-labels?"]
    local function on_first_invoc()
      if no_labels_3f then
        for _, t in ipairs(targets) do
          t["label-state"] = "inactive"
        end
        return nil
      elseif not empty_3f(opts.safe_labels) then
        local last_labeled = inc(#opts.safe_labels)
        for i = inc(last_labeled), #targets do
          local _133_ = targets[i]
          _133_["label"] = nil
          _133_["beacon"] = nil
        end
        return nil
      else
        return nil
      end
    end
    local function display()
      set_beacons(targets, {["no-labels?"] = no_labels_3f, ["aot?"] = vars["aot?"], ["user-given-targets?"] = user_given_targets_3f})
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
      local _138_ = get_input()
      if (nil ~= _138_) then
        local _in = _138_
        local _139_ = get_new_idx(idx, _in)
        if (nil ~= _139_) then
          local new_idx = _139_
          do
            local _140_
            do
              local t_141_ = targets
              if (nil ~= t_141_) then
                t_141_ = (t_141_)[new_idx]
              else
              end
              if (nil ~= t_141_) then
                t_141_ = (t_141_).chars
              else
              end
              if (nil ~= t_141_) then
                t_141_ = (t_141_)[2]
              else
              end
              _140_ = t_141_
            end
            if (nil ~= _140_) then
              local ch2 = _140_
              state["repeat"].in2 = ch2
            else
            end
          end
          jump_to_21(targets[new_idx])
          return loop(new_idx, false)
        elseif true then
          local _ = _139_
          local _146_ = get_target_with_active_primary_label(targets, _in)
          if ((_G.type(_146_) == "table") and true and (nil ~= (_146_)[2])) then
            local _0 = (_146_)[1]
            local target = (_146_)[2]
            return jump_to_21(target)
          elseif true then
            local _0 = _146_
            return vim.fn.feedkeys(_in, "i")
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
    return loop(start_idx, true)
  end
  local do_action = (user_given_action or jump_to_21)
  exec_user_autocmds("LeapEnter")
  local in1, _3fin2 = nil, nil
  if dot_repeat_3f then
    if state.dot_repeat.callback then
      in1, _3fin2 = true, true
    else
      in1, _3fin2 = state.dot_repeat.in1, state.dot_repeat.in2
    end
  elseif user_given_targets_3f then
    in1, _3fin2 = true, true
  elseif vars["aot?"] then
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
    local _159_ = targets[state.dot_repeat.target_idx]
    if (nil ~= _159_) then
      local target = _159_
      do_action(target)
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    elseif true then
      local _ = _159_
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
  else
  end
  if _3fin2 then
    if empty_label_lists_3f then
      targets["autojump?"] = true
    else
      prepare_targets(targets)
    end
  else
    if (#targets > max_phase_one_targets) then
      vars["aot?"] = false
    else
    end
    populate_sublists(targets)
    for _, sublist in pairs(targets.sublists) do
      prepare_targets(sublist)
    end
    set_initial_label_states(targets)
    set_beacons(targets, {["aot?"] = vars["aot?"]})
  end
  local in2 = (_3fin2 or get_second_pattern_input(targets))
  if not in2 then
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
  if (in2 == spec_keys.next_phase_one_target) then
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
    local in2_2a = target.chars[2]
    update_repeat_state({in1 = in1, in2 = in2_2a})
    do_action(target)
    local can_traverse_3f = (not count and not op_mode_3f and not user_given_action and directional_3f and (#targets > 1))
    if can_traverse_3f then
      traversal_loop(targets, 1, {["no-labels?"] = true})
    else
      set_dot_repeat(in1, in2_2a, n)
    end
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  update_repeat_state({in1 = in1, in2 = in2})
  local targets_2a
  if targets.sublists then
    targets_2a = targets.sublists[in2]
  else
    targets_2a = targets
  end
  if not targets_2a then
    vars.errmsg = ("not found: " .. in1 .. in2)
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
      set_dot_repeat(in1, in2, count)
      do_action((targets_2a)[count])
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    end
  elseif (#targets_2a == 1) then
    set_dot_repeat(in1, in2, 1)
    do_action((targets_2a)[1])
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  if targets_2a["autojump?"] then
    vars["curr-idx"] = 1
    do_action((targets_2a)[1])
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
    local can_traverse_3f = (not op_mode_3f and not user_given_action and directional_3f)
    if can_traverse_3f then
      local new_idx = inc(vars["curr-idx"])
      do_action((targets_2a)[new_idx])
      traversal_loop(targets_2a, new_idx, {["no-labels?"] = (empty_label_lists_3f or not targets_2a["autojump?"])})
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    else
      set_dot_repeat(in1, in2, 1)
      do_action((targets_2a)[1])
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    end
  else
  end
  local _local_193_ = get_target_with_active_primary_label(targets_2a, in_final)
  local idx = _local_193_[1]
  local _ = _local_193_[2]
  if idx then
    set_dot_repeat(in1, in2, idx)
    do_action((targets_2a)[idx])
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  elseif targets_2a["autojump?"] then
    vim.fn.feedkeys(in_final, "i")
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
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
    local _201_ = scope
    if (_201_ == "w") then
      for _, w in ipairs(wins) do
        state.saved_editor_opts[{"w", w, name}] = api.nvim_win_get_option(w, name)
        api.nvim_win_set_option(w, name, val)
      end
    elseif (_201_ == "b") then
      for _, w in ipairs(wins) do
        local b = api.nvim_win_get_buf(w)
        do end (state.saved_editor_opts)[{"b", b, name}] = api.nvim_buf_get_option(b, name)
        api.nvim_buf_set_option(b, name, val)
      end
    elseif true then
      local _ = _201_
      state.saved_editor_opts[name] = api.nvim_get_option(name)
      api.nvim_set_option(name, val)
    else
    end
  end
  return nil
end
local function restore_editor_opts()
  for key, val in pairs(state.saved_editor_opts) do
    local _203_ = key
    if ((_G.type(_203_) == "table") and ((_203_)[1] == "w") and (nil ~= (_203_)[2]) and (nil ~= (_203_)[3])) then
      local w = (_203_)[2]
      local name = (_203_)[3]
      api.nvim_win_set_option(w, name, val)
    elseif ((_G.type(_203_) == "table") and ((_203_)[1] == "b") and (nil ~= (_203_)[2]) and (nil ~= (_203_)[3])) then
      local b = (_203_)[2]
      local name = (_203_)[3]
      api.nvim_buf_set_option(b, name, val)
    elseif (nil ~= _203_) then
      local name = _203_
      api.nvim_set_option(name, val)
    else
    end
  end
  return nil
end
local temporary_editor_opts = {["w.conceallevel"] = 0, ["g.scrolloff"] = 0, ["w.scrolloff"] = 0, ["g.sidescrolloff"] = 0, ["w.sidescrolloff"] = 0, ["b.modeline"] = false}
local function _205_()
  return set_editor_opts(temporary_editor_opts)
end
api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _205_, group = "LeapDefault"})
local function _206_()
  return restore_editor_opts()
end
api.nvim_create_autocmd("User", {pattern = "LeapLeave", callback = _206_, group = "LeapDefault"})
return {state = state, leap = leap}
