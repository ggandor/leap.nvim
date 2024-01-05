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
Sneak. The main novel idea in Leap is that you get a **live preview of the
target labels** - by mapping possible futures, Leap can show you which key(s)
you will need to press _before_ you actually need to do that.

- Initiate the search in the forward (`s`) or backward (`S`) direction, or in
  the other windows (`gs`).
- Start typing a 2-character pattern (`{c1}{c2}`).
- After typing the first character, you see "labels" appearing next to some of
  the `{c1}{?}` pairs. You cannot _use_ the labels yet.
- Enter `{c2}`. If the pair was not labeled, then voilà, you're already there.
  No need to be bothered by remaining labels - those are guaranteed "safe"
  letters -, just continue editing.
- Else: type the label character. If there are too many matches (more than
  ~50), you might need to switch to the desired group first, using `<space>`
  (step back with `<tab>`, if needed).

### Why is this method cool?

It is **ridiculously fast**: not counting the trigger key, leaping to literally
anywhere on the screen rarely takes more than 3 keystrokes in total, that can be
typed in one go. Often 2 is enough.

At the same time, it **reduces mental effort to almost zero**:

- You _don't have to weigh alternatives_: a single universal motion type can be
  used in all non-trivial situations.

- You _don't have to compose in your head_: one command achieves one logical
  movement.

- You _don't have to be aware of the context_: the eyes can keep focusing on the
  target the whole time.

- You _don't have to make decisions on the fly_: the sequence you should enter
  is determined from the very beginning - just type out what you see.

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

