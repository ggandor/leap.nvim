local function setup(user_opts)
  for k, v in pairs(user_opts) do
    require("leap.opts")["default"][k] = v
  end
  return nil
end
local function add_default_mappings(force_3f)
  for _, _1_ in ipairs({{{"n", "x", "o"}, "s", "<Plug>(leap-forward-to)"}, {{"n", "x", "o"}, "S", "<Plug>(leap-backward-to)"}, {{"x", "o"}, "x", "<Plug>(leap-forward-till)"}, {{"x", "o"}, "X", "<Plug>(leap-backward-till)"}, {{"n", "x", "o"}, "gs", "<Plug>(leap-cross-window)"}}) do
    local _each_2_ = _1_
    local modes = _each_2_[1]
    local lhs = _each_2_[2]
    local rhs = _each_2_[3]
    for _0, mode in ipairs(modes) do
      if (force_3f or ((vim.fn.mapcheck(lhs, mode) == "") and (vim.fn.hasmapto(rhs, mode) == 0))) then
        vim.keymap.set(mode, lhs, rhs, {silent = true})
      else
      end
    end
  end
  return nil
end
local function set_default_keymaps(force_3f)
  for _, _4_ in ipairs({{"n", "s", "<Plug>(leap-forward)"}, {"n", "S", "<Plug>(leap-backward)"}, {"x", "s", "<Plug>(leap-forward)"}, {"x", "S", "<Plug>(leap-backward)"}, {"o", "z", "<Plug>(leap-forward)"}, {"o", "Z", "<Plug>(leap-backward)"}, {"o", "x", "<Plug>(leap-forward-x)"}, {"o", "X", "<Plug>(leap-backward-x)"}, {"n", "gs", "<Plug>(leap-cross-window)"}, {"x", "gs", "<Plug>(leap-cross-window)"}, {"o", "gs", "<Plug>(leap-cross-window)"}}) do
    local _each_5_ = _4_
    local mode = _each_5_[1]
    local lhs = _each_5_[2]
    local rhs = _each_5_[3]
    if (force_3f or ((vim.fn.mapcheck(lhs, mode) == "") and (vim.fn.hasmapto(rhs, mode) == 0))) then
      vim.keymap.set(mode, lhs, rhs, {silent = true})
    else
    end
  end
  return nil
end
return {setup = setup, add_default_mappings = add_default_mappings, set_default_keymaps = set_default_keymaps}
