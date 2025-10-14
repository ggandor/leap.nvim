local plug_mappings = {
  {
    { 'n', 'x', 'o' },
    '<Plug>(leap)',
    function ()
      require('leap').leap {
        windows = { vim.api.nvim_get_current_win() },
        inclusive = true
      }
    end
  },
  {
    { 'n', 'x', 'o' },
    '<Plug>(leap-from-window)',
    function ()
      require('leap').leap {
        windows = require('leap.util').get_enterable_windows()
      }
    end
  },
  {
    { 'n', 'x', 'o' },
    '<Plug>(leap-anywhere)',
    function ()
      require('leap').leap {
        windows = require('leap.util').get_focusable_windows()
      }
    end
  },
  {
    { 'n', 'x', 'o' },
    '<Plug>(leap-forward)',
    function () require('leap').leap { inclusive = true } end
  },
  {
    { 'n', 'x', 'o' },
    '<Plug>(leap-backward)',
    function () require('leap').leap { backward = true } end
  },
  {
    { 'n', 'x', 'o' },
    '<Plug>(leap-forward-till)',
    function () require('leap').leap { offset = -1, inclusive = true } end
  },
  {
    { 'n', 'x', 'o' },
    '<Plug>(leap-backward-till)',
    function () require('leap').leap { backward = true, offset = 1 } end
  },

  -- Deprecated
  {
    { 'n', 'x', 'o' },
    '<Plug>(leap-forward-to)',
    function ()
      local msg = ('leap.nvim: <Plug>(leap-forward-to) is deprecated. '
                   .. 'See `:help leap-mappings` to update your config.')
      vim.notify(msg, vim.log.levels.WARN)
      require('leap').leap { inclusive = true }
    end
  },
  {
    { 'n', 'x', 'o' },
    '<Plug>(leap-backward-to)',
    function ()
      local msg = ('leap.nvim: <Plug>(leap-backward-to) is deprecated. '
                   .. 'See `:help leap-mappings` to update your config.')
      vim.notify(msg, vim.log.levels.WARN)
      require('leap').leap { backward = true }
    end
  },
  {
    { 'n', 'x', 'o' },
    '<Plug>(leap-cross-window)',
    function ()
      local msg = ('leap.nvim: <Plug>(leap-cross-window) is deprecated. '
                   .. 'See `:help leap-mappings` to update your config.')
      vim.notify(msg, vim.log.levels.WARN)
      require('leap').leap {
        windows = require('leap.util').get_enterable_windows()
      }
    end
  },
  {
    { 'n', 'x', 'o' },
    '<Plug>(leap-forward-x)',
    function ()
      local msg = ('leap.nvim: <Plug>(leap-forward-x) is deprecated. '
                   .. 'See `:help leap-mappings` to update your config.')
      vim.notify(msg, vim.log.levels.WARN)
      require('leap').leap { offset = 1, inclusive = true }
    end
  },
  {
    { 'n', 'x', 'o' },
    '<Plug>(leap-backward-x)',
    function ()
      local msg = ('leap.nvim: <Plug>(leap-backward-x) is deprecated. '
                   .. 'See `:help leap-mappings` to update your config.')
      vim.notify(msg, vim.log.levels.WARN)
      require('leap').leap { backward = true, offset = 2 }
    end
  },
}


for _, t in ipairs(plug_mappings) do
  local modes, lhs, rhs = unpack(t)
  vim.keymap.set(modes, lhs, rhs, { silent = true })
end
