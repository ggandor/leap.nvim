<img align="left" width="150" height="85" src="../media/kangaroo.png?raw=true">

# leap.nvim

Leap is a general-purpose motion plugin for Neovim, building and improving
primarily on [vim-sneak](https://github.com/justinmk/vim-sneak), with the
ultimate goal of establishing a new standard interface for moving around in the
visible area in Vim-like modal editors. It aims to be consistent, reliable,
needs zero configuration, and tries to get out of your way as much as possible.

![showcase](../media/showcase.gif?raw=true)

### How to use it (TL;DR)

Leap's default motions allow you to jump to any positions in the visible editor
area by entering a 2-character search pattern, and then potentially a label
character to pick your target from multiple matches, in a manner similar to
Sneak. The novel idea in Leap is its "clairvoyant" ability: you get a **live
preview** of the target labels - by mapping possible futures, Leap can show you
which key(s) you will need to press _before_ you actually need to do that.

- Initiate the search in the forward (`s`) or backward (`S`) direction, or in
  the other windows (`gs`).
- Start typing a 2-character pattern (`{c1}{c2}`).
- After typing the first character, you see "labels" appearing next to some of
  the `{c1}{?}` pairs. You cannot _use_ the labels yet.
- Enter `{c2}`. If the pair was not labeled, then voilà, you're already there.
  No need to be bothered by remaining labels - those are guaranteed "safe"
  letters -, just continue editing.
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
  is determined from the very beginning - just type out what you see.

- You _don't have to pause in the middle_: if typing at a moderate speed, at
  each step you already know what the immediate next keypress should be, and
  your mind can process the rest in the background.

### Supplemental features

Type

- `s{char}<space>` to jump to the end of a line.
- `s<space><space>` to jump to an empty line.
- `s{char}<enter>` to jump to the first `{char}{?}` pair right away.
- `s<enter>` to repeat the last search.
- `s<enter><enter>...` or `s{char}<enter><enter>...` to traverse through the
  matches.

You can also

- map e.g. `;` and `,` to repeat motions without explicitly invoking Leap,
  similar to the native `f`/`t` repeat (see [Configuration](#configuration)).
- search bidirectionally in the window, if you are okay with the trade-offs
  (see [FAQ](#faq)).

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

- **the command**: we need one fundamental targeting method that can bring you
  anywhere: a "jetpack" instead of a "railway network" (↔ EasyMotion and its
  derivatives)
- **the context**: it should be enough to look at the target, and nothing else
  (↔ vanilla Vim motion combinations using relative line numbers and/or
  repeats)
- **the steps**: the motion should be atomic (↔ Vim motion combos), and you
  should be able to type the sequence in one go, without having to make
  semi-conscious decisions on the fly (the ever-present dilemma when using
  `/`/`?`: "Shall I try one more input character, or start a `<C-g>` streak?"),
  or having to react to events (labels appearing on the screen).

All the while using **as few keystrokes as possible**, and getting distracted by
**as little incidental visual noise as possible**.

### How do we measure up?

It is obviously impossible to achieve all of the above at the same time, without
some trade-offs at least; but Leap comes pretty close, occupying a sweet spot in
the design space.

The **one-step shift between perception and action** cuts the Gordian knot:
while the input sequence can be scaled to any number of targets (by adding new
groups you can switch to), ahead-of-time labeling eliminates the surprise
factor: leaping is like doing incremental search with knowing in advance when
to finish.

Fortunately, a 2-character search pattern - the shortest one with which we can
play this trick - is also long enough to sufficiently narrow down the matches in
the vast majority of cases. It is very rare that you should type more than 3
characters altogether to reach a given target.

### Auxiliary principles

- Optimize for the common case, not the pathological: a good example of this is
  the Sneak-like "use strictly one-character labels, and switch between
  groups"-approach, which can become awkward for, say, 200 targets, but
  eliminates all kinds of edge cases and implementation problems, and allows
  for features like [multiselect](#extending-leap).

- [Sharpen the saw](http://vimcasts.org/blog/2012/08/on-sharpening-the-saw/):
  build on Vim's native interface, and aim for synergy as much as possible. The
  plugin supports macros, operators, dot-repeat (`.`), inclusive/exclusive
  toggle (`v`), multibyte text and
  [keymaps](http://vimdoc.sourceforge.net/htmldoc/mbyte.html#mbyte-keymap)
  (language mappings), autocommands via `User` events, among others, and intends
  to continuously improve in this respect.

- [Mechanisms instead of
  policies](https://cacm.acm.org/magazines/2018/11/232214-a-look-at-the-design-of-lua/fulltext):
  Complement the small and opinionated core by [extension
  points](#extending-leap), keeping the plugin flexible and future-proof.

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
<summary>Workaround for the duplicate cursor bug</summary>

Check
[#70](https://github.com/ggandor/leap.nvim/issues/70#issuecomment-1521177534),
but also [#143](https://github.com/ggandor/leap.nvim/pull/143) if you
experience any problems after it.

</details>


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

-- With that out of the way, I'll tell you the simple trick: just
-- initiate multi-window mode with the current window as the only
-- target.

vim.keymap.set(<modes>, <your-preferred-key>, function ()
  local current_window = vim.fn.win_getid()
  require('leap').leap { target_windows = { current_window } }
end)
```

</details>


<details>
<summary>Search in all windows</summary>

```lua
-- The same caveats as above about bidirectional search apply here.

vim.keymap.set('n', <your-preferred-key>, function ()
  local focusable_windows_on_tabpage = vim.tbl_filter(
    function (win) return vim.api.nvim_win_get_config(win).focusable end,
    vim.api.nvim_tabpage_list_wins(0)
  )
  require('leap').leap { target_windows = focusable_windows_on_tabpage }
end)
```
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
<summary>How to live without `s`/`S`/`x`/`X`?</summary>

All of them have aliases or obvious equivalents:

- `s` = `cl` (or `xi`)
- `S` = `cc`
- `v_s` = `v_c`
- `v_S` = `Vc`, unless already in linewise mode (then = `v_c`)
- `v_x` = `v_d`
- `v_X` -> `vnoremap D X`, and use `$D` for vanilla `v_b_D` behaviour

</details>


<details>
<summary>I am too used to using `x` instead of `d` in Visual mode</summary>

```lua
-- Getting used to `d` shouldn't take long - after all, it is more comfortable
-- than `x`. Also Visual `x`/`d` are the counterparts of Operator-pending `d`
-- (not Normal `x`), so `d` is a much more obvious default choice among the two
-- redundant alternatives.
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
<summary>Working with non-English text</summary>

Check out `opts.equivalence_classes`. For example, you can group accented
vowels together: `{ 'aá', 'eé', 'ií', ... }`.
</details>


<details>
<summary>Was the name inspired by Jef Raskin's Leap?</summary>

To paraphrase Steve Jobs, I wish it were, but it is a coincidence. "Leap" is
just another synonym for "jump", that happens to rhyme with Sneak. That said, in
some respects you can indeed think of leap.nvim as a spiritual successor to
Raskin's work, and thus the name as a little tribute to the great pioneer of
interface design, even though embracing the modal paradigm is a fundamental
difference in our approach.

</details>

## Getting started

### Requirements

* Neovim >= 0.7.0 stable, or latest nightly

### Dependencies

* [repeat.vim](https://github.com/tpope/vim-repeat), for dot-repeats (`.`) to
  work as intended

### Installation

Use your preferred method or plugin manager. No extra steps needed besides
defining keybindings - to use the default ones, put the following into your
config:

`require('leap').add_default_mappings()` (init.lua)

`lua require('leap').add_default_mappings()` (init.vim)

Note that the above function will check for conflicts with any custom mappings
created by you or other plugins, and will _not_ overwrite them, unless
explicitly told so (called with a `true` argument).

### Lazy loading

...is all the rage now, but doing it manually or via some plugin manager is
completely redundant, as Leap takes care of it itself. Nothing unnecessary is
loaded until you actually trigger a motion.

## Usage

[Permalink](https://github.com/neovim/neovim/blob/8215c05945054755b2c3cadae198894372dbfe0f/src/nvim/window.c#L1078)
to the example file, if you want to follow along.

The search is invoked with `s` in the forward direction, and `S` in the backward
direction. Let's target some word containing `ol`. After entering the letter
`o`, the plugin processes all character pairs starting with it, and from here
on, you have all the visual information you need to reach your specific target.

![quick example 1](../media/quick_example_1.png?raw=true)

To reach an unlabeled match, just finish the pattern, i.e., type the second
character. For the rest, you also need to type the label character that is
displayed right next to the match. (Note: the highlighting of unlabeled matches
\- green underlined on the screenshots - is opt-in, turned on for clarity here.)

To continue with the example, type `l`.

If you aimed for the first match (in `oldwin->w_frame`), you are good to go,
just continue your work! The labels for the subsequent matches of `ol` remain
visible until the next keypress, but they are carefully chosen "safe" letters,
guaranteed to not interfere with your following editing command.

![quick example 2](../media/quick_example_2.png?raw=true)

If you aimed for some other match, then type the label, for example `u`, and
move on to that.

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

### Special cases and additional features

#### Jumping to the end of the line and to empty lines

A character at the end of a line can be targeted by pressing `<space>` after it.
There is no special mechanism behind this: you can set aliases for the newline
character simply by defining a set in `opts.equivalence_classes` that contains
it.

Empty lines can also be targeted, by pressing the newline alias twice
(`<space><space>` by default). This latter is a slightly more magical feature,
but fulfills the principle that any visible position you can move to with the
cursor should be reachable by Leap too.

#### Visual and Operator-pending mode

Visual/Operator-pending `s`/`S` are like their Normal-mode counterparts, except
that `s` includes _the whole match_ in the selection/operation (which might be
considered the more intuitive behaviour for these modes).

In these modes, there is also an additional pair of directional motions
available, to provide more comfort and precision. `x`/`X` are to `s`/`S` as
`t`/`T` are to `f`/`F` - they exclude the matched pair:

```
abcd|                    |bcde
████e  ←  Sab    sde  →  █████
ab██e  ←  Xab    xde  →  ███de
```

Note that each of the forward motions are inclusive (`:h inclusive`), and the
`v` modifier (`:h o_v`) works as expected on them.

#### Targeting consecutive repeating characters 

An `aaa...` sequence will be matched at one position only (by default, at the
beginning). In Visual and Operator-pending mode, however, `s` and `X` will
match at the _end_ instead (so that the sequence behaves as a chunk, and either
the whole or none of it will be selected).

#### Cross-window motions

In this case, the matches are sorted by their screen distance from the cursor,
advancing in concentric circles. The one default motion that works this way is
`gs` (`<Plug>(leap-from-window)`), searching in all other windows on the tab
page.

To create custom motions like this, e.g. bidirectional search in the current
window, see [Extending Leap](#extending-leap).

#### Repeat and traversal

`<enter>` (`special_keys.next_target`) is a very special key: at any stage, it
initiates "traversal" mode, moving on to the next match on each subsequent
keypress. If you press it right after invoking a Leap motion (e.g. `s<enter>`),
it uses the previous search pattern. In case you accidentally overshoot your
target, `<tab>` (`special_keys.prev_target`) can revert the previous jump(s).
Note that if the safe label set is in use, the labels will remain available the
whole time!

In case of cross-window search, you cannot traverse (since there's no direction
to follow), but the search can be repeated, and you can also accept the first
(presumably only) match with `<enter>`, even after one input.

##### Tips

- Traversal mode can be used as a substitute for normal-mode `f`/`t` motions.
  `s{char}<enter><enter>` is the same as `f{char};`, but works over multiple
  lines.

- Accepting the first match after one input character is a useful shortcut in
  operator-pending mode (e.g. `ds{char}<enter>`).

#### Smart autojump

Leap automatically jumps to the first match if the remaining matches can be
covered by a limited set of "safe" target labels (keys you would not use right
after a jump), but stays in place, and switches to an extended label set
otherwise. (The trade-off becomes more and more acceptable as the number of
targets increases, since the probability of aiming for the very first target
becomes less and less.)

For fine-tuning, see `:h leap-config` (`labels` and `safe_labels`).

#### Concealed labels

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

## Configuration

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
safe_labels = { 's', 'f', 'n', 'u', 't', . . . }
labels = { 's', 'f', 'n', 'j', 'k', . . . }
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
`<Plug>` keys listed at `:h leap-custom-mappings`.

There is also a convenience function that helps you set repeat keys (it is
not trivial, you would need to define autocommands for that):

```lua
require('leap').add_repeat_mappings(';', ',', {
  -- False by default. If set to true, the keys will work like the
  -- native semicolon/comma, i.e., forward/backward is understood in
  -- relation to the last motion.
  relative_directions = true,
  -- By default, all modes are included.
  modes = {'n', 'x', 'o'},
})
```

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

-- For maximum comfort, make sure to set the mappings in a way that
-- forces linewise selection:
vim.keymap.set('x', '\\', function ()
  -- Do not exit from V if already in it (pressing v/V/<C-v>
  -- again exits the corresponding Visual mode).
  return (vim.fn.mode(1) == "V" and "" or "V") .. "<cmd>lua leap_linewise()<cr>"
end, { expr = true })
vim.keymap.set('o', '\\', "V<cmd>lua leap_linewise()<cr>")
```
</details>

`action`: A Lua function that will be executed by Leap in place of the jump. (You
could obviously implement some custom jump logic here too.) Its only argument is
either a target, or a list of targets (in multiselect mode).

<details>
<summary>Example: pick a window</summary>

```lua
function leap_to_window()
  local target_windows = require('leap.util').get_enterable_windows()
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

- [leap-spooky.nvim](https://github.com/ggandor/leap-spooky.nvim) (remote
  operations on text objects)
- [flit.nvim](https://github.com/ggandor/flit.nvim) (enhanced f/t motions)
- [leap-ast.nvim](https://github.com/ggandor/leap-ast.nvim) (Tree-sitter nodes)

