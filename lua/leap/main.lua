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
local get_eq_class_of = _local_1_["get-eq-class-of"]
local __3erepresentative_char = _local_1_["->representative-char"]
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
  local _6_
  if empty_3f(opts.labels) then
    _6_ = opts.safe_labels
  elseif empty_3f(opts.safe_labels) then
    _6_ = opts.labels
  elseif targets["autojump?"] then
    _6_ = opts.safe_labels
  else
    _6_ = opts.labels
  end
  targets["label-set"] = _6_
  return nil
end
local function set_labels(targets, multi_select_3f)
  if ((#targets > 1) or multi_select_3f) then
    local _local_8_ = targets
    local autojump_3f = _local_8_["autojump?"]
    local label_set = _local_8_["label-set"]
    for i, target in ipairs(targets) do
      local i_2a
      if autojump_3f then
        i_2a = dec(i)
      else
        i_2a = i
      end
      if (i_2a > 0) then
        local _11_
        do
          local _10_ = (i_2a % #label_set)
          if (_10_ == 0) then
            _11_ = label_set[#label_set]
          elseif (nil ~= _10_) then
            local n = _10_
            _11_ = label_set[n]
          else
            _11_ = nil
          end
        end
        target["label"] = _11_
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
      local _20_
      if (function(_21_,_22_,_23_) return (_21_ <= _22_) and (_22_ <= _23_) end)(primary_start,i,primary_end) then
        _20_ = "active-primary"
      elseif (function(_24_,_25_,_26_) return (_24_ <= _25_) and (_25_ <= _26_) end)(secondary_start,i,secondary_end) then
        _20_ = "active-secondary"
      elseif (i > secondary_end) then
        _20_ = "inactive"
      else
        _20_ = nil
      end
      target["label-state"] = _20_
    else
    end
  end
  return nil
end
local function populate_sublists(targets)
  local function _29_(self, ch)
    return rawget(self, __3erepresentative_char(ch))
  end
  local function _30_(self, ch, sublist)
    return rawset(self, __3erepresentative_char(ch), sublist)
  end
  targets["sublists"] = setmetatable({}, {__index = _29_, __newindex = _30_})
  for _, _31_ in ipairs(targets) do
    local _each_32_ = _31_
    local _each_33_ = _each_32_["chars"]
    local _0 = _each_33_[1]
    local ch2 = _each_33_[2]
    local target = _each_32_
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
  local _let_35_ = target
  local _let_36_ = _let_35_["chars"]
  local ch1 = _let_36_[1]
  local ch2 = _let_36_[2]
  if target["empty-line?"] then
    return 0
  elseif target["edge-pos?"] then
    return ch1:len()
  else
    return (ch1:len() + ch2:len())
  end
end
local function set_beacon_for_labeled(target, _38_)
  local _arg_39_ = _38_
  local user_given_targets_3f = _arg_39_["user-given-targets?"]
  local aot_3f = _arg_39_["aot?"]
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
    local _42_ = target["label-state"]
    if (_42_ == "selected") then
      virttext = {{text, hl.group["label-selected"]}}
    elseif (_42_ == "active-primary") then
      virttext = {{text, hl.group["label-primary"]}}
    elseif (_42_ == "active-secondary") then
      virttext = {{text, hl.group["label-secondary"]}}
    elseif (_42_ == "inactive") then
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
  local _45_
  if virttext then
    _45_ = {offset, virttext}
  else
    _45_ = nil
  end
  target["beacon"] = _45_
  return nil
end
local function set_beacon_to_match_hl(target)
  local virttext
  local function _47_(_241)
    return (opts.substitute_chars[_241] or _241)
  end
  virttext = table.concat(map(_47_, target.chars))
  do end (target)["beacon"] = {0, {{virttext, hl.group.match}}}
  return nil
end
local function set_beacon_to_empty_label(target)
  target["beacon"][2][1][1] = " "
  return nil
end
local function resolve_conflicts(targets)
  local pos_unlabeled_match = {}
  local pos_labeled_match = {}
  local pos_label = {}
  for _, target in ipairs(targets) do
    if not target["empty-line?"] then
      local _local_48_ = target.wininfo
      local bufnr = _local_48_["bufnr"]
      local winid = _local_48_["winid"]
      local _local_49_ = target.pos
      local lnum = _local_49_[1]
      local col = _local_49_[2]
      local col_ch2 = (col + string.len(target.chars[1]))
      if (target.label and target.beacon) then
        local label_offset = target.beacon[1]
        local col_label = (col + label_offset)
        local shifted_label_3f = (col_label == col_ch2)
        do
          local _50_ = pos_unlabeled_match[(bufnr .. " " .. winid .. " " .. lnum .. " " .. col_label)]
          if (nil ~= _50_) then
            local other = _50_
            target.beacon = nil
            set_beacon_to_match_hl(other)
          else
          end
        end
        if shifted_label_3f then
          local _52_ = pos_unlabeled_match[(bufnr .. " " .. winid .. " " .. lnum .. " " .. col)]
          if (nil ~= _52_) then
            local other = _52_
            set_beacon_to_match_hl(other)
          else
          end
        else
        end
        do
          local _55_ = pos_label[(bufnr .. " " .. winid .. " " .. lnum .. " " .. col_label)]
          if (nil ~= _55_) then
            local other = _55_
            target.beacon = nil
            set_beacon_to_empty_label(other)
          else
          end
        end
        pos_label[(bufnr .. " " .. winid .. " " .. lnum .. " " .. col_label)] = target
        pos_labeled_match[(bufnr .. " " .. winid .. " " .. lnum .. " " .. col)] = target
        if not shifted_label_3f then
          pos_labeled_match[(bufnr .. " " .. winid .. " " .. lnum .. " " .. col_ch2)] = target
        else
        end
      elseif not target.label then
        for _0, key in ipairs({(bufnr .. " " .. winid .. " " .. lnum .. " " .. col), (bufnr .. " " .. winid .. " " .. lnum .. " " .. col_ch2)}) do
          pos_unlabeled_match[key] = target
          local _58_ = pos_label[key]
          if (nil ~= _58_) then
            local other = _58_
            other.beacon = nil
            set_beacon_to_match_hl(target)
          else
          end
        end
        local col_after = (col_ch2 + string.len(target.chars[2]))
        local _60_ = pos_label[(bufnr .. " " .. winid .. " " .. lnum .. " " .. col_after)]
        if (nil ~= _60_) then
          local other = _60_
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
  local _local_72_ = kwargs
  local dot_repeat_3f = _local_72_["dot_repeat"]
  local target_windows = _local_72_["target_windows"]
  local user_given_opts = _local_72_["opts"]
  local user_given_targets = _local_72_["targets"]
  local user_given_action = _local_72_["action"]
  local multi_select_3f = _local_72_["multiselect"]
  local function _74_()
    if dot_repeat_3f then
      return state.dot_repeat
    else
      return kwargs
    end
  end
  local _local_73_ = _74_()
  local backward_3f = _local_73_["backward"]
  local match_last_overlapping_3f = _local_73_["match_last_overlapping"]
  local inclusive_op_3f = _local_73_["inclusive_op"]
  local offset = _local_73_["offset"]
  opts.current_call = (user_given_opts or {})
  do
    local _75_ = opts.current_call.equivalence_classes
    if (nil ~= _75_) then
      opts.current_call.eq_class_of = eq_classes__3emembership_lookup(_75_)
    else
      opts.current_call.eq_class_of = _75_
    end
  end
  local curr_winid = vim.fn.win_getid()
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
  state.args = kwargs
  state.source_window = curr_winid
  local id__3ewininfo
  local function _80_(_241)
    return (vim.fn.getwininfo(_241))[1]
  end
  id__3ewininfo = _80_
  local curr_win = id__3ewininfo(curr_winid)
  local _3ftarget_windows
  do
    local _81_ = target_windows
    if (_81_ ~= nil) then
      _3ftarget_windows = map(id__3ewininfo, _81_)
    else
      _3ftarget_windows = _81_
    end
  end
  local hl_affected_windows
  do
    local tbl_17_auto = {curr_win}
    local i_18_auto = #tbl_17_auto
    for _, w in ipairs((_3ftarget_windows or {})) do
      local val_19_auto = w
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
  local force_noautojump_3f = (op_mode_3f or multi_select_3f or not directional_3f or user_given_action)
  local max_phase_one_targets = (opts.max_phase_one_targets or math.huge)
  local user_given_targets_3f = user_given_targets
  local prompt = {str = ">"}
  local spec_keys
  do
    local function __index(_, k)
      local _86_ = opts.special_keys[k]
      if (nil ~= _86_) then
        local v = _86_
        if ((k == "next_target") or (k == "prev_target")) then
          local _87_ = type(v)
          if (_87_ == "table") then
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
          elseif (_87_ == "string") then
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
  local _2aaot_3f_2a = not ((max_phase_one_targets == 0) or count or empty_label_lists_3f or multi_select_3f or user_given_targets_3f)
  local _2acurr_idx_2a = 0
  local _2aerrmsg_2a = nil
  local function get_user_given_targets(targets)
    local targets_2a
    if (type(targets) == "function") then
      targets_2a = targets()
    else
      targets_2a = targets
    end
    if (targets_2a and (#targets_2a > 0)) then
      if not (targets_2a)[1].wininfo then
        for _, t in ipairs(targets_2a) do
          t["wininfo"] = curr_win
        end
      else
      end
      return targets_2a
    else
      _2aerrmsg_2a = "no targets"
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
    local pat2
    local function _97_()
      local _98_ = _3fin2
      if (nil ~= _98_) then
        return expand_to_equivalence_class(_98_)
      else
        return _98_
      end
    end
    pat2 = (_97_() or _3fin2 or "\\_.")
    local pat
    if (pat1:match("\\n") and (not _3fin2 or pat2:match("\\n"))) then
      pat = (pat1 .. pat2 .. "\\|\\^\\n")
    else
      pat = (pat1 .. pat2)
    end
    local function _101_()
      if opts.case_sensitive then
        return "\\C"
      else
        return "\\c"
      end
    end
    return ("\\V" .. _101_() .. pat)
  end
  local function get_targets(in1, _3fin2)
    local search = require("leap.search")
    local pattern = prepare_pattern(in1, _3fin2)
    local kwargs0 = {["backward?"] = backward_3f, ["match-last-overlapping?"] = match_last_overlapping_3f, ["target-windows"] = _3ftarget_windows}
    local targets = search["get-targets"](pattern, kwargs0)
    local function _102_()
      _2aerrmsg_2a = ("not found: " .. in1 .. (_3fin2 or ""))
      return nil
    end
    return (targets or _102_())
  end
  local function get_target_with_active_primary_label(sublist, input)
    local res = {}
    for idx, _103_ in ipairs(sublist) do
      local _each_104_ = _103_
      local label = _each_104_["label"]
      local label_state = _each_104_["label-state"]
      local target = _each_104_
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
      local _107_
      if user_given_targets then
        _107_ = {callback = user_given_targets}
      else
        _107_ = {in1 = in1, in2 = in2}
      end
      state.dot_repeat = vim.tbl_extend("error", _107_, {target_idx = target_idx, offset = offset, backward = backward_3f, inclusive_op = inclusive_op_3f})
      return set_dot_repeat_2a()
    else
      return nil
    end
  end
  local jump_to_21
  do
    local first_jump_3f = true
    local function _110_(target)
      local jump = require("leap.jump")
      jump["jump-to!"](target.pos, {winid = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["backward?"] = backward_3f, ["inclusive-op?"] = inclusive_op_3f})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _110_
  end
  local function get_number_of_highlighted_targets()
    local _111_ = opts.max_highlighted_traversal_targets
    if (nil ~= _111_) then
      local group_size = _111_
      local consumed = (dec(_2acurr_idx_2a) % group_size)
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
      local start = inc(_2acurr_idx_2a)
      local _end
      if no_labels_3f then
        local _114_ = get_number_of_highlighted_targets()
        if (nil ~= _114_) then
          local _115_ = (_114_ + dec(start))
          if (nil ~= _115_) then
            _end = min(_115_, #targets)
          else
            _end = _115_
          end
        else
          _end = _114_
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
    local _121_ = get_input_by_keymap(prompt)
    if (_121_ == spec_keys.repeat_search) then
      if state["repeat"].in1 then
        _2aaot_3f_2a = false
        return state["repeat"].in1, state["repeat"].in2
      else
        _2aerrmsg_2a = "no previous search"
        return nil
      end
    elseif (nil ~= _121_) then
      local in1 = _121_
      return in1
    else
      return nil
    end
  end
  local function get_second_pattern_input(targets)
    if (#targets <= max_phase_one_targets) then
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
    local _126_, _127_ = get_first_pattern_input()
    if ((nil ~= _126_) and (nil ~= _127_)) then
      local in1 = _126_
      local in2 = _127_
      return in1, in2
    elseif ((nil ~= _126_) and (_127_ == nil)) then
      local in1 = _126_
      local _128_ = get_input_by_keymap(prompt)
      if (nil ~= _128_) then
        local in2 = _128_
        return in1, in2
      else
        return nil
      end
    else
      return nil
    end
  end
  local function post_pattern_input_loop(targets, _3fgroup_offset, first_invoc_3f)
    local function loop(group_offset, first_invoc_3f0)
      local no_labels_3f = empty_label_lists_3f
      if targets["label-set"] then
        set_label_states(targets, {["group-offset"] = group_offset})
      else
      end
      set_beacons(targets, {["aot?"] = _2aaot_3f_2a, ["no-labels?"] = no_labels_3f, ["user-given-targets?"] = user_given_targets_3f})
      do
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
        vim.cmd("redraw")
      end
      local _133_ = get_input()
      if (nil ~= _133_) then
        local input = _133_
        if (targets["label-set"] and (not targets["autojump?"] or empty_3f(opts.labels)) and ((input == spec_keys.next_group) or ((input == spec_keys.prev_group) and not first_invoc_3f0))) then
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
      local _137_, _138_ = post_pattern_input_loop(targets, group_offset, first_invoc_3f)
      if (_137_ == spec_keys.multi_accept) then
        if not empty_3f(selection) then
          return selection
        else
          return loop(targets)
        end
      elseif (_137_ == spec_keys.multi_revert) then
        do
          local _140_ = table.remove(selection)
          if (nil ~= _140_) then
            _140_["label-state"] = nil
          else
          end
        end
        return loop(targets)
      elseif ((nil ~= _137_) and (nil ~= _138_)) then
        local _in = _137_
        local group_offset_2a = _138_
        group_offset = group_offset_2a
        first_invoc_3f = false
        do
          local _142_ = get_target_with_active_primary_label(targets, _in)
          if ((_G.type(_142_) == "table") and true and (nil ~= (_142_)[2])) then
            local _ = (_142_)[1]
            local target = (_142_)[2]
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
  local function traversal_loop(targets, idx, _146_)
    local _arg_147_ = _146_
    local no_labels_3f = _arg_147_["no-labels?"]
    local traversing_3f = _arg_147_["traversing?"]
    _2acurr_idx_2a = idx
    if not traversing_3f then
      if no_labels_3f then
        for _, target in ipairs(targets) do
          target["label-state"] = "inactive"
        end
      elseif not empty_3f(opts.safe_labels) then
        local last_labeled = inc(#opts.safe_labels)
        for i = inc(last_labeled), #targets do
          targets[i]["label"] = nil
          targets[i]["beacon"] = nil
        end
      else
      end
    else
    end
    set_beacons(targets, {["no-labels?"] = no_labels_3f, ["aot?"] = _2aaot_3f_2a, ["user-given-targets?"] = user_given_targets_3f})
    do
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
      vim.cmd("redraw")
    end
    local _151_ = get_input()
    if (nil ~= _151_) then
      local input = _151_
      local _152_
      if contains_3f(spec_keys.next_target, input) then
        _152_ = min(inc(idx), #targets)
      elseif contains_3f(spec_keys.prev_target, input) then
        _152_ = max(dec(idx), 1)
      else
        _152_ = nil
      end
      if (nil ~= _152_) then
        local new_idx = _152_
        local _155_
        do
          local t_154_ = targets
          if (nil ~= t_154_) then
            t_154_ = (t_154_)[new_idx]
          else
          end
          if (nil ~= t_154_) then
            t_154_ = (t_154_).chars
          else
          end
          if (nil ~= t_154_) then
            t_154_ = (t_154_)[2]
          else
          end
          _155_ = t_154_
        end
        update_repeat_state({in1 = state["repeat"].in1, in2 = _155_})
        jump_to_21(targets[new_idx])
        return traversal_loop(targets, new_idx, {["no-labels?"] = no_labels_3f, ["traversing?"] = true})
      elseif true then
        local _ = _152_
        local _159_ = get_target_with_active_primary_label(targets, input)
        if ((_G.type(_159_) == "table") and true and (nil ~= (_159_)[2])) then
          local _0 = (_159_)[1]
          local target = (_159_)[2]
          return jump_to_21(target)
        elseif true then
          local _0 = _159_
          return vim.fn.feedkeys(input, "i")
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
  local in1, _3fin2 = nil, nil
  if dot_repeat_3f then
    if state.dot_repeat.callback then
      in1, _3fin2 = true, true
    else
      in1, _3fin2 = state.dot_repeat.in1, state.dot_repeat.in2
    end
  elseif user_given_targets_3f then
    in1, _3fin2 = true, true
  elseif _2aaot_3f_2a then
    in1, _3fin2 = get_first_pattern_input()
  else
    in1, _3fin2 = get_full_pattern_input()
  end
  if not in1 then
    if change_op_3f then
      handle_interrupted_change_op_21()
    else
    end
    if _2aerrmsg_2a then
      echo(_2aerrmsg_2a)
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
    if _2aerrmsg_2a then
      echo(_2aerrmsg_2a)
    else
    end
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  if dot_repeat_3f then
    local _172_ = targets[state.dot_repeat.target_idx]
    if (nil ~= _172_) then
      local target = _172_
      do_action(target)
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    elseif true then
      local _ = _172_
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      if _2aerrmsg_2a then
        echo(_2aerrmsg_2a)
      else
      end
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    else
    end
  else
  end
  do
    local prepare
    local function _177_(_241)
      set_autojump(_241, force_noautojump_3f)
      attach_label_set(_241)
      set_labels(_241, multi_select_3f)
      return _241
    end
    prepare = _177_
    if _3fin2 then
      if empty_label_lists_3f then
        targets["autojump?"] = true
      else
        prepare(targets)
      end
    else
      if (#targets > max_phase_one_targets) then
        _2aaot_3f_2a = false
      else
      end
      populate_sublists(targets)
      for _, sublist in pairs(targets.sublists) do
        prepare(sublist)
      end
      set_initial_label_states(targets)
      set_beacons(targets, {["aot?"] = _2aaot_3f_2a})
    end
  end
  local in2 = (_3fin2 or get_second_pattern_input(targets))
  if not in2 then
    if change_op_3f then
      handle_interrupted_change_op_21()
    else
    end
    if _2aerrmsg_2a then
      echo(_2aerrmsg_2a)
    else
    end
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  if (in2 == spec_keys.next_phase_one_target) then
    local first = targets[1]
    local in2_2a = first.chars[2]
    update_repeat_state({in1 = in1, in2 = in2_2a})
    do_action(first)
    if ((#targets == 1) or op_mode_3f or not directional_3f or user_given_action) then
      set_dot_repeat(in1, in2_2a, 1)
    else
      traversal_loop(targets, 1, {["no-labels?"] = true})
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
    _2aerrmsg_2a = ("not found: " .. in1 .. in2)
    if change_op_3f then
      handle_interrupted_change_op_21()
    else
    end
    if _2aerrmsg_2a then
      echo(_2aerrmsg_2a)
    else
    end
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  if multi_select_3f then
    do
      local _190_ = multi_select_loop(targets_2a)
      if (nil ~= _190_) then
        local targets_2a_2a = _190_
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
      if _2aerrmsg_2a then
        echo(_2aerrmsg_2a)
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
    _2acurr_idx_2a = 1
    do_action((targets_2a)[1])
  else
  end
  local in_final = post_pattern_input_loop(targets_2a)
  if not in_final then
    if change_op_3f then
      handle_interrupted_change_op_21()
    else
    end
    if _2aerrmsg_2a then
      echo(_2aerrmsg_2a)
    else
    end
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  else
  end
  if contains_3f(spec_keys.next_target, in_final) then
    if (op_mode_3f or not directional_3f or user_given_action) then
      set_dot_repeat(in1, in2, 1)
      do_action((targets_2a)[1])
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    else
      local new_idx = inc(_2acurr_idx_2a)
      do_action((targets_2a)[new_idx])
      traversal_loop(targets_2a, new_idx, {["no-labels?"] = (empty_label_lists_3f or not targets_2a["autojump?"])})
      hl:cleanup(hl_affected_windows)
      exec_user_autocmds("LeapLeave")
      return
    end
  else
  end
  local _local_204_ = get_target_with_active_primary_label(targets_2a, in_final)
  local idx = _local_204_[1]
  local _ = _local_204_[2]
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
    if _2aerrmsg_2a then
      echo(_2aerrmsg_2a)
    else
    end
    hl:cleanup(hl_affected_windows)
    exec_user_autocmds("LeapLeave")
    return
  end
  return nil
end
local _209_
do
  local _208_ = opts.default.equivalence_classes
  if (nil ~= _208_) then
    _209_ = eq_classes__3emembership_lookup(_208_)
  else
    _209_ = _208_
  end
end
opts.default["eq_class_of"] = _209_
api.nvim_create_augroup("LeapDefault", {})
hl["init-highlight"](hl)
local function _211_()
  return hl["init-highlight"](hl)
end
api.nvim_create_autocmd("ColorScheme", {callback = _211_, group = "LeapDefault"})
local function set_editor_opts(t)
  state.saved_editor_opts = {}
  local wins = (state.args.target_windows or {state.source_window})
  for opt, val in pairs(t) do
    local _let_212_ = vim.split(opt, ".", {plain = true})
    local scope = _let_212_[1]
    local name = _let_212_[2]
    local _213_ = scope
    if (_213_ == "w") then
      for _, w in ipairs(wins) do
        state.saved_editor_opts[{"w", w, name}] = api.nvim_win_get_option(w, name)
        api.nvim_win_set_option(w, name, val)
      end
    elseif (_213_ == "b") then
      for _, w in ipairs(wins) do
        local b = api.nvim_win_get_buf(w)
        do end (state.saved_editor_opts)[{"b", b, name}] = api.nvim_buf_get_option(b, name)
        api.nvim_buf_set_option(b, name, val)
      end
    elseif true then
      local _ = _213_
      state.saved_editor_opts[name] = api.nvim_get_option(name)
      api.nvim_set_option(name, val)
    else
    end
  end
  return nil
end
local function restore_editor_opts()
  for key, val in pairs(state.saved_editor_opts) do
    local _215_ = key
    if ((_G.type(_215_) == "table") and ((_215_)[1] == "w") and (nil ~= (_215_)[2]) and (nil ~= (_215_)[3])) then
      local w = (_215_)[2]
      local name = (_215_)[3]
      api.nvim_win_set_option(w, name, val)
    elseif ((_G.type(_215_) == "table") and ((_215_)[1] == "b") and (nil ~= (_215_)[2]) and (nil ~= (_215_)[3])) then
      local b = (_215_)[2]
      local name = (_215_)[3]
      api.nvim_buf_set_option(b, name, val)
    elseif (nil ~= _215_) then
      local name = _215_
      api.nvim_set_option(name, val)
    else
    end
  end
  return nil
end
local temporary_editor_opts = {["w.conceallevel"] = 0, ["g.scrolloff"] = 0, ["w.scrolloff"] = 0, ["g.sidescrolloff"] = 0, ["w.sidescrolloff"] = 0, ["b.modeline"] = false}
local function _217_()
  return set_editor_opts(temporary_editor_opts)
end
api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _217_, group = "LeapDefault"})
local function _218_()
  return restore_editor_opts()
end
api.nvim_create_autocmd("User", {pattern = "LeapLeave", callback = _218_, group = "LeapDefault"})
return {state = state, leap = leap}
