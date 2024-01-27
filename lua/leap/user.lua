local function create_default_mappings()
  for _, _1_ in ipairs({{{"n", "x", "o"}, "s", "<Plug>(leap-forward)", "Leap forward"}, {{"n", "x", "o"}, "S", "<Plug>(leap-backward)", "Leap backward"}, {{"n", "x", "o"}, "gs", "<Plug>(leap-from-window)", "Leap from window"}}) do
    local _each_2_ = _1_
    local modes = _each_2_[1]
    local lhs = _each_2_[2]
    local rhs = _each_2_[3]
    local desc = _each_2_[4]
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
local function set_repeat_keys(fwd_key, bwd_key, opts_2a)
  local opts_2a0 = (opts_2a or {})
  local modes = (opts_2a0.modes or {"n", "x", "o"})
  local relative_directions_3f = opts_2a0.relative_directions
  local function leap_repeat(backward_invoc_3f)
    local leap = require("leap")
    local opts
    local _5_
    if backward_invoc_3f then
      _5_ = bwd_key
    else
      _5_ = fwd_key
    end
    local _7_
    if backward_invoc_3f then
      _7_ = fwd_key
    else
      _7_ = bwd_key
    end
    opts = {special_keys = vim.tbl_extend("force", leap.opts.special_keys, {next_target = _5_, prev_target = _7_})}
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
  local function _11_()
    return leap_repeat(false)
  end
  vim.keymap.set(modes, fwd_key, _11_, {silent = true, desc = "Repeat leap"})
  local function _12_()
    return leap_repeat(true)
  end
  local _13_
  if relative_directions_3f then
    _13_ = "Repeat leap in opposite direction"
  else
    _13_ = "Repeat leap backward"
  end
  return vim.keymap.set(modes, bwd_key, _12_, {silent = true, desc = _13_})
end
local function add_default_mappings(force_3f)
  for _, _15_ in ipairs({{{"n", "x", "o"}, "s", "<Plug>(leap-forward-to)", "Leap forward to"}, {{"n", "x", "o"}, "S", "<Plug>(leap-backward-to)", "Leap backward to"}, {{"x", "o"}, "x", "<Plug>(leap-forward-till)", "Leap forward till"}, {{"x", "o"}, "X", "<Plug>(leap-backward-till)", "Leap backward till"}, {{"n", "x", "o"}, "gs", "<Plug>(leap-from-window)", "Leap from window"}, {{"n", "x", "o"}, "gs", "<Plug>(leap-cross-window)", "Leap from window"}}) do
    local _each_16_ = _15_
    local modes = _each_16_[1]
    local lhs = _each_16_[2]
    local rhs = _each_16_[3]
    local desc = _each_16_[4]
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
  for _, _18_ in ipairs({{"n", "s", "<Plug>(leap-forward)"}, {"n", "S", "<Plug>(leap-backward)"}, {"x", "s", "<Plug>(leap-forward)"}, {"x", "S", "<Plug>(leap-backward)"}, {"o", "z", "<Plug>(leap-forward)"}, {"o", "Z", "<Plug>(leap-backward)"}, {"o", "x", "<Plug>(leap-forward-x)"}, {"o", "X", "<Plug>(leap-backward-x)"}, {"n", "gs", "<Plug>(leap-cross-window)"}, {"x", "gs", "<Plug>(leap-cross-window)"}, {"o", "gs", "<Plug>(leap-cross-window)"}}) do
    local _each_19_ = _18_
    local mode = _each_19_[1]
    local lhs = _each_19_[2]
    local rhs = _each_19_[3]
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
return {create_default_mappings = create_default_mappings, set_repeat_keys = set_repeat_keys, add_repeat_mappings = set_repeat_keys, add_default_mappings = add_default_mappings, set_default_keymaps = set_default_keymaps, setup = setup}
