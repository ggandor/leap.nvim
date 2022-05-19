<img align="left" width="150" height="85" src="../media/kangaroo.png?raw=true">

# leap.nvim

Leap is a general-purpose motion plugin for [Neovim](https://neovim.io/), that
unites the strengths and aims of various similar plugins like
[Sneak](https://github.com/justinmk/vim-sneak) (minimalism, speed, convenience),
[EasyMotion](https://github.com/easymotion/vim-easymotion)/[Hop](https://github.com/phaazon/hop.nvim)
(scaling well for lots of targets), and
[Pounce](https://github.com/rlane/pounce.nvim) (incremental search + dynamic
feedback). It is essentially a streamlined version of
[Lightspeed](https://github.com/ggandor/lightspeed.nvim), with a focus on
simplicity, sane defaults, and maintainability. Leap aims to be a common
denominator, its goal being to establish a new standard interface for
moving around in the visible editor area in Vim-like editors.

Compared to Lightspeed, Leap

* is just as efficient in the common case, and almost as efficient generally;
  all the really important features are there
* has less complexity and configuration options
* has a smaller and simpler visual footprint; it feels like using Sneak

## Status

Leap is not stable yet - expect breaking changes in the API from time to time.

## Getting started

### Requirements

* Neovim >= 0.7.0

Leap follows the actual latest nightly release - always update Neovim before
submitting issues.

### Dependencies

* For the moment, [repeat.vim](https://github.com/tpope/vim-repeat) is required
  for the dot-repeat functionality to work as intended.

### Installation

Use your preferred plugin manager. No extra steps needed, besides optionally
setting the default keymaps:

`lua require('leap').set_default_keymaps()`

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
after one more `<space>`, green.

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

In Operator-pending mode, there are two different (pairs of) motions available,
providing the necessary additional comfort and precision, since in that case we
are targeting exact positions, and can only aim once, without the means of easy
correction.

`z`/`Z` are the equivalents of Normal/Visual `s`/`S`, and they follow the
semantics of `/` and `?` in terms of cursor placement and inclusive/exclusive
operational behaviour, including forced motion types (`:h forced-motion`).

The mnemonic for **X-mode** could be **extend/exclude** (corresponding to
`x`/`X`). It provides missing variants for the two directions:

```
ab···|                    |···ab
█████·  ←  Zab    zab  →  ████ab
ab███·  ←  Xab    xab  →  ██████
```

As you can see from the figure, `x` goes to the end of the match, including it
in the operation, while `X` stops just before - in an absolute sense, after -
the end of the match (the equivalent of `T` for Leap motions). In simpler terms:
in X-mode, the relevant edge of the operated area gets an offset of +2.

### Jumping to the last character on a line

A character at the end of a line can be targeted by pressing `<space>`
(`special_keys.eol`) after it.

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

```Lua
require('leap').setup {
  case_insensitive = true,
  -- Leaving the appropriate list empty effectively disables "smart" mode,
  -- and forces auto-jump to be on or off.
  safe_labels = { . . . },
  labels = { . . . },
  -- These keys are captured directly by the plugin at runtime.
  special_keys = {
    repeat_search = '<enter>',
    next_match    = '<enter>',
    prev_match    = '<tab>',
    next_group    = '<space>',
    prev_group    = '<tab>',
    eol           = '<space>',
  },
}
```

For details, see `:h leap-config`.

### Keymaps

You can set the defaults keymaps (`:h leap-default-keymaps`) by calling
`require('leap').set_default_keymaps()`. Note that the function will check for
conflicts with any custom mappings created by you or other plugins, and will not
overwite them, unless explicitly told so (called with a `true` argument).

To set alternative keymaps, you can use the `<Plug>` keys listed in `:h
leap-custom-keymaps`.

### Search mode tweaks (bidirectional and all-windows search)

For further customization you can call the `leap` function directly. The
`target-windows` argument allows you to pass in a list of window ID-s (`:h
winid`).

```lua
-- Searching in all windows (including the current one) on the tab page:
function leap_all_windows()
  require'leap'.leap { ['target-windows'] = vim.api.nvim_tabpage_list_wins(0) }
end

-- Bidirectional search in the current window is just a specific case of the
-- multi-window mode - set `target-windows` to a table containing the current
-- window as the only element:
function leap_bidirectional()
  require'leap'.leap { ['target-windows'] = {vim.api.nvim_get_current_win()} }
end

-- Map them to your preferred key, like:
vim.keymap.set('n', 's', leap_all_windows, { silent = true })
```

### User events

Leap triggers `User` events on entering/exiting (with patterns `LeapEnter` and
`LeapLeave`), so that you can set up autocommands, e.g. to change the values of
some editor options while the plugin is active (`:h leap-events`).

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

