local plug_mappings = {
  ['<Plug>(leap-forward)'] = function()
    require'leap'.leap {}
  end,
  ['<Plug>(leap-backward)'] = function()
    require'leap'.leap { ['backward?'] = true }
  end,
  ['<Plug>(leap-forward-x)'] = function()
    require'leap'.leap { offset = 1, ['inclusive-op?'] = true }
  end,
  ['<Plug>(leap-backward-x)'] = function()
    require'leap'.leap { offset = 2, ['backward?'] = true }
  end,
  ['<Plug>(leap-cross-window)'] = function()
    require'leap'.leap {
      ['target-windows'] = require'leap.util'.get_enterable_windows()
    }
  end,
}

for lhs, rhs in pairs(plug_mappings) do
  vim.keymap.set({'n', 'x', 'o'}, lhs, rhs, {silent = true})
end
