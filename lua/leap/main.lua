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
local get_input = _local_1_["get-input"]
local get_input_by_keymap = _local_1_["get-input-by-keymap"]
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
local function set_autojump(targets, force_noautojump_3f)
  targets["autojump?"] = (not (force_noautojump_3f or empty_3f(opts.safe_labels)) and (empty_3f(opts.labels) or (#opts.safe_labels >= dec(#targets))))
  return nil
end
local function attach_label_set(targets)
  local _5_
  if empty_3f(opts.labels) then
    _5_ = opts.safe_labels
  elseif empty_3f(opts.safe_labels) then
    _5_ = opts.labels
  elseif targets["autojump?"] then
    _5_ = opts.safe_labels
  else
    _5_ = opts.labels
  end
  targets["label-set"] = _5_
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
        local _10_
        do
          local _9_ = (i_2a % #label_set)
          if (_9_ == 0) then
            _10_ = label_set[#label_set]
          elseif (nil ~= _9_) then
            local n = _9_
            _10_ = label_set[n]
          else
            _10_ = nil
          end
        end
        target["label"] = _10_
      else
      end
    end
    return nil
  else
    return nil
  end
end
local function set_label_states(targets, _16_)
  local _arg_17_ = _16_
  local group_offset = _arg_17_["group-offset"]
  local _7clabel_set_7c = #targets["label-set"]
  local offset = (group_offset * _7clabel_set_7c)
  local primary_start
  local function _18_()
    if targets["autojump?"] then
      return 2
    else
      return 1
    end
  end
  primary_start = (offset + _18_())
  local primary_end = (primary_start + dec(_7clabel_set_7c))
  local secondary_start = inc(primary_end)
  local secondary_end = (primary_end + _7clabel_set_7c)
  for i, target in ipairs(targets) do
    if (target.label and (target["label-state"] ~= "selected")) then
      local _19_
      if (function(_20_,_21_,_22_) return (_20_ <= _21_) and (_21_ <= _22_) end)(primary_start,i,primary_end) then
        _19_ = "active-primary"
      elseif (function(_23_,_24_,_25_) return (_23_ <= _24_) and (_24_ <= _25_) end)(secondary_start,i,secondary_end) then
        _19_ = "active-secondary"
      elseif (i > secondary_end) then
        _19_ = "inactive"
      else
        _19_ = nil
      end
      target["label-state"] = _19_
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
  local function _31_()
    local __3ecommon_key
    local function _28_(_241)
      local function _29_()
        if not opts.case_sensitive then
          return _241:lower()
        else
          return nil
        end
      end
      return (opts.eq_class_of[_241] or _29_() or _241)
    end
    __3ecommon_key = _28_
    local function _32_(t, k)
      return rawget(t, __3ecommon_key(k))
    end
    local function _33_(t, k, v)
      return rawset(t, __3ecommon_key(k), v)
    end
    return {__index = _32_, __newindex = _33_}
  end
  targets["sublists"] = setmetatable({}, _31_())
  for _, _34_ in ipairs(targets) do
    local _each_35_ = _34_
    local _each_36_ = _each_35_["chars"]
    local _0 = _each_36_[1]
    local ch2 = _each_36_[2]
    local target = _each_35_
    if not targets.sublists[ch2] then
      targets.sublists[ch2] = {}
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
  local _let_38_ = target
  local _let_39_ = _let_38_["chars"]
  local ch1 = _let_39_[1]
  local ch2 = _let_39_[2]
  local edge_pos_3f = _let_38_["edge-pos?"]
  local function _40_()
    if edge_pos_3f then
      return 0
    else
      return ch2:len()
    end
  end
  return (ch1:len() + _40_())
end
local function set_beacon_for_labeled(target, _41_)
  local _arg_42_ = _41_
  local user_given_targets_3f = _arg_42_["user-given-targets?"]
  local aot_3f = _arg_42_["aot?"]
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
    local _45_ = target["label-state"]
    if (_45_ == "selected") then
      virttext = {{text, hl.group["label-selected"]}}
    elseif (_45_ == "active-primary") then
      virttext = {{text, hl.group["label-primary"]}}
    elseif (_45_ == "active-secondary") then
      virttext = {{text, hl.group["label-secondary"]}}
    elseif (_45_ == "inactive") then
      if (aot_3f and not opts.highlight_unlabeled) then
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
  local _48_
  if virttext then
    _48_ = {offset, virttext}
  else
    _48_ = nil
  end
  target["beacon"] = _48_
  return nil
end
local function set_beacon_to_match_hl(target)
  target["beacon"] = {0, {{table.concat(target.chars), hl.group.match}}}
  return nil
end
local function set_beacon_to_empty_label(target)
  target["beacon"][2][1][1] = " "
  return nil
end
local function resolve_conflicts(targets)
  local unlabeled_match_positions = {}
  local label_positions = {}
  for _, target in ipairs(targets) do
    local _local_50_ = target
    local _local_51_ = _local_50_["pos"]
    local lnum = _local_51_[1]
    local col = _local_51_[2]
    local _local_52_ = _local_50_["chars"]
    local ch1 = _local_52_[1]
    local _0 = _local_52_[2]
    local _local_53_ = _local_50_["wininfo"]
    local bufnr = _local_53_["bufnr"]
    local winid = _local_53_["winid"]
    if target.label then
      if target.beacon then
        local label_offset = target.beacon[1]
        local key = (bufnr .. " " .. winid .. " " .. lnum .. " " .. (col + label_offset))
        do
          local _54_ = unlabeled_match_positions[key]
          if (nil ~= _54_) then
            local other = _54_
            target.beacon = nil
            set_beacon_to_match_hl(other)
          elseif true then
            local _1 = _54_
            local _55_ = label_positions[key]
            if (nil ~= _55_) then
              local other = _55_
              target.beacon = nil
              set_beacon_to_empty_label(other)
            else
            end
          else
          end
        end
        label_positions[key] = target
      else
      end
    else
      for _1, key in ipairs({(bufnr .. " " .. winid .. " " .. lnum .. " " .. col), (bufnr .. " " .. winid .. " " .. lnum .. " " .. (col + ch1:len()))}) do
        do
          local _59_ = label_positions[key]
          if (nil ~= _59_) then
            local other = _59_
            other.beacon = nil
            set_beacon_to_match_hl(target)
          else
          end
        end
        unlabeled_match_positions[key] = target
      end
    end
  end
  return nil
end
local function set_beacons(targets, _62_)
  local _arg_63_ = _62_
  local no_labels_3f = _arg_63_["no-labels?"]
  local user_given_targets_3f = _arg_63_["user-given-targets?"]
  local aot_3f = _arg_63_["aot?"]
  if (no_labels_3f and targets[1].chars) then
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
    local _67_ = target.beacon
    if ((_G.type(_67_) == "table") and (nil ~= (_67_)[1]) and (nil ~= (_67_)[2])) then
      local offset = (_67_)[1]
      local virttext = (_67_)[2]
      local bufnr = target.wininfo.bufnr
      local _let_68_ = map(dec, target.pos)
      local lnum = _let_68_[1]
      local col = _let_68_[2]
      local id = api.nvim_buf_set_extmark(bufnr, hl.ns, lnum, (col + offset), {virt_text = virttext, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.label})
      table.insert(hl.extmarks, {bufnr, id})
    else
    end
  end
  return nil
end
local state = {args = nil, source_window = nil, ["repeat"] = {in1 = nil, in2 = nil}, dot_repeat = {in1 = nil, in2 = nil, target_idx = nil, backward = nil, inclusive_op = nil, offset = nil}, saved_editor_opts = {}}
local function leap(kwargs)
  local _let_70_ = kwargs
  local dot_repeat_3f = _let_70_["dot_repeat"]
  local target_windows = _let_70_["target_windows"]
  local user_given_opts = _let_70_["opts"]
  local user_given_targets = _let_70_["targets"]
  local user_given_action = _let_70_["action"]
  local multi_select_3f = _let_70_["multiselect"]
  local function _72_()
    if dot_repeat_3f then
      return state.dot_repeat
    else
      return kwargs
    end
  end
  local _let_71_ = _72_()
  local backward_3f = _let_71_["backward"]
  local inclusive_op_3f = _let_71_["inclusive_op"]
  local offset = _let_71_["offset"]
  local _
  state.args = kwargs
  _ = nil
  local _0
  opts.current_call = (user_given_opts or {})
  _0 = nil
  local id__3ewininfo
  local function _73_(_241)
    return (vim.fn.getwininfo(_241))[1]
  end
  id__3ewininfo = _73_
  local curr_winid = vim.fn.win_getid()
  local _1
  state.source_window = curr_winid
  _1 = nil
  local curr_win = id__3ewininfo(curr_winid)
  local _3ftarget_windows
  do
    local _74_ = target_windows
    if (_74_ ~= nil) then
      _3ftarget_windows = map(id__3ewininfo, _74_)
    else
      _3ftarget_windows = _74_
    end
  end
  local hl_affected_windows
  do
    local tbl_15_auto = {curr_win}
    local i_16_auto = #tbl_15_auto
    for _2, w in ipairs((_3ftarget_windows or {})) do
      local val_17_auto = w
      if (nil ~= val_17_auto) then
        i_16_auto = (i_16_auto + 1)
        do end (tbl_15_auto)[i_16_auto] = val_17_auto
      else
      end
    end
    hl_affected_windows = tbl_15_auto
  end
  local directional_3f = not target_windows
  local mode = api.nvim_get_mode().mode
  local op_mode_3f = mode:match("o")
  local change_op_3f = (op_mode_3f and (vim.v.operator == "c"))
  local dot_repeatable_op_3f = (op_mode_3f and directional_3f and (vim.v.operator ~= "y"))
  local no_labels_3f = (empty_3f(opts.labels) and empty_3f(opts.safe_labels))
  local count
  if not directional_3f then
    count = nil
  elseif (vim.v.count == 0) then
    if (op_mode_3f and no_labels_3f) then
      count = 1
    else
      count = nil
    end
  else
    count = vim.v.count
  end
  local force_noautojump_3f = (op_mode_3f or multi_select_3f or not directional_3f or user_given_action)
  local max_aot_targets = (opts.max_aot_targets or math.huge)
  local user_given_targets_3f = user_given_targets
  local prompt = {str = ">"}
  local spec_keys
  local function _79_(_2, k)
    local _80_ = opts.special_keys[k]
    if (nil ~= _80_) then
      return replace_keycodes(_80_)
    else
      return _80_
    end
  end
  spec_keys = setmetatable({}, {__index = _79_})
  if (target_windows and empty_3f(target_windows)) then
    echo("no targetable windows")
    return
  else
  end
  if (not directional_3f and no_labels_3f) then
    echo("no labels to use")
    return
  else
  end
  local aot_3f = not ((max_aot_targets == 0) or count or no_labels_3f or multi_select_3f or user_given_targets_3f)
  local function echo_not_found(s)
    return echo(("not found: " .. s))
  end
  local function fill_wininfo(targets)
    if not empty_3f(targets) then
      if not targets[1].wininfo then
        for _2, t in ipairs(targets) do
          t.wininfo = curr_win
        end
      else
      end
      return targets
    else
      return nil
    end
  end
  local function get_user_given_targets(targets)
    local _86_
    do
      local _87_ = targets
      if (_G.type(_87_) == "table") then
        local tbl = _87_
        _86_ = tbl
      elseif (nil ~= _87_) then
        local func = _87_
        _86_ = func()
      else
        _86_ = nil
      end
    end
    if (nil ~= _86_) then
      return fill_wininfo(_86_)
    else
      return _86_
    end
  end
  local function expand_to_equivalence_class(_in)
    local _90_ = opts.eq_class_of[_in]
    if (nil ~= _90_) then
      local chars = _90_
      local chars_2a
      local function _91_(_241)
        local _92_ = _241
        if (_92_ == "\n") then
          return "\\n"
        elseif (_92_ == "\\") then
          return "\\\\"
        elseif true then
          local _2 = _92_
          return _241
        else
          return nil
        end
      end
      chars_2a = map(_91_, chars)
      return ("\\(" .. table.concat(chars_2a, "\\|") .. "\\)")
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
    return ("\\V" .. _95_() .. (expand_to_equivalence_class(in1) or in1:gsub("\\", "\\\\")) .. (expand_to_equivalence_class(_3fin2) or _3fin2 or "\\_."))
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
      local function _100_()
        if user_given_targets then
          return {callback = user_given_targets}
        else
          return {in1 = in1, in2 = in2}
        end
      end
      state.dot_repeat = vim.tbl_extend("error", {target_idx = target_idx, backward = backward_3f, inclusive_op = inclusive_op_3f, offset = offset}, _100_())
      return set_dot_repeat_2a()
    else
      return nil
    end
  end
  local jump_to_21
  do
    local first_jump_3f = true
    local function _102_(target)
      local jump = require("leap.jump")
      jump["jump-to!"](target.pos, {winid = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["backward?"] = backward_3f, ["inclusive-op?"] = inclusive_op_3f})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _102_
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
    local _104_
    local function _105_()
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
    _104_ = (get_input_by_keymap(prompt) or _105_())
    if (_104_ == spec_keys.repeat_search) then
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
    elseif (nil ~= _104_) then
      local in1 = _104_
      return in1
    else
      return nil
    end
  end
  local function get_second_pattern_input(targets)
    if (#targets <= max_aot_targets) then
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
    local function _112_()
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
    return (get_input_by_keymap(prompt) or _112_())
  end
  local function get_full_pattern_input()
    local _114_, _115_ = get_first_pattern_input()
    if ((nil ~= _114_) and (nil ~= _115_)) then
      local in1 = _114_
      local in2 = _115_
      return in1, in2
    elseif ((nil ~= _114_) and (_115_ == nil)) then
      local in1 = _114_
      local _116_ = get_input_by_keymap(prompt)
      if (nil ~= _116_) then
        local in2 = _116_
        return in1, in2
      elseif true then
        local _2 = _116_
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
  local function post_pattern_input_loop(targets, _3fgroup_offset, first_invoc_3f)
    local function loop(group_offset, first_invoc_3f0)
      if targets["label-set"] then
        set_label_states(targets, {["group-offset"] = group_offset})
      else
      end
      set_beacons(targets, {["aot?"] = aot_3f, ["no-labels?"] = no_labels_3f, ["user-given-targets?"] = user_given_targets_3f})
      do
        hl:cleanup(hl_affected_windows)
        if not count then
          hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
        else
        end
        do
          local function _122_()
            if targets["autojump?"] then
              return 2
            else
              return nil
            end
          end
          light_up_beacons(targets, _122_())
        end
        hl["highlight-cursor"](hl)
        vim.cmd("redraw")
      end
      local _123_
      local function _124_()
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
      _123_ = (get_input() or _124_())
      if (nil ~= _123_) then
        local input = _123_
        if (((input == spec_keys.next_group) or ((input == spec_keys.prev_group) and not first_invoc_3f0)) and (not targets["autojump?"] or empty_3f(opts.labels))) then
          local inc_2fdec
          if (input == spec_keys.next_group) then
            inc_2fdec = inc
          else
            inc_2fdec = dec
          end
          local _7cgroups_7c = ceil((#targets / #targets["label-set"]))
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
    return loop((_3fgroup_offset or 0), ((nil == first_invoc_3f) or first_invoc_3f))
  end
  local multi_select_loop
  do
    local selection = {}
    local group_offset = 0
    local first_invoc_3f = true
    local function loop(targets)
      local _129_, _130_ = post_pattern_input_loop(targets, group_offset, first_invoc_3f)
      if (_129_ == spec_keys.multi_accept) then
        if next(selection) then
          return selection
        else
          return loop(targets)
        end
      elseif (_129_ == spec_keys.multi_revert) then
        do
          local _132_ = table.remove(selection)
          if (nil ~= _132_) then
            _132_["label-state"] = nil
          else
          end
        end
        return loop(targets)
      elseif ((nil ~= _129_) and (nil ~= _130_)) then
        local _in = _129_
        local group_offset_2a = _130_
        group_offset = group_offset_2a
        first_invoc_3f = false
        do
          local _134_ = get_target_with_active_primary_label(targets, _in)
          if ((_G.type(_134_) == "table") and true and (nil ~= (_134_)[2])) then
            local _2 = (_134_)[1]
            local target = (_134_)[2]
            if not contains_3f(selection, target) then
              table.insert(selection, target)
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
  local function traversal_loop(targets, idx, _138_)
    local _arg_139_ = _138_
    local no_labels_3f0 = _arg_139_["no-labels?"]
    if no_labels_3f0 then
      inactivate_labels(targets)
    else
    end
    set_beacons(targets, {["no-labels?"] = no_labels_3f0, ["aot?"] = aot_3f, ["user-given-targets?"] = user_given_targets_3f})
    do
      hl:cleanup(hl_affected_windows)
      if not count then
        hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
      else
      end
      do
        light_up_beacons(targets, inc(idx))
      end
      hl["highlight-cursor"](hl)
      vim.cmd("redraw")
    end
    local _142_
    local function _143_()
      do
      end
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return nil
    end
    _142_ = (get_input() or _143_())
    if (nil ~= _142_) then
      local input = _142_
      local _144_
      if (input == spec_keys.next_match) then
        _144_ = min(inc(idx), #targets)
      elseif (input == spec_keys.prev_match) then
        _144_ = max(dec(idx), 1)
      else
        _144_ = nil
      end
      if (nil ~= _144_) then
        local new_idx = _144_
        local _147_
        do
          local t_146_ = targets
          if (nil ~= t_146_) then
            t_146_ = (t_146_)[new_idx]
          else
          end
          if (nil ~= t_146_) then
            t_146_ = (t_146_).chars
          else
          end
          if (nil ~= t_146_) then
            t_146_ = (t_146_)[2]
          else
          end
          _147_ = t_146_
        end
        update_repeat_state({in1 = state["repeat"].in1, in2 = _147_})
        jump_to_21(targets[new_idx])
        return traversal_loop(targets, new_idx, {["no-labels?"] = no_labels_3f0})
      elseif true then
        local _2 = _144_
        local _151_ = get_target_with_active_primary_label(targets, input)
        if ((_G.type(_151_) == "table") and true and (nil ~= (_151_)[2])) then
          local _3 = (_151_)[1]
          local target = (_151_)[2]
          do
            jump_to_21(target)
          end
          hl:cleanup(hl_affected_windows)
          exec_user_autocmds("LeapLeave")
          return nil
        elseif true then
          local _3 = _151_
          do
            vim.fn.feedkeys(input, "i")
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
    else
      return nil
    end
  end
  local do_action = (user_given_action or jump_to_21)
  exec_user_autocmds("LeapEnter")
  local function _155_(...)
    local _156_, _157_ = ...
    if ((nil ~= _156_) and true) then
      local in1 = _156_
      local _3fin2 = _157_
      local function _158_(...)
        local _159_ = ...
        if (nil ~= _159_) then
          local targets = _159_
          local function _160_(...)
            local _161_ = ...
            if (nil ~= _161_) then
              local in2 = _161_
              if ((in2 == spec_keys.next_match) and directional_3f) then
                local in20 = targets[1].chars[2]
                update_repeat_state({in1 = in1, in2 = in20})
                do_action(targets[1])
                if ((#targets == 1) or op_mode_3f or user_given_action) then
                  do
                    set_dot_repeat(in1, in20, 1)
                  end
                  hl:cleanup(hl_affected_windows)
                  exec_user_autocmds("LeapLeave")
                  return nil
                else
                  return traversal_loop(targets, 1, {["no-labels?"] = true})
                end
              else
                update_repeat_state({in1 = in1, in2 = in2})
                local _163_
                local function _164_(...)
                  if targets.sublists then
                    return targets.sublists[in2]
                  else
                    return targets
                  end
                end
                local function _165_(...)
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
                _163_ = (_164_(...) or _165_(...))
                if (nil ~= _163_) then
                  local targets_2a = _163_
                  if multi_select_3f then
                    local _167_ = multi_select_loop(targets_2a)
                    if (nil ~= _167_) then
                      local targets_2a_2a = _167_
                      do
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
                      end
                      hl:cleanup(hl_affected_windows)
                      exec_user_autocmds("LeapLeave")
                      return nil
                    else
                      return nil
                    end
                  else
                    local exit_with_action
                    local function _170_(idx)
                      do
                        set_dot_repeat(in1, in2, idx)
                        do_action((targets_2a)[idx])
                      end
                      hl:cleanup(hl_affected_windows)
                      exec_user_autocmds("LeapLeave")
                      return nil
                    end
                    exit_with_action = _170_
                    local _7ctargets_2a_7c = #targets_2a
                    if (_7ctargets_2a_7c == 1) then
                      return exit_with_action(1)
                    elseif count then
                      if (count <= _7ctargets_2a_7c) then
                        return exit_with_action(count)
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
                      if targets_2a["autojump?"] then
                        do_action((targets_2a)[1])
                      else
                      end
                      local _174_ = post_pattern_input_loop(targets_2a)
                      if (nil ~= _174_) then
                        local in_final = _174_
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
                            if (empty_3f(opts.labels) and not empty_3f(opts.safe_labels)) then
                              for i = (#opts.safe_labels + 2), _7ctargets_2a_7c do
                                targets_2a[i]["label"] = nil
                                targets_2a[i]["beacon"] = nil
                              end
                            else
                            end
                            return traversal_loop(targets_2a, new_idx, {["no-labels?"] = (no_labels_3f or not targets_2a["autojump?"])})
                          end
                        else
                          local _178_ = get_target_with_active_primary_label(targets_2a, in_final)
                          if ((_G.type(_178_) == "table") and (nil ~= (_178_)[1]) and true) then
                            local idx = (_178_)[1]
                            local _2 = (_178_)[2]
                            return exit_with_action(idx)
                          elseif true then
                            local _2 = _178_
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
              local __61_auto = _161_
              return ...
            else
              return nil
            end
          end
          local function _199_(...)
            if dot_repeat_3f then
              local _189_ = targets[state.dot_repeat.target_idx]
              if (nil ~= _189_) then
                local target = _189_
                do
                  do_action(target)
                end
                hl:cleanup(hl_affected_windows)
                exec_user_autocmds("LeapLeave")
                return nil
              elseif true then
                local _2 = _189_
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
              local function _192_(_241)
                local _193_ = _241
                set_autojump(_193_, force_noautojump_3f)
                attach_label_set(_193_)
                set_labels(_193_, multi_select_3f)
                return _193_
              end
              prepare_targets = _192_
              if _3fin2 then
                if no_labels_3f then
                  targets["autojump?"] = true
                else
                  prepare_targets(targets)
                end
              else
                populate_sublists(targets)
                for _2, sublist in pairs(targets.sublists) do
                  prepare_targets(sublist)
                end
              end
              if (#targets > max_aot_targets) then
                aot_3f = false
              else
              end
              local function _197_(...)
                do
                  local _198_ = targets
                  set_initial_label_states(_198_)
                  set_beacons(_198_, {["aot?"] = aot_3f})
                end
                return get_second_pattern_input(targets)
              end
              return (_3fin2 or _197_(...))
            end
          end
          return _160_(_199_(...))
        elseif true then
          local __61_auto = _159_
          return ...
        else
          return nil
        end
      end
      local function _206_(...)
        if (dot_repeat_3f and state.dot_repeat.callback) then
          return get_user_given_targets(state.dot_repeat.callback)
        elseif user_given_targets_3f then
          local function _201_(...)
            if change_op_3f then
              handle_interrupted_change_op_21()
            else
            end
            do
              echo("no targets")
            end
            hl:cleanup(hl_affected_windows)
            exec_user_autocmds("LeapLeave")
            return nil
          end
          return (get_user_given_targets(user_given_targets) or _201_(...))
        else
          local function _203_(...)
            local search = require("leap.search")
            local pattern = prepare_pattern(in1, _3fin2)
            local kwargs0 = {["backward?"] = backward_3f, ["target-windows"] = _3ftarget_windows}
            return search["get-targets"](pattern, kwargs0)
          end
          local function _204_(...)
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
          return (_203_(...) or _204_(...))
        end
      end
      return _158_(_206_(...))
    elseif true then
      local __61_auto = _156_
      return ...
    else
      return nil
    end
  end
  local function _209_()
    if dot_repeat_3f then
      if state.dot_repeat.callback then
        return true, true
      else
        return state.dot_repeat.in1, state.dot_repeat.in2
      end
    elseif user_given_targets_3f then
      return true, true
    elseif aot_3f then
      return get_first_pattern_input()
    else
      return get_full_pattern_input()
    end
  end
  return _155_(_209_())
end
local _210_
do
  local res = {}
  for _, eqcl in ipairs((opts.equivalence_classes or {})) do
    local eqcl_2a
    if (type(eqcl) == "table") then
      eqcl_2a = eqcl
    else
      local tbl_15_auto = {}
      local i_16_auto = #tbl_15_auto
      for ch in eqcl:gmatch(".") do
        local val_17_auto = ch
        if (nil ~= val_17_auto) then
          i_16_auto = (i_16_auto + 1)
          do end (tbl_15_auto)[i_16_auto] = val_17_auto
        else
        end
      end
      eqcl_2a = tbl_15_auto
    end
    for _0, ch in ipairs(eqcl_2a) do
      res[ch] = eqcl_2a
    end
  end
  _210_ = res
end
opts["eq_class_of"] = _210_
api.nvim_create_augroup("LeapDefault", {})
hl["init-highlight"](hl)
local function _213_()
  return hl["init-highlight"](hl)
end
api.nvim_create_autocmd("ColorScheme", {callback = _213_, group = "LeapDefault"})
local function set_editor_opts(t)
  state.saved_editor_opts = {}
  local wins = (state.args.target_windows or {state.source_window})
  for opt, val in pairs(t) do
    local _let_214_ = vim.split(opt, ".", {plain = true})
    local scope = _let_214_[1]
    local name = _let_214_[2]
    local _215_ = scope
    if (_215_ == "w") then
      for _, w in ipairs(wins) do
        state.saved_editor_opts[{"w", w, name}] = api.nvim_win_get_option(w, name)
        api.nvim_win_set_option(w, name, val)
      end
    elseif (_215_ == "b") then
      for _, w in ipairs(wins) do
        local b = api.nvim_win_get_buf(w)
        do end (state.saved_editor_opts)[{"b", b, name}] = api.nvim_buf_get_option(b, name)
        api.nvim_buf_set_option(b, name, val)
      end
    elseif true then
      local _ = _215_
      state.saved_editor_opts[name] = api.nvim_get_option(name)
      api.nvim_set_option(name, val)
    else
    end
  end
  return nil
end
local function restore_editor_opts()
  for key, val in pairs(state.saved_editor_opts) do
    local _217_ = key
    if ((_G.type(_217_) == "table") and ((_217_)[1] == "w") and (nil ~= (_217_)[2]) and (nil ~= (_217_)[3])) then
      local w = (_217_)[2]
      local name = (_217_)[3]
      api.nvim_win_set_option(w, name, val)
    elseif ((_G.type(_217_) == "table") and ((_217_)[1] == "b") and (nil ~= (_217_)[2]) and (nil ~= (_217_)[3])) then
      local b = (_217_)[2]
      local name = (_217_)[3]
      api.nvim_buf_set_option(b, name, val)
    elseif (nil ~= _217_) then
      local name = _217_
      api.nvim_set_option(name, val)
    else
    end
  end
  return nil
end
local temporary_editor_opts = {["w.conceallevel"] = 0, ["g.scrolloff"] = 0, ["w.scrolloff"] = 0, ["g.sidescrolloff"] = 0, ["w.sidescrolloff"] = 0, ["b.modeline"] = false}
local function _219_()
  return set_editor_opts(temporary_editor_opts)
end
api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _219_, group = "LeapDefault"})
local function _220_()
  return restore_editor_opts()
end
api.nvim_create_autocmd("User", {pattern = "LeapLeave", callback = _220_, group = "LeapDefault"})
return {state = state, leap = leap}
