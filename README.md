<img align="left" width="150" height="85" src="../media/kangaroo.png?raw=true">

# leap.nvim

Leap is a general-purpose motion plugin for [Neovim](https://neovim.io/), with
the ultimate goal of establishing a new standard interface for moving around in
the visible area in Vim-like modal editors.

![showcase](../media/showcase.gif?raw=true)

### How to use it (TL;DR)

Leap allows you to jump to any positions in the visible window / tab page area
by entering a 2-character search pattern, and then potentially a "label"
character to choose among multiple matches, similar to
[Sneak](https://github.com/justinmk/vim-sneak). The novel idea in Leap is its
"clairvoyant" ability: it maps possible futures, and shows you which key(s) you
will need to press _before_ you actually need to do that.

- Initiate the search in the forward (`s`) or backward (`S`) direction, or in
  the other windows (`gs`).
- Start typing a 2-character pattern (`{c1}{c2}`).
- After typing the first character, you see "labels" appearing next to some of
  the `{c1}{?}` pairs. You cannot _use_ the labels yet.
- Enter `{c2}`. If the pair was not labeled, then voilà, you're already there.
  No need to be bothered by remaining labels, just continue editing.
- Else: select a label. In case of multiple groups, first switch to the desired
  one, using `<space>` (step back with `<tab>`, if needed).

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
  is determined from the very beginning.

- You _don't have to pause in the middle_: if typing at a moderate speed, at
  each step you already know what the immediate next keypress should be, and
  your mind can process the rest in the background.

### Down the kangaroo hole

This was just a teaser - mind that Leap is extremely flexible, and offers much
more beyond the defaults: you can configure it to resemble other similar
plugins, extend it with custom targeting methods, and even do arbitrary actions
with the selected target(s) - read on to dig deeper.

- [Design considerations in detail](#design-considerations-in-detail)
- [Background](#background)
- [Status](#status)
- [FAQ](#faq)
- [Getting started](#getting-started)
- [Usage](#usage)
- [Configuration](#configuration)
- [Extending Leap](#extending-leap)
- [Plugins using Leap](#plugins-using-leap)

## Design considerations in detail

### The ideal

Premise: jumping from point A to B on the screen should not be some [exciting
puzzle](https://www.vimgolf.com/), for which you should train yourself; it
should be a _non-issue_. An ideal keyboard-driven interface would impose almost
**no more cognitive burden than using a mouse**, without the constant
context-switching required by the latter.

That is, **you do not want to think about**

- **the context**: it should be enough to look at the target, and nothing else
  (↔ vanilla Vim motion combinations using relative line numbers and/or repeats)
- **the command**: we need one fundamental targeting method that can bring you
  anywhere: a "jetpack" instead of a "railway network" (↔ EasyMotion and its
  derivatives)
- **the steps**: the motion should be atomic (↔ Vim motion combos), and you
  should be able to type the sequence in one go, without having to make
  semi-conscious decisions on the fly ("Shall I start a `<C-g>` streak, or try
  one more input character?"), or instantly react to events (labels appearing).

All the while using **as few keystrokes as possible**, and getting distracted by
**as little incidental visual noise as possible**.

### How do we measure up?

It is obviously impossible to achieve all of the above at the same time, without
some trade-offs at least; but Leap comes pretty close, occupying a sweet spot in
the design space.

The one-step shift between perception and action - that is, ahead-of-time
labeling - cuts the Gordian knot: while the input sequence can be extended
dynamically, to scale to any number of targets (by adding new labeled groups you
can switch to), it still behaves as if it would be an already known pattern,
that you just have to type out. Leaping is like incremental search on some kind
of autopilot, where you know it in advance when to finish.

Fortunately, a 2-character search pattern - the shortest one with which we can
play this trick - is also long enough to sufficiently narrow down the matches in
the vast majority of cases. It is very rare that you should type more than 3
characters altogether to reach a given target.

### Auxiliary principles

- Optimize for the common case (not the pathological): a good example of this is
  the Sneak-like "one-character labels in multiple groups" approach (instead of
  using arbitrary-length labels), which can become awkward for, say, 200
  targets, but usually more comfortable, eliminates all kinds of edge cases and
  implementation problems, and allows for features like
  [multiselect](#extending-leap).

- [Sharpen the saw](http://vimcasts.org/blog/2012/08/on-sharpening-the-saw/):
  build on Vim's native interface, and aim for synergy as much as possible. The
  plugin supports macros, operators, dot-repeat (`.`), inclusive/exclusive
  toggle (`v`), multibyte text and
  [keymaps](http://vimdoc.sourceforge.net/htmldoc/mbyte.html#mbyte-keymap)
  (language mappings), autocommands via `User` events, among others, and intends
  to continuously improve in this respect.

- [Mechanisms instead of
  policies](https://cacm.acm.org/magazines/2018/11/232214-a-look-at-the-design-of-lua/fulltext)
  (or "be opinionated, but not stubborn"): aim for a small, maintainable core,
  with reasonable defaults; at the same time, keep the plugin flexible and
  future-proof via [extension points](#extending-leap).

## Background

Leap is a reboot of [Lightspeed](https://github.com/ggandor/lightspeed.nvim); a
streamlined but in many respects enhanced version of its ancestor. Compared to
Lightspeed, Leap:

- gets rid of some gimmicks with a low benefit/cost ratio (like Lightspeed's
  "shortcut" labels), but works the same way in the common case; all the really
  important features are there
- has a smaller and simpler visual footprint; it feels like using Sneak
- is more flexible and extensible; it can be used as an engine for selecting
  arbitrary targets, and performing arbitrary actions on them

## Status

The plugin is not fully stable yet, but don't let that stop you - the usage
basics are extremely unlikely to change. To follow breaking changes, subscribe
to the corresponding [issue](https://github.com/ggandor/leap.nvim/issues/18).

## FAQ

<details>
<summary>Bidirectional search</summary>

```lua
-- Beware that the trade-off in this mode is that you always have to
-- select a label, as there is no automatic jump to the first target (it
-- would be very confusing if the cursor would suddenly jump in the
-- opposite direction than your goal). Former vim-sneak users will know
-- how awesome a feature that is. I really suggest trying out the plugin
-- with the defaults for a while first.
-- An additional disadvantage is that operations cannot be dot-repeated
-- if the search is non-directional.

-- Now that you have carefully considered my wise advice above, I'll
-- tell you the simple trick: just initiate multi-window mode with the
-- current window as the only target.
require('leap').leap { target_windows = { vim.fn.win_getid() } }
```

</details>

<details>
<summary>Search in all windows</summary>

```lua
-- The same caveats as above about bidirectional search apply here.

require('leap').leap { target_windows = vim.tbl_filter(
  function (win) return vim.api.nvim_win_get_config(win).focusable end,
  vim.api.nvim_tabpage_list_wins(0)
)}
```
</details>

<details>
<summary>Enhanced f/t motions</summary>

Check flit.nvim, an extension plugin for Leap.

</details>

<details>
<summary>Linewise motions</summary>

See the "Extending Leap" section below for an example snippet.

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
vim.api.nvim_set_hl(0, 'LeapBackdrop', { link = 'Comment' })
```

</details>

<details>
<summary>How to live without `s`/`S`/`x`/`X`?</summary>

All of them have aliases or obvious equivalents:

- `s` = `cl`
- `S` = `cc`
- `v_s` = `v_c`
- `v_S` = `Vc` if not already in linewise mode (else = `v_c`)
- `v_x` = `v_d`
- `v_X` -> `vnoremap D X`, and use `$D` for vanilla `v_b_D` behaviour

</details>

<details>
<summary>I am too used to using `x` instead of `d` in Visual mode</summary>

```lua
-- Getting used to `d` shouldn't take long - after all, it is more comfortable
-- than `x`, and even has a better mnemonic.
-- If you still desperately want your old `x` back, then just delete these
-- mappings set by Leap:
vim.keymap.del({'x', 'o'}, 'x')
vim.keymap.del({'x', 'o'}, 'X')
-- To set alternative keys for "exclusive" selection:
vim.keymap.set({'x', 'o'}, <some-other-key>, '<Plug>(leap-forward-till)')
vim.keymap.set({'x', 'o'}, <some-other-key>, '<Plug>(leap-backward-till)')
```

</details>

<details>
<summary>Was the name inspired by Jef Raskin's Leap?</summary>

To paraphrase Steve Jobs, I wish it was, but it is a coincidence. "Leap" is just
another synonym for "jump", that happens to rhyme with Sneak. That said, in some
respects you can indeed think of leap.nvim as a spiritual successor to Raskin's
work, and thus the name as a little tribute to the great pioneer of interface
design, even though embracing the modal paradigm is a fundamental difference
in our approach.

</details>

## Getting started

### Requirements

* Neovim >= 0.7.0

### Dependencies

* For the moment, [repeat.vim](https://github.com/tpope/vim-repeat) is required
  for dot-repeats (`.`) to work as intended.

### Installation

Use your preferred plugin manager. No extra steps needed besides defining
keybindings - to use the default ones, put the following into your config:

`require('leap').add_default_mappings()` (init.lua)

`lua require('leap').add_default_mappings()` (init.vim)

## Usage

Without further ado, let's cut to the chase, and learn by doing.
([Permalink](https://github.com/neovim/neovim/blob/8215c05945054755b2c3cadae198894372dbfe0f/src/nvim/window.c#L1078)
to the file, if you want to follow along.)

The search is invoked with `s` in the forward direction, and `S` in the backward
direction. Let's target some word containing `ol`. After entering the letter
`o`, the plugin processes all character pairs starting with it, and from here
on, you have all the visual information you need to reach your specific target.

To reach an unlabeled match, just finish the pattern, i.e., type the second
character. (Note: the highlighting of unlabeled matches - green underlined on
the screenshots - is opt-in, turned on for clarity here.) For the rest, you also
need to type the label character that is displayed right next to the match.

![quick example 1](../media/quick_example_1.png?raw=true)

To continue with the example, type `l`.

If you aimed for the first match (in `oldwin->w_frame`), you are good to go,
just continue your work! The labels for the subsequent matches of `ol` remain
visible until the next keypress, but they are carefully chosen "safe" letters,
guaranteed to not interfere with your following editing command.

If you aimed for some other match, then type the label, for example `u`, and
move on to that.

![quick example 2](../media/quick_example_2.png?raw=true)

To show the last important feature, let's go back to the start position, and
target the struct member on the line `available = oldwin->w_frame->fr_height;`
near the bottom, using the pattern `fr`, by first pressing `s`, and then `f`:

![quick example 3](../media/quick_example_3.png?raw=true)

The blue labels indicate the "secondary" group of matches, where we start to
reuse the available labels for a given pair (`s`, `f`, `n`... again). You can
reach those by prefixing the label with `<space>`, that switches to the
subsequent match group. For example, to jump to the "blue" `j` target, you
should now press `r<space>j`.

In very rare cases, if the large number of matches cannot be covered even by two
label groups, you might need to press `<space>` multiple times, until you see
the target labeled, first with blue, and then, after one more `<space>`, green.
(Substitute "green" and "blue" with the actual colors in the current theme.)

### Cross-window motions

`gs` searches in all the other windows on the tab page. In this case, the
matches are sorted by their screen distance from the cursor, advancing in
concentric circles.

### Visual and Operator-pending mode

In these modes, there are two different pairs of directional motions available,
providing the necessary additional comfort and precision.

`s`/`S` are like their Normal-mode counterparts, except that `s` includes _the
whole match_ in the selection/operation (which might be considered the more
intuitive behaviour for these modes).

On the other hand, `x`/`X` are like `t`/`T` for `f`/`F` - they exclude the
matched pair:

```
abcd|                    |bcde
████e  ←  Sab    sde  →  █████
ab██e  ←  Xab    xde  →  ███de
```

Note that each of the forward motions are inclusive (`:h inclusive`), and the
`v` modifier (`:h o_v`) works as expected on them.

### Jumping to the last character on a line

A character at the end of a line can be targeted by pressing `<space>` after it.
(There is no special mechanism behind this: you can set aliases for the newline
character simply by defining a set in `opts.equivalence_classes` that contains
it.)

### Repeating the previous search

Pressing `<enter>` (`special_keys.repeat_search`) after invoking any of Leap's
motions sets the search pattern to the previous one.

### Traversal mode

After entering at least one input character, `<enter>`
(`special_keys.next_aot_match`) initiates "traversal" mode, moving on to the
next match on each keypress. `<tab>` (`special_keys.prev_match`) can revert the
previous jump(s) in case you accidentally overshoot your target.

`s|S ch1 ch2? <enter> (<enter>|<tab>)*`

#### Tips

- When repeating the previous search, you can immediately move on:
  `s<enter><enter>...`

- Accepting the first match after one input character is a useful shortcut in
  operator-pending mode (e.g. `dz{char}<enter>`).

- Traversal mode can be used as a substitute for normal-mode `f`/`t` motions.
  `s{char}<enter><enter>` is the same as `f{char};`, but works over multiple
  lines.

#### Notes

- If the safe label set is in use, the labels will remain available during the
  whole time.

- For cross-window search, traversal mode is not supported (since there's no
  direction to follow).

### Resolving highlighting conflicts in the first phase

If a directly reachable match covers a label, the match will get highlighted
(telling the user, "Label underneath!"), and the label will only be displayed
after the second input, that resolves the ambiguity. If a label gets positioned
over another label (this might occur before EOL or the window edge, when the
labels need to be shifted left), an "empty" label will be displayed until
entering the second input.

### Smart autojump

Leap automatically jumps to the first match if the remaining matches can be
covered by a limited set of "safe" target labels (keys you would not use right
after a jump), but stays in place, and switches to an extended, more comfortable
label set otherwise. For fine-tuning, see `:h leap-config`.

The rationale behind this is that the probability of the user aiming for the
very first target lessens with the number of targets; at the same time, the
probability of being able to reach the first target by other means (`www`, `f`,
etc.) increases. That is, staying in place in exchange for more comfortable
labels becomes a more and more acceptable trade-off.

Smart autojump gives the best of both worlds between Sneak (jumps
unconditionally, can only use a seriously limited label set) and Hop (labels
everything, always requires that one extra keystroke).

## Configuration

`setup` has no implicit side effects, it is just a convenience function for
changing the values in the configuration table (which can also be accessed
directly as `require('leap').opts`). There is no need to call it if you're
fine with the defaults. Also note that table values (like `special_keys`) are
not extended, but simply overwritten by the given ones, so in many cases, it
might be more straightforward to set `opts` directly.

```Lua
require('leap').setup {
  max_aot_targets = nil,
  highlight_unlabeled = false,
  max_highlighted_traversal_targets = 10,
  case_sensitive = false,
  -- Sets of characters that should match each other.
  -- Obvious candidates are braces and quotes ('([{', ')]}', '`"\'').
  equivalence_classes = { ' \t\r\n', },
  substitute_chars = {},
  -- Leaving the appropriate list empty effectively disables "smart" mode,
  -- and forces auto-jump to be on or off.
  safe_labels = {},
  labels = {},
  special_keys = {
    repeat_search  = '<enter>',
    next_aot_match = '<enter>',
    next_match     = {';', '<enter>'},
    prev_match     = {',', '<tab>'},
    next_group     = '<space>',
    prev_group     = '<tab>',
    multi_accept   = '<enter>',
    multi_revert   = '<backspace>',
  },
}
```

For details, see `:h leap-config`.

### Mappings

You can add the default mappings (listed in `:h leap-default-mappings`) by
calling `require('leap').add_default_mappings()`. Note that the function will
check for conflicts with any custom mappings created by you or other plugins,
and will not overwite them, unless explicitly told so (called with a `true`
argument).

To define alternative mappings, you can use the `<Plug>` keys listed in `:h
leap-custom-mappings`.

Note: To create custom motions, see [Extending Leap](#extending-leap) below.

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
-- Bidirectional search in the current window is just a specific case of the
-- multi-window mode.
require('leap').leap { target_windows = { vim.fn.win_getid() } }

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
local function leap_to_line()
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

<details>
<summary>Example: pick a window</summary>

```lua
function leap_to_window()
  target_windows = require('leap.util').get_enterable_windows()
  local targets = {}
  for _, win in ipairs(target_windows) do
    local wininfo = vim.fn.getwininfo(win)[1]
    local pos = { wininfo.topline, 1 }  -- top/left corner
    table.insert(targets, { pos = pos, wininfo = wininfo })
  end

  require('leap').leap {
    target_windows = target_windows,
    targets = targets,
    action = function (target)
      vim.api.nvim_set_current_win(target.wininfo.winid)
    end
  }
end
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

function paranormal(targets)
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
    action = paranormal,
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

## Plugins using Leap

- [flit.nvim](https://github.com/ggandor/flit.nvim) (enhanced f/t motions)
- [leap-ast.nvim](https://github.com/ggandor/leap-ast.nvim) (Tree-sitter nodes)

