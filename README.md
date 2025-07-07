<img align="left" width="150" height="85" src="../media/kangaroo.png?raw=true">

# leap.nvim

Leap is a general-purpose motion plugin for Neovim, building and improving
primarily on [vim-sneak](https://github.com/justinmk/vim-sneak), with the
ultimate goal of establishing a new standard interface for moving around in the
visible area in Vim-like modal editors. It allows you to reach any target in a
very fast, uniform way, and minimizes the required focus level while executing
a jump.

![showcase](../media/showcase.gif?raw=true)

### How to use it (TL;DR)

Leap's default motions allow you to jump to any position in the visible editor
area by entering a 2-character search pattern, and then potentially a label
character to pick your target from multiple matches, similar to Sneak. The main
novel idea in Leap is that **you get a preview of the target labels** - you can
see which key you will need to press before you actually need to do that.

- Initiate the search in the current window (`s`) or in the other windows
  (`S`). (Note: you can use a single key for the whole tab page, if you are
  okay with the trade-offs.)
- Start typing a 2-character pattern (`{char1}{char2}`).
- After typing the first character, you see "labels" appearing next to some of
  the `{char1}{?}` pairs. You cannot use them yet - they only get active after
  finishing the pattern.
- Enter `{char2}`. If the pair was not labeled, you automatically jump there.
  You can safely ignore the remaining labels, and continue editing - those are
  guaranteed non-conflicting letters, disappearing on the next keypress.
- Else: type the label character, that is now active. If there are more matches
  than available labels, you can switch between groups, using `<space>` and
  `<backspace>`.

Every visible position is targetable:

- `s{char}<space>` jumps to the last character on a line.
- `s<space><space>` jumps to end-of-line characters, including empty lines.

At any stage, `<enter>` jumps to the next/closest available target
(`<backspace>` steps back):

- `s<enter>...` repeats the previous search.
- `s{char}<enter>...` can be used as a multiline substitute for `fFtT` motions.

### Why is this method cool?

It is ridiculously fast: not counting the trigger key, leaping to literally
anywhere on the screen rarely takes more than 3 keystrokes in total, that can be
typed in one go. Often 2 is enough.

At the same time, it reduces mental effort to almost zero:

- You _don't have to weigh alternatives_: a single universal motion type can be
  used in all non-trivial situations.

- You _don't have to compose motions in your head_: one command achieves one
  logical movement.

- You _don't have to be aware of the context_: the eyes can keep focusing on the
  target the whole time.

- You _don't have to make decisions on the fly_: the sequence you should type
  is fixed from the start.

- You _don't have to pause in the middle_: if typing at a moderate speed, at
  each step you already know what the immediate next keypress should be, and
  your mind can process the rest in the background.

## Getting started

### Status

The plugin is not 100% stable yet, but don't let that stop you - the usage
basics are extremely unlikely to change. To follow breaking changes, subscribe
to the corresponding [issue](https://github.com/ggandor/leap.nvim/issues/18).

### Requirements

* Neovim >= 0.10.0 stable, or latest nightly

### Dependencies

* [repeat.vim](https://github.com/tpope/vim-repeat), for dot-repeats (`.`) to
  work

### Installation

Use your preferred method or plugin manager. No extra steps needed besides
defining keybindings - to use the default ones, put the following into your
config (overrides `s` in all modes, and `S` in Normal mode):

`require('leap').set_default_mappings()`

<details>
<summary>Alternative key mappings and arrangements</summary>

Calling `require('leap').set_default_mappings()` is equivalent to:

```lua
vim.keymap.set({'n', 'x', 'o'}, 's', '<Plug>(leap)')
vim.keymap.set('n',             'S', '<Plug>(leap-from-window)')
```

Jump to anywhere in Normal mode with one key:

```lua
vim.keymap.set('n',        's', '<Plug>(leap-anywhere)')
vim.keymap.set({'x', 'o'}, 's', '<Plug>(leap)')
```

Trade-off: if you have multiple windows open on the tab page, you will almost
never get an automatic jump, except if all targets are in the same window.
(This is an intentional restriction: it would be too disorienting if the cursor
could jump in/to a different window than your goal, right before selecting the
target.)

Sneak-style:

```lua
vim.keymap.set({'n', 'x', 'o'}, 's',  '<Plug>(leap-forward)')
vim.keymap.set({'n', 'x', 'o'}, 'S',  '<Plug>(leap-backward)')
vim.keymap.set('n',             'gs', '<Plug>(leap-from-window)')
```

See `:h leap-custom-mappings` for more.

</details>

<details>
<summary>Suggested additional tweaks</summary>

Highly recommended: define a preview filter to reduce visual noise and the
blinking effect after the first keypress (`:h leap.opts.preview_filter`). You
can still target any visible positions if needed, but you can define what is
considered an exceptional case ("don't bother me with preview for them").

```lua
-- Exclude whitespace and the middle of alphabetic words from preview:
--   foobar[baaz] = quux
--   ^----^^^--^^-^-^--^
require('leap').opts.preview_filter =
  function (ch0, ch1, ch2)
    return not (
      ch1:match('%s') or
      ch0:match('%a') and ch1:match('%a') and ch2:match('%a')
    )
  end
```

Define equivalence classes for brackets and quotes, in addition to the default
whitespace group:

```lua
require('leap').opts.equivalence_classes = { ' \t\r\n', '([{', ')]}', '\'"`' }
```

Use the traversal keys to repeat the previous motion without explicitly
invoking Leap:

```lua
require('leap.user').set_repeat_keys('<enter>', '<backspace>')
```

</details>

<details>
<summary>Lazy loading</summary>

...is all the rage now, but doing it via your plugin manager is unnecessary, as
Leap lazy loads itself. Using the `keys` feature of lazy.nvim might even cause
[problems](https://github.com/ggandor/leap.nvim/issues/191).

</details>

### Extras

Experimental modules, might be moved out, and APIs are subject to change.

<details>
<summary>Remote actions</summary>

Inspired by [leap-spooky.nvim](https://github.com/ggandor/leap-spooky.nvim),
and [flash.nvim](https://github.com/folke/flash.nvim)'s similar feature.

This function allows you to perform an action in a remote location: it
forgets the current mode or pending operator, lets you leap with the
cursor (to anywhere on the tab page), then continues where it left off.
Once an operation or insertion is finished, it moves the cursor back to
the original position, as if you had operated from the distance.

```lua
vim.keymap.set({'n', 'x', 'o'}, 'gs', function ()
  require('leap.remote').action()
end)
```

Example: `gs{leap}yap`, `vgs{leap}apy`, or `ygs{leap}ap` yank the paragraph at
the position specified by `{leap}`.

Tip: As the remote mode is active until returning to Normal mode again (by any
means), `<ctrl-o>` becomes your friend in Insert mode, or when doing change
operations.

**Swapping regions**

Exchanging two regions of text becomes moderately simple, without needing a
custom plugin: `d{region1} gs{leap}v{region2}p P`. Example (swapping two
words): `diw gs{leap}viwp P`.

With remote text objects (see below), the swap is even simpler, almost on par
with [vim-exchange](https://github.com/tommcdo/vim-exchange): `diw virw{leap}p
P`.

Using remote text objects _and_ combining them with an exchange operator is
pretty much text editing at the speed of thought: `cxiw cxirw{leap}`.

**Icing on the cake, no. 1 - giving input ahead of time**

The `input` parameter lets you feed keystrokes automatically after the jump:

```lua
-- Trigger visual selection right away, so that you can `gs{leap}apy`:
vim.keymap.set({'n', 'o'}, 'gs', function ()
  require('leap.remote').action { input = 'v' }
end)

-- Other ideas: `V` (forced linewise), `K`, `gx`, etc.
```

By feeding text objects as `input`, you can create **remote text objects**, for
an even more intuitive workflow (`yarp{leap}` - "yank a remote paragraph
at..."):

```lua
-- Create remote versions of all a/i text objects by inserting `r`
-- into the middle (`iw` becomes `irw`, etc.).
-- A trick to avoid having to create separate hardcoded mappings for
-- each text object: when entering `ar`/`ir`, consume the next
-- character, and create the input from that character concatenated to
-- `a`/`i`.
do
  local remote_text_object = function (prefix)
     local ok, ch = pcall(vim.fn.getcharstr)  -- pcall for handling <C-c>
     if not ok or (ch == vim.keycode('<esc>')) then
       return
     end
     require('leap.remote').action { input = prefix .. ch }
  end
  vim.keymap.set({'x', 'o'}, 'ar', function () remote_text_object('a') end)
  vim.keymap.set({'x', 'o'}, 'ir', function () remote_text_object('i') end)
end
```

A very handy custom mapping - remote line(s), with optional `count`
(`yaa{leap}`, `y3aa{leap}`):

```lua
vim.keymap.set({'x', 'o'}, 'aa', function ()
  -- Force linewise selection.
  local V = vim.fn.mode(true):match('V') and '' or 'V'
  -- In any case, move horizontally, to trigger operations.
  local input = vim.v.count > 1 and (vim.v.count - 1 .. 'j') or 'hl'
  -- With `count=false` you can skip feeding count to the command
  -- automatically (we need -1 here, see above).
  require('leap.remote').action { input = V .. input, count = false }
end)
```

**Icing on the cake, no. 2 - automatic paste after yanking**

With this, you can clone text objects or regions in the blink of an eye, even
from another window (`yarp{leap}`, and voilà, the remote paragraph appears
there):

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

</details>

<details>
<summary>Incremental treesitter node selection</summary>

Besides choosing a label (`R{label}`), in Normal/Visual mode you can also use
the traversal keys for incremental selection. The labels are forced to be safe,
so you can operate on the selection right away (`RRRy`). Traversal can also
"wrap around" backwards (`Rr` selects the root node).

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

Note that it is worth using (forced) linewise mode (`VRRR...`, `yVR`), as
redundant nodes are filtered out (only the outermost are kept in a given line
range), making the selection much more efficient.

</details>

### Next steps

Help files are not exactly page-turners, but I suggest at least skimming
[`:help leap`](doc/leap.txt), even if you don't have a specific question yet
(if nothing else: `:h leap-usage`, `:h leap-config`, `:h leap-events`). While
Leap has deeply thought-through, opinionated defaults, its small(ish) but
comprehensive API makes it pretty flexible.

## Design considerations in detail

### The ideal

Premise: jumping from point A to B on the screen should not be some [exciting
puzzle](https://www.vimgolf.com/), for which you should train yourself; it
should be a non-issue. An ideal keyboard-driven interface would impose almost no
more cognitive burden than using a mouse, without the constant context-switching
required by the latter.

That is, **you do not want to think about**

- **the command**: we need one fundamental targeting method that can bring you
  anywhere: a jetpack on the back, instead of airline routes (↔
  [EasyMotion](https://github.com/easymotion/vim-easymotion) and its
  derivatives)
- **the context**: it should be enough to look at the target, and nothing else
  (↔ vanilla Vim motion combinations using relative line numbers and/or
  repeats)
- **the steps**: the motion should be atomic (↔ Vim motion combos), and ideally
  you should be able to type the whole sequence in one go, on more or less
  autopilot (↔ any kind of "just-in-time" labeling method; note that the
  "search command on steroids" approach by
  [Pounce](https://github.com/rlane/pounce.nvim) and
  [Flash](https://github.com/folke/flash.nvim), where the labels appear at an
  unknown time by design, makes this last goal impossible)

All the while using **as few keystrokes as possible**, and getting distracted by
**as little incidental visual noise as possible**.

### How do we measure up?

It is obviously impossible to achieve all of the above at the same time, without
some trade-offs at least; but in our opinion Leap comes pretty close, occupying
a sweet spot in the design space. (The worst remaining offender might be visual
noise, but clever filtering in the preview phase can help - see `:h
leap.opts.preview_filter`.)

The **one-step shift between perception and action** is the big idea that cuts
the Gordian knot: a fixed pattern length combined with previewing labels can
eliminate the surprise factor from the search-based method (which is the only
viable approach - see "jetpack" above). Fortunately, a 2-character pattern \-
the shortest one with which we can play this trick - is also long enough to
sufficiently narrow down the matches in the vast majority of cases.

Fixed pattern length also makes **(safe) automatic jump to the first target**
possible. You cannot improve on jumping directly, just like how `f` and `t`
works, not having to read a label at all, and not having to accept the match
with `<enter>` either. However, we can do this in a smart way: if there are
many targets (more than 15-20), we stay put, so we can use a bigger, "unsafe"
label set - getting the best of both worlds. The non-determinism we're
introducing is less of an issue here, since the outcome is known in advance.

In sum, compared to other methods based on labeling targets, Leap's approach is
unique in that it

* offers a smoother experience, by (somewhat) eliminating the pause before
  typing the label

* feels natural to use for both distant _and_ close targets

## FAQ

### Defaults

<details>
<summary>Why remap `s`/`S`?</summary>

Common operations should use the fewest keystrokes and the most comfortable
keys, so it makes sense to take those over by Leap, especially given that both
native commands have synonyms:

Normal mode

- `s` = `cl` (or `xi`)
- `S` = `cc`

Visual mode

- `s` = `c`
- `S` = `Vc`, or `c` if already in linewise mode

If you are not convinced, just head to `:h leap-custom-mappings`.

</details>

### Features

<details>
<summary>Smart case sensitivity, wildcard characters (one-way
aliases)</summary>

The preview phase, unfortunately, makes them impossible, by design: for a
potential match, we might need to show two different labels (corresponding to
two different futures) at the same time.
([1](https://github.com/ggandor/leap.nvim/issues/28),
[2](https://github.com/ggandor/leap.nvim/issues/89#issuecomment-1368885497),
[3](https://github.com/ggandor/leap.nvim/issues/155#issuecomment-1556124351))

</details>

<details>
<summary>Arbitrary remote actions instead of jumping</summary>

Basic template:

```lua
local function remote_action ()
  require('leap').leap {
    target_windows = require('leap.user').get_focusable_windows(),
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
require('leap').opts.safe_labels = {}
```

</details>

<details>
<summary>Disable previewing labels</summary>

```lua
require('leap').opts.preview_filter = function () return false end
```

</details>


<details>
<summary>Always show labels at the beginning of the match</summary>

Note: `on_beacons` is an experimental escape hatch, and this workaround depends
on implementation details.

```lua
-- `on_beacons` hooks into `beacons.light_up_beacons`, the function
-- responsible for displaying stuff.
require('leap').opts.on_beacons = function (targets, _, _)
  for _, t in ipairs(targets) do
    -- Overwrite the `offset` value in all beacons.
    -- target.beacon looks like: { <offset>, <extmark_opts> }
    if t.label and t.beacon then t.beacon[1] = 0 end
  end
  -- Returning `true` tells `light_up_beacons` to continue as usual
  -- (`false` would short-circuit).
  return true
end
```

</details>

<details>
<summary>Greying out the search area</summary>

```lua
-- Or just set to grey directly, e.g. { fg = '#777777' },
-- if Comment is saturated.
vim.api.nvim_set_hl(0, 'LeapBackdrop', { link = 'Comment' })
```

</details>

<details>
<summary>Working with non-English text</summary>

If a [`language-mapping`](https://neovim.io/doc/user/map.html#language-mapping)
([`'keymap'`](https://neovim.io/doc/user/options.html#'keymap')) is active,
Leap waits for keymapped sequences as needed and searches for the keymapped
result as expected.

Also check out `opts.equivalence_classes`, that lets you group certain
characters together as mutual aliases, e.g.:

```lua
{
  ' \t\r\n', 'aäàáâãā', 'dḍ', 'eëéèêē', 'gǧğ', 'hḥḫ',
  'iïīíìîı', 'nñ', 'oō', 'sṣšß', 'tṭ', 'uúûüűū', 'zẓ'
}
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

## Extending Leap

There are lots of ways you can extend the plugin and bend it to your will - see
`:h leap.leap()` and `:h leap-events`. Besides tweaking the basic parameters of
the function (search scope, jump offset, etc.), you can:

* give it a custom **action** to perform, instead of jumping
* feed it with custom **targets**, and only use it as labeler/selector
* customize its behavior on a per-call basis via **autocommands**

Some practical examples:

<details>
<summary>1-character search (enhanced f/t motions)</summary>

Note: `inpulen` is an experimental feature at the moment, subject to change or
removal.

```lua
do
  local function ft_args (key_specific_args)
    local common_args = {
      inputlen = 1,
      inclusive_op = true,
      opts = {
        case_sensitive = true,
        labels = {},
        -- Match the modes here for which you don't want to use labels.
        safe_labels = vim.fn.mode(1):match('o') and {} or nil,
      },
    }
    return vim.tbl_deep_extend('keep', common_args, key_specific_args)
  end

  local leap = require('leap').leap
  -- This helper function makes it easier to set "clever-f"-like
  -- functionality (https://github.com/rhysd/clever-f.vim), returning
  -- an `opts` table, where:
  -- * the given keys are set as `next_target` and `prev_target`
  -- * `prev_target` is removed from `safe_labels` (if appears there)
  -- * `next_target` is used as the first label
  local with_traversal_keys = require('leap.user').with_traversal_keys
  local f_opts = with_traversal_keys('f', 'F')
  local t_opts = with_traversal_keys('t', 'T')
  -- You can of course set ;/, for both instead:
  -- local ft_opts = with_traversal_keys(';', ',')

  vim.keymap.set({'n', 'x', 'o'}, 'f', function ()
    leap(ft_args({ opts = f_opts, }))
  end)
  vim.keymap.set({'n', 'x', 'o'}, 'F', function ()
    leap(ft_args({ opts = f_opts, backward = true }))
  end)
  vim.keymap.set({'n', 'x', 'o'}, 't', function ()
    leap(ft_args({ opts = t_opts, offset = -1 }))
  end)
  vim.keymap.set({'n', 'x', 'o'}, 'T', function ()
    leap(ft_args({ opts = t_opts, backward = true, offset = 1 }))
  end)
end
```

</details>

<details>
<summary>Jump to lines</summary>

Note: `pattern` is an experimental feature at the moment, subject to
removal.

```lua
local function leap_linewise ()
  local _, l, c = unpack(vim.fn.getpos('.'))
  local pattern =
    '\\v'
    -- Skip 3-3 lines around the cursor.
    .. '(%<'..(math.max(1,l-3))..'l|%>'..(l+3)..'l)'
    -- Cursor column or EOL (if the cursor is beyond that).
    .. '(%'..c..'v|$%<'..c..'v)'
  require('leap').leap {
    pattern = pattern,
    target_windows = { vim.fn.win_getid() },
    opts = { safe_labels = '' }
  }
end
-- For maximum comfort, force linewise selection in
-- the mappings:
vim.keymap.set({'n', 'x', 'o'}, '|', function ()
  local mode = vim.fn.mode(1)
  -- Only force V if not already in it (otherwise it exits Visual mode).
  if not mode:match('n$') and not mode:match('V') then
    vim.cmd('normal! V')
  end
  leap_linewise()
end)
```

</details>

<details>
<summary>Shortcuts to Telescope results</summary>

```lua
-- NOTE: If you try to use this before entering any input, an error is thrown.
-- (Help would be appreciated, if someone knows a fix.)
local function get_targets (buf)
  local pick = require('telescope.actions.state').get_current_picker(buf)
  local scroller = require('telescope.pickers.scroller')
  local wininfo = vim.fn.getwininfo(pick.results_win)[1]
  local top = math.max(
    scroller.top(pick.sorting_strategy, pick.max_results, pick.manager:num_results()),
    wininfo.topline - 1
  )
  local bottom = wininfo.botline - 2  -- skip the current row
  local targets = {}
  for lnum = bottom, top, -1 do  -- start labeling from the closest (bottom) row
    table.insert(targets, { wininfo = wininfo, pos = { lnum + 1, 1 }, pick = pick, })
  end
  return targets
end

local function pick_with_leap (buf)
  require('leap').leap {
    targets = function () return get_targets(buf) end,
    action = function (target)
      target.pick:set_selection(target.pos[1] - 1)
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
