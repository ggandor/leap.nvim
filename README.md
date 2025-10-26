<img align="left" width="150" height="85" src="../media/kangaroo.png?raw=true">

# leap.nvim

Leap is a general-purpose motion plugin for Neovim, building and improving
primarily on [vim-sneak](https://github.com/justinmk/vim-sneak). Using some
clever ideas, it allows you to jump to any position in the visible editor area
very quickly, with near-zero mental overhead.

### Features

* Previewing target labels while typing, for smoother jumps
* Safe automatic jump to the first match (no need to press `<enter>`)
* No blind spots - even empty lines are reachable with the same command
* Multi-window search
* Consistent, intuitive way to traverse matches and repeat motions
* Native feel (`forced-motion`, `.`-repeat)
* Friendly to non-English languages (`'keymap'`, mutual aliases)
* Treesitter integration
* Bundled module for remote operations ("spooky actions at a distance")
* Small API surface, yet highly extensible

![showcase](../media/showcase.gif?raw=true)

### How to use it (TL;DR)

* Initiate the search in a given scope, and start typing a 2-character pattern
  (`{char1}{char2}`).

* After typing `{char1}`, you see "labels" appearing next to some pairs. This
  is just a **preview** - labels only get active after finishing the pattern.

* Type `{char2}`, which filters the matches. When the closest pair is
  unlabeled, you automatically jump there. In case that was your target, you
  can safely ignore the remaining labels - those will not conflict with any
  sensible command, and will disappear on the next keypress.

* Else: type the label character to jump to the given position. If there are
  more matches than available labels, you can move between groups with
  `<space>` and `<backspace>`.

To move to the last character on a line, type `{char}<space>`. To move to an
empty line, type `<space><space>`.

At any stage, `<enter>` jumps to the next/closest available target: pressing
`<enter>` right away repeats the previous search; `{char}<enter>` accepts the
closest `{char}` match (can be used as a multiline substitute for `fFtT`
motions).

### Why is this method cool?

It is ridiculously fast: not counting the trigger key, leaping to literally
anywhere on the screen rarely takes more than 3 keystrokes in total, that can
be typed in one go. Often 2 is enough.

At the same time, it reduces mental effort by all possible means:

* _You don't have to weigh alternatives_: a single universal motion type can be
  used in all non-trivial situations.

* _You don't have to compose motions_: one command achieves one logical
  movement.

* _You don't have to be aware of the context_: the eyes can keep focusing on
  the target the whole time.

* _You don't have to make decisions on the fly_: the sequence you should type
  is fixed from the start.

* _You don't have to pause in the middle_: if typing at a moderate speed, at
  each step you already know what the immediate next keypress should be, and
  your mind can process the rest in the background.

## 🚀 Getting started

### Requirements

* Neovim >= 0.10.0 stable, or latest nightly

* [repeat.vim](https://github.com/tpope/vim-repeat), for dot-repeats (`.`) to
  work

### Installation

<details>
<summary>Mappings</summary>

No setup is required, just define keybindings - our recommended
arrangement is:

```lua
vim.keymap.set({'n', 'x', 'o'}, 's', '<Plug>(leap)')
vim.keymap.set('n',             'S', '<Plug>(leap-from-window)')
```

See `:h leap-mappings` for more.

Remote operations (`gs{leap}apy` or `ygs{leap}ap` - `{leap}` means
`{char1}{char2}{label?}`, as usual):

```lua
vim.keymap.set({'n', 'o'}, 'gs', function ()
  require('leap.remote').action {
    -- Automatically enter Visual mode when coming from Normal.
    input = vim.fn.mode(true):match('o') and '' or 'v'
  }
end)
-- Forced linewise version (`gS{leap}jjy`):
vim.keymap.set({'n', 'o'}, 'gS', function ()
  require('leap.remote').action { input = 'V' }
end)
```

See below for more (e.g. setting up automatic paste after yanking).

Treesitter node selection (`vRRR...y` or `yR{label}`):

```lua
vim.keymap.set({'x', 'o'}, 'R',  function ()
  require('leap.treesitter').select {
    opts = require('leap.user').with_traversal_keys('R', 'r')
  }
end)
```

</details>

<details>
<summary>Suggested additional tweaks</summary>

```lua
-- Highly recommended: define a preview filter to reduce visual noise
-- and the blinking effect after the first keypress
-- (`:h leap.opts.preview`). You can still target any visible
-- positions if needed, but you can define what is considered an
-- exceptional case.
-- Exclude whitespace and the middle of alphabetic words from preview:
--   foobar[baaz] = quux
--   ^----^^^--^^-^-^--^
require('leap').opts.preview = function (ch0, ch1, ch2)
  return not (
    ch1:match('%s')
    or (ch0:match('%a') and ch1:match('%a') and ch2:match('%a'))
  )
end

-- Define equivalence classes for brackets and quotes, in addition to
-- the default whitespace group:
require('leap').opts.equivalence_classes = {
  ' \t\r\n', '([{', ')]}', '\'"`'
}

-- Use the traversal keys to repeat the previous motion without
-- explicitly invoking Leap:
require('leap.user').set_repeat_keys('<enter>', '<backspace>')
```

</details>

<details>
<summary>Lazy loading</summary>

...is all the rage now, but doing it via your plugin manager is unnecessary, as
Leap already lazy-loads itself, [as it
should](https://github.com/neovim/neovim/issues/35562#issuecomment-3239702727).
Using the `keys` feature of lazy.nvim might even cause
[problems](https://github.com/ggandor/leap.nvim/issues/191).

</details>

Help files are not exactly page-turners, but I suggest at least skimming
[`:help leap`](doc/leap.txt), even if you don't have a specific question yet,
as it contains lots of additional information and details.

### Experimental modules

<details>
<summary>Treesitter integration</summary>

You can either choose a node directly (`vR{label}`), or, in Normal/Visual mode,
use the traversal keys for incremental selection. The labels are forced to be
safe, so you can operate on the selection right away then (`vRRRy`). Traversal
can "wrap around" backwards (`vRr` selects the root node).

It is also worth noting that linewise mode (`VRRR...`, `yVR`) filters out
redundant nodes (only the outermost are kept in a given line range), making the
selection much more efficient.

```lua
vim.keymap.set({'x', 'o'}, 'R',  function ()
  require('leap.treesitter').select {
    -- To increase/decrease the selection in a clever-f-like manner,
    -- with the trigger key itself (vRRRRrr...). The default keys
    -- (<enter>/<backspace>) also work, so feel free to skip this.
    opts = require('leap.user').with_traversal_keys('R', 'r')
  }
end)
```

</details>

<details>
<summary>Remote actions</summary>

Inspired by [leap-spooky.nvim](https://github.com/ggandor/leap-spooky.nvim),
and [flash.nvim](https://github.com/folke/flash.nvim)'s similar feature.

This function allows you to perform an action in a remote location: it forgets
the current mode or pending operator, lets you leap to anywhere on the tab
page, then continues where it left off. Once returning to Normal mode, it jumps
back, as if you had operated from the distance.

```lua
vim.keymap.set({'n', 'x', 'o'}, 'gs', function ()
  require('leap.remote').action()
end)
```

Example: `gs{leap}yap`, `vgs{leap}apy`, or `ygs{leap}ap` yank the paragraph at
the position specified by `{leap}`.

**Icing on the cake, no. 1 - automatic paste after yanking**

With this, you can clone text objects or regions in the blink of an eye, even
from another window (just `ygs{leap}ap`, or, with predefiend remote text
object, `yarp{leap}`, and voilà, the remote paragraph appears there):

```lua
vim.api.nvim_create_autocmd('User', {
  pattern = 'RemoteOperationDone',
  group = vim.api.nvim_create_augroup('LeapRemote', {}),
  callback = function (event)
    -- Do not paste if some special register was in use.
    if vim.v.operator == 'y' and event.data.register == '"' then
      vim.cmd('normal! p')
    end
  end,
})
```

**Icing on the cake, no. 2 - giving input ahead of time (remote text objects)**

The `input` parameter lets you feed keystrokes automatically after the jump:

```lua
-- Trigger visual selection right away, so that you can `gs{leap}apy`:
vim.keymap.set({'n', 'o'}, 'gs', function ()
  require('leap.remote').action { input = 'v' }
end)

```

Other ideas: `V` (forced linewise), `K`, `gx`, etc.

By feeding text objects as `input`, you can create _remote text objects_, for
an even more intuitive workflow (`yarp{leap}` - "yank a remote paragraph
at..."):

```lua
-- Create remote versions of all a/i text objects by inserting `r`
-- into the middle (`iw` becomes `irw`, etc.).
do
  -- A trick to avoid having to create separate hardcoded mappings for
  -- each text object: when entering `ar`/`ir`, consume the next
  -- character, and create the input from that character concatenated to
  -- `a`/`i`.
  local remote_text_object = function (prefix)
     local ok, ch = pcall(vim.fn.getcharstr)  -- pcall for handling <C-c>
     if not ok or (ch == vim.keycode('<esc>')) then
       return
     end
     require('leap.remote').action { input = prefix .. ch }
  end

  for _, prefix in ipairs { 'a', 'i' } do
    vim.keymap.set({'x', 'o'}, prefix .. 'r', function ()
      remote_text_object(prefix)
    end)
  end
end
```

**Swapping regions**

It deserves mention that this feature also makes exchanging two regions of text
moderately simple, without needing a custom plugin: `d{region1} gs{leap}
v{region2}p <jumping-back-here> P`.

Example (swapping two words): `diw gs{leap} viwp P`.

With remote text objects, the swap is even simpler, almost on par with
[vim-exchange](https://github.com/tommcdo/vim-exchange): `diw virw{leap}p P`.

Using remote text objects _and_ combining them with an exchange operator is
pretty much text editing at the speed of thought: `cxiw cxirw{leap}`.

**Jumping to off-screen areas with native search commands**

The `remote` module is not really an extension, but more of an "inverse plugin"
bundled with Leap; the jump logic is not hardcoded - `action` can in fact use
any function via the `jumper` parameter, be it a custom `leap()` call or
something entirely different.

You can even use the native search commands directly, that is, target
off-screen regions, with the special `jumper` values `/` and `?`:

```lua
vim.keymap.set({'n', 'o'}, 'g/', function ()
  require('leap.remote').action { jumper = '/' }
end)
vim.keymap.set({'n', 'o'}, 'g?', function ()
  require('leap.remote').action { jumper = '?' }
end)
```

Vim tip: use `c_CTRL-G` and `c_CTRL-T` to move between matches without
finishing the search.

Note that in Normal mode you are free to move around after the jump. For
example, search for a markdown header, then move to the concrete target
(paragraph, line, word) you want to operate on.

</details>

## 🔍 Design considerations in detail

### The ideal

Premise: [Vim golf](https://www.vimgolf.com/) is incredibly fun, but efficient
movement between point A and B on the screen, in particular, should rather be a
non-issue. An ideal keyboard-driven interface would impose almost no more
cognitive burden than using a mouse, without the constant context-switching
required by the latter.

That is, **you do not want to think about**

* **the command**: we need one fundamental targeting method that can bring you
  anywhere: a jetpack on the back, instead of airline routes (↔
  [EasyMotion](https://github.com/easymotion/vim-easymotion) and its
  derivatives)

* **the context**: it should be enough to look at the target, and nothing else
  (↔ vanilla Vim motion combinations using relative line numbers and/or
  repeats)

* **the steps**: the motion should be atomic (↔ Vim motion combos), and ideally
  you should be able to type the whole input sequence in one go, on more or
  less autopilot (↔ any kind of just-in-time labeling method; note that the
  "search command on steroids" approach by
  [Pounce](https://github.com/rlane/pounce.nvim) and
  [Flash](https://github.com/folke/flash.nvim), where you can type as many
  characters as you want, and the labels appear at an unknown time by design,
  makes this last goal impossible)

All the while using **as few keystrokes as possible**, and getting distracted by
**as little incidental visual noise as possible**.

### How do we measure up?

It is obviously impossible to achieve all of the above at the same time, without
some trade-offs at least; but in our opinion Leap comes pretty close, occupying
a sweet spot in the design space. (The worst remaining offender might be visual
noise, but clever filtering in the preview phase can help - see `:h
leap.opts.preview`.)

The **one-step shift between perception and action** is the big idea that cuts
the Gordian knot: a fixed pattern length combined with previewing labels can
eliminate the surprise factor, and make the search-based method (our "jetpack")
work smoothly. Fortunately, even a 2-character pattern - the shortest one with
which we can play this trick - is usually long enough to sufficiently narrow
down the matches.

Fixed pattern length also makes **(safe) automatic jump to the first target**
possible. Even with preview, labels are a necessary evil, and we should
optimize for the common case as much as possible (something that Sneak got
absolutely right from the beginning). You cannot improve on jumping directly,
just like how `f` and `t` works, not having to use even `<enter>` to accept the
match. However, we can do this in a smart way: if there are many targets (more
than 15-20), we stay put, so we can use a bigger, "unsafe" label set - getting
the best of both worlds. The non-determinism we're introducing is less of an
issue here, since the outcome is known in advance.

In sum, compared to other methods based on labeling targets, Leap's approach is
unique in that it

* offers a smoother experience, by (somewhat) eliminating the pause before
  typing the label

* feels natural to use for both distant _and_ close targets

## ❔ FAQ

### Defaults

<details>
<summary>Why remap `s`/`S`?</summary>

Common operations should use the fewest keystrokes and the most comfortable
keys, so it makes sense to take those over by Leap, especially given that both
native commands have synonyms:

Normal mode

* `s` = `cl` (or `xi`)
* `S` = `cc`

Visual mode

* `s` = `c`
* `S` = `Vc`, or `c` if already in linewise mode

</details>

### Features

<details>
<summary>Smart case sensitivity, wildcard characters (one-way
aliases)</summary>

The preview phase, unfortunately, makes them impossible, by design: for a
potential match, we might need to show two different labels (corresponding to
two different futures) at the same time (`:h leap-wildcard-problem`).
([1](https://github.com/ggandor/leap.nvim/issues/28),
[2](https://github.com/ggandor/leap.nvim/issues/89#issuecomment-1368885497),
[3](https://github.com/ggandor/leap.nvim/issues/155#issuecomment-1556124351))

</details>

<details>
<summary>Working with non-English text</summary>

If a [`language-mapping`](https://neovim.io/doc/user/map.html#language-mapping)
([`'keymap'`](https://neovim.io/doc/user/options.html#'keymap')) is active,
Leap waits for keymapped sequences as needed and searches for the keymapped
result.

Also check out `opts.equivalence_classes`, that lets you group certain
characters together as mutual aliases, e.g.:

```lua
{
  ' \t\r\n', 'aäàáâãā', 'dḍ', 'eëéèêē', 'gǧğ', 'hḥḫ',
  'iïīíìîı', 'nñ', 'oō', 'sṣšß', 'tṭ', 'uúûüűū', 'zẓ'
}
```

</details>

<details>
<summary>Arbitrary remote actions instead of jumping</summary>

Basic template:

```lua
local function remote_action ()
  require('leap').leap {
    windows = require('leap.user').get_focusable_windows(),
    action = function (target)
      local winid = target.wininfo.winid
      local lnum, col = unpack(target.pos)  -- 1/1-based indexing!
      -- ... do something at the given position ...
    end,
  }
end
```

See [Extending Leap](#extending-leap) for more.

</details>

### Configuration

<details>
<summary>Disable auto-jumping to the first match</summary>

```lua
require('leap').opts.safe_labels = ''
```

</details>

<details>
<summary>Force auto-jumping to the first match</summary>

```lua
require('leap').opts.labels = ''
```

</details>

<details>
<summary>Disable previewing labels</summary>

```lua
require('leap').opts.preview = false
```

</details>


<details>
<summary>Always show labels at the beginning of the match</summary>

Warning: `on_beacons` is an experimental escape hatch, and this workaround
depends on implementation details.

```lua
-- `on_beacons` hooks into `beacons.light_up_beacons`, the function
-- responsible for displaying stuff.
require('leap').opts.on_beacons = function (targets, _, _)
  for _, t in ipairs(targets) do
    -- Overwrite the `offset` value in all beacons.
    -- target.beacon looks like: { <offset>, <extmark_opts> }
    if t.label and t.beacon then t.beacon[1] = 0 end
  end
end
```

</details>

<details>
<summary>Grey out the search area</summary>

Set the `LeapBackdrop` highlight group (usually linking to `Comment` is
preferable):

```lua
vim.api.nvim_set_hl(0, 'LeapBackdrop', { link = 'Comment' })
```

</details>

<details>
<summary>Restore the default highlighting</summary>

If a certain color scheme sets the highlight groups for Leap in a way that you
don't particularly like, the simplest solution (besides a PR) is:

```lua
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('LeapColorTweaks', {}),
  callback = function ()
    if vim.g.colors_name == 'bad_color_scheme' then
      -- Forces using the defaults: sets `IncSearch` for labels,
      -- `Search` for matches, removes `LeapBackdrop`, and updates the
      -- look of concealed labels.
      require('leap').init_hl(true)
    end
  end
})
```

</details>

### Miscellaneous

<details>
<summary>Was the name inspired by Jef Raskin's Leap?</summary>

To paraphrase Steve Jobs about their logo and Turing's poison apple, I wish it
were, but it is a coincidence. "Leap" is just another synonym for "jump", that
happens to rhyme with Sneak. That said, you can think of the name as a
little tribute to the great pioneer of interface design, even though embracing
the modal paradigm is a fundamental difference in Vim's approach.

</details>

## 🔧 Extending Leap

There are lots of ways you can extend the plugin and bend it to your will - see
`:h leap.leap()` and `:h leap-events`. Besides tweaking the basic parameters of
the function (search scope, jump offset, etc.), you can:

* feed it with a prepared **search pattern**
* feed it with prepared **targets**, and only use it as labeler/selector
* give it a custom **action** to perform, instead of jumping
* customize the behavior of specific calls via **autocommands**

Examples:

<details>
<summary>Search integration</summary>

When finishing a `/` or `?` search command, automatically label visible
matches, so that you can jump to them directly.

Note: `pattern` is an experimental feature at the moment.

```lua
vim.api.nvim_create_autocmd('CmdlineLeave', {
  group = vim.api.nvim_create_augroup('LeapOnSearch', {}),
  callback = function ()
    local ev = vim.v.event
    local is_search_cmd = (ev.cmdtype == '/') or (ev.cmdtype == '?')
    local cnt = vim.fn.searchcount().total
    if is_search_cmd and (not ev.abort) and (cnt > 1) then
      -- Allow CmdLineLeave-related chores to be completed before
      -- invoking Leap.
      vim.schedule(function ()
        -- We want "safe" labels, but no auto-jump (as the search
        -- command already does that), so just use `safe_labels`
        -- as `labels`, with n/N removed.
        local labels = require('leap').opts.safe_labels:gsub('[nN]', '')
        -- For `pattern` search, we never need to adjust conceallevel
        -- (no user input). We cannot merge `nil` from a table, but
        -- using the option's current value has the same effect.
        local vim_opts = { ['wo.conceallevel'] = vim.wo.conceallevel }
        require('leap').leap {
          pattern = vim.fn.getreg('/'),  -- last search pattern
          windows = { vim.fn.win_getid() },
          opts = { safe_labels = '', labels = labels, vim_opts = vim_opts, }
        }
      end)
    end
  end,
})
```

The above might be enough for your needs, but here is another snippet, which
sets keys to leap to visible matches of the previous search pattern anytime. It
also:

* allows traversing with the trigger key, so that you can `<c-s><c-s>...`.
* allows using the keys in Command-line mode too, so that you can exit and jump
  (or traverse) right away, without needing to press `enter` first
  (`/pattern<c-s>{label}`, `/pattern<c-s><c-s>...`).

Rationale for the suggested keys: `<c-s>` is the default Leap trigger combined
with a modifier, to make it usable in Command-line mode; and with `<c-q>`, the
pair resembles `c_CTRL-G` and `c_CTRL-T` (`s` is - sort of - below `q`).

```lua
do
  local function leap_search (key, is_reverse)
    local cmdline_mode = vim.fn.mode(true):match('^c')
    if cmdline_mode then
      -- Finish the search command.
      vim.api.nvim_feedkeys(vim.keycode('<enter>'), 't', false)
    end
    if vim.fn.searchcount().total < 1 then
      return
    end
    -- Activate again if `:nohlsearch` has been used (Normal/Visual mode).
    vim.go.hlsearch = vim.go.hlsearch
    -- Allow the search command to complete its chores before
    -- invoking Leap (Command-line mode).
    vim.schedule(function ()
      require('leap').leap {
        pattern = vim.fn.getreg('/'),
        -- If you always want to go forward/backward with the given key,
        -- regardless of the previous search direction, just set this to
        -- `is_reverse`.
        backward = (is_reverse and vim.v.searchforward == 1)
                   or (not is_reverse and vim.v.searchforward == 0),
        opts = require('leap.user').with_traversal_keys(key, nil, {
          -- Auto-jumping to the second match would be confusing without
          -- 'incsearch'.
          safe_labels = (cmdline_mode and not vim.o.incsearch) and ''
                        -- Keep n/N usable in any case.
                        or require('leap').opts.safe_labels:gsub('[nN]', '')
        })
      }
      -- You might want to switch off the highlights after leaping.
      -- vim.cmd('nohlsearch')
    end)
  end

  vim.keymap.set({'n', 'x', 'o', 'c'}, '<c-s>', function ()
    leap_search('<c-s>', false)
  end, { desc = 'Leap to search matches' })

  vim.keymap.set({'n', 'x', 'o', 'c'}, '<c-q>', function ()
    leap_search('<c-q>', true)
  end, { desc = 'Leap to search matches (reverse)' })
