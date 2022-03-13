local plug_mappings = {
  ['<Plug>(leap-forward)'] = function()
    require'leap'.leap {}
  end,
  ['<Plug>(leap-backward)'] = function()
    require'leap'.leap { ['reverse?'] = true }
  end,
  ['<Plug>(leap-forward-x)'] = function()
    require'leap'.leap { ['x-mode?'] = true }
  end,
  ['<Plug>(leap-backward-x)'] = function()
    require'leap'.leap { ['reverse?'] = true, ['x-mode?'] = true }
  end,
  ['<Plug>(leap-omni)'] = function()
    require'leap'.leap { ['omni?'] = true }
  end,
  ['<Plug>(leap-cross-window)'] = function() 
    require'leap'.leap { ['omni?'] = true, ['cross-window?'] = true }
  end,
}

for lhs, rhs in pairs(plug_mappings) do
  vim.keymap.set({'n', 'x', 'o'}, lhs, rhs, {silent = true})
end
