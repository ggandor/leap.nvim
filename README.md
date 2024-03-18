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

Leap's default motions allow you to jump to any positions in the visible editor
area by entering a 2-character search pattern, and then potentially a label
character to pick your target from multiple matches, in a manner similar to
Sneak. The main novel idea in Leap is that **you get a preview of the target
labels** - Leap shows you which key you will need to press before you actually
need to do that.

- Initiate the search in the forward (`s`) or backward (`S`) direction, or in
  the other windows (`gs`). (Note: you can configure the plugin to merge these
  cases, using two keys instead, or even just one, if you are okay with the
  trade-offs.)
- Start typing a 2-character pattern (`{char1}{char2}`).
- After typing the first character, you see "labels" appearing next to some of
  the `{char1}{?}` pairs. You cannot _use_ the labels yet.
- Enter `{char2}`. If the pair was not labeled, then voilà, you're already there.
  No need to be bothered by remaining labels - those are guaranteed "safe"
  letters -, just continue editing.
- Else: type the label character. If there are too many matches (more than
  ~50), you might need to switch to the desired group first, using `<space>`
  (step back with `<tab>`, if needed).

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

### Supplemental features

Type

- `s{char}<space>` to jump to a character before the end of the line.
- `s<space><space>` to jump to an empty line (or any EOL position if Visual
  mode or `virtualedit` allows it)
- `s{char}<enter>` to jump to the first `{char}{?}` pair right away.
- `s<enter>` to repeat the last search.
- `s<enter><enter>...` or `s{char}<enter><enter>...` to traverse through the
  matches.

You can also

