local hl = require("leap.highlight")
local opts = require("leap.opts")
local api = vim.api
local map = vim.tbl_map
local function should_highlight_matches_3f()
  local or_1_ = (0 ~= opts.highlight_target_range_for_phase2)
  if not or_1_ then
    if opts.highlight_unlabeled_phase_one_targets then
      opts.highlight_target_range_for_phase2 = 1
      or_1_ = true
    else
      or_1_ = nil
    end
  end
  return or_1_
end
local function set_beacon_to_match_hl(target)
  local offset = math.max(0, ( - opts.highlight_target_range_for_phase2))
  local slice
  if (0 < opts.highlight_target_range_for_phase2) then
    slice = vim.list_slice(target.chars, 1, opts.highlight_target_range_for_phase2)
  else
    slice = vim.list_slice(target.chars, (#target.chars - 1 - opts.highlight_target_range_for_phase2))
  end
  local virttext
  local function _4_(_241)
    return (opts.substitute_chars[_241] or _241)
  end
  virttext = table.concat(map(_4_, slice))
  target.beacon = {offset, {{virttext, hl.group.match}}}
  return nil
end
local function get_label_offset(target)
  local _let_5_ = target["chars"]
  local ch1 = _let_5_[1]
  local ch2 = _let_5_[2]
  if (ch1 == "\n") then
    return 0
  elseif (target["edge-pos?"] or (ch2 == "\n")) then
    return ch1:len()
  else
    return (ch1:len() + ch2:len())
  end
end
local function set_beacon_for_labeled(target, _3fgroup_offset, _3fphase)
  local offset
  if (target.chars and _3fphase) then
    offset = get_label_offset(target)
  else
    offset = 0
  end
  local pad
  if ((opts.max_phase_one_targets ~= 0) and not _3fphase and target.chars and target.chars[2]) then
    pad = " "
  else
    pad = ""
  end
  local label = (opts.substitute_chars[target.label] or target.label)
  local relative_group = (target.group - (_3fgroup_offset or 0))
  local show_all_3f = (_3fphase and not should_highlight_matches_3f())
  local virttext
  if (relative_group == 1) then
    virttext = {{(label .. pad), hl.group.label}}
  elseif (relative_group == 2) then
    virttext = {{(opts.concealed_label .. pad), hl.group["label-dimmed"]}}
  elseif ((relative_group > 2) and show_all_3f) then
    virttext = {{(opts.concealed_label .. pad), hl.group["label-dimmed"]}}
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
local function set_beacons(targets, _11_)
  local group_offset = _11_["group-offset"]
  local use_no_labels_3f = _11_["use-no-labels?"]
  local phase = _11_["phase"]
  if use_no_labels_3f then
    if (targets[1].chars and should_highlight_matches_3f()) then
      for _, target in ipairs(targets) do
        set_beacon_to_match_hl(target)
      end
      return nil
    else
      return nil
    end
  else
    for _, target in ipairs(targets) do
      if target.label then
        if ((phase ~= 1) or target["previewable?"]) then
          set_beacon_for_labeled(target, group_offset, phase)
        else
        end
      elseif ((phase == 1) and should_highlight_matches_3f()) then
        set_beacon_to_match_hl(target)
      else
      end
    end
    return nil
  end
end
local function resolve_conflicts(targets)
  local function set_beacon_to_empty_label(target)
    if target.beacon then
      target["beacon"][2][1][1] = opts.concealed_label
      return nil
    else
      return nil
    end
  end
  local unlabeled_match_positions = {}
  local label_positions = {}
  for _, target in ipairs(targets) do
    local empty_line_3f = ((target.chars[1] == "\n") and (target.pos[2] == 0))
    if not empty_line_3f then
      local bufnr = target.wininfo["bufnr"]
      local winid = target.wininfo["winid"]
      local lnum = target.pos[1]
      local col_ch1 = target.pos[2]
      local col_ch2 = (col_ch1 + string.len(target.chars[1]))
      local key_prefix = (bufnr .. " " .. winid .. " " .. lnum .. " ")
      if (target.label and target.beacon) then
        local label_offset = target.beacon[1]
        local col_label = (col_ch1 + label_offset)
        local shifted_label_3f = (col_label == col_ch2)
        do
          local _17_
          local or_18_ = label_positions[(key_prefix .. col_label)]
          if not or_18_ then
            if shifted_label_3f then
              or_18_ = unlabeled_match_positions[(key_prefix .. col_ch1)]
            else
              or_18_ = nil
            end
          end
          if not or_18_ then
            or_18_ = unlabeled_match_positions[(key_prefix .. col_label)]
          end
          _17_ = or_18_
          if (nil ~= _17_) then
            local other = _17_
            other.beacon = nil
            set_beacon_to_empty_label(target)
          else
          end
        end
        label_positions[(key_prefix .. col_label)] = target
      else
        local col_ch3 = (col_ch2 + string.len(target.chars[2]))
        do
          local _21_
          local or_22_ = label_positions[(key_prefix .. col_ch1)]
          if not or_22_ then
            or_22_ = label_positions[(key_prefix .. col_ch2)]
          end
          if not or_22_ then
            or_22_ = label_positions[(key_prefix .. col_ch3)]
          end
          _21_ = or_22_
          if (nil ~= _21_) then
            local other = _21_
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
local function light_up_beacon(target, endpos_3f)
  local _let_26_ = ((endpos_3f and target.endpos) or target.pos)
  local lnum = _let_26_[1]
  local col = _let_26_[2]
  local bufnr = target.wininfo.bufnr
  local offset = target.beacon[1]
  local virttext = target.beacon[2]
  local opts0 = {virt_text = virttext, virt_text_pos = (opts.virt_text_pos or "overlay"), hl_mode = "combine", priority = hl.priority.label, strict = false}
  local id = api.nvim_buf_set_extmark(bufnr, hl.ns, (lnum - 1), (col + -1 + offset), opts0)
  return table.insert(hl.extmarks, {bufnr, id})
end
local function light_up_beacons(targets, _3fstart, _3fend)
  if (not opts.on_beacons or opts.on_beacons(targets, _3fstart, _3fend)) then
    for i = (_3fstart or 1), (_3fend or #targets) do
      local target = targets[i]
      if target.beacon then
        light_up_beacon(target)
        if target.endpos then
          light_up_beacon(target, true)
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
return {["set-beacons"] = set_beacons, ["resolve-conflicts"] = resolve_conflicts, ["light-up-beacons"] = light_up_beacons}
