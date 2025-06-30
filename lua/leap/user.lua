local function set_default_mappings()
  for _, _1_ in ipairs({{{"n", "x", "o"}, "s", "<Plug>(leap)", "Leap"}, {{"n"}, "S", "<Plug>(leap-from-window)", "Leap from window"}}) do
    local modes = _1_[1]
    local lhs = _1_[2]
    local rhs = _1_[3]
    local desc = _1_[4]
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
local function with_traversal_keys(fwd_key, bwd_key)
  local leap = require("leap")
  local keys = vim.deepcopy(leap.opts.keys)
  local function with_key(t, key)
    local t0
    do
      local _4_ = type(t)
      if (_4_ == "table") then
        t0 = t
      else
        local _ = _4_
        t0 = {t}
      end
    end
    table.insert(t0, key)
    return t0
  end
  local keys_2a = {next_target = with_key(keys.next_target, fwd_key), prev_target = with_key(keys.prev_target, bwd_key)}
  local safe_labels = vim.deepcopy(leap.opts.safe_labels)
  if (type(safe_labels) == "string") then
    safe_labels = vim.fn.split(safe_labels, "\\zs")
  else
  end
  local safe_labels_2a
  do
    local tbl_19_ = {fwd_key}
    for _, l in ipairs(safe_labels) do
      local val_20_
      if ((l ~= fwd_key) and (l ~= bwd_key)) then
        val_20_ = l
      else
        val_20_ = nil
      end
      table.insert(tbl_19_, val_20_)
    end
    safe_labels_2a = tbl_19_
  end
  return {keys = keys_2a, safe_labels = safe_labels_2a}
end
local function set_repeat_keys(fwd_key, bwd_key, opts_2a)
  local opts_2a0 = (opts_2a or {})
  local modes = (opts_2a0.modes or {"n", "x", "o"})
  local relative_directions_3f = opts_2a0.relative_directions
  local function leap_repeat(backward_invoc_3f)
    local leap = require("leap")
    local opts
    local _8_
    if backward_invoc_3f then
      _8_ = bwd_key
    else
      _8_ = fwd_key
    end
    local _10_
    if backward_invoc_3f then
      _10_ = fwd_key
    else
      _10_ = bwd_key
    end
    opts = {keys = vim.tbl_extend("force", leap.opts.keys, {next_target = _8_, prev_target = _10_})}
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
  local function _14_()
    return leap_repeat(false)
  end
  vim.keymap.set(modes, fwd_key, _14_, {silent = true, desc = "Repeat leap"})
  local function _15_()
    return leap_repeat(true)
  end
  local _16_
  if relative_directions_3f then
    _16_ = "Repeat leap in opposite direction"
  else
    _16_ = "Repeat leap backward"
  end
  return vim.keymap.set(modes, bwd_key, _15_, {silent = true, desc = _16_})
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
  for k, v in pairs(user_opts) do
    require("leap.opts")["default"][k] = v
  end
  return nil
end
local function _25_()
  return require("leap.util").get_enterable_windows()
end
local function _26_()
  return require("leap.util").get_focusable_windows()
end
return {set_default_mappings = set_default_mappings, with_traversal_keys = with_traversal_keys, set_repeat_keys = set_repeat_keys, get_enterable_windows = _25_, get_focusable_windows = _26_, create_default_mappings = create_default_mappings, add_repeat_mappings = set_repeat_keys, add_default_mappings = add_default_mappings, set_default_keymaps = set_default_keymaps, setup = setup}
