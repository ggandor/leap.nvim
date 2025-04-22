local hl = require("leap.highlight")
local opts = require("leap.opts")
local api = vim.api
local map = vim.tbl_map
local function set_beacon_to_match_hl(target)
  local _local_1_ = target["chars"]
  local ch1 = _local_1_[1]
  local ch2 = _local_1_[2]
  if (ch1 == "\n") then
    target.beacon = {0, {virt_text = {{" ", hl.group.match}}}}
    return nil
  else
    local col = target.pos[2]
    local len = (ch1:len() + ((ch2 and (ch2 ~= "\n") and ch2:len()) or 0))
    target.beacon = {0, {end_col = (col + len + -1), hl_group = hl.group.match}}
    return nil
  end
end
local function get_label_offset(target)
  local _let_3_ = target["chars"]
  local ch1 = _let_3_[1]
  local ch2 = _let_3_[2]
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
  local show_all_3f = (_3fphase and not opts.highlight_unlabeled_phase_one_targets)
  local vtext
  if (relative_group == 1) then
    vtext = {{(label .. pad), hl.group.label}}
  elseif (relative_group == 2) then
    vtext = {{(opts.concealed_label .. pad), hl.group["label-dimmed"]}}
  elseif ((relative_group > 2) and show_all_3f) then
    vtext = {{(opts.concealed_label .. pad), hl.group["label-dimmed"]}}
  else
    vtext = nil
  end
  if vtext then
    target.beacon = {offset, {virt_text = vtext}}
  else
    target.beacon = nil
  end
  return nil
end
local function set_beacons(targets, _9_)
  local group_offset = _9_["group-offset"]
  local use_no_labels_3f = _9_["use-no-labels?"]
  local phase = _9_["phase"]
  if use_no_labels_3f then
    if targets[1].chars then
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
      elseif ((phase == 1) and target["previewable?"] and opts.highlight_unlabeled_phase_one_targets) then
        set_beacon_to_match_hl(target)
      else
      end
    end
    return nil
  end
end
local function resolve_conflicts(targets)
  local function set_beacon_to_concealed_label(target)
    local vtext = target.beacon[2].virt_text
    if vtext then
      vtext[1][1] = opts.concealed_label
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
          local _15_
          local or_16_ = label_positions[(key_prefix .. col_label)]
          if not or_16_ then
            if shifted_label_3f then
              or_16_ = unlabeled_match_positions[(key_prefix .. col_ch1)]
            else
              or_16_ = nil
            end
          end
          if not or_16_ then
            or_16_ = unlabeled_match_positions[(key_prefix .. col_label)]
          end
          _15_ = or_16_
          if (nil ~= _15_) then
            local other = _15_
            other.beacon = nil
            set_beacon_to_concealed_label(target)
          else
          end
        end
        label_positions[(key_prefix .. col_label)] = target
      else
        local col_ch3 = (col_ch2 + string.len(target.chars[2]))
        do
          local _19_
          local or_20_ = label_positions[(key_prefix .. col_ch1)]
          if not or_20_ then
            or_20_ = label_positions[(key_prefix .. col_ch2)]
          end
          if not or_20_ then
            or_20_ = label_positions[(key_prefix .. col_ch3)]
          end
          _19_ = or_20_
          if (nil ~= _19_) then
            local other = _19_
            target.beacon = nil
            set_beacon_to_concealed_label(other)
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
  local _let_24_ = ((endpos_3f and target.endpos) or target.pos)
  local lnum = _let_24_[1]
  local col = _let_24_[2]
  local bufnr = target.wininfo.bufnr
  local offset = target.beacon[1]
  local opts_2a = target.beacon[2]
  local opts0 = vim.tbl_extend("keep", opts_2a, {virt_text_pos = (opts.virt_text_pos or "overlay"), hl_mode = "combine", priority = hl.priority.label, strict = false})
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
