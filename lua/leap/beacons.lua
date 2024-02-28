local hl = require("leap.highlight")
local opts = require("leap.opts")
local _local_1_ = require("leap.util")
local dec = _local_1_["dec"]
local api = vim.api
local map = vim.tbl_map
local function set_beacon_to_match_hl(target)
  local virttext
  local function _2_(_241)
    return (opts.substitute_chars[_241] or _241)
  end
  virttext = table.concat(map(_2_, target.chars))
  target.beacon = {0, {{virttext, hl.group.match}}}
  return nil
end
local function get_label_offset(target)
  local _let_3_ = target
  local _let_4_ = _let_3_["chars"]
  local ch1 = _let_4_[1]
  local ch2 = _let_4_[2]
  if (ch1 == "\n") then
    return 0
  elseif (target["edge-pos?"] or (ch2 == "\n")) then
    return ch1:len()
  else
    return (ch1:len() + ch2:len())
  end
end
local function set_beacon_for_labeled(target, group_offset, _6_)
  local _arg_7_ = _6_
  local user_given_targets_3f = _arg_7_["user-given-targets?"]
  local phase = _arg_7_["phase"]
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
  if (group_2a == 1) then
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
local function set_beacons(targets, _13_)
  local _arg_14_ = _13_
  local group_offset = _arg_14_["group-offset"]
  local no_labels_3f = _arg_14_["no-labels?"]
  local user_given_targets_3f = _arg_14_["user-given-targets?"]
  local phase = _arg_14_["phase"]
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
      local _let_18_ = target.wininfo
      local bufnr = _let_18_["bufnr"]
      local winid = _let_18_["winid"]
      local _let_19_ = target.pos
      local lnum = _let_19_[1]
      local col_ch1 = _let_19_[2]
      local col_ch2 = (col_ch1 + string.len(target.chars[1]))
      local key_prefix = (bufnr .. " " .. winid .. " " .. lnum .. " ")
      if (target.label and target.beacon) then
        local label_offset = target.beacon[1]
        local col_label = (col_ch1 + label_offset)
        local shifted_label_3f = (col_label == col_ch2)
        do
          local _20_
          local function _21_(...)
            if shifted_label_3f then
              return unlabeled_match_positions[(key_prefix .. col_ch1)]
            else
              return nil
            end
          end
          _20_ = (label_positions[(key_prefix .. col_label)] or _21_() or unlabeled_match_positions[(key_prefix .. col_label)])
          if (nil ~= _20_) then
            local other = _20_
            other.beacon = nil
            set_beacon_to_empty_label(target)
          else
          end
        end
        label_positions[(key_prefix .. col_label)] = target
      else
        local col_ch3 = (col_ch2 + string.len(target.chars[2]))
        do
          local _24_ = (label_positions[(key_prefix .. col_ch1)] or label_positions[(key_prefix .. col_ch2)] or label_positions[(key_prefix .. col_ch3)])
          if (nil ~= _24_) then
            local other = _24_
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
local function light_up_beacons(targets, _3fstart, _3fend)
  if (not opts.on_beacons or opts.on_beacons(targets, _3fstart, _3fend)) then
    for i = (_3fstart or 1), (_3fend or #targets) do
      local target = targets[i]
      local _28_ = target.beacon
      if ((_G.type(_28_) == "table") and (nil ~= _28_[1]) and (nil ~= _28_[2])) then
        local offset = _28_[1]
        local virttext = _28_[2]
        local bufnr = target.wininfo.bufnr
        local _let_29_ = map(dec, target.pos)
        local lnum = _let_29_[1]
        local col = _let_29_[2]
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
return {["set-beacons"] = set_beacons, ["resolve-conflicts"] = resolve_conflicts, ["light-up-beacons"] = light_up_beacons}
