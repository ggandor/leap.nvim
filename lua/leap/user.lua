-- Code generated from fnl/leap/user.fnl - do not edit directly.

local function with_traversal_keys(fwd_key, bwd_key, opts)
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
  local opts_2a = {keys = {next_target = with_key(keys.next_target, fwd_key), prev_target = with_key(keys.prev_target, bwd_key)}}
  if opts then
    return vim.tbl_deep_extend("error", opts, opts_2a)
  else
    return opts_2a
  end
end
local function set_repeat_keys(fwd_key, bwd_key, opts_2a)
  local opts_2a0 = (opts_2a or {})
  local modes = (opts_2a0.modes or {"n", "x", "o"})
  local relative_directions_3f = opts_2a0.relative_directions
  local function leap_repeat(backward_invoc_3f)
    local leap = require("leap")
    local opts
    local _4_
    if backward_invoc_3f then
      _4_ = bwd_key
    else
      _4_ = fwd_key
    end
    local _6_
    if backward_invoc_3f then
      _6_ = fwd_key
    else
      _6_ = bwd_key
    end
    opts = {keys = vim.tbl_extend("force", leap.opts.keys, {next_target = _4_, prev_target = _6_})}
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
  local function _10_()
    return leap_repeat(false)
  end
  local _11_
  if relative_directions_3f then
    _11_ = "Repeat leap in the previous direction"
  else
    _11_ = "Repeat leap forward"
  end
  vim.keymap.set(modes, fwd_key, _10_, {silent = true, desc = _11_})
  local function _13_()
    return leap_repeat(true)
  end
  local _14_
  if relative_directions_3f then
    _14_ = "Repeat leap in the opposite direction"
  else
    _14_ = "Repeat leap backward"
  end
  return vim.keymap.set(modes, bwd_key, _13_, {silent = true, desc = _14_})
end
local function set_default_mappings()
  local msg = ("leap.nvim: `set_default_mappings()` is deprecated. " .. "See `:help leap-mappings` to update your config.")
  vim.notify(msg, vim.log.levels.WARN)
  for _, _16_ in ipairs({{{"n", "x", "o"}, "s", "<Plug>(leap)", "Leap"}, {{"n"}, "S", "<Plug>(leap-from-window)", "Leap from window"}}) do
    local modes = _16_[1]
    local lhs = _16_[2]
    local rhs = _16_[3]
    local desc = _16_[4]
    for _0, mode in ipairs(modes) do
      local rhs_2a = vim.fn.mapcheck(lhs, mode)
      if (rhs_2a == "") then
        vim.keymap.set(mode, lhs, rhs, {silent = true, desc = desc})
      else
        if (rhs_2a ~= rhs) then
          local msg0 = ("leap.nvim: set_default_mappings() " .. "found conflicting mapping for " .. lhs .. ": " .. rhs_2a)
          vim.notify(msg0, vim.log.levels.WARN)
        else
        end
      end
    end
  end
  return nil
end
local function create_default_mappings()
  local msg = ("leap.nvim: `create_default_mappings()` is deprecated. " .. "See `:help leap-mappings` to update your config.")
  vim.notify(msg, vim.log.levels.WARN)
  for _, _19_ in ipairs({{{"n", "x", "o"}, "s", "<Plug>(leap-forward)", "Leap forward"}, {{"n", "x", "o"}, "S", "<Plug>(leap-backward)", "Leap backward"}, {{"n", "x", "o"}, "gs", "<Plug>(leap-from-window)", "Leap from window"}}) do
    local modes = _19_[1]
    local lhs = _19_[2]
    local rhs = _19_[3]
    local desc = _19_[4]
    for _0, mode in ipairs(modes) do
      local rhs_2a = vim.fn.mapcheck(lhs, mode)
      if (rhs_2a == "") then
        vim.keymap.set(mode, lhs, rhs, {silent = true, desc = desc})
      else
        if (rhs_2a ~= rhs) then
          local msg0 = ("leap.nvim: create_default_mappings() " .. "found conflicting mapping for " .. lhs .. ": " .. rhs_2a)
          vim.notify(msg0, vim.log.levels.WARN)
        else
        end
      end
    end
  end
  return nil
end
local function add_default_mappings(force_3f)
  local msg = ("leap.nvim: `add_default_mappings()` is deprecated. " .. "See `:help leap-mappings` to update your config.")
  vim.notify(msg, vim.log.levels.WARN)
  for _, _22_ in ipairs({{{"n", "x", "o"}, "s", "<Plug>(leap-forward)", "Leap forward"}, {{"n", "x", "o"}, "S", "<Plug>(leap-backward)", "Leap backward"}, {{"x", "o"}, "x", "<Plug>(leap-forward-till)", "Leap forward till"}, {{"x", "o"}, "X", "<Plug>(leap-backward-till)", "Leap backward till"}, {{"n", "x", "o"}, "gs", "<Plug>(leap-from-window)", "Leap from window"}}) do
    local modes = _22_[1]
    local lhs = _22_[2]
    local rhs = _22_[3]
    local desc = _22_[4]
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
  local msg = ("leap.nvim: `set_default_keymaps()` is deprecated. " .. "See `:help leap-mappings` to update your config.")
  vim.notify(msg, vim.log.levels.WARN)
  for _, _24_ in ipairs({{"n", "s", "<Plug>(leap-forward)"}, {"n", "S", "<Plug>(leap-backward)"}, {"x", "s", "<Plug>(leap-forward)"}, {"x", "S", "<Plug>(leap-backward)"}, {"o", "z", "<Plug>(leap-forward)"}, {"o", "Z", "<Plug>(leap-backward)"}, {"o", "x", "<Plug>(leap-forward-x)"}, {"o", "X", "<Plug>(leap-backward-x)"}, {"n", "gs", "<Plug>(leap-cross-window)"}, {"x", "gs", "<Plug>(leap-cross-window)"}, {"o", "gs", "<Plug>(leap-cross-window)"}}) do
    local mode = _24_[1]
    local lhs = _24_[2]
    local rhs = _24_[3]
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
local function _26_()
  return require("leap.util").get_enterable_windows()
end
local function _27_()
  return require("leap.util").get_focusable_windows()
end
return {with_traversal_keys = with_traversal_keys, set_repeat_keys = set_repeat_keys, get_enterable_windows = _26_, get_focusable_windows = _27_, set_default_mappings = set_default_mappings, create_default_mappings = create_default_mappings, add_repeat_mappings = set_repeat_keys, add_default_mappings = add_default_mappings, set_default_keymaps = set_default_keymaps, setup = setup}