- search bidirectionally in the window, or bind only one key to Leap, and
  search in all windows, if you are okay with the trade-offs (see [FAQ](#faq)).
- map keys to repeat motions without explicitly invoking Leap, similar to how
  `;` and `,` works (see `:h leap-repeat-keys`).

### Down the kangaroo hole

This was just a teaser - mind that while Leap has deeply thought-through,
opinionated defaults, its small(ish) but comprehensive API makes it flexible:
you can configure it to resemble other similar plugins, extend it with custom
targeting methods, and even do arbitrary actions with the selected target(s) -
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
should be a _non-issue_. An ideal keyboard-driven interface would impose
**almost no more cognitive burden than using a mouse**, without the constant
context-switching required by the latter.

That is, **you do not want to think about**

- **the command**: we need one fundamental targeting method that can bring you
  anywhere: a "jetpack" instead of a "railway network" (↔ EasyMotion and its
  derivatives)
- **the context**: it should be enough to look at the target, and nothing else
  (↔ vanilla Vim motion combinations using relative line numbers and/or
  repeats)
- **the steps**: the motion should be atomic (↔ Vim motion combos), and ideally
  you should be able to type the sequence in one go, always knowing the next
  step in advance (↔ any kind of "just-in-time" labeling method; note that the
  "`/` on steroids" approach by Pounce and Flash, where the pattern length is
  not fixed, and thus the labels appear at an unknown time, makes this last
  goal impossible)

All the while using **as few keystrokes as possible**, and getting distracted by
**as little incidental visual noise as possible**.

### How do we measure up?

It is obviously impossible to achieve all of the above at the same time, without
some trade-offs at least; but in our opinion Leap comes pretty close, occupying
a sweet spot in the design space.

The **one-step shift between perception and action** is the big idea that cuts
the Gordian knot: a fixed pattern length combined with ahead-of-time labeling
can eliminate the surprise factor from the search-based method (which is the
only viable approach - see "jetpack" above). Fortunately, a 2-character pattern
\- the shortest one with which we can play this trick - is also long enough to
sufficiently narrow down the matches in the vast majority of cases.

Fixed pattern length also makes autojump possible - you cannot improve on
jumping directly, not having to read a label at all. With ahead-of-time
labeling, hovever, we can do this in a smarter way too - disabling autojump and
switching back to a bigger, "unsafe" label set, if there are lots of targets.
The non-determinism is not much of an issue here, since the outcome is known
ahead of time.

### Auxiliary principles

- Optimize for the common case, not the pathological: a good example is using
  strictly one-character labels and switching between groups, which can become
  awkward beyond, say, 200 targets, but makes a whole bunch of edge cases and
  UI problems nonexistent.

- [Sharpen the saw](http://vimcasts.org/blog/2012/08/on-sharpening-the-saw/):
  build on Vim's native features, aim for synergy, and don't reinvent the wheel
  (dot-repeat (`.`), inclusive/exclusive toggle (`v`),
  [keymap](http://vimdoc.sourceforge.net/htmldoc/mbyte.html#mbyte-keymap)
  support, autocommands via `User` events, `<Plug>` keys, etc.).

- [Mechanisms instead of
  policies](https://cacm.acm.org/magazines/2018/11/232214-a-look-at-the-design-of-lua/fulltext):
  Complement the small and opinionated core by [extension
  points](#extending-leap), keeping the plugin flexible and future-proof.

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
config:

`require('leap').create_default_mappings()` (init.lua)

`lua require('leap').create_default_mappings()` (init.vim)

This will override `s`, `S`, and `gs` in all modes. Note that the above
function will check for conflicts with any custom mappings created by you or
other plugins, and will _not_ overwrite them, unless called with a `true`
argument.

To set custom mappings instead, see `:h leap-custom-mappings`.

<details>
<summary>Workaround for the duplicate cursor bug when autojumping</summary>

Until https://github.com/neovim/neovim/issues/20793 is fixed:

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

### Lazy loading

...is all the rage now, but doing it manually or via some plugin manager is
completely redundant, as Leap takes care of it itself. Nothing unnecessary is
loaded until you actually trigger a motion.

## Usage

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
covered by a limited set of safe target labels (keys you would not use right
after a jump), but stays in place, and switches to an extended label set
otherwise. For fine-tuning or disabling this behaviour, see `:h leap-config`
(`labels` and `safe_labels`).

### Multiple target groups

To show the last important feature, let's go back to the start position, and
start a new jump - we will target the struct member on line 1100, near the
bottom (`available = oldwin->w_frame->fr_height;`), using the pattern `fr`.
Press `s`, and then `f`:

![quick example 3](../media/quick_example_3.png?raw=true)

The blue labels indicate a secondary group of matches, where we start to reuse
the available labels. You can reach those by pressing `<space>` first, which
switches to the subsequent match group. To jump to our target (the blue `j`),
you should now press `r` (to finish the pattern), and then `<space>j`.

In very rare cases, if the large number of matches cannot be covered even by
two label groups, you might need to press `<space>` multiple times, until you
see the target label, first in blue, and then in green. (Substitute "green" and
"blue" with the actual colors in the current theme.)

### Repeat and traversal

`<enter>` (`special_keys.next_target`) is a very special key: at any stage, it
initiates "traversal" mode, moving on to the next match on each subsequent
keypress. If you press it right after invoking a Leap motion (e.g. `s<enter>`),
it uses the previous search pattern. In case you overshoot your target, `<tab>`
(`special_keys.prev_target`) can revert the previous jump(s). Note that if the
safe label set is in use, the labels will remain available the whole time!

You can make `next_target` and `prev_target` behave like like `;` and `,`, that
is, repeat the last motion without explicitly invoking Leap (see `:h
leap-repeat-keys`).

Traversal mode can be used as a substitute for `fFtT` motions.
`s{char}<enter><enter>` is the same as `f{char};`, or `ds{char}<enter>` as
`dt{char}`, but they work over multiple lines.

In case of cross-window search (`gs`), you cannot traverse (since there's no
direction to follow), but the search can be repeated, and you can also accept
the first (presumably only) match with `<enter>`, even after one input.

### Special cases

<details>
<summary>Jumping to the end of the line and to empty lines</summary>

A character at the end of a line can be targeted by pressing `<space>` after it.
There is no special mechanism behind this: `<space>` is simply an alias for the
newline character, defined in `opts.equivalence_classes` by default.

Empty lines or EOL positions can also be targeted, by pressing the newline
alias twice (`<space><space>`). This latter is a slightly more magical feature,
but fulfills the principle that any visible position you can move to with the
cursor should be reachable by Leap too.

</details>

<details>
<summary>Concealed labels</summary>

A special character might replace the label if either:

* Two labels would occupy the same position (this is possible in phase one,
  when the target is right before EOL or the window edge, and the label needs
  to be shifted left).

* Two-phase processing is enabled, and unlabeled phase one targets have no
  highlighting (the default). In this case targets beyond the secondary group
  need to have some kind of label next to them, to signal that they are not
  directly reachable.

Leap automatically uses either space (if both primary and secondary labels have
a background in the current color scheme) or a middle dot (U+00B7).

</details>

## Configuration

### Options

Below is a list of all configurable values in the `opts` table, with their
defaults. Set them like: `require('leap').opts.<key> = <value>`. For details on
the particular fields, see `:h leap-config`.

```Lua
max_phase_one_targets = nil
highlight_unlabeled_phase_one_targets = false
max_highlighted_traversal_targets = 10
case_sensitive = false
equivalence_classes = { ' \t\r\n', }
substitute_chars = {}
safe_labels = 'sfnut/SFNLHMUGTZ?'
labels = 'sfnjklhodweimbuyvrgtaqpcxz/SFNJKLHODWEIMBUYVRGTAQPCXZ?'
special_keys = {
  next_target = '<enter>',
  prev_target = '<tab>',
  next_group = '<space>',
  prev_group = '<tab>',
  multi_accept = '<enter>',
  multi_revert = '<backspace>',
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
without explicitly invoking Leap, see `:h leap-repeat-keys`.

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

## FAQ

<details>
<summary>Workaround for the duplicate cursor bug when autojumping</summary>

Until https://github.com/neovim/neovim/issues/20793 is fixed:

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

<details>
<summary>Why remap `s`/`S`?</summary>

Common operations should use the fewest keystrokes, so it makes sense to take
those keys over by Leap, especially given that both have short synonyms:

Normal mode

- `s` = `cl` (or `xi`)
- `S` = `cc`

Visual mode

- `s` = `c`
- `S` = `Vc`, or `c` if already in linewise mode

If you are not convinced, just head to `:h leap-custom-mappings`.

</details>

<details>
<summary>Bidirectional search</summary>

Beware that the trade-off in this mode is that you always have to select a
label, as there is no automatic jump to the first target (it would be very
confusing if the cursor would suddenly jump in the opposite direction than your
goal). Former vim-sneak users will know how awesome a feature that is. I really
suggest trying out the plugin with the defaults for a while first.

An additional disadvantage is that operations cannot be dot-repeated if the
search is non-directional.

With that out of the way, I'll tell you the simple trick: just initiate
multi-window mode with the current window as the only target.

```lua
vim.keymap.set(<modes>, <key>, function ()
  require('leap').leap { target_windows = { vim.api.nvim_get_current_win() } }
end)
```

</details>

<details>
<summary>Search in all windows</summary>

The same caveats as above about bidirectional search apply here.

```lua
vim.keymap.set('n', <key>, function ()
  local focusable_windows = vim.tbl_filter(
    function (win) return vim.api.nvim_win_get_config(win).focusable end,
    vim.api.nvim_tabpage_list_wins(0)
  )
  require('leap').leap { target_windows = focusable_windows }
end)
```
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

<details>
<summary>Jumping to lines</summary>

It's easy to add to your config, see [Extending Leap](#extending-leap)
for the example snippet (30-40 lines).

</details>

<details>
<summary>Enhanced f/t motions</summary>

Check [flit.nvim](https://github.com/ggandor/flit.nvim), an extension plugin for Leap.

</details>

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
<summary>Disable secondary labels</summary>

You can hide the letters, and show emtpy boxes by tweaking the
`LeapLabelSecondary` highlight group (that way you keep a visual indication
that the target is labeled):

```lua
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function ()
    local bg = vim.api.nvim_get_hl(0, {name = "LeapLabelSecondary"}).bg
    vim.api.nvim_set_hl(0, "LeapLabelSecondary",{ fg = bg, bg = bg, })
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
with them.

There are lots of ways you can extend the plugin and bend it to your will, and
the combinations of them give you almost infinite possibilities.

### Calling `leap` with custom arguments

Instead of using the provided `<Plug>` keys, you can also call the `leap`
function directly. The following arguments are available:

`opts`: A table just like `leap.opts`, to override any default setting for the
specific call. E.g.:

```lua
require('leap').leap { opts = { labels = {} } }
```

`offset`: Where to land with the cursor compared to the target position (-1, 0,
1, 2).

`inclusive_op`: A flag indicating whether an operation should behave as
inclusive (`:h inclusive`).

`backward`: Search backward instead of forward in the current window.

`target_windows`: A list of windows (as `winid`s) to be searched.

<details>
<summary>Example: bidirectional and all-windows search</summary>

```lua
-- Bidirectional search in the current window is just a specific case of
-- multi-window mode.
require('leap').leap { target_windows = { vim.api.nvim_get_current_win() } }

-- Searching in all windows (including the current one) on the tab page.
require('leap').leap { target_windows = vim.tbl_filter(
  function (win) return vim.api.nvim_win_get_config(win).focusable end,
  vim.api.nvim_tabpage_list_wins(0)
)}
```
</details>

This is where things start to become really interesting:

`targets`: Either a list of targets, or a function returning such a list. The
elements of the list are tables of arbitrary structure, with the only mandatory
field being `pos` - a (1,1)-indexed tuple; this is the position of the label,
and also the jump target, if there is no custom `action` provided. If you have
targets in multiple windows, you also need to provide a `wininfo` field for each
(`:h getwininfo()`). Targets can represent anything with a position, like
Tree-sitter nodes, etc.

<details>
<summary>Example: linewise motions</summary>

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
function leap_linewise(skip_range)
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
  leap_linewise()
end)
vim.keymap.set('o', '|', "V<cmd>lua leap_linewise()<cr>")
```
</details>

`action`: A Lua function that will be executed by Leap in place of the jump. (You
could obviously implement some custom jump logic here too.) Its only argument is
either a target, or a list of targets (in multiselect mode).

<details>
<summary>Example: select Tree-sitter nodes</summary>

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

`multiselect`: A flag allowing for selecting multiple targets for `action`. In
this mode, you can just start picking labels one after the other. You can revert
the most recent pick with `<backspace>`, and accept the selection with
`<enter>`.

<details>
<summary>Example: multi-cursor `:normal`</summary>

```lua
-- The following example showcases a custom action, using `multiselect`. We're
-- executing a `normal!` command at each selected position (this could be even
-- more useful if we'd pass in custom targets too).

local api = vim.api

function paranormal(targets)
  -- Get the :normal sequence to be executed.
  local input = vim.fn.input("normal! ")
  if #input < 1 then return end

  local ns = api.nvim_create_namespace("")

  -- Set an extmark as an anchor for each target, so that we can also execute
  -- commands that modify the positions of other targets (insert/change/delete).
  for _, target in ipairs(targets) do
    local line, col = unpack(target.pos)
    id = api.nvim_buf_set_extmark(0, ns, line - 1, col - 1, {})
    target.extmark_id = id
  end

  -- Jump to each extmark (anchored to the "moving" targets), and execute the
  -- command sequence.
  for _, target in ipairs(targets) do
    local id = target.extmark_id
    local pos = api.nvim_buf_get_extmark_by_id(0, ns, id, {})
    vim.fn.cursor(pos[1] + 1, pos[2] + 1)
    vim.cmd("normal! " .. input)
  end

  -- Clean up the extmarks.
  api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

-- Usage:
require('leap').leap {
    target_windows = { api.nvim_get_current_win() },
    action = paranormal,
    multiselect = true,
}
```
</details>

### Setting up autocommands

Leap triggers `User` events on entering/exiting (with patterns `LeapEnter` and
`LeapLeave`), so that you can set up autocommands, e.g. to change the values of
some editor options while the plugin is active (`:h leap-events`).

### Accessing the arguments passed to `leap`

The arguments of the current call are always available at runtime, in the
`state.args` table.

Using autocommands together with the `args` table, you can customize
practically anything on a per-call basis. Keep in mind that nothing prevents
you from passing arbitrary flags when calling `leap`:

```Lua
function my_custom_leap_func()
    require('leap').leap { my_custom_flag = true, ... }
end

vim.api.nvim_create_autocmd('User', {
  pattern = 'LeapEnter',
  callback = function ()
    if require('leap').state.args.my_custom_flag then
      -- Implement some special logic here, that will only apply to
      -- my_custom_leap_func() (e.g., change the style of the labels),
      -- and clean up with an analogous `LeapLeave` autocommand.
    end
  end
})
```

### Plugins using Leap

- [leap-spooky.nvim](https://github.com/ggandor/leap-spooky.nvim) (remote
  operations on text objects)
- [flit.nvim](https://github.com/ggandor/flit.nvim) (enhanced f/t motions)

