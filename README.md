<img align="left" width="150" height="85" src="../media/kangaroo.png?raw=true">

# leap.nvim

Leap is a general-purpose motion plugin for [Neovim](https://neovim.io/), with
the ultimate goal of establishing a new standard interface for moving around in
the visible editor area in Vim-like editors.

The aim is: to be a common denominator, and unite the strengths of various
similar plugins like [Sneak](https://github.com/justinmk/vim-sneak) (minimalism,
speed, convenience),
[EasyMotion](https://github.com/easymotion/vim-easymotion)/[Hop](https://github.com/phaazon/hop.nvim)
(scaling well for lots of targets), and
[Pounce](https://github.com/rlane/pounce.nvim) (incremental search + dynamic
feedback). To reach a level of sophistication where one does not have to think
much about motion commands anymore - just be able to reach any target in a
blink, while keeping the required mental effort close to zero.

- [Introduction](#introduction)
- [FAQ](#faq)
- [Getting started](#getting-started)
- [Usage](#usage)
- [Configuration](#configuration)
- [Extending Leap](#extending-leap)

## Introduction

Jumping from point A to B on the screen should not be some [exciting
puzzle](https://www.vimgolf.com/), for which you should train yourself; it
should be a _non-issue_. An ideal keyboard-driven interface would impose almost
**no more cognitive burden than using a mouse**, without the constant
context-switching required by the latter.

That is, **you do not want to think about**

- **the motion command**: we need one fundamental targeting method, instead of a
  smorgasbord of possibilities, having "enhanced" versions of each native
  motion, and more (↔ EasyMotion and co.)
- **the context**: it should be enough to look at the target, and nothing else
  (↔ vanilla Vim motion combinations, Sneak in non-labeled mode)
- **the steps**: the motion should be atomic (↔ Vim motion combos) and you
  should be able to type the command in one go, without interruptions (↔ most
  "labeling" plugins except Pounce to some degree, marred by its
  non-determinism)

And of course, all the while using as few keystrokes as possible, and getting
distracted by as little incidental visual noise as possible.

It is obviously impossible to achieve all of these at the same time, without
some trade-offs at least; but Leap comes pretty close, occupying a sweet spot in
the design space.

### How to use it (TL;DR)

- Initiate the search in the forward (`s`) or backward (`S`) direction, or in
  the other windows (`gs`).
- Start typing a 2-character search pattern (`{c1}{c2}`).
- After typing the first character, you see "labels" appearing next to some of
  the `{c1}{?}` pairs. You cannot _use_ the labels yet.
- As a convenience, at this point you can just start walking through the matches
  using `<enter>/<tab>` ("traversal" mode). [**#2**]
- Else: enter `{c2}`.
- If the pair was not labeled, then voilà, you're already there (no need to be
  bothered by remaining labels, just continue editing). [**#1**]
- Else: select a label. In case of multiple groups, first switch to the desired
  one, using `<space>/<tab>`. [**#3**, **#4**]

![showcase](../media/showcase.gif?raw=true)

(1: `sha`; 2: `s,<cr><cr><cr>`; 3: `sanN`; 4: `gshe<space>m`)

For further features, head to the [usage](#usage) section.

### Background

Leap is essentially a streamlined, refactored fork of
[Lightspeed](https://github.com/ggandor/lightspeed.nvim) (by the same author),
with more focus on simplicity, intuitiveness, and maintainability.

Compared to Lightspeed, Leap

* is just as efficient in the common case, and almost as efficient generally;
  all the really important features are there
* has less complexity and configuration options
* has a smaller and simpler visual footprint; it feels like using Sneak

### Auxiliary design principles

- [Sharpen the saw](http://vimcasts.org/blog/2012/08/on-sharpening-the-saw/):
  build on the native interface, and aim for synergy as much as possible. The
  plugin supports operators, dot-repeat (`.`), inclusive/exclusive toggle (`v`),
  multibyte text and
  [keymaps](http://vimdoc.sourceforge.net/htmldoc/mbyte.html#mbyte-keymap)
  (language mapping), autocommands via `User` events, among others, and intends
  to continuously improve in this respect.

- [Mechanisms instead of
  policies](https://cacm.acm.org/magazines/2018/11/232214-a-look-at-the-design-of-lua/fulltext)
  (or "be opinionated, but not stubborn"): aim for a small, maintainable core,
  and provide reasonable defaults; at the same time, keep the plugin flexible
  and future-proof via [extension points](#extending-leap).

### Status

Leap is not fully stable yet, but don't let that stop you - the usage basics are
extremely unlikely to change. To follow breaking changes, subscribe to the
corresponding [issue](https://github.com/ggandor/leap.nvim/issues/18).

## FAQ

<details>
<summary>Bidirectional search</summary>

```lua
-- Initiate multi-window mode with the current window as the only target:
require('leap').leap { target_windows = { vim.fn.win_getid() } }
```
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
vim.api.nvim_set_hl(0, 'LeapBackdrop', { fg = '#707070' })
```
</details>

<details>
<summary>How to live without 's' and 'S'?</summary>

`s` = `cl`, `S` = `cc`.
</details>

## Getting started

### Requirements

* Neovim >= 0.7.0

### Dependencies

* For the moment, [repeat.vim](https://github.com/tpope/vim-repeat) is required
  for the dot-repeat functionality to work as intended.

### Installation

Use your preferred plugin manager. No extra steps needed, besides optionally
setting the default keymaps:

`require('leap').set_default_keymaps()`

## Usage

With Leap you can jump to any positions in the visible window / tab page area by
entering a 2-character search pattern, and then optionally a "label" character
for choosing among multiple matches, similar to Sneak. The game-changing idea in
Leap is its "clairvoyant" ability: it maps possible futures, and shows you which
keys you will need to press _before_ you actually need to do that, so despite
the use of target labels, you can keep typing in a continuous manner.

Without further ado, let's cut to the chase, and learn by doing.
([Permalink](https://github.com/neovim/neovim/blob/8215c05945054755b2c3cadae198894372dbfe0f/src/nvim/window.c#L1078)
to the file, if you want to follow along.)

The search is invoked with `s` in the forward direction, and `S` in the backward
direction. Let's target some word containing `ol`. After entering the letter
`o`, the plugin processes all character pairs starting with it, and from here
on, you have all the visual information you need to reach your specific target.
To reach the unlabeled matches, just finish the pattern, i.e., type the second
character. For the others, you also need to type the label character that is
displayed right next to the match.

![quick example 1](../media/quick_example_1.png?raw=true)

Now type `l`. If you aimed for the first match (in `oldwin->w_frame`), you are
good to go, just continue the work! (The labels for the subsequent matches of
`ol` remain visible until the next keypress, but they are carefully chosen
"safe" letters, guaranteed to not interfere with your following editing
command.) If you aimed for some other match, then type the label, for example
`u`, and move on to that.

![quick example 2](../media/quick_example_2.png?raw=true)

To show the last important feature, let's go back to the start position, and
target the struct member on the line `available = oldwin->w_frame->fr_height;`
near the bottom, using the pattern `fr`, by first pressing `s`, and then `f`:

![quick example 3](../media/quick_example_3.png?raw=true)

The blue labels indicate the "secondary" group of matches, where we start to
reuse the available labels for a given pair (`s`, `f`, `n`... again). You can
reach those by prefixing the label with `<space>`, that switches to the
subsequent match group. For example, to jump to the "blue" `j` target, you
should now press `r<space>j`. In very rare cases, if the large number of matches
cannot be covered even by two label groups, you might need to press `<space>`
multiple times, until you see the target labeled, first with blue, and then,
after one more `<space>`, green. (Substitute "green" and "blue" with the actual
colors in the current theme.)

To summarize, here is the general flow again (in Normal and Visual mode, with
the default settings):

`s|S char1 char2 <space>? (<space>|<tab>)* label?`

That is,
- invoke in the forward (`s`) or backward (`S`) direction
- enter the first character of the search pattern
    - _the "beacons" are lit at this point; all potential matches (char1 + ?)
      are labeled_
- enter the second character of the search pattern (might short-circuit after
  this, if there is only one match)
    - _certain beacons are extinguished; only char1 + char2 matches remain_
    - _the cursor automatically jumps to the first match if there are enough
      "safe" labels; pressing any other key than a group-switch or a target
      label exits the plugin now_
- optionally cycle through the groups of matches that can be labeled at once
- choose a labeled target to jump to (in the current group)

### Smart autojump

Leap automatically jumps to the first match if the remaining matches can be
covered by a limited set of "safe" target labels (keys you would not use right
after a jump), but stays in place, and switches to an extended, more comfortable
label set otherwise. For details on configuring this behaviour, see `:h
leap-config`.

### Resolving conflicts in the first phase

If a directly reachable match covers a label, the match will get a highlight
(like in traversal mode), and the label will only be displayed after the second
input, that resolves the ambiguity. If a label gets positioned over another
label (this might occur before EOL or the window edge, when the labels need to
be shifted left), an "empty" label will be displayed until entering the second
input.

### Operator-pending mode

In Operator-pending mode, there are two different (pairs of) default motions
available, providing the necessary additional comfort and precision, since in
that case we are targeting exact positions, and can only aim once, without the
means of easy correction.

`z`/`Z` are the equivalents of Normal/Visual `s`/`S`, and they follow the
semantics of `/` and `?` in terms of cursor placement and inclusive/exclusive
operational behaviour, including forced motion types (`:h forced-motion`).

`x`/`X` provide missing variants for the two directions; the mnemonics could be
e**x**tend/e**X**clude:

```
ab···|                    |···ab
█████·  ←  Zab    zab  →  ████ab
ab███·  ←  Xab    xab  →  ██████
```

As you can see from the figure, `x` goes to the end of the match, including it
in the operation, while `X` stops just before - in an absolute sense, after -
the end of the match (the equivalent of `T` for Leap motions). In simpler
terms: `x`/`X` both shift the relevant edge of the operated area by +2.

### Jumping to the last character on a line

A character at the end of a line can be targeted by pressing `<space>` after it.
(There is no special mechanism behind this: you can set aliases for the newline
character simply by defining a group in `opts.character_classes` that contains
it.)

### Cross-window motions

`gs` searches in all the other windows on the tab page. In this case, the
matches are sorted by their screen distance from the cursor, advancing in
concentric circles.

### Repeating the search and traversing through the matches

Pressing `<enter>` (`special_keys.repeat_search`) after invoking any of Leap's
motions searches with the previous input.

After entering at least one input character, `<enter>`
(`special_keys.next_match`) moves on to the immediate next match (enters
traversal mode). Once in traversal mode, `<tab>` (`special_keys.prev_match`) can
revert the previous jump - that is, it puts the cursor back to its
previous position, allowing for an easy correction when you accidentally
overshoot your target.

`s|S char1 <enter> (<enter>|<tab>)*`

`s|S char1 char2 <enter>? (<enter>|<tab>)*`

Of course, the two can be combined - you can immediately move on after a
repeated search:

`s|S <enter> <enter>? (<enter>|<tab>)*`

Entering traversal mode after the first input is a useful shortcut, especially
in operator-pending mode, but it can also be used as a substitute for
normal-mode `f`/`t` motions. `s{char}<enter>` is the same as `f{char}`, but
works over multiple lines.

If the safe label set is in use, the labels will remain available during the
whole time, even after entering traversal mode.

For cross-window search, traversal mode is not supported.

## Configuration

`setup` has no implicit side effects, it is just a convenience function for
changing the values in the configuration table (which can also be accessed
directly as `require('leap').opts`). There is no need to call it if you're
fine with the defaults. Also note that `setup` is not recursive - table values
will simply be overwritten -, so in many cases, it might be more straightforward
to set `opts` directly.

```Lua
require('leap').setup {
  max_aot_targets = nil,
  highlight_unlabeled = false,
  case_sensitive = false,
  -- Groups of characters that should match each other.
  -- Obvious candidates are braces & quotes ('([{', ')]}', '`"\'').
  character_classes = { ' \t\r\n', },
  -- Leaving the appropriate list empty effectively disables "smart" mode,
  -- and forces auto-jump to be on or off.
  safe_labels = { . . . },
  labels = { . . . },
  -- These keys are captured directly by the plugin at runtime.
  -- (For `prev_match`, I suggest <s-enter> if possible in the terminal/GUI.)
  special_keys = {
    repeat_search = '<enter>',
    next_match    = '<enter>',
    prev_match    = '<tab>',
    next_group    = '<space>',
    prev_group    = '<tab>',
  },
}
```

For details, see `:h leap-config`.

### Keymaps

You can set the defaults keymaps (listed in `:h leap-default-keymaps`) by
calling `require('leap').set_default_keymaps()`. Note that the function will
check for conflicts with any custom mappings created by you or other plugins,
and will not overwite them, unless explicitly told so (called with a `true`
argument).

To set alternative keymaps, you can use the `<Plug>` keys listed in `:h
leap-custom-keymaps`.

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

`offset`: Where to land with the cursor compared to the target position (-1, 0,
1, 2).

`inclusive_op`: A flag indicating whether an operation should behave as
inclusive (`:h inclusive`).

`target_windows` allows you to pass in a list of windows (ID-s) to be searched.

<details>
<summary>Example: bidirectional and all-windows search</summary>

```lua
-- Bidirectional search in the current window is just a specific case of the
-- multi-window mode.
function leap_current_window()
  require('leap').leap { target_windows = { vim.fn.win_getid() } }
end

-- Searching in all windows (including the current one) on the tab page.
function leap_all_windows()
  local focusable_windows_on_tabpage = vim.tbl_filter(
    function (win) return vim.api.nvim_win_get_config(win).focusable end,
    vim.api.nvim_tabpage_list_wins(0)
  )
  require('leap').leap { target_windows = focusable_windows_on_tabpage }
end
```
</details>

This is where things start to become really interesting:

`targets`: A list of target items: tables of arbitrary structure, with the only
mandatory field being `pos` - a (1,1)-indexed tuple; this is the position of the
label, and also the jump target, if there is no custom `action` provided.
Targets can represent anything that has a position in the window, like
Tree-sitter nodes, etc.

<details>
<summary>Example: linewise motions</summary>

```lua
-- Here we feed Leap with custom targets.

local function get_line_starts(winid)
  local wininfo =  vim.fn.getwininfo(winid)[1]
  local cur_line = vim.fn.line('.')

  -- Get targets.
  local targets = {}
  local lnum = wininfo.topline
  while lnum <= wininfo.botline do
    local fold_end = vim.fn.foldclosedend(lnum)
    -- Skip folded ranges.
    if fold_end ~= -1 then
      lnum = fold_end + 1
    else
      if lnum ~= cur_line then table.insert(targets, { pos = { lnum, 1 } }) end
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

-- Usage:
local function leap_lines()
  winid = vim.api.nvim_get_current_win()
  require('leap').leap {
    target_windows = { winid },
    targets = get_line_starts(winid),
  }
end
```
</details>

`action`: A Lua function that will be executed by Leap in place of the jump. (You
could obviously implement some custom jump logic here too.) Its only argument is
either a target, or a list of targets (in multiselect mode).

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

function leap_paranormal(targets)
  -- Get the :normal sequence to be executed.
  local input = vim.fn.input("normal! ")
  if #input < 1 then return end

  local ns = vim.api.nvim_create_namespace("")

  -- Set an extmark as an anchor for each target, so that we can also execute
  -- commands that modify the positions of other targets (insert/change/delete).
  for _, target in ipairs(targets) do
    local line, col = unpack(target.pos)
    id = vim.api.nvim_buf_set_extmark(0, ns, line - 1, col - 1, {})
    target.extmark_id = id
  end

  -- Jump to each extmark (anchored to the "moving" targets), and execute the
  -- command sequence.
  for _, target in ipairs(targets) do
    local id = target.extmark_id
    local pos = vim.api.nvim_buf_get_extmark_by_id(0, ns, id, {})
    vim.fn.cursor(pos[1] + 1, pos[2] + 1)
    vim.cmd("normal! " .. input)
  end

  -- Clean up the extmarks.
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

-- Usage:
require('leap').leap {
    target_windows = { vim.fn.win_getid() },
    action = leap_paranormal
    multiselect = true,
}
```
</details>

### Accessing the arguments passed to `leap`

The arguments of the current call are always available at runtime, in the
`state.args` table.

### Setting up autocommands

Leap triggers `User` events on entering/exiting (with patterns `LeapEnter` and
`LeapLeave`), so that you can set up autocommands, e.g. to change the values of
some editor options while the plugin is active (`:h leap-events`).

### Customizing specific invocations

Using autocommands together with the `args` table, you can customize practically
anything on a per-call basis - keep in mind that nothing prevents you from
passing arbitrary flags when calling `leap`:

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
