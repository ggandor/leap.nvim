local plug_mappings = {
  {
    {'n', 'x', 'o'}, '<Plug>(leap-forward)',
    function () require('leap').leap {} end
  },
  {
    {'n', 'x', 'o'}, '<Plug>(leap-backward)',
    function () require('leap').leap { backward = true } end
  },
  {
    {'n'}, '<Plug>(leap-forward-to)',
    function () require('leap').leap {} end
  },
  {
    {'x', 'o'}, '<Plug>(leap-forward-to)',
    function () require('leap').leap {
        offset = 1, inclusive_op = true, match_same_char_seq_at_end = true
      }
    end
  },
  {
    {'n', 'x', 'o'}, '<Plug>(leap-forward-till)',
    function () require('leap').leap { offset = -1, inclusive_op = true } end
  },
  {
    {'n', 'x', 'o'}, '<Plug>(leap-backward-to)',
    function ()
      require('leap').leap { backward = true, }
    end
  },
  {
    {'n', 'x', 'o'}, '<Plug>(leap-backward-till)',
    function () require('leap').leap {
        backward = true, offset = 2, match_same_char_seq_at_end = true,
      }
    end
  },
  {
    {'n', 'x', 'o'}, '<Plug>(leap-from-window)',
    function () require('leap').leap {
        target_windows = require'leap.util'.get_enterable_windows()
      }
    end
  },

  -- Deprecated mappings.
  {
    {'n', 'x', 'o'}, '<Plug>(leap-cross-window)',
    function () require('leap').leap { target_windows = require'leap.util'.get_enterable_windows() } end
  },
  {{'n', 'x', 'o'}, '<Plug>(leap-forward-x)',  function () require('leap').leap { offset = 1, inclusive_op = true } end},
  {{'n', 'x', 'o'}, '<Plug>(leap-backward-x)', function () require('leap').leap { backward = true, offset = 2 } end},
}

for _, t in ipairs(plug_mappings) do
  local modes, lhs, rhs = unpack(t)
  vim.keymap.set(modes, lhs, rhs, {silent = true})
end
