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
local function should_autojump(targets, force_noautojump_3f)
  return (not (force_noautojump_3f or empty_3f(opts.safe_labels)) and (empty_3f(opts.labels) or (#opts.safe_labels >= dec(#targets))))
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
    local label_set = _local_7_["label-set"]
    for i, target in ipairs(targets) do
      if not target["no-label"] then
        local _8_ = (i % #label_set)
        if (_8_ == 0) then
          target.label = label_set[#label_set]
        elseif (nil ~= _8_) then
          local n = _8_
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
local function set_label_states(targets, _12_)
  local _arg_13_ = _12_
  local group_offset = _arg_13_["group-offset"]
  local _7clabel_set_7c = #targets["label-set"]
  local offset = (group_offset * _7clabel_set_7c)
  local primary_start = (offset + 1)
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
local function populate_sublists(targets)
  targets.sublists = {}
  local function _16_(self, ch, sublist)
    return rawset(self, __3erepresentative_char(ch), sublist)
  end
  local function _17_(self, ch)
    return rawget(self, __3erepresentative_char(ch))
  end
  setmetatable(targets.sublists, {__newindex = _16_, __index = _17_})
  for _, _18_ in ipairs(targets) do
    local _each_19_ = _18_
    local _each_20_ = _each_19_["chars"]
    local _0 = _each_20_[1]
    local ch2 = _each_20_[2]
    local target = _each_19_
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
  local _let_22_ = target
  local _let_23_ = _let_22_["chars"]
  local ch1 = _let_23_[1]
  local ch2 = _let_23_[2]
  if target["empty-line?"] then
    return 0
  elseif target["edge-pos?"] then
    return ch1:len()
  else
    return (ch1:len() + ch2:len())
  end
end
local function set_beacon_for_labeled(target)
  local offset = (target["beacon-offset"] or 0)
  local pad = (target.pad or "")
  local label = (opts.substitute_chars[target.label] or target.label)
  local text = (target.text or (label .. pad))
  local virttext
  do
    local _25_ = target["label-state"]
    if (_25_ == "selected") then
      virttext = {{text, hl.group["label-selected"]}}
    elseif (_25_ == "active-primary") then
      virttext = {{text, hl.group["label-primary"]}}
    elseif (_25_ == "active-secondary") then
      virttext = {{text, hl.group["label-secondary"]}}
    elseif (_25_ == "inactive") then
      if target.text then
        virttext = {{target.text, hl.group["label-secondary"]}}
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
  local function _29_(_241)
    return (opts.substitute_chars[_241] or _241)
  end
  virttext = table.concat(map(_29_, target.chars))
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
      local _let_30_ = target.wininfo
      local bufnr = _let_30_["bufnr"]
      local winid = _let_30_["winid"]
      local _let_31_ = target.pos
      local lnum = _let_31_[1]
      local col_ch1 = _let_31_[2]
      local col_ch2 = (col_ch1 + string.len(target.chars[1]))
      if (target.label and target.beacon) then
        local label_offset = target.beacon[1]
        local col_label = (col_ch1 + label_offset)
        local shifted_label_3f = (col_label == col_ch2)
        do
          local _32_ = unlabeled_match_positions[(bufnr .. " " .. winid .. " " .. lnum .. " " .. col_label)]
          if (nil ~= _32_) then
            local other = _32_
            target.beacon = nil
            set_beacon_to_match_hl(other)
          else
          end
        end
        if shifted_label_3f then
          local _34_ = unlabeled_match_positions[(bufnr .. " " .. winid .. " " .. lnum .. " " .. col_ch1)]
          if (nil ~= _34_) then
            local other = _34_
            set_beacon_to_match_hl(other)
          else
          end
        else
        end
        do
          local _37_ = label_positions[(bufnr .. " " .. winid .. " " .. lnum .. " " .. col_label)]
          if (nil ~= _37_) then
            local other = _37_
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
          local _40_ = label_positions[key]
          if (nil ~= _40_) then
            local other = _40_
            other.beacon = nil
            set_beacon_to_match_hl(target)
          else
          end
        end
        local col_after = (col_ch2 + string.len(target.chars[2]))
        local _42_ = label_positions[(bufnr .. " " .. winid .. " " .. lnum .. " " .. col_after)]
        if (nil ~= _42_) then
          local other = _42_
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
local function set_beacons(targets, _46_)
  local _arg_47_ = _46_
  local no_labels_3f = _arg_47_["no-labels?"]
  local aot_3f = _arg_47_["aot?"]
  if (no_labels_3f and targets[1].chars) then
    for _, target in ipairs(targets) do
      set_beacon_to_match_hl(target)
    end
    return nil
  else
    for _, target in ipairs(targets) do
      if target.label then
        set_beacon_for_labeled(target)
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
local target_state = {["backdrop-ranges"] = nil, ["hl-affected-windows"] = nil}
local function with_highlight_chores(task)
  local hl_affected_windows = (target_state["hl-affected-windows"] or {})
  local backdrop_ranges = (target_state["backdrop-ranges"] or {})
  hl:cleanup((hl_affected_windows or {}))
  hl["apply-backdrop"](hl, (backdrop_ranges or {}))
  task()
  hl["highlight-cursor"](hl)
  return vim.cmd("redraw")
end
local function pre_exit()
  target_state["hl-affected-windows"] = nil
  target_state["backdrop-ranges"] = nil
  return nil
end
local function prebeacon(opts0)
  target_state["backdrop-ranges"] = opts0["backdrop-ranges"]
  target_state["hl-affected-windows"] = opts0["hl-affected-windows"]
  local function _51_()
  end
  return with_highlight_chores(_51_)
end
local function light_up_beacons(targets, opts0)
  local opts1 = (opts0 or {})
  for i = (opts1.start or 1), (opts1["end"] or #targets) do
    local target = targets[i]
    local _52_ = target.beacon
    if ((_G.type(_52_) == "table") and (nil ~= (_52_)[1]) and (nil ~= (_52_)[2])) then
      local offset = (_52_)[1]
      local virttext = (_52_)[2]
      local bufnr = target.wininfo.bufnr
      local _let_53_ = map(dec, target.pos)
      local lnum = _let_53_[1]
      local col = _let_53_[2]
      local id = api.nvim_buf_set_extmark(bufnr, hl.ns, lnum, (col + offset), {virt_text = virttext, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.label})
      table.insert(hl.extmarks, {bufnr, id})
    else
    end
  end
  return nil
end
local state = {args = nil, source_window = nil, ["repeat"] = {in1 = nil, in2 = nil}, dot_repeat = {in1 = nil, in2 = nil, target_idx = nil, backward = nil, inclusive_op = nil, offset = nil}, saved_editor_opts = {}}
local function leap(kwargs)
  local _local_55_ = kwargs
  local dot_repeat_3f = _local_55_["dot_repeat"]
  local target_windows = _local_55_["target_windows"]
  local user_given_opts = _local_55_["opts"]
  local user_given_targets = _local_55_["targets"]
  local user_given_action = _local_55_["action"]
  local multi_select_3f = _local_55_["multiselect"]
  local function _57_()
    if dot_repeat_3f then
      return state.dot_repeat
    else
      return kwargs
    end
  end
  local _local_56_ = _57_()
  local backward_3f = _local_56_["backward"]
  local match_xxx_2a_at_the_end_3f = _local_56_["match-xxx*-at-the-end?"]
  local inclusive_op_3f = _local_56_["inclusive_op"]
  local offset = _local_56_["offset"]
  opts.current_call = (user_given_opts or {})
  do
    local _58_ = opts.current_call.equivalence_classes
    if (nil ~= _58_) then
      opts.current_call.eq_class_of = eq_classes__3emembership_lookup(_58_)
    else
      opts.current_call.eq_class_of = _58_
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
      local _66_ = opts.special_keys[k]
      if (nil ~= _66_) then
        local v = _66_
        if ((k == "next_target") or (k == "prev_target")) then
          local _67_ = type(v)
          if (_67_ == "table") then
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
          elseif (_67_ == "string") then
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
  local backdrop_ranges = {}
  if (pcall(api.nvim_get_hl_by_name, hl.group.backdrop, false) and not count) then
    if _3ftarget_windows then
      for _, winid in ipairs(_3ftarget_windows) do
        local wininfo = vim.fn.getwininfo(winid)[1]
        local range = {bufnr = wininfo.bufnr, startrow = dec(wininfo.topline), startcol = 0, endrow = dec(wininfo.botline), endcol = -1}
        table.insert(backdrop_ranges, range)
      end
    else
      local _let_72_ = map(dec, {vim.fn.line("."), vim.fn.col(".")})
      local curline = _let_72_[1]
      local curcol = _let_72_[2]
      local _let_73_ = {dec(vim.fn.line("w0")), dec(vim.fn.line("w$"))}
      local win_top = _let_73_[1]
      local win_bot = _let_73_[2]
      local function _75_()
        if backward_3f then
          return {win_top, 0, curline, curcol}
        else
          return {curline, inc(curcol), win_bot, -1}
        end
      end
      local _let_74_ = _75_()
      local startrow = _let_74_[1]
      local startcol = _let_74_[2]
      local endrow = _let_74_[3]
      local endcol = _let_74_[4]
      local wininfo = (vim.fn.getwininfo(0))[1]
      local range = {bufnr = wininfo.bufnr, startrow = startrow, startcol = startcol, endrow = endrow, endcol = endcol}
      table.insert(backdrop_ranges, range)
    end
  else
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
    local function _84_()
      if opts.case_sensitive then
        return "\\C"
      else
        return "\\c"
      end
    end
    return ("\\V" .. _84_() .. pat)
  end
  local function get_targets(in1, _3fin2)
    local search = require("leap.search")
    local pattern = prepare_pattern(in1, _3fin2)
    local kwargs0 = {["backward?"] = backward_3f, ["match-xxx*-at-the-end?"] = match_xxx_2a_at_the_end_3f, ["target-windows"] = _3ftarget_windows}
    local targets = search["get-targets"](pattern, kwargs0)
    local function _85_()
      vars.errmsg = ("not found: " .. in1 .. (_3fin2 or ""))
      return nil
    end
    return (targets or _85_())
  end
  local function should_autojump_3f(targets)
    local funny_edge_case_3f
    local function _86_()
      if ((_G.type(targets) == "table") and ((_G.type(targets[1]) == "table") and ((_G.type((targets[1]).pos) == "table") and (nil ~= ((targets[1]).pos)[1]) and (nil ~= ((targets[1]).pos)[2]))) and ((_G.type(targets[2]) == "table") and ((_G.type((targets[2]).pos) == "table") and (nil ~= ((targets[2]).pos)[1]) and (nil ~= ((targets[2]).pos)[2])))) then
        local l1 = ((targets[1]).pos)[1]
        local c1 = ((targets[1]).pos)[2]
        local l2 = ((targets[2]).pos)[1]
        local c2 = ((targets[2]).pos)[2]
        return ((l1 == l2) and (c1 == (c2 + 2)))
      else
        return nil
      end
    end
    funny_edge_case_3f = (backward_3f and _86_())
    local force_noautojump_3f = (op_mode_3f or multi_select_3f or not directional_3f or user_given_action or funny_edge_case_3f)
    return should_autojump(force_noautojump_3f, targets)
  end
  local function prepare_targets(targets)
    targets["autojump?"] = should_autojump_3f(targets)
    attach_label_set(targets)
    local first_target = targets[1]
    if targets["autojump?"] then
      first_target["no-label"] = true
    else
    end
    return set_labels(multi_select_3f, targets)
  end
  local function get_target_with_active_primary_label(sublist, input)
    local res = {}
    for idx, _89_ in ipairs(sublist) do
      local _each_90_ = _89_
      local label = _each_90_["label"]
      local label_state = _each_90_["label-state"]
      local target = _each_90_
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
    local function _94_(target)
      local jump = require("leap.jump")
      jump["jump-to!"](target.pos, {winid = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["backward?"] = backward_3f, ["inclusive-op?"] = inclusive_op_3f})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _94_
  end
  local function get_number_of_highlighted_targets()
    local _95_ = opts.max_highlighted_traversal_targets
    if (nil ~= _95_) then
      local group_size = _95_
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
        local _98_ = get_number_of_highlighted_targets()
        if (nil ~= _98_) then
          local _99_ = (_98_ + dec(start))
          if (nil ~= _99_) then
            _end = min(_99_, #targets)
          else
            _end = _99_
          end
        else
          _end = _98_
        end
      else
        _end = nil
      end
      return start, _end
    end
  end
  local function get_first_pattern_input()
    local function _104_()
      return echo("")
    end
    with_highlight_chores(_104_)
    local _105_, _106_ = get_input_by_keymap(prompt)
    if (_105_ == spec_keys.repeat_search) then
      if state["repeat"].in1 then
        vars["aot?"] = false
        return state["repeat"].in1, state["repeat"].in2
      else
        vars.errmsg = "no previous search"
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
    if ((#targets <= max_phase_one_targets) and not count) then
      local function _109_()
        return light_up_beacons(targets)
      end
      with_highlight_chores(_109_)
    else
    end
    return get_input_by_keymap(prompt)
  end
  local function get_full_pattern_input()
    local _111_, _112_ = get_first_pattern_input()
    if ((nil ~= _111_) and (nil ~= _112_)) then
      local in1 = _111_
      local in2 = _112_
      return in1, in2
    elseif ((nil ~= _111_) and (_112_ == nil)) then
      local in1 = _111_
      local _113_ = get_input_by_keymap(prompt)
      if (nil ~= _113_) then
        local in2 = _113_
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
      set_beacons(targets, {["aot?"] = vars["aot?"], ["no-labels?"] = no_labels_3f})
      local start, _end = get_highlighted_idx_range(targets, no_labels_3f)
      local function _118_()
        return light_up_beacons(targets, {start = start, ["end"] = _end})
      end
      return with_highlight_chores(_118_)
    end
    local function loop(group_offset, first_invoc_3f0)
      display(group_offset)
      local _119_ = get_input()
      if (nil ~= _119_) then
        local input = _119_
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
      local _123_, _124_ = post_pattern_input_loop(targets, group_offset, first_invoc_3f)
      if (_123_ == spec_keys.multi_accept) then
        if not empty_3f(selection) then
          return selection
        else
          return loop(targets)
        end
      elseif (_123_ == spec_keys.multi_revert) then
        do
          local _126_ = table.remove(selection)
          if (nil ~= _126_) then
            _126_["label-state"] = nil
          else
          end
        end
        return loop(targets)
      elseif ((nil ~= _123_) and (nil ~= _124_)) then
        local _in = _123_
        local group_offset_2a = _124_
        group_offset = group_offset_2a
        first_invoc_3f = false
        do
          local _128_ = get_target_with_active_primary_label(targets, _in)
          if ((_G.type(_128_) == "table") and true and (nil ~= (_128_)[2])) then
            local _ = (_128_)[1]
            local target = (_128_)[2]
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
  local function traversal_loop(targets, start_idx, _132_)
    local _arg_133_ = _132_
    local no_labels_3f = _arg_133_["no-labels?"]
    local function on_first_invoc()
      if no_labels_3f then
        for _, t in ipairs(targets) do
          t["label-state"] = "inactive"
        end
        return nil
      elseif not empty_3f(opts.safe_labels) then
        local last_labeled = inc(#opts.safe_labels)
        for i = inc(last_labeled), #targets do
          local _134_ = targets[i]
          _134_["label"] = nil
          _134_["beacon"] = nil
        end
        return nil
      else
        return nil
      end
    end
    local function display()
      set_beacons(targets, {["no-labels?"] = no_labels_3f, ["aot?"] = vars["aot?"]})
      local start, _end = get_highlighted_idx_range(targets, no_labels_3f)
      local function _136_()
        return light_up_beacons(targets, {start = start, ["end"] = _end})
      end
      return with_highlight_chores(_136_)
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
      local _139_ = get_input()
      if (nil ~= _139_) then
        local _in = _139_
        local _140_ = get_new_idx(idx, _in)
        if (nil ~= _140_) then
          local new_idx = _140_
          do
            local _141_
            do
              local t_142_ = targets
              if (nil ~= t_142_) then
                t_142_ = (t_142_)[new_idx]
              else
              end
              if (nil ~= t_142_) then
                t_142_ = (t_142_).chars
              else
              end
              if (nil ~= t_142_) then
                t_142_ = (t_142_)[2]
              else
              end
              _141_ = t_142_
            end
            if (nil ~= _141_) then
              local ch2 = _141_
              state["repeat"].in2 = ch2
            else
            end
          end
          jump_to_21(targets[new_idx])
          return loop(new_idx, false)
        elseif true then
          local _ = _140_
          local _147_ = get_target_with_active_primary_label(targets, _in)
          if ((_G.type(_147_) == "table") and true and (nil ~= (_147_)[2])) then
            local _0 = (_147_)[1]
            local target = (_147_)[2]
            return jump_to_21(target)
          elseif true then
            local _0 = _147_
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
  prebeacon({["backdrop-ranges"] = backdrop_ranges, ["hl-affected-windows"] = hl_affected_windows})
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
    hl:cleanup(target_state["hl-affected-windows"])
    pre_exit()
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
    hl:cleanup(target_state["hl-affected-windows"])
    pre_exit()
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  if dot_repeat_3f then
    local _160_ = targets[state.dot_repeat.target_idx]
    if (nil ~= _160_) then
      local target = _160_
      do_action(target)
      hl:cleanup(target_state["hl-affected-windows"])
      pre_exit()
      exec_user_autocmds("LeapLeave")
      return
    elseif true then
      local _ = _160_
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      if vars.errmsg then
        echo(vars.errmsg)
      else
      end
      hl:cleanup(target_state["hl-affected-windows"])
      pre_exit()
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
      for _, target in ipairs(targets) do
        target["beacon-offset"] = 0
      end
    else
    end
    populate_sublists(targets)
    for _, sublist in pairs(targets.sublists) do
      prepare_targets(sublist)
    end
    set_initial_label_states(targets)
    for _, target in ipairs(targets) do
      if vars["aot?"] then
        target["beacon-offset"] = get_label_offset(target)
        if (not opts.highlight_unlabeled_phase_one_targets and (target["label-state"] == "inactive")) then
          target.text = " "
        else
        end
      else
        if not user_given_targets_3f then
          target.pad = " "
        else
        end
      end
    end
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
    hl:cleanup(target_state["hl-affected-windows"])
    pre_exit()
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
      hl:cleanup(target_state["hl-affected-windows"])
      pre_exit()
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
    hl:cleanup(target_state["hl-affected-windows"])
    pre_exit()
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
    hl:cleanup(target_state["hl-affected-windows"])
    pre_exit()
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  if multi_select_3f then
    do
      local _183_ = multi_select_loop(targets_2a)
      if (nil ~= _183_) then
        local targets_2a_2a = _183_
        local function _184_()
          return light_up_beacons(targets_2a_2a)
        end
        with_highlight_chores(_184_)
        do_action(targets_2a_2a)
      else
      end
    end
    hl:cleanup(target_state["hl-affected-windows"])
    pre_exit()
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
      hl:cleanup(target_state["hl-affected-windows"])
      pre_exit()
      exec_user_autocmds("LeapLeave")
      return
    else
      set_dot_repeat(in1, in2, count)
      do_action((targets_2a)[count])
      hl:cleanup(target_state["hl-affected-windows"])
      pre_exit()
      exec_user_autocmds("LeapLeave")
      return
    end
  elseif (#targets_2a == 1) then
    set_dot_repeat(in1, in2, 1)
    do_action((targets_2a)[1])
    hl:cleanup(target_state["hl-affected-windows"])
    pre_exit()
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
    hl:cleanup(target_state["hl-affected-windows"])
    pre_exit()
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
      hl:cleanup(target_state["hl-affected-windows"])
      pre_exit()
      exec_user_autocmds("LeapLeave")
      return
    else
      set_dot_repeat(in1, in2, 1)
      do_action((targets_2a)[1])
      hl:cleanup(target_state["hl-affected-windows"])
      pre_exit()
      exec_user_autocmds("LeapLeave")
      return
    end
  else
  end
  local _local_197_ = get_target_with_active_primary_label(targets_2a, in_final)
  local idx = _local_197_[1]
  local _ = _local_197_[2]
  if idx then
    set_dot_repeat(in1, in2, idx)
    do_action((targets_2a)[idx])
    hl:cleanup(target_state["hl-affected-windows"])
    pre_exit()
    exec_user_autocmds("LeapLeave")
    return
  elseif targets_2a["autojump?"] then
    vim.fn.feedkeys(in_final, "i")
    hl:cleanup(target_state["hl-affected-windows"])
    pre_exit()
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
    hl:cleanup(target_state["hl-affected-windows"])
    pre_exit()
    exec_user_autocmds("LeapLeave")
    return
  end
  return nil
end
do
  local _201_ = opts.default.equivalence_classes
  if (nil ~= _201_) then
    opts.default.eq_class_of = eq_classes__3emembership_lookup(_201_)
  else
    opts.default.eq_class_of = _201_
  end
end
api.nvim_create_augroup("LeapDefault", {})
hl["init-highlight"](hl)
local function _203_()
  return hl["init-highlight"](hl)
end
api.nvim_create_autocmd("ColorScheme", {callback = _203_, group = "LeapDefault"})
local function set_editor_opts(t)
  state.saved_editor_opts = {}
  local wins = (state.args.target_windows or {state.source_window})
  for opt, val in pairs(t) do
    local _let_204_ = vim.split(opt, ".", {plain = true})
    local scope = _let_204_[1]
    local name = _let_204_[2]
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
    elseif true then
      local _ = scope
      state.saved_editor_opts[name] = api.nvim_get_option(name)
      api.nvim_set_option(name, val)
    else
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
local function _207_()
  return set_editor_opts(temporary_editor_opts)
end
api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _207_, group = "LeapDefault"})
local function _208_()
  return restore_editor_opts()
end
api.nvim_create_autocmd("User", {pattern = "LeapLeave", callback = _208_, group = "LeapDefault"})
return {state = state, leap = leap}
