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
local function eq_classes__3emembership_lookup(eqcls)
  local res = {}
  for _, eqcl in ipairs(eqcls) do
    local eqcl_2a
    if (type(eqcl) == "string") then
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
  local _7_
  if empty_3f(opts.labels) then
    _7_ = opts.safe_labels
  elseif empty_3f(opts.safe_labels) then
    _7_ = opts.labels
  elseif targets["autojump?"] then
    _7_ = opts.safe_labels
  else
    _7_ = opts.labels
  end
  targets["label-set"] = _7_
  return nil
end
local function set_labels(targets, multi_select_3f)
  if ((#targets > 1) or multi_select_3f) then
    local _local_9_ = targets
    local autojump_3f = _local_9_["autojump?"]
    local label_set = _local_9_["label-set"]
    for i, target in ipairs(targets) do
      local i_2a
      if autojump_3f then
        i_2a = dec(i)
      else
        i_2a = i
      end
      if (i_2a > 0) then
        local _12_
        do
          local _11_ = (i_2a % #label_set)
          if (_11_ == 0) then
            _12_ = label_set[#label_set]
          elseif (nil ~= _11_) then
            local n = _11_
            _12_ = label_set[n]
          else
            _12_ = nil
          end
        end
        target["label"] = _12_
      else
      end
    end
    return nil
  else
    return nil
  end
end
local function set_label_states(targets, _18_)
  local _arg_19_ = _18_
  local group_offset = _arg_19_["group-offset"]
  local _7clabel_set_7c = #targets["label-set"]
  local offset = (group_offset * _7clabel_set_7c)
  local primary_start
  local function _20_()
    if targets["autojump?"] then
      return 2
    else
      return 1
    end
  end
  primary_start = (offset + _20_())
  local primary_end = (primary_start + dec(_7clabel_set_7c))
  local secondary_start = inc(primary_end)
  local secondary_end = (primary_end + _7clabel_set_7c)
  for i, target in ipairs(targets) do
    if (target.label and (target["label-state"] ~= "selected")) then
      local _21_
      if (function(_22_,_23_,_24_) return (_22_ <= _23_) and (_23_ <= _24_) end)(primary_start,i,primary_end) then
        _21_ = "active-primary"
      elseif (function(_25_,_26_,_27_) return (_25_ <= _26_) and (_26_ <= _27_) end)(secondary_start,i,secondary_end) then
        _21_ = "active-secondary"
      elseif (i > secondary_end) then
        _21_ = "inactive"
      else
        _21_ = nil
      end
      target["label-state"] = _21_
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
  local function _33_()
    local __3ecommon_key
    local function _30_(_241)
      local function _31_()
        if not opts.case_sensitive then
          return _241:lower()
        else
          return nil
        end
      end
      return (opts.eq_class_of[_241] or _31_() or _241)
    end
    __3ecommon_key = _30_
    local function _34_(t, k)
      return rawget(t, __3ecommon_key(k))
    end
    local function _35_(t, k, v)
      return rawset(t, __3ecommon_key(k), v)
    end
    return {__index = _34_, __newindex = _35_}
  end
  targets["sublists"] = setmetatable({}, _33_())
  for _, _36_ in ipairs(targets) do
    local _each_37_ = _36_
    local _each_38_ = _each_37_["chars"]
    local _0 = _each_38_[1]
    local ch2 = _each_38_[2]
    local target = _each_37_
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
  local _let_40_ = target
  local _let_41_ = _let_40_["chars"]
  local ch1 = _let_41_[1]
  local ch2 = _let_41_[2]
  local edge_pos_3f = _let_40_["edge-pos?"]
  local function _42_()
    if edge_pos_3f then
      return 0
    else
      return ch2:len()
    end
  end
  return (ch1:len() + _42_())
end
local function set_beacon_for_labeled(target, _43_)
  local _arg_44_ = _43_
  local user_given_targets_3f = _arg_44_["user-given-targets?"]
  local aot_3f = _arg_44_["aot?"]
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
    local _47_ = target["label-state"]
    if (_47_ == "selected") then
      virttext = {{text, hl.group["label-selected"]}}
    elseif (_47_ == "active-primary") then
      virttext = {{text, hl.group["label-primary"]}}
    elseif (_47_ == "active-secondary") then
      virttext = {{text, hl.group["label-secondary"]}}
    elseif (_47_ == "inactive") then
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
  local _50_
  if virttext then
    _50_ = {offset, virttext}
  else
    _50_ = nil
  end
  target["beacon"] = _50_
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
    local _local_52_ = target
    local _local_53_ = _local_52_["pos"]
    local lnum = _local_53_[1]
    local col = _local_53_[2]
    local _local_54_ = _local_52_["chars"]
    local ch1 = _local_54_[1]
    local _0 = _local_54_[2]
    local _local_55_ = _local_52_["wininfo"]
    local bufnr = _local_55_["bufnr"]
    local winid = _local_55_["winid"]
    if target.label then
      if target.beacon then
        local label_offset = target.beacon[1]
        local key = (bufnr .. " " .. winid .. " " .. lnum .. " " .. (col + label_offset))
        do
          local _56_ = unlabeled_match_positions[key]
          if (nil ~= _56_) then
            local other = _56_
            target.beacon = nil
            set_beacon_to_match_hl(other)
          elseif true then
            local _1 = _56_
            local _57_ = label_positions[key]
            if (nil ~= _57_) then
              local other = _57_
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
          local _61_ = label_positions[key]
          if (nil ~= _61_) then
            local other = _61_
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
local function set_beacons(targets, _64_)
  local _arg_65_ = _64_
  local no_labels_3f = _arg_65_["no-labels?"]
  local user_given_targets_3f = _arg_65_["user-given-targets?"]
  local aot_3f = _arg_65_["aot?"]
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
    local _69_ = target.beacon
    if ((_G.type(_69_) == "table") and (nil ~= (_69_)[1]) and (nil ~= (_69_)[2])) then
      local offset = (_69_)[1]
      local virttext = (_69_)[2]
      local bufnr = target.wininfo.bufnr
      local _let_70_ = map(dec, target.pos)
      local lnum = _let_70_[1]
      local col = _let_70_[2]
      local id = api.nvim_buf_set_extmark(bufnr, hl.ns, lnum, (col + offset), {virt_text = virttext, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.label})
      table.insert(hl.extmarks, {bufnr, id})
    else
    end
  end
  return nil
end
local state = {args = nil, source_window = nil, ["repeat"] = {in1 = nil, in2 = nil}, dot_repeat = {in1 = nil, in2 = nil, target_idx = nil, backward = nil, inclusive_op = nil, offset = nil}, saved_editor_opts = {}}
local function leap(kwargs)
  local _let_72_ = kwargs
  local dot_repeat_3f = _let_72_["dot_repeat"]
  local target_windows = _let_72_["target_windows"]
  local user_given_opts = _let_72_["opts"]
  local user_given_targets = _let_72_["targets"]
  local user_given_action = _let_72_["action"]
  local multi_select_3f = _let_72_["multiselect"]
  local function _74_()
    if dot_repeat_3f then
      return state.dot_repeat
    else
      return kwargs
    end
  end
  local _let_73_ = _74_()
  local backward_3f = _let_73_["backward"]
  local inclusive_op_3f = _let_73_["inclusive_op"]
  local offset = _let_73_["offset"]
  local _
  state.args = kwargs
  _ = nil
  local _0
  opts.current_call = (user_given_opts or {})
  _0 = nil
  local _1
  local _76_
  do
    local _75_ = opts.current_call.equivalence_classes
    if (nil ~= _75_) then
      _76_ = eq_classes__3emembership_lookup(_75_)
    else
      _76_ = _75_
    end
  end
  opts.current_call["eq_class_of"] = _76_
  _1 = nil
  local id__3ewininfo
  local function _78_(_241)
    return (vim.fn.getwininfo(_241))[1]
  end
  id__3ewininfo = _78_
  local curr_winid = vim.fn.win_getid()
  local _2
  state.source_window = curr_winid
  _2 = nil
  local curr_win = id__3ewininfo(curr_winid)
  local _3ftarget_windows
  do
    local _79_ = target_windows
    if (_79_ ~= nil) then
      _3ftarget_windows = map(id__3ewininfo, _79_)
    else
      _3ftarget_windows = _79_
    end
  end
  local hl_affected_windows
  do
    local tbl_15_auto = {curr_win}
    local i_16_auto = #tbl_15_auto
    for _3, w in ipairs((_3ftarget_windows or {})) do
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
  local function _84_(_3, k)
    local _85_ = opts.special_keys[k]
    if (nil ~= _85_) then
      local v = _85_
      if ((k == "next_match") or (k == "prev_match")) then
        local _86_ = type(v)
        if (_86_ == "table") then
          local tbl_15_auto = {}
          local i_16_auto = #tbl_15_auto
          for _4, str in ipairs(v) do
            local val_17_auto = replace_keycodes(str)
            if (nil ~= val_17_auto) then
              i_16_auto = (i_16_auto + 1)
              do end (tbl_15_auto)[i_16_auto] = val_17_auto
            else
            end
          end
          return tbl_15_auto
        elseif (_86_ == "string") then
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
  spec_keys = setmetatable({}, {__index = _84_})
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
        for _3, t in ipairs(targets) do
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
    local _95_
    do
      local _96_ = targets
      if (_G.type(_96_) == "table") then
        local tbl = _96_
        _95_ = tbl
      elseif (nil ~= _96_) then
        local func = _96_
        _95_ = func()
      else
        _95_ = nil
      end
    end
    if (nil ~= _95_) then
      return fill_wininfo(_95_)
    else
      return _95_
    end
  end
  local function expand_to_equivalence_class(_in)
    local _99_ = opts.eq_class_of[_in]
    if (nil ~= _99_) then
      local chars = _99_
      local chars_2a
      local function _100_(_241)
        local _101_ = _241
        if (_101_ == "\n") then
          return "\\n"
        elseif (_101_ == "\\") then
          return "\\\\"
        elseif true then
          local _3 = _101_
          return _241
        else
          return nil
        end
      end
      chars_2a = map(_100_, chars)
      return ("\\(" .. table.concat(chars_2a, "\\|") .. "\\)")
    else
      return nil
    end
  end
  local function prepare_pattern(in1, _3fin2)
    local function _104_()
      if opts.case_sensitive then
        return "\\C"
      else
        return "\\c"
      end
    end
    return ("\\V" .. _104_() .. (expand_to_equivalence_class(in1) or in1:gsub("\\", "\\\\")) .. (expand_to_equivalence_class(_3fin2) or _3fin2 or "\\_."))
  end
  local function get_target_with_active_primary_label(sublist, input)
    local res = nil
    for idx, _105_ in ipairs(sublist) do
      local _each_106_ = _105_
      local label = _each_106_["label"]
      local label_state = _each_106_["label-state"]
      local target = _each_106_
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
      local function _109_()
        if user_given_targets then
          return {callback = user_given_targets}
        else
          return {in1 = in1, in2 = in2}
        end
      end
      state.dot_repeat = vim.tbl_extend("error", {target_idx = target_idx, backward = backward_3f, inclusive_op = inclusive_op_3f, offset = offset}, _109_())
      return set_dot_repeat_2a()
    else
      return nil
    end
  end
  local jump_to_21
  do
    local first_jump_3f = true
    local function _111_(target)
      local jump = require("leap.jump")
      jump["jump-to!"](target.pos, {winid = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["backward?"] = backward_3f, ["inclusive-op?"] = inclusive_op_3f})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _111_
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
    local _113_
    local function _114_()
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
    _113_ = (get_input_by_keymap(prompt) or _114_())
    if (_113_ == spec_keys.repeat_search) then
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
    elseif (nil ~= _113_) then
      local in1 = _113_
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
    local function _121_()
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
    return (get_input_by_keymap(prompt) or _121_())
  end
  local function get_full_pattern_input()
    local _123_, _124_ = get_first_pattern_input()
    if ((nil ~= _123_) and (nil ~= _124_)) then
      local in1 = _123_
      local in2 = _124_
      return in1, in2
    elseif ((nil ~= _123_) and (_124_ == nil)) then
      local in1 = _123_
      local _125_ = get_input_by_keymap(prompt)
      if (nil ~= _125_) then
        local in2 = _125_
        return in1, in2
      elseif true then
        local _3 = _125_
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
          local function _131_()
            if targets["autojump?"] then
              return 2
            else
              return nil
            end
          end
          light_up_beacons(targets, _131_())
        end
        hl["highlight-cursor"](hl)
        vim.cmd("redraw")
      end
      local _132_
      local function _133_()
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
      _132_ = (get_input() or _133_())
      if (nil ~= _132_) then
        local input = _132_
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
      local _138_, _139_ = post_pattern_input_loop(targets, group_offset, first_invoc_3f)
      if (_138_ == spec_keys.multi_accept) then
        if next(selection) then
          return selection
        else
          return loop(targets)
        end
      elseif (_138_ == spec_keys.multi_revert) then
        do
          local _141_ = table.remove(selection)
          if (nil ~= _141_) then
            _141_["label-state"] = nil
          else
          end
        end
        return loop(targets)
      elseif ((nil ~= _138_) and (nil ~= _139_)) then
        local _in = _138_
        local group_offset_2a = _139_
        group_offset = group_offset_2a
        first_invoc_3f = false
        do
          local _143_ = get_target_with_active_primary_label(targets, _in)
          if ((_G.type(_143_) == "table") and true and (nil ~= (_143_)[2])) then
            local _3 = (_143_)[1]
            local target = (_143_)[2]
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
  local function traversal_loop(targets, idx, _147_)
    local _arg_148_ = _147_
    local no_labels_3f0 = _arg_148_["no-labels?"]
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
    local _151_
    local function _152_()
      do
      end
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return nil
    end
    _151_ = (get_input() or _152_())
    if (nil ~= _151_) then
      local input = _151_
      local _153_
      if contains_3f(spec_keys.next_match, input) then
        _153_ = min(inc(idx), #targets)
      elseif contains_3f(spec_keys.prev_match, input) then
        _153_ = max(dec(idx), 1)
      else
        _153_ = nil
      end
      if (nil ~= _153_) then
        local new_idx = _153_
        local _156_
        do
          local t_155_ = targets
          if (nil ~= t_155_) then
            t_155_ = (t_155_)[new_idx]
          else
          end
          if (nil ~= t_155_) then
            t_155_ = (t_155_).chars
          else
          end
          if (nil ~= t_155_) then
            t_155_ = (t_155_)[2]
          else
          end
          _156_ = t_155_
        end
        update_repeat_state({in1 = state["repeat"].in1, in2 = _156_})
        jump_to_21(targets[new_idx])
        return traversal_loop(targets, new_idx, {["no-labels?"] = no_labels_3f0})
      elseif true then
        local _3 = _153_
        local _160_ = get_target_with_active_primary_label(targets, input)
        if ((_G.type(_160_) == "table") and true and (nil ~= (_160_)[2])) then
          local _4 = (_160_)[1]
          local target = (_160_)[2]
          do
            jump_to_21(target)
          end
          hl:cleanup(hl_affected_windows)
          exec_user_autocmds("LeapLeave")
          return nil
        elseif true then
          local _4 = _160_
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
  local function _164_(...)
    local _165_, _166_ = ...
    if ((nil ~= _165_) and true) then
      local in1 = _165_
      local _3fin2 = _166_
      local function _167_(...)
        local _168_ = ...
        if (nil ~= _168_) then
          local targets = _168_
          local function _169_(...)
            local _170_ = ...
            if (nil ~= _170_) then
              local in2 = _170_
              if (contains_3f(spec_keys.next_match, in2) and directional_3f) then
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
                local _172_
                local function _173_(...)
                  if targets.sublists then
                    return targets.sublists[in2]
                  else
                    return targets
                  end
                end
                local function _174_(...)
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
                _172_ = (_173_(...) or _174_(...))
                if (nil ~= _172_) then
                  local targets_2a = _172_
                  if multi_select_3f then
                    local _176_ = multi_select_loop(targets_2a)
                    if (nil ~= _176_) then
                      local targets_2a_2a = _176_
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
                    local function _179_(idx)
                      do
                        set_dot_repeat(in1, in2, idx)
                        do_action((targets_2a)[idx])
                      end
                      hl:cleanup(hl_affected_windows)
                      exec_user_autocmds("LeapLeave")
                      return nil
                    end
                    exit_with_action = _179_
                    local _7ctargets_2a_7c = #targets_2a
                    if count then
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
                    elseif (_7ctargets_2a_7c == 1) then
                      return exit_with_action(1)
                    else
                      if targets_2a["autojump?"] then
                        do_action((targets_2a)[1])
                      else
                      end
                      local _183_ = post_pattern_input_loop(targets_2a)
                      if (nil ~= _183_) then
                        local in_final = _183_
                        if (contains_3f(spec_keys.next_match, in_final) and directional_3f) then
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
                          local _187_ = get_target_with_active_primary_label(targets_2a, in_final)
                          if ((_G.type(_187_) == "table") and (nil ~= (_187_)[1]) and true) then
                            local idx = (_187_)[1]
                            local _3 = (_187_)[2]
                            return exit_with_action(idx)
                          elseif true then
                            local _3 = _187_
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
              local __61_auto = _170_
              return ...
            else
              return nil
            end
          end
          local function _208_(...)
            if dot_repeat_3f then
              local _198_ = targets[state.dot_repeat.target_idx]
              if (nil ~= _198_) then
                local target = _198_
                do
                  do_action(target)
                end
                hl:cleanup(hl_affected_windows)
                exec_user_autocmds("LeapLeave")
                return nil
              elseif true then
                local _3 = _198_
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
              local function _201_(_241)
                local _202_ = _241
                set_autojump(_202_, force_noautojump_3f)
                attach_label_set(_202_)
                set_labels(_202_, multi_select_3f)
                return _202_
              end
              prepare_targets = _201_
              if _3fin2 then
                if no_labels_3f then
                  targets["autojump?"] = true
                else
                  prepare_targets(targets)
                end
              else
                populate_sublists(targets)
                for _3, sublist in pairs(targets.sublists) do
                  prepare_targets(sublist)
                end
              end
              if (#targets > max_aot_targets) then
                aot_3f = false
              else
              end
              local function _206_(...)
                do
                  local _207_ = targets
                  set_initial_label_states(_207_)
                  set_beacons(_207_, {["aot?"] = aot_3f})
                end
                return get_second_pattern_input(targets)
              end
              return (_3fin2 or _206_(...))
            end
          end
          return _169_(_208_(...))
        elseif true then
          local __61_auto = _168_
          return ...
        else
          return nil
        end
      end
      local function _215_(...)
        if (dot_repeat_3f and state.dot_repeat.callback) then
          return get_user_given_targets(state.dot_repeat.callback)
        elseif user_given_targets_3f then
          local function _210_(...)
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
          return (get_user_given_targets(user_given_targets) or _210_(...))
        else
          local function _212_(...)
            local search = require("leap.search")
            local pattern = prepare_pattern(in1, _3fin2)
            local kwargs0 = {["backward?"] = backward_3f, ["target-windows"] = _3ftarget_windows}
            return search["get-targets"](pattern, kwargs0)
          end
          local function _213_(...)
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
          return (_212_(...) or _213_(...))
        end
      end
      return _167_(_215_(...))
    elseif true then
      local __61_auto = _165_
      return ...
    else
      return nil
    end
  end
  local function _218_()
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
  return _164_(_218_())
end
local _220_
do
  local _219_ = opts.default.equivalence_classes
  if (nil ~= _219_) then
    _220_ = eq_classes__3emembership_lookup(_219_)
  else
    _220_ = _219_
  end
end
opts.default["eq_class_of"] = _220_
api.nvim_create_augroup("LeapDefault", {})
hl["init-highlight"](hl)
local function _222_()
  return hl["init-highlight"](hl)
end
api.nvim_create_autocmd("ColorScheme", {callback = _222_, group = "LeapDefault"})
local function set_editor_opts(t)
  state.saved_editor_opts = {}
  local wins = (state.args.target_windows or {state.source_window})
  for opt, val in pairs(t) do
    local _let_223_ = vim.split(opt, ".", {plain = true})
    local scope = _let_223_[1]
    local name = _let_223_[2]
    local _224_ = scope
    if (_224_ == "w") then
      for _, w in ipairs(wins) do
        state.saved_editor_opts[{"w", w, name}] = api.nvim_win_get_option(w, name)
        api.nvim_win_set_option(w, name, val)
      end
    elseif (_224_ == "b") then
      for _, w in ipairs(wins) do
        local b = api.nvim_win_get_buf(w)
        do end (state.saved_editor_opts)[{"b", b, name}] = api.nvim_buf_get_option(b, name)
        api.nvim_buf_set_option(b, name, val)
      end
    elseif true then
      local _ = _224_
      state.saved_editor_opts[name] = api.nvim_get_option(name)
      api.nvim_set_option(name, val)
    else
    end
  end
  return nil
end
local function restore_editor_opts()
  for key, val in pairs(state.saved_editor_opts) do
    local _226_ = key
    if ((_G.type(_226_) == "table") and ((_226_)[1] == "w") and (nil ~= (_226_)[2]) and (nil ~= (_226_)[3])) then
      local w = (_226_)[2]
      local name = (_226_)[3]
      api.nvim_win_set_option(w, name, val)
    elseif ((_G.type(_226_) == "table") and ((_226_)[1] == "b") and (nil ~= (_226_)[2]) and (nil ~= (_226_)[3])) then
      local b = (_226_)[2]
      local name = (_226_)[3]
      api.nvim_buf_set_option(b, name, val)
    elseif (nil ~= _226_) then
      local name = _226_
      api.nvim_set_option(name, val)
    else
    end
  end
  return nil
end
local temporary_editor_opts = {["w.conceallevel"] = 0, ["g.scrolloff"] = 0, ["w.scrolloff"] = 0, ["g.sidescrolloff"] = 0, ["w.sidescrolloff"] = 0, ["b.modeline"] = false}
local function _228_()
  return set_editor_opts(temporary_editor_opts)
end
api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _228_, group = "LeapDefault"})
local function _229_()
  return restore_editor_opts()
end
api.nvim_create_autocmd("User", {pattern = "LeapLeave", callback = _229_, group = "LeapDefault"})
return {state = state, leap = leap}