end
```

</details>

<details>
<summary>1-character search (enhanced f/t motions)</summary>

Note: `inputlen` is an experimental feature at the moment.

```lua
do
  -- Return an argument table for `leap()`, tailored for f/t-motions.
  local function as_ft (key_specific_args)
    local common_args = {
      inputlen = 1,
      inclusive = true,
      -- To limit search scope to the current line:
      -- pattern = function (pat) return '\\%.l'..pat end,
      opts = {
        labels = '',  -- force autojump
        safe_labels = vim.fn.mode(1):match'[no]' and '' or nil,  -- [1]
      },
    }
    return vim.tbl_deep_extend('keep', common_args, key_specific_args)
  end

  local clever = require('leap.user').with_traversal_keys        -- [2]
  local clever_f = clever('f', 'F')
  local clever_t = clever('t', 'T')

  for key, key_specific_args in pairs {
    f = { opts = clever_f, },
    F = { backward = true, opts = clever_f },
    t = { offset = -1, opts = clever_t },
    T = { backward = true, offset = 1, opts = clever_t },
  } do
    vim.keymap.set({'n', 'x', 'o'}, key, function ()
      require('leap').leap(as_ft(key_specific_args))
    end)
  end
end

------------------------------------------------------------------------
-- [1] Match the modes here for which you don't want to use labels
--     (`:h mode()`, `:h lua-pattern`).
-- [2] This helper function makes it easier to set "clever-f"-like
--     functionality (https://github.com/rhysd/clever-f.vim), returning
--     an `opts` table derived from the defaults, where the given keys
--     are added to `keys.next_target` and `keys.prev_target`
```

</details>

<details>
<summary>Jump to lines</summary>

Note: `pattern` is an experimental feature at the moment.

```lua
vim.keymap.set({'n', 'x', 'o'}, '|', function ()
  local line = vim.fn.line('.')
  -- Skip 3-3 lines around the cursor.
  local top, bot = unpack { math.max(1, line - 3), line + 3 }
  require('leap').leap {
    pattern = '\\v(%<'..top..'l|%>'..bot..'l)$',
    windows = { vim.fn.win_getid() },
    opts = { safe_labels = '' }
  }
end)
```

</details>

<details>
<summary>Shortcuts to Telescope results</summary>

```lua
local function get_targets (picker)
  local scroller = require('telescope.pickers.scroller')
  local wininfo = vim.fn.getwininfo(picker.results_win)[1]
  local bottom = wininfo.botline - 2  -- skip the current row
  local top = math.max(
    scroller.top(picker.sorting_strategy,
                 picker.max_results,
                 picker.manager:num_results()),
    wininfo.topline - 1
  )
  local targets = {}
  for lnum = bottom, top, -1 do
    table.insert(targets, { wininfo = wininfo, pos = { lnum + 1, 1 } })
  end
  return targets
end

local function pick_with_leap (buf)
  local picker = require('telescope.actions.state').get_current_picker(buf)
  require('leap').leap {
    targets = get_targets(picker),
    action = function (target)
      picker:set_selection(target.pos[1] - 1)
      require('telescope.actions').select_default(buf)
    end,
  }
end

require('telescope').setup {
  defaults = {
    mappings = {
      i = { ['<a-p>'] = pick_with_leap },
    }
  }
}
```

</details>
