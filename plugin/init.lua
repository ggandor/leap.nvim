local plug_mappings = {
  ['<Plug>(leap-forward)'] = function()
    require'leap'.leap {}
  end,
  ['<Plug>(leap-backward)'] = function()
    require'leap'.leap { ['reverse?'] = true }
  end,
  ['<Plug>(leap-forward-x)'] = function()
    require'leap'.leap { offset = 1, ['inclusive-op?'] = true }
  end,
  ['<Plug>(leap-backward-x)'] = function()
    require'leap'.leap { offset = 2, ['reverse?'] = true }
  end,
  ['<Plug>(leap-cross-window)'] = function()
    require'leap'.leap { ['target-windows'] = true }
  end,
}

for lhs, rhs in pairs(plug_mappings) do
  vim.keymap.set({'n', 'x', 'o'}, lhs, rhs, {silent = true})
end
