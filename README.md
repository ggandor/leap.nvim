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

- Initiate the search in the forward (`s`) or backward (`S`) direction, or in
  the other windows (`gs`). (Note: you can use a single key for the current
  window or even the whole tab page, if you are okay with the trade-offs.)
- Start typing a 2-character pattern (`{char1}{char2}`).
- After typing the first character, you see "labels" appearing next to some of
  the `{char1}{?}` pairs. You cannot use the labels yet - they only get active
  after finishing the pattern.
- Enter `{char2}`. If the pair was not labeled, then voilà, you're already
  there. You can safely ignore the remaining labels, and continue editing -
  those are guaranteed non-conflicting letters, disappearing on the next
  keypress.
- Else: type the label character, that is now active. If there are more matches
  than available labels, you can switch between groups, using `<space>` and
  `<backspace>`.

Character pairs give you full coverage of the screen:

- `s{char}<space>` jumps to the last character on a line.
- `s<space><space>` jumps to actual end-of-line characters, including empty
  lines.

At any stage, `<enter>` consistently jumps to the next available target
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

- You _don't have to compose in your head_: one command achieves one logical
  movement.

- You _don't have to be aware of the context_: the eyes can keep focusing on the
  target the whole time.

- You _don't have to make decisions on the fly_: the sequence you should enter
  is determined from the very beginning.

- You _don't have to pause in the middle_: if typing at a moderate speed, at
  each step you already know what the immediate next keypress should be, and
  your mind can process the rest in the background.

## Getting started

### Status

