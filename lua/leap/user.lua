-- Code generated from fnl/leap/user.fnl - do not edit directly.

local function with_traversal_keys(fwd_key, bwd_key)
  local with_key
  local function _1_(t, key)
    if (type(t) == "table") then
      return {t[1], key}
    else
      return {t, key}
    end
  end
  with_key = _1_
  local keys = vim.deepcopy(require("leap").opts.keys)
  return {keys = {next_target = with_key(keys.next_target, fwd_key), prev_target = with_key(keys.prev_target, bwd_key)}}
end
local function set_repeat_keys(fwd_key, bwd_key, opts_2a)
  local opts_2a0 = (opts_2a or {})
  local modes = (opts_2a0.modes or {"n", "x", "o"})
  local relative_directions_3f = opts_2a0.relative_directions
  local function leap_repeat(backward_invoc_3f)
    local leap = require("leap")
    local opts
    local _3_
    if backward_invoc_3f then
      _3_ = bwd_key
    else
      _3_ = fwd_key
    end
    local _5_
    if backward_invoc_3f then
      _5_ = fwd_key
    else
      _5_ = bwd_key
    end
    opts = {keys = vim.tbl_extend("force", leap.opts.keys, {next_target = _3_, prev_target = _5_})}
    local backward
    if relative_directions_3f then
      if backward_invoc_3f then
        backward = not leap.state["repeat"].backward
      else
        backward = leap.state["repeat"].backward
      end
    else
      backward = backward_invoc_3f
    end
    return leap.leap({["repeat"] = true, opts = opts, backward = backward})
  end
  local function _9_()
    return leap_repeat(false)
  end
  local _10_
  if relative_directions_3f then
    _10_ = "Repeat leap in the previous direction"
  else
    _10_ = "Repeat leap forward"
  end
  vim.keymap.set(modes, fwd_key, _9_, {silent = true, desc = _10_})
  local function _12_()
    return leap_repeat(true)
  end
  local _13_
  if relative_directions_3f then
    _13_ = "Repeat leap in the opposite direction"
  else
    _13_ = "Repeat leap backward"
  end
  return vim.keymap.set(modes, bwd_key, _12_, {silent = true, desc = _13_})
end
local function set_default_mappings()
  for _, _15_ in ipairs({{{"n", "x", "o"}, "s", "<Plug>(leap)", "Leap"}, {{"n"}, "S", "<Plug>(leap-from-window)", "Leap from window"}}) do
    local modes = _15_[1]
    local lhs = _15_[2]
    local rhs = _15_[3]
    local desc = _15_[4]
    for _0, mode in ipairs(modes) do
      local rhs_2a = vim.fn.mapcheck(lhs, mode)
      if (rhs_2a == "") then
        vim.keymap.set(mode, lhs, rhs, {silent = true, desc = desc})
      else
        if (rhs_2a ~= rhs) then
          local msg = ("leap.nvim: set_default_mappings() " .. "found conflicting mapping for " .. lhs .. ": " .. rhs_2a)
          vim.notify(msg, vim.log.levels.WARN)
        else
        end
      end
    end
  end
  return nil
end
local function create_default_mappings()
  for _, _18_ in ipairs({{{"n", "x", "o"}, "s", "<Plug>(leap-forward)", "Leap forward"}, {{"n", "x", "o"}, "S", "<Plug>(leap-backward)", "Leap backward"}, {{"n", "x", "o"}, "gs", "<Plug>(leap-from-window)", "Leap from window"}}) do
    local modes = _18_[1]
    local lhs = _18_[2]
    local rhs = _18_[3]
    local desc = _18_[4]
    for _0, mode in ipairs(modes) do
      local rhs_2a = vim.fn.mapcheck(lhs, mode)
      if (rhs_2a == "") then
        vim.keymap.set(mode, lhs, rhs, {silent = true, desc = desc})
      else
        if (rhs_2a ~= rhs) then
          local msg = ("leap.nvim: create_default_mappings() " .. "found conflicting mapping for " .. lhs .. ": " .. rhs_2a)
          vim.notify(msg, vim.log.levels.WARN)
        else
        end
      end
    end
  end
  return nil
end
local function add_default_mappings(force_3f)
  for _, _21_ in ipairs({{{"n", "x", "o"}, "s", "<Plug>(leap-forward-to)", "Leap forward to"}, {{"n", "x", "o"}, "S", "<Plug>(leap-backward-to)", "Leap backward to"}, {{"x", "o"}, "x", "<Plug>(leap-forward-till)", "Leap forward till"}, {{"x", "o"}, "X", "<Plug>(leap-backward-till)", "Leap backward till"}, {{"n", "x", "o"}, "gs", "<Plug>(leap-from-window)", "Leap from window"}, {{"n", "x", "o"}, "gs", "<Plug>(leap-cross-window)", "Leap from window"}}) do
    local modes = _21_[1]
    local lhs = _21_[2]
    local rhs = _21_[3]
    local desc = _21_[4]
    for _0, mode in ipairs(modes) do
      if (force_3f or ((vim.fn.mapcheck(lhs, mode) == "") and (vim.fn.hasmapto(rhs, mode) == 0))) then
        vim.keymap.set(mode, lhs, rhs, {silent = true, desc = desc})
      else
      end
    end
  end
  return nil
end
local function set_default_keymaps(force_3f)
  for _, _23_ in ipairs({{"n", "s", "<Plug>(leap-forward)"}, {"n", "S", "<Plug>(leap-backward)"}, {"x", "s", "<Plug>(leap-forward)"}, {"x", "S", "<Plug>(leap-backward)"}, {"o", "z", "<Plug>(leap-forward)"}, {"o", "Z", "<Plug>(leap-backward)"}, {"o", "x", "<Plug>(leap-forward-x)"}, {"o", "X", "<Plug>(leap-backward-x)"}, {"n", "gs", "<Plug>(leap-cross-window)"}, {"x", "gs", "<Plug>(leap-cross-window)"}, {"o", "gs", "<Plug>(leap-cross-window)"}}) do
    local mode = _23_[1]
    local lhs = _23_[2]
    local rhs = _23_[3]
    if (force_3f or ((vim.fn.mapcheck(lhs, mode) == "") and (vim.fn.hasmapto(rhs, mode) == 0))) then
      vim.keymap.set(mode, lhs, rhs, {silent = true})
    else
    end
  end
  return nil
end
local function setup(user_opts)
  local opts = require("leap.opts").default
  for k, v in pairs(user_opts) do
    opts[k] = v
  end
  return nil
end
local function _25_()
  return require("leap.util").get_enterable_windows()
end
local function _26_()
  return require("leap.util").get_focusable_windows()
end
return {with_traversal_keys = with_traversal_keys, set_repeat_keys = set_repeat_keys, get_enterable_windows = _25_, get_focusable_windows = _26_, set_default_mappings = set_default_mappings, create_default_mappings = create_default_mappings, add_repeat_mappings = set_repeat_keys, add_default_mappings = add_default_mappings, set_default_keymaps = set_default_keymaps, setup = setup}
