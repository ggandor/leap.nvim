local function add_default_mappings(force_3f)
  for _, _1_ in ipairs({{{"n", "x", "o"}, "s", "<Plug>(leap-forward-to)", "Leap forward to"}, {{"n", "x", "o"}, "S", "<Plug>(leap-backward-to)", "Leap backward to"}, {{"x", "o"}, "x", "<Plug>(leap-forward-till)", "Leap forward till"}, {{"x", "o"}, "X", "<Plug>(leap-backward-till)", "Leap backward till"}, {{"n", "x", "o"}, "gs", "<Plug>(leap-from-window)", "Leap from window"}, {{"n", "x", "o"}, "gs", "<Plug>(leap-cross-window)", "Leap from window"}}) do
    local _each_2_ = _1_
    local modes = _each_2_[1]
    local lhs = _each_2_[2]
    local rhs = _each_2_[3]
    local desc = _each_2_[4]
    for _0, mode in ipairs(modes) do
      if (force_3f or ((vim.fn.mapcheck(lhs, mode) == "") and (vim.fn.hasmapto(rhs, mode) == 0))) then
        vim.keymap.set(mode, lhs, rhs, {silent = true, desc = desc})
      else
      end
    end
  end
  return nil
end
local function add_repeat_mappings(forward_key, backward_key, kwargs)
  local kwargs0 = (kwargs or {})
  local modes = (kwargs0.modes or {"n", "x", "o"})
  local relative_directions_3f = kwargs0.relative_directions
  local function do_repeat(backward_3f)
    local state = (require("leap.main")).state
    local sk = (require("leap")).opts.special_keys
    local leap = (require("leap")).leap
    local id
    local function _4_()
      state.saved_next_target = sk.next_target
      state.saved_prev_target = sk.prev_target
      if backward_3f then
        sk.next_target = backward_key
      else
        sk.next_target = forward_key
      end
      if backward_3f then
        sk.prev_target = forward_key
      else
        sk.prev_target = backward_key
      end
      state.added_temp_keys = true
      return nil
    end
    id = vim.api.nvim_create_autocmd("User", {pattern = "LeapPatternPost", once = true, callback = _4_})
    local function _7_()
      pcall(vim.api.nvim_del_autocmd, id)
      if state.added_temp_keys then
        sk.next_target = state.saved_next_target
        sk.prev_target = state.saved_prev_target
        state.added_temp_keys = false
        return nil
      else
        return nil
      end
    end
    vim.api.nvim_create_autocmd("User", {pattern = "LeapLeave", once = true, callback = _7_})
    local _9_
    if relative_directions_3f then
      if backward_3f then
        _9_ = not state["repeat"].backward
      else
        _9_ = state["repeat"].backward
      end
    else
      _9_ = backward_3f
    end
    return leap({["repeat"] = true, backward = _9_})
  end
  local function _12_()
    return do_repeat()
  end
  vim.keymap.set(modes, forward_key, _12_, {silent = true, desc = "Repeat Leap motion"})
  local function _13_()
    return do_repeat(true)
  end
  return vim.keymap.set(modes, backward_key, _13_, {silent = true, desc = "Repeat Leap motion backward"})
end
local function set_default_keymaps(force_3f)
  for _, _14_ in ipairs({{"n", "s", "<Plug>(leap-forward)"}, {"n", "S", "<Plug>(leap-backward)"}, {"x", "s", "<Plug>(leap-forward)"}, {"x", "S", "<Plug>(leap-backward)"}, {"o", "z", "<Plug>(leap-forward)"}, {"o", "Z", "<Plug>(leap-backward)"}, {"o", "x", "<Plug>(leap-forward-x)"}, {"o", "X", "<Plug>(leap-backward-x)"}, {"n", "gs", "<Plug>(leap-cross-window)"}, {"x", "gs", "<Plug>(leap-cross-window)"}, {"o", "gs", "<Plug>(leap-cross-window)"}}) do
    local _each_15_ = _14_
    local mode = _each_15_[1]
    local lhs = _each_15_[2]
    local rhs = _each_15_[3]
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
return {add_default_mappings = add_default_mappings, add_repeat_mappings = add_repeat_mappings, set_default_keymaps = set_default_keymaps, setup = setup}