The plugin is not 100% stable yet, but don't let that stop you - the usage
basics are extremely unlikely to change. To follow breaking changes, subscribe
to the corresponding [issue](https://github.com/ggandor/leap.nvim/issues/18).

### Requirements

* Neovim >= 0.9.0 stable, or latest nightly

### Dependencies

* [repeat.vim](https://github.com/tpope/vim-repeat), for dot-repeats (`.`) to
  work

### Installation

Use your preferred method or plugin manager. No extra steps needed besides
defining keybindings - to use the default ones, put the following into your
config (overrides `s`, `S` and `gs` in all modes):

`require('leap').create_default_mappings()` (init.lua)

`lua require('leap').create_default_mappings()` (init.vim)

<details>
<summary>Alternative key mappings and arrangements (bidirectional jump,
etc.)</summary>

Calling `require('leap').create_default_mappings()` is equivalent to:

```lua
vim.keymap.set({'n', 'x', 'o'}, 's',  '<Plug>(leap-forward)')
vim.keymap.set({'n', 'x', 'o'}, 'S',  '<Plug>(leap-backward)')
vim.keymap.set({'n', 'x', 'o'}, 'gs', '<Plug>(leap-from-window)')
```

Bidirectional `s` for Normal and Visual mode:

```lua
vim.keymap.set({'n', 'x'}, 's', '<Plug>(leap)')
vim.keymap.set('n',        'S', '<Plug>(leap-from-window)')
vim.keymap.set('o',        's', '<Plug>(leap-forward)')
vim.keymap.set('o',        'S', '<Plug>(leap-backward)')
```

Trade-off: Compared to using separate keys for the two directions, you will
only get half as many autojumps on average.

Jump to anywhere in Normal mode with one key:

```lua
vim.keymap.set('n', 's', '<Plug>(leap-anywhere)')
vim.keymap.set('x', 's', '<Plug>(leap)')
vim.keymap.set('o', 's', '<Plug>(leap-forward)')
vim.keymap.set('o', 'S', '<Plug>(leap-backward)')
```

Trade-off: if you have multiple windows open on the tab page, you will almost
never get an autojump, except if all targets are in the same window. (This is
an intentional restriction: it would be too disorienting if the cursor could
jump in/to a different window than your goal, right before selecting the
target.)

Note that when searching bidirectionally in the current window, Leap sorts
matches by euclidean (beeline) distance from the cursor, with the exception
that the current line you're on, and on that line, forward direction is
prioritized. That is, you can always be sure that the targets right in front of
you will be the first ones.

Bidirectional search is not recommended for Operator-pending mode, as
dot-repeat cannot be used if the search is non-directional. Also worth noting
that in Normal and Visual mode you cannot traverse through the matches anymore
(`:h leap-traversal`), although invoking repeat right away (`:h leap-repeat`)
can substitute for that.

See `:h leap-custom-mappings` for more.

</details>

<details>
<summary>Suggested additional tweaks</summary>

```lua
-- Define equivalence classes for brackets and quotes, in addition to
-- the default whitespace group:
require('leap').opts.equivalence_classes = { ' \t\r\n', '([{', ')]}', '\'"`' }

-- Use the traversal keys to repeat the previous motion without
-- explicitly invoking Leap:
require('leap.user').set_repeat_keys('<enter>', '<backspace>')

-- Define a preview filter (skip the middle of alphanumeric words):
require('leap').opts.preview_filter =
  function (ch0, ch1, ch2)
    return not (
      ch1:match('%s') or
      ch0:match('%w') and ch1:match('%w') and ch2:match('%w')
    )
  end
```

</details>

<details>
<summary>Lazy loading</summary>

...is all the rage now, but doing it via your plugin manager is unnecessary, as
Leap lazy loads itself. Using the `keys` feature of lazy.nvim might even cause
[problems](https://github.com/ggandor/leap.nvim/issues/191).

</details>

### Extras

Experimental features, APIs might be subject to change.

<details>
<summary>Remote operations ("spooky actions at a distance")</summary>

Inspired by [leap-spooky.nvim](https://github.com/ggandor/leap-spooky.nvim),
and [flash.nvim](https://github.com/folke/flash.nvim)'s similar feature.

This function allows you to perform an action in a remote location: it
forgets the current mode or pending operator, lets you leap with the
cursor (to anywhere on the tab page), then continues where it left off.
Once an operation or insertion is finished, it moves the cursor back to
the original position, as if you had operated from the distance.

```lua
-- If using the default mappings (`gs` for multi-window mode), you can
-- map e.g. `gS` here.
vim.keymap.set({'n', 'x', 'o'}, 'gs', function ()
  require('leap.remote').action()
end)
```

Example: `gs{leap}yap`, `vgs{leap}apy`, or `ygs{leap}ap` yank the paragraph at
the position specified by `{leap}`.

**Tips**

* Swapping regions becomes moderately simple, without needing a custom
  plugin: `d{region1} gs{leap} v{region2} pP`. Example (swapping two
  words): `diwgs{leap}viwpP`.

* As the remote mode is active until returning to Normal mode again (by
  any means), `<ctrl-o>` becomes your friend in Insert mode, or when
  doing change operations.

**Icing on the cake, no. 1 - giving input ahead of time**

The `input` parameter lets you feed keystrokes automatically after the jump:

```lua
-- Trigger visual selection right away, so that you can `gs{leap}apy`:
vim.keymap.set({'n', 'o'}, 'gs', function ()
  require('leap.remote').action { input = 'v' }
end)
-- Forced linewise version:
vim.keymap.set({'n', 'o'}, 'gS', function ()
  require('leap.remote').action { input = 'V' }
end)
-- Remote K:
vim.keymap.set('n', 'gK', function ()
 require('leap.remote').action { input = 'K' }
end)
-- Remote gx:
vim.keymap.set('n', 'gX', function ()
 require('leap.remote').action { input = 'gx' }
end)
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
     if not ok or ch == vim.keycode('<esc>') then return end
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
  -- In any case, do some movement, to trigger operations in O-p mode.
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
vim.api.nvim_create_augroup('LeapRemote', {})
vim.api.nvim_create_autocmd('User', {
  pattern = 'RemoteOperationDone',
  group = 'LeapRemote',
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

```lua
vim.keymap.set({'n', 'x', 'o'}, 'ga',  function ()
  require('leap.treesitter').select()
end)

-- Linewise.
vim.keymap.set({'n', 'x', 'o'}, 'gA',
  'V<cmd>lua require("leap.treesitter").select()<cr>'
)
```

Besides choosing a label (`ga{label}`), in Normal/Visual mode you can also use
the traversal keys for incremental selection (`;` and `,` are automatically
added to the default keys). The labels are forced to be safe, so you can
operate on the current selection right away (`ga;;y`).

**Tips**

* The traversal can "wrap around" backwards, so you can select the root node
  right away (`ga,`), instead of going forward (`ga;;;...`).

* Linewise mode skips the current line, and redundant nodes are also filtered
  out (only the outermost are kept among the ones that span the same line
  ranges).

* To increase/decrease the selection in a
  [clever-f](https://github.com/rhysd/clever-f.vim)-like manner (`gaaaAA...`
  instead of `ga;;,,`), set the trigger key (or the suffix of it) and its
  inverted case as temporary traversal keys for this specific call (`select()`
  can take an `opts` argument, just like `leap()` - see `:h leap.leap()`):

  ```lua
  -- "clever-a"
  vim.keymap.set({'n', 'x', 'o'}, 'ga',  function ()
    local sk = vim.deepcopy(require('leap').opts.special_keys)
    -- The items in `special_keys` can be both strings or tables - the
    -- shortest workaround might be the below one:
    sk.next_target = vim.fn.flatten(vim.list_extend({'a'}, {sk.next_target}))
    sk.prev_target = vim.fn.flatten(vim.list_extend({'A'}, {sk.prev_target}))

    require('leap.treesitter').select { opts = { special_keys = sk } }
  end)
  ```

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

### Bugs

<details>
<summary>Workaround for the duplicate cursor bug when autojumping</summary>

For Neovim versions < 0.10 (https://github.com/neovim/neovim/issues/20793):

```lua
-- Hide the (real) cursor when leaping, and restore it afterwards.
vim.api.nvim_create_autocmd('User', { pattern = 'LeapEnter',
    callback = function()
      vim.cmd.hi('Cursor', 'blend=100')
      vim.opt.guicursor:append { 'a:Cursor/lCursor' }
    end,
  }
)
vim.api.nvim_create_autocmd('User', { pattern = 'LeapLeave',
    callback = function()
      vim.cmd.hi('Cursor', 'blend=0')
      vim.opt.guicursor:remove { 'a:Cursor/lCursor' }
    end,
  }
)
```

Caveat: If you experience any problems after using the above snippet, check
[#70](https://github.com/ggandor/leap.nvim/issues/70#issuecomment-1521177534)
and [#143](https://github.com/ggandor/leap.nvim/pull/143) to tweak it.

</details>

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
<summary>Greying out the search area</summary>

```lua
-- Or just set to grey directly, e.g. { fg = '#777777' },
-- if Comment is saturated.
vim.api.nvim_set_hl(0, 'LeapBackdrop', { link = 'Comment' })
```

</details>

<details>
<summary>Highlight only the next input candidates</summary>

```lua
require('leap').opts.highlight_target_range_for_phase2 = -1
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
happens to rhyme with Sneak. That said, in some respects you can indeed think
of leap.nvim as a spiritual successor to Raskin's work, and thus the name as a
little tribute to the great pioneer of interface design, even though embracing
the modal paradigm is a fundamental difference in our approach.

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
<summary>Linewise motions</summary>

```lua
local function get_line_starts(winid, skip_range)
  local wininfo =  vim.fn.getwininfo(winid)[1]
  local cur_line = vim.fn.line('.')
  -- Skip lines close to the cursor.
  local skip_range = skip_range or 2

  -- Get targets.
  local targets = {}
  local lnum = wininfo.topline
  while lnum <= wininfo.botline do
    local fold_end = vim.fn.foldclosedend(lnum)
    -- Skip folded ranges.
    if fold_end ~= -1 then
      lnum = fold_end + 1
    else
      if (lnum < cur_line - skip_range) or (lnum > cur_line + skip_range) then
        table.insert(targets, { pos = { lnum, 1 } })
      end
      lnum = lnum + 1
    end
  end

  -- Sort them by vertical screen distance from cursor.
  local cur_screen_row = vim.fn.screenpos(winid, cur_line, 1)['row']
  local function screen_rows_from_cur(t)
    local t_screen_row = vim.fn.screenpos(winid, t.pos[1], t.pos[2])['row']
    return math.abs(cur_screen_row - t_screen_row)
  end
  table.sort(targets, function (t1, t2)
    return screen_rows_from_cur(t1) < screen_rows_from_cur(t2)
  end)

  if #targets >= 1 then
    return targets
  end
end

-- You can pass an argument to specify a range to be skipped
-- before/after the cursor (default is +/-2).
function leap_line_start(skip_range)
  local winid = vim.api.nvim_get_current_win()
  require('leap').leap {
    target_windows = { winid },
    targets = get_line_starts(winid, skip_range),
  }
end

-- For maximum comfort, force linewise selection in the mappings:
vim.keymap.set('x', '|', function ()
  -- Only force V if not already in it (otherwise it would exit Visual mode).
  if vim.fn.mode(1) ~= 'V' then vim.cmd('normal! V') end
  leap_line_start()
end)
vim.keymap.set('o', '|', "V<cmd>lua leap_line_start()<cr>")
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

<details>
<summary>Enhanced f/t motions</summary>

See [flit.nvim](https://github.com/ggandor/flit.nvim). Note that this is not a
proper extension plugin, as it uses undocumented API too.

</details>