- search bidirectionally in the whole window (`<Plug>(leap)`), or bind only one
  key to Leap, and search in all windows (see [FAQ](#faq)).
- map keys to repeat motions without explicitly invoking Leap, similar to how
  `;` and `,` works (see `:h leap-repeat`).

### Down the kangaroo hole

This was just a teaser - mind that while Leap has deeply thought-through,
opinionated defaults, its small(ish) but comprehensive API makes it flexible:
you can configure it to resemble other similar plugins, extend it with custom
targeting methods, and even do arbitrary actions with the selected target -
read on to dig deeper.

- [Design considerations in detail](#design-considerations-in-detail)
- [Getting started](#getting-started)
- [Usage](#usage)
- [Configuration](#configuration)
- [FAQ](#faq)
- [Extending Leap](#extending-leap)

## Design considerations in detail

### The ideal

Premise: jumping from point A to B on the screen should not be some [exciting
puzzle](https://www.vimgolf.com/), for which you should train yourself; it
should be a non-issue. An ideal keyboard-driven interface would impose almost no
more cognitive burden than using a mouse, without the constant context-switching
required by the latter.

That is, **you do not want to think about**

- **the command**: we need one fundamental targeting method that can bring you
  anywhere: a "jetpack" instead of a "railway network" (↔ EasyMotion and its
  derivatives)
- **the context**: it should be enough to look at the target, and nothing else
  (↔ vanilla Vim motion combinations using relative line numbers and/or
  repeats)
- **the steps**: the motion should be atomic (↔ Vim motion combos), and ideally
  you should be able to type the whole sequence in one go, always knowing the
  next step in advance (↔ any kind of "just-in-time" labeling method; note that
  the "`/` on steroids" approach by Pounce and Flash, where the pattern length
  is not fixed, and thus the labels appear at an unknown time, makes this last
  goal impossible)

All the while using **as few keystrokes as possible**, and getting distracted by
**as little incidental visual noise as possible**.

### How do we measure up?

It is obviously impossible to achieve all of the above at the same time, without
some trade-offs at least; but in our opinion Leap comes pretty close, occupying
a sweet spot in the design space. (The worst remaining offender might be visual
noise.)

The **one-step shift between perception and action** is the big idea that cuts
the Gordian knot: a fixed pattern length combined with ahead-of-time labeling
can eliminate the surprise factor from the search-based method (which is the
only viable approach - see "jetpack" above). Fortunately, a 2-character pattern
\- the shortest one with which we can play this trick - is also long enough to
sufficiently narrow down the matches in the vast majority of cases.

Fixed pattern length also makes **(safe) automatic jump to the first target**
possible. You cannot improve on jumping directly, just like how `f` and `t`
works, not having to read a label at all, and not having to accept the match
with `<enter>` either. However, we can do this in a smart way: if there are
many targets (more than 15-20), we stay put, so we can use a bigger, "unsafe"
label set - getting the best of both worlds. The non-determinism we're
introducing is less of an issue here, since the outcome is known in advance.

In sum, compared to other labeling plugins, Leap is unique in that it

* offers a more fluid experience, by (somewhat) eliminating the pause before
  typing the label

* feels natural to use for both distant _and_ close targets

### Auxiliary principles

<details>
<summary>Optimize for the common case</summary>

A good example is using strictly one-character labels and switching between
groups, which can become awkward beyond, say, 200 targets, but makes a whole
bunch of edge cases and UI problems nonexistent.

</details>

<details>
<summary>Sharpen the saw</summary>

Build on Vim's native features, aim for synergy, and don't reinvent the wheel
(dot-repeat (`.`), inclusive/exclusive toggle (`v`),
[keymap](http://vimdoc.sourceforge.net/htmldoc/mbyte.html#mbyte-keymap)
support, autocommands via `User` events, `<Plug>` keys, etc.).
(http://vimcasts.org/blog/2012/08/on-sharpening-the-saw/)

</details>

<details>
<summary>Mechanisms instead of policies</summary>

Complement the small and opinionated core by [extension
points](#extending-leap), keeping the plugin flexible and future-proof.

</details>

## Getting started

### Status

The plugin is not 100% stable yet, but don't let that stop you - the usage
basics are extremely unlikely to change. To follow breaking changes, subscribe
to the corresponding [issue](https://github.com/ggandor/leap.nvim/issues/18).

### Requirements

* Neovim >= 0.7.0 stable, or latest nightly

### Dependencies

* [repeat.vim](https://github.com/tpope/vim-repeat), for dot-repeats (`.`) to
  work

### Installation

Use your preferred method or plugin manager. No extra steps needed besides
defining keybindings - to use the default ones, put the following into your
config (overrides `s`, `S` and `gs` in all modes):

`require('leap').create_default_mappings()` (init.lua)

`lua require('leap').create_default_mappings()` (init.vim)

Note: Do not set lazy loading via your fancy plugin manager, as it is
completely redundant (Leap takes care of lazy loading itself), and might even
cause [problems](https://github.com/ggandor/leap.nvim/issues/191).

<details>
<summary>Alternative key mappings</summary>

Calling `require('leap').create_default_mappings()` is equivalent to:

```lua
vim.keymap.set({'n', 'x', 'o'}, 's',  '<Plug>(leap-forward)')
vim.keymap.set({'n', 'x', 'o'}, 'S',  '<Plug>(leap-backward)')
vim.keymap.set({'n', 'x', 'o'}, 'gs', '<Plug>(leap-from-window)')
```

A suggested alternative arrangement (bidirectional `s` for Normal mode):

```lua
vim.keymap.set('n',        's', '<Plug>(leap)')
vim.keymap.set('n',        'S', '<Plug>(leap-from-window)')
vim.keymap.set({'x', 'o'}, 's', '<Plug>(leap-forward)')
vim.keymap.set({'x', 'o'}, 'S', '<Plug>(leap-backward)')
```

Note that you will get half as many auto-jumps on average, but not needing to
press `shift` might compensate for that.

`<Plug>(leap)` sorts matches by euclidean distance from the cursor, with the
exception that the current line, and on the current line, forward direction is
prioritized. That is, you can always be sure that the targets right in front of
you will be the first ones.

Mapping to `<Plug>(leap)` is not recommended for Visual mode, as autojumping in
a random direction might be too annoying with the selection highlight on, and
neither for Operator-pending mode, as dot-repeat cannot be used if the search
is non-directional. Another caveat is that you cannot traverse through the
matches (`:h leap-traversal`).

For further customization, see `:h leap-custom-mappings`.

</details>

<details>
<summary>Suggested additional tweaks</summary>

```lua
-- Define equivalence classes for brackets and quotes, in addition to
-- the default whitespace group.
require('leap').opts.equivalence_classes = { ' \t\r\n', '([{', ')]}', '\'"`' }

-- Override some old defaults - use backspace instead of tab (see issue #165).
require('leap').opts.special_keys.prev_target = '<backspace>'
require('leap').opts.special_keys.prev_group = '<backspace>'

-- Use the traversal keys to repeat the previous motion without explicitly
-- invoking Leap.
require('leap.user').set_repeat_keys('<enter>', '<backspace>')
```

</details>

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

## Usage

See `:h leap-usage` for supplemental features not mentioned here (targeting
empty lines, "traversal" mode, repeating motions, etc.)

[Permalink](https://github.com/neovim/neovim/blob/8215c05945054755b2c3cadae198894372dbfe0f/src/nvim/window.c#L1078)
to the example file, if you want to follow along.

### Phase one

The search is invoked with `s` in the forward direction, `S` in the backward
direction, and `gs` in the other windows. Let's target some word containing
`ol`. After entering the letter `o`, the plugin processes all character pairs
starting with it, and from here on, you have all the visual information you
need to reach your specific target. (The highlighting of unlabeled matches -
green underlined on the screenshots - is opt-in, turned on for clarity here.)

![quick example 1](../media/quick_example_1.png?raw=true)

### Phase two

Let's finish the pattern, i.e., type `l`. Leap now jumps to the first match
(the unlabeled one) automatically - if you aimed for that, you are good to go,
just continue your work! (The labels for the subsequent matches of `ol` will
remain visible until the next keypress, but they are carefully chosen "safe"
letters, guaranteed to not interfere with your following editing command.)
Otherwise, type the label character next to your target match, and move on to
that.

![quick example 2](../media/quick_example_2.png?raw=true)

Note that Leap only jumps to the first match if the remaining matches can be
covered by the limited set of safe target labels, but stays in place, and
switches to an extended label set otherwise. For fine-tuning or disabling this
behaviour, see `:h leap-config` (`labels` and `safe_labels`).

### Multiple target groups

To show the last important feature, let's go back to the start position, and
start a new jump - we will target the struct member `fr_height` on line 1100,
near the bottom (`available = oldwin->w_frame->fr_height;`), using the pattern
`fr`. Press `s`, and then `f`:

![quick example 3](../media/quick_example_3.png?raw=true)

The blue labels indicate a secondary group of matches, where we start to reuse
the available labels. You can reach those by pressing `<space>` first, which
switches to the subsequent match group. To jump to our target (the blue `j`),
you should now press `r` (to finish the pattern), and then `<space>j`.

In very rare cases, if the large number of matches cannot be covered even by
two label groups, you might need to press `<space>` multiple times, until you
see the target label, first in blue, and then in green. (Substitute "green" and
"blue" with the actual colors in the current theme.)

## Configuration

### Options

Below is a list of all configurable values in the `opts` table, with their
defaults. Set them like: `require('leap').opts.<key> = <value>`. For details on
the particular fields, see `:h leap-config`.

```Lua
case_sensitive = false
equivalence_classes = { ' \t\r\n', }
max_phase_one_targets = nil
highlight_unlabeled_phase_one_targets = false
max_highlighted_traversal_targets = 10
substitute_chars = {}
safe_labels = 'sfnut/SFNLHMUGTZ?'
labels = 'sfnjklhodweimbuyvrgtaqpcxz/SFNJKLHODWEIMBUYVRGTAQPCXZ?'
special_keys = {
  next_target = '<enter>',
  prev_target = '<tab>',
  next_group = '<space>',
  prev_group = '<tab>',
}
```

### Mappings

See `:h leap-default-mappings`. To define alternative mappings, you can use the
`<Plug>` keys listed at `:h leap-custom-mappings`. There is also an
alternative, "fFtT"-style key set for in-window motions, including or excluding
the whole 2-character match in Visual and Operator-pending-mode.

To create custom motions with behaviours different from the predefined ones,
see `:h leap.leap()`.

To set repeat keys that work like `;` and `,` that is, repeat the last motion
without explicitly invoking Leap, see `:h leap-repeat`.

### Highlight groups

For customizing the highlight colors, see `:h leap-highlight`.

In case you - as a user - are not happy with a certain colorscheme's
integration, you could force reloading the default settings by calling
`leap.init_highlight(true)`. The call can even be wrapped in an
autocommand to automatically re-init on every colorscheme change:

```Vim
autocmd ColorScheme * lua require('leap').init_highlight(true)
```

This can be tweaked further, you could e.g. check the actual colorscheme, and
only execute for certain ones, etc.

### Autocommands

Leap triggers `User` events on entering/exiting (with patterns `LeapEnter` and
`LeapLeave`), so that you can set up autocommands, e.g. to change the values of
some editor options while the plugin is active (`:h leap-events`).

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
<summary>Search in all windows</summary>

```lua
vim.keymap.set('n', 's', function ()
  local focusable_windows = vim.tbl_filter(
    function (win) return vim.api.nvim_win_get_config(win).focusable end,
    vim.api.nvim_tabpage_list_wins(0)
  )
  require('leap').leap { target_windows = focusable_windows }
end)
```
</details>

<details>
<summary>Smart case sensitivity, wildcard characters (one-way
aliases)</summary>

Ahead-of-time labeling, unfortunately, makes them impossible, by design: for a
potential match in phase one, we might need to show two different labels
(corresponding to two different futures) at the same time.
([1](https://github.com/ggandor/leap.nvim/issues/28),
[2](https://github.com/ggandor/leap.nvim/issues/89#issuecomment-1368885497),
[3](https://github.com/ggandor/leap.nvim/issues/155#issuecomment-1556124351))

</details>

<details>
<summary>Arbitrary remote actions instead of jumping</summary>

Basic template:

```lua
local function remote_action ()
  local focusable_windows = vim.tbl_filter(
    function (win) return vim.api.nvim_win_get_config(win).focusable end,
    vim.api.nvim_tabpage_list_wins(0)
  )
  require('leap').leap {
    target_windows = focusable_windows,
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

<details>
<summary>Other supernatural powers besides clairvoyance?</summary>

You might be interested in [telekinesis](https://github.com/ggandor/leap-spooky.nvim).

</details>

### Configuration

<details>
<summary>Disable auto-jumping to the first match</summary>

```lua
require('leap').opts.safe_labels = {}
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
<summary>Hiding secondary labels</summary>

You can hide the letters, and show emtpy boxes by tweaking the
`LeapLabelSecondary` highlight group (that way you keep a visual indication
that the target is labeled):

```lua
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function ()
    local bg = vim.api.nvim_get_hl(0, {name = 'LeapLabelSecondary'}).bg
    vim.api.nvim_set_hl(0, 'LeapLabelSecondary',{ fg = bg, bg = bg, })
  end
})
```

</details>

<details>
<summary>Lightspeed-style highlighting</summary>

```lua
-- The below settings make Leap's highlighting closer to what you've been
-- used to in Lightspeed.

vim.api.nvim_set_hl(0, 'LeapBackdrop', { link = 'Comment' }) -- or some grey
vim.api.nvim_set_hl(0, 'LeapMatch', {
  -- For light themes, set to 'black' or similar.
  fg = 'white', bold = true, nocombine = true,
})

-- Lightspeed colors
-- primary labels: bg = "#f02077" (light theme) or "#ff2f87"  (dark theme)
-- secondary labels: bg = "#399d9f" (light theme) or "#99ddff" (dark theme)
-- shortcuts: bg = "#f00077", fg = "white"
-- You might want to use either the primary label or the shortcut colors
-- for Leap primary labels, depending on your taste.
vim.api.nvim_set_hl(0, 'LeapLabelPrimary', {
  fg = 'red', bold = true, nocombine = true,
})
vim.api.nvim_set_hl(0, 'LeapLabelSecondary', {
  fg = 'blue', bold = true, nocombine = true,
})
-- Try it without this setting first, you might find you don't even miss it.
require('leap').opts.highlight_unlabeled_phase_one_targets = true
```

</details>

<details>
<summary>Working with non-English text</summary>

Check out `opts.equivalence_classes`. For example, you can group accented
vowels together: `{ 'aá', 'eé', 'ií', ... }`.

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

There is more to Leap than meets the eye. On a general level, you should think
of it as less of a motion plugin and more of an engine for selecting visible
targets on the screen (acquired by arbitrary means), and doing arbitrary things
with them. See `:h leap.leap()` and `:h leap-events`.

There are lots of ways you can extend the plugin and bend it to your will, and
the combinations of them give you almost infinite possibilities. Some practical
examples:

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
<summary>Select Tree-sitter nodes</summary>

Not as sophisticated as flash.nvim's implementation, but totally usable, in 50
lines:

```lua
local api = vim.api
local ts = vim.treesitter

local function get_ts_nodes()
  if not pcall(ts.get_parser) then return end
  local wininfo = vim.fn.getwininfo(api.nvim_get_current_win())[1]
  -- Get current node, and then its parent nodes recursively.
  local cur_node = ts.get_node()
  if not cur_node then return end
  local nodes = { cur_node }
  local parent = cur_node:parent()
  while parent do
    table.insert(nodes, parent)
    parent = parent:parent()
  end
  -- Create Leap targets from TS nodes.
  local targets = {}
  local startline, startcol
  for _, node in ipairs(nodes) do
    startline, startcol, endline, endcol = node:range()  -- (0,0)
    local startpos = { startline + 1, startcol + 1 }
    local endpos = { endline + 1, endcol + 1 }
    -- Add both ends of the node.
    if startline + 1 >= wininfo.topline then
      table.insert(targets, { pos = startpos, altpos = endpos })
    end
    if endline + 1 <= wininfo.botline then
      table.insert(targets, { pos = endpos, altpos = startpos })
    end
  end
  if #targets >= 1 then return targets end
end

local function select_node_range(target)
  local mode = api.nvim_get_mode().mode
  -- Force going back to Normal from Visual mode.
  if not mode:match('no?') then vim.cmd('normal! ' .. mode) end
  vim.fn.cursor(unpack(target.pos))
  local v = mode:match('V') and 'V' or mode:match('') and '' or 'v'
  vim.cmd('normal! ' .. v)
  vim.fn.cursor(unpack(target.altpos))
end

local function leap_ts()
  require('leap').leap {
    target_windows = { api.nvim_get_current_win() },
    targets = get_ts_nodes,
    action = select_node_range,
  }
end

vim.keymap.set({'x', 'o'}, '\\', leap_ts)
```

</details>

<details>
<summary>Remote text objects</summary>

See [leap-spooky.nvim](https://github.com/ggandor/leap-spooky.nvim).

</details>

<details>
<summary>Enhanced f/t motions</summary>

See [flit.nvim](https://github.com/ggandor/flit.nvim).

</details>
