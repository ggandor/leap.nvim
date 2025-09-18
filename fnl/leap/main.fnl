; Imports & aliases ///1

(local hl (require "leap.highlight"))
(local opts (require "leap.opts"))

(local {: set-beacons
        : resolve-conflicts
        : light-up-beacons}
        (require "leap.beacons"))

(local {: inc
        : dec
        : clamp
        : echo
        : char-to-search-pattern
        : get-representative-char
        : get-char
        : get-char-keymapped}
       (require "leap.util"))

(local api vim.api)
(local empty? vim.tbl_isempty)
(local map vim.tbl_map)
(local {: abs : ceil : floor : min} math)


; Fennel utils ///1

(macro when-not [cond ...]
  `(when (not ,cond) ,...))


; Utils ///1

(fn handle-interrupted-change-op! []
  "Return to Normal mode and restore the cursor position after an
interrupted change operation."
  (api.nvim_feedkeys
    (vim.keycode
      (.. "<C-\\><C-N>"  ; :h CTRL-\_CTRL-N
          (if (> (vim.fn.col ".") 1) "<RIGHT>" "")))
    :n
    true))


; repeat.vim support
; (see the docs in the script:
; https://github.com/tpope/vim-repeat/blob/master/autoload/repeat.vim)
(fn set-dot-repeat* []
  ; Note: We're not checking here whether the operation should be
  ; repeated (see `set-dot-repeat` in `leap()`).
  (let [op vim.v.operator
        force (string.sub (vim.fn.mode true) 3)
        cmd (vim.keycode "<cmd>lua require'leap'.leap { dot_repeat = true }<cr>")
        ; We cannot getreg('.') at this point, since the change has not
        ; happened yet - therefore the below hack (thx Sneak).
        change (when (= op :c) (vim.keycode "<c-r>.<esc>"))
        seq (.. op force cmd (or change ""))]
    ; Using pcall, since vim-repeat might not be installed.
    ; Use the same register for the repeated operation.
    (pcall vim.fn.repeat#setreg seq vim.v.register)
    ; Note: we're feeding count inside the seq itself.
    (pcall vim.fn.repeat#set seq -1)))


; Return a char->equivalence-class lookup table (the relevant one for us).
(fn to-membership-lookup [eqv-classes]
  (let [res {}]
    (each [_ cl (ipairs eqv-classes)]
      ; Do not use `vim.split`, it doesn't handle multibyte chars.
      (let [cl* (if (= (type cl) :string) (vim.fn.split cl "\\zs") cl)]
        (each [_ ch (ipairs cl*)]
          (set (. res ch) cl*))))
    res))


; Processing targets ///1

; Might be skipped, if two-step processing is disabled.

(fn populate-sublists [targets]
  "Populate a sub-table in `targets` containing lists that allow for
easy iteration through each subset of targets with a given successor
char separately.

  ab  ac  ab  ab  ac  ac  ad  ac
{ T1, T2, T3, T4, T5, T6, T7, T8 }
-->
{
  T1, T2, T3, T4, T5, T6, T7, T8,
  sublists = {
    ['b'] = { T1, T3, T4 },
    ['c'] = { T2, T5, T6, T8 },
    ['d'] = { T7 }
  },
}
"
  ; NOTE: If preview (two-step processing) is enabled, for any kind of
  ; input mapping (case-insensitivity, character classes, etc.) we need
  ; to tweak things in two different places:
  ;   1. For the first input, we modify the search pattern itself (see
  ;   `prepare-pattern`).
  ;   2. For the second input, we play with the sublist keys (here).

  ; Setting a metatable to handle case insensitivity and equivalence
  ; classes (in both cases: multiple keys -> one value).
  ; If `ch` is not found, try to get a sublist belonging to some common
  ; key: the equivalence class that `ch` belongs to (if there is one),
  ; or, if case insensivity is set, the lowercased verison of `ch`.
  ; (And in the above cases, `ch` will not be found, since we also
  ; redirect to the common keys when inserting a new sublist.)
  (set targets.sublists
       (setmetatable {}
         {:__index    (fn [self ch]
                        (rawget self (get-representative-char ch)))
          :__newindex (fn [self ch sublist]
                        (rawset self (get-representative-char ch) sublist))}))
  ; Filling the sublists.
  (each [_ {:chars [_ ch2] &as target} (ipairs targets)]
    (when-not (. targets.sublists ch2)
      (set (. targets.sublists ch2) []))
    (table.insert (. targets.sublists ch2) target)))


; `targets` might be a sublist of an original target list from here on.

(local prepare-labeled-targets
  (do
    ; Problem:
    ; We are autojumping to some position in window A, but our chosen
    ; labeled target happens to be in window B - in that case we do not
    ; actually want to reposition the cursor in window A. Restoring it
    ; afterwards would be overcomplicated, not to mention that the jump
    ; itself is disorienting in the first place, especially an A->B->C
    ; version (autojumping to B from A, before moving on to C).
    (fn all-in-the-same-window? [targets]
      (var same-win? true)
      (local win (. targets 1 :wininfo :winid))
      (each [_ target (ipairs targets) &until (= same-win? false)]
        (when (not= target.wininfo.winid win)
          (set same-win? false)))
      same-win?)

    ; Problem:
    ;     xy   target #1
    ;   xyL    target #2 (labeled)
    ;     ^    auto-jump would move the cursor here (covering the label)
    ;
    ; Note: The situation implies backward search, and may arise in
    ; phase two, when only the chosen sublist remained.
    ;
    ; Caveat: this case in fact depends on the label position, for
    ; which the `beacons` module is responsible (e.g. the label is on
    ; top of the match when repeating), but we're not considering
    ; that, and just err on the safe side instead of complicating the
    ; code.
    (fn first-target-covers-label-of-second? [targets]
      (case targets
        [{:pos [l1 c1]} {:pos [l2 c2] :chars [char1 char2]}]
        (and (= l1 l2) (= c1 (+ c2 (char1:len) (char2:len))))))

    (fn set-autojump [targets]
      (when-not (empty? opts.safe_labels)
        (set targets.autojump?
             (or (empty? opts.labels)                                       ; forced
                 (>= (length opts.safe_labels) (dec (length targets)))))))  ; smart

    (fn attach-label-set [targets]
      (set targets.label-set (if (empty? opts.labels) opts.safe_labels
                                 (empty? opts.safe_labels) opts.labels
                                 targets.autojump? opts.safe_labels
                                 opts.labels)))

    (fn set-labels [targets]
      (when-not (and (= (length targets) 1) targets.autojump?)
        (local {: autojump? : label-set} targets)
        (local |label-set| (length label-set))
        (each [i* target (ipairs targets)]
          ; Skip labeling the first target if autojump is set.
          (local i (if autojump? (dec i*) i*))
          (when (>= i 1)
            (case (% i |label-set|)
              0 (do
                  (set target.label (. label-set |label-set|))
                  (set target.group (floor (/ i |label-set|))))
              n (do
                  (set target.label (. label-set n))
                  (set target.group (inc (floor (/ i |label-set|))))))))))

    (fn [targets force-noautojump? multi-window-search?]
      "Set the following attributes for `targets`:

      `autojump?`: A flag indicating whether we should autojump to the
                   first target, without having to select a label.
      `label-set`: a field referencing the label set to be used for
                   `targets` (safe or unsafe). Note that there is no
                   one-to-one correspondence between the `autojump?`
                   flag and this field. No-autojump might be forced
                   implicitly, regardless of using safe labels.

      Set the following attributes for each individual target:

      `label`: Label characters are assigned by using the given
               `label-set` repeated indefinitely. Note that this is a
               once and for all fixed attribute - whether and how the
               labels should actually be displayed depends on other
               parts of the code.
      `group`: Number of the label group (also a fixed attribute - the
               actual state is followed in `st.group-offset` in
               `leap`)."
      (when-not (or force-noautojump?
                    (and multi-window-search?
                         (not (all-in-the-same-window? targets)))
                    (first-target-covers-label-of-second? targets))
        (set-autojump targets))
      (attach-label-set targets)
      (set-labels targets))))


; Main ///1

; State that is persisted between invocations.
(local state {:repeat {:in1 nil
                       :in2 nil
                       :pattern nil
                       ; For when wanting to repeat in relative direction
                       ; (for "outside" use only).
                       :backward nil
                       :inclusive_op nil
                       :offset nil
                       :inputlen nil
                       :opts nil}
              :dot_repeat {:targets nil
                           :pattern nil
                           :in1 nil
                           :in2 nil
                           :target_idx nil
                           :backward nil
                           :inclusive_op nil
                           :offset nil
                           :inputlen nil
                           :opts nil}

              ; We also use this table to reach the argument table
              ; passed to `leap()` in autocommands (using event data
              ; would be cleaner, but it is far too problematic [at the
              ; moment at least], it cannot handle tables with mixed
              ; keys, metatables, function values, etc.).
              :args nil})


(fn leap [kwargs]
  "Entry point for Leap motions."
  (local {:repeat invoked-repeat?
          :dot_repeat invoked-dot-repeat?
          :target_windows target-windows
          :opts user-given-opts
          :targets user-given-targets
          :action user-given-action
          :traversal action-can-traverse?}
         kwargs)
  (local {:backward backward?}
         (if invoked-dot-repeat? state.dot_repeat
             kwargs))
  (local {:inclusive_op inclusive-op?
          : offset
          : inputlen
          :pattern user-given-pattern}
         (if invoked-dot-repeat? state.dot_repeat
             invoked-repeat? state.repeat
             kwargs))

  (set state.args kwargs)

  ; `opts` hierarchy: current > saved-for-repeat > default.
  ; (We might want to give specific arguments exclusively for repeats,
  ; see e.g. `user.set-repeat-keys`.)
  (local opts-current-call
    (if user-given-opts
        (if invoked-repeat? (vim.tbl_deep_extend :keep
                              user-given-opts (or state.repeat.opts {}))
            invoked-dot-repeat? (vim.tbl_deep_extend :keep
                                  user-given-opts (or state.dot-repeat.opts {}))
            user-given-opts)
        {}))

  ; Do this before accessing `opts`.
  ; From here on, the metatable of `opts` manages dispatch,
  ; instead of merging here.
  (set opts.current_call opts-current-call)

  (set opts.current_call.eqv_class_of
       (-?> opts.current_call.equivalence_classes
            to-membership-lookup
            ; Prevent merging with the defaults, as this is derived
            ; programmatically from a list-like option (see opts.fnl).
            (setmetatable {:merge false})))
  ; Force the label lists into tables.
  (each [_ t (ipairs [:default :current_call])]
    (each [_ k (ipairs [:labels :safe_labels])]
      (when (= (type (. opts t k)) :string)
        (set (. opts t k) (vim.fn.split (. opts t k) "\\zs")))))

  (local directional? (not target-windows))
  (local no-labels-to-use? (and (empty? opts.labels)
                                (empty? opts.safe_labels)))

  (when (and (not directional?) no-labels-to-use?)
    (echo "no labels to use")
    (lua :return))
  (when (and target-windows (empty? target-windows))
    (echo "no targetable windows")
    (lua :return))

  (local ?target-windows target-windows)

  (local multi-window-search? (and ?target-windows
                                   (> (length ?target-windows) 1)))

  (local curr-win (api.nvim_get_current_win))
  (local hl-affected-windows (or ?target-windows [curr-win]))

  ; We need to save the mode here, because the `:normal` command in
  ; `jump.jump-to!` can change the state. See vim/vim#9332.
  (local mode (. (api.nvim_get_mode) :mode))
  (local op-mode? (mode:match :o))
  (local change-op? (and op-mode? (= vim.v.operator :c)))

  (local count (if (not directional?) nil
                   (= vim.v.count 0) (if (and op-mode? no-labels-to-use?) 1 nil)
                   vim.v.count))

  (local keyboard-input? (not (or invoked-repeat?
                                  invoked-dot-repeat?
                                  (= (type user-given-pattern) :string)
                                  user-given-targets)))

  (local inputlen (if inputlen inputlen
                      keyboard-input? 2
                      0))

  ; Force the values into a table, and translate keycodes.
  ; Using a metatable instead of deepcopy, in case one would modify the
  ; entries on `LeapEnter` (or even later).
  (local keys (setmetatable {}
                {:__index (fn [_ k]
                            (case (. opts.keys k)
                              v (map vim.keycode
                                     (if (= (type v) :string) [v] v))))}))
  ; The first key on a `keys` list is considered "safe" (not to be used
  ; as search input).
  (local contains? vim.list_contains)
  (local contains-safe? (fn [t v] (= (. t 1) v)))

  ; Ephemeral state (of the current call) that is not interesting for
  ; the outside world.
  (local st {; Multi-phase processing (show beacons ahead of time,
             ; right after the first input)?
             :phase (when (and keyboard-input?
                               (= inputlen 2)
                               (not no-labels-to-use?))
                      1)
             ; When repeating a `{char}<enter>` search (started to
             ; traverse after the first input).
             :repeating-shortcut? false
             ; For traversal mode.
             :curr-idx 0
             ; Currently selected label group, 0-indexed
             ; (`target.group` starts at 1).
             :group-offset 0
             ; For getting keymapped input.
             :prompt nil
             :errmsg nil})

  (fn exec-user-autocmds [pattern]
    (api.nvim_exec_autocmds "User" {: pattern :modeline false}))

  ; Exit macros

  (fn exit* []
    (hl:cleanup hl-affected-windows)
    (exec-user-autocmds :LeapLeave))

  ; Be sure not to call this twice accidentally,
  ; `handle-interrupted-change-op!` moves the cursor!
  (fn exit-early* []
    (when change-op? (handle-interrupted-change-op!))
    (when st.errmsg (echo st.errmsg))
    (exit*))

  ; See also `exit-with-action-on` later.
  (macro exit [] `(do (exit*) (lua :return)))
  (macro exit-early [] `(do (exit-early*) (lua :return)))

  ; Helper functions ///

  ; Misc. helpers

  (fn with-highlight-chores [callback]
    (hl:cleanup hl-affected-windows)
    (when-not count
      (hl:apply-backdrop backward? ?target-windows))
    (when callback (callback))
    (vim.cmd :redraw))

  (fn can-traverse? [targets]
    (or action-can-traverse?
        (and directional?
             (not (or count op-mode? user-given-action))
             (>= (length targets) 2))))

  ; When traversing without labels, keep highlighting the same one group
  ; of targets, and do not shift until reaching the end of the group - it
  ; is less disorienting if the "snake" does not move continuously, on
  ; every jump.
  (fn get-number-of-highlighted-traversal-targets []
    (case opts.max_highlighted_traversal_targets
      group-size
      ; Assumption: being here means we are after an autojump, and
      ; started highlighting from the 2nd target (no `count`).
      ; Thus, we can use `st.curr-idx` as the reference, instead of some
      ; separate counter (but only because of the above).
      (let [consumed (% (dec st.curr-idx) group-size)
            remaining (- group-size consumed)]
        ; Switch just before the whole group gets eaten up.
        (if (= remaining 1) (inc group-size)
            (= remaining 0) group-size
            remaining))))

  (fn get-highlighted-idx-range [targets use-no-labels?]
    (if (and use-no-labels? (= opts.max_highlighted_traversal_targets 0))
        (values 0 -1)  ; empty range
        (let [start (inc st.curr-idx)
              end (when use-no-labels?
                    (case (get-number-of-highlighted-traversal-targets)
                      n (min (+ (dec start) n) (length targets))))]
          (values start end))))

  (fn get-target-with-active-label [targets input]
    (var target* nil)
    (var idx* nil)
    (var break? false)
    (each [idx target (ipairs targets) &until (or target* break?)]
      (when target.label
        (local relative-group (- target.group st.group-offset))
        (if (> relative-group 1) (set break? true)  ; beyond the active group
            (= relative-group 1) (when (= target.label input)
                                   (set target* target)
                                   (set idx* idx)))))
    (values target* idx*))

  ; Get inputs

  (fn get-repeat-input []
    (if state.repeat.in1
        (if (= inputlen 1) state.repeat.in1
            (= inputlen 2) (do (when-not state.repeat.in2
                                 (set st.repeating-shortcut? true))
                               (values state.repeat.in1 state.repeat.in2)))
        (set st.errmsg "no previous search")))

  (fn get-first-pattern-input []
    (with-highlight-chores nil)
    (case (get-char-keymapped st.prompt)
      ; Here we can handle any other modifier key as "zeroth" input,
      ; if the need arises.
      (in1 ?prompt) (if (contains-safe? keys.next_target in1)
                        (do (set st.phase nil)
                            (get-repeat-input))
                        (do (set st.prompt ?prompt)
                            in1))))

  (fn get-second-pattern-input [targets]
    ; Note: `count` does _not_ automatically disable two-phase
    ; processing altogether, as we might want to do a char<enter>
    ; shortcut, but it implies not needing to show beacons.
    (when-not count
      (with-highlight-chores #(light-up-beacons targets)))
    (get-char-keymapped st.prompt))

  (fn get-full-pattern-input []
    (case (get-first-pattern-input)
      (in1 in2) (values in1 in2)
      (in1 nil) (if (= inputlen 1)
                    in1
                    (case (get-char-keymapped st.prompt)
                      in2 (values in1 in2)))))

  ; Get targets

  ; NOTE: If preview (two-step processing) is enabled, for any kind of
  ; input mapping (case-insensitivity, character classes, etc.) we need
  ; to tweak things in two different places:
  ;   1. For the first input, we modify the search pattern itself (here).
  ;   2. For the second input, we play with the sublist keys (see
  ;   `populate-sublists`).
  (fn prepare-pattern [in1 ?in2]
    "Transform user input to the appropriate search pattern."
    (let [any-char "\\_."  ; :help /\_.
          pat1 (char-to-search-pattern in1)
          pat2 (if (= inputlen 1) ""
                   ?in2 (char-to-search-pattern ?in2)
                   any-char)
          ; If `\n\n` is a possible sequence to appear, add `|\n` as a
          ; separate branch after the whole pattern, to make our
          ; convenience feature - targeting EOL positions by typing the
          ; newline alias twice - work.
          ; This hack is always necessary when we already have the full
          ; pattern (like repeating the previous search), but also for
          ; two-step processing, in the special case of targeting EOF.
          ; (Normally, `get-targets` would take care of this situation,
          ; but the pattern `\n\_.` does not match `\n$` if it's on the
          ; last line of the file.)
          ; NOTE: This should be checked on the expanded patterns (once
          ; equivalence classes have been taken into account).
          |<nl> (if (and (pat1:match "\\n")
                         (or (pat2:match "\\n")
                             (= pat2 any-char)))
                    "\\|\\n"
                    "")
          ic (if opts.case_sensitive "\\C" "\\c")]
      (.. "\\V" ic pat1 pat2 |<nl>)))

  (fn get-targets [pattern in1 ?in2]
    (let [errmsg (if in1 (.. "not found: " in1 (or ?in2 "")) "no targets")
          search (require :leap.search)
          kwargs {: backward? : offset : op-mode? : inputlen
                  :target-windows ?target-windows}
          targets (search.get-targets pattern kwargs)]
      (or targets (set st.errmsg errmsg))))

  (fn get-user-given-targets [targets]
    (local default-errmsg "no targets")
    (local (targets* errmsg) (if (= (type targets) :function) (targets) targets))
    (if (not targets*)
        (set st.errmsg (or errmsg default-errmsg))

        (= (length targets*) 0)
        (set st.errmsg default-errmsg)

        (do
          ; Fill wininfo-s when not provided.
          (when-not (. targets* 1 :wininfo)
            (local wininfo (. (vim.fn.getwininfo curr-win) 1))
            (each [_ t (ipairs targets*)]
              (set t.wininfo wininfo)))
          targets*)))

  ; Sets `autojump` and `label_set` attributes for the target list, plus
  ; `label` and `group` attributes for each individual target.
  (fn prepare-labeled-targets* [targets]
    (local force-noautojump? (and (not action-can-traverse?)
                                  (or
                                    ; No jump, doing sg else.
                                    user-given-action
                                    ; Should be able to select our target.
                                    (and op-mode? (> (length targets) 1)))))
    (prepare-labeled-targets targets force-noautojump? multi-window-search?))

  ; Repeat

  (local repeat-state {:offset kwargs.offset
                       :backward kwargs.backward
                       :inclusive_op kwargs.inclusive_op
                       :pattern kwargs.pattern
                       :inputlen inputlen
                       :opts opts-current-call})

  (fn update-repeat-state [in1 in2]
    (when (and (not invoked-repeat?)
               (or keyboard-input? user-given-pattern))
      (set state.repeat (vim.tbl_extend :error
                          repeat-state
                          {:in1 (and keyboard-input? in1)
                           :in2 (and keyboard-input? in2)}))))


  (fn set-dot-repeat [in1 in2 target_idx]
    (local dot-repeatable-op? (and op-mode?
                                   (or (vim.o.cpo:match "y")
                                       (not= vim.v.operator "y"))))

    (local dot-repeatable-call? (and dot-repeatable-op?
                                     (not invoked-dot-repeat?)
                                     (not= (type user-given-targets) :table)))

    (fn update-dot-repeat-state []
      (set state.dot_repeat (vim.tbl_extend :error
                              repeat-state
                              {: target_idx
                               :targets user-given-targets
                               :in1 (and keyboard-input? in1)
                               :in2 (and keyboard-input? in2)}))
      (when (not directional?)
        (set state.dot_repeat.backward (< target_idx 0))
        (set state.dot_repeat.target_idx (abs target_idx))))

    (when dot-repeatable-call?
      (update-dot-repeat-state)
      (set-dot-repeat*)))


  (fn normalize-indexes-for-dot-repeat [targets]
    "On a filtered sublist, update the directional indexes of the
    targets, like:
    -7 -4 -2   1  3  7
    -->
    -3 -2 -1   1  2  3
    "
    (local bwd [])
    (local fwd [])
    (each [_ t (ipairs targets)]
      (if (< t.idx 0)
          (table.insert bwd t.idx)
          (table.insert fwd t.idx)))
    (table.sort bwd #(> $1 $2))
    (table.sort fwd)
    (local new-idx {})
    (collect [i idx (ipairs bwd) &into new-idx]
      (values idx (- i)))
    (collect [i idx (ipairs fwd) &into new-idx]
      (values idx i))
    (each [_ t (ipairs targets)]
      (set t.idx (. new-idx t.idx))))

  ; Jump

  (local jump-to!
    (do
      (var first-jump? true)  ; better be managed by the function itself
      (fn [target]
        (local jump (require "leap.jump"))
        (jump.jump-to! target.pos
                       {:win target.wininfo.winid
                        :add-to-jumplist? first-jump?
                        : mode
                        : offset
                        :backward? (or backward?
                                       (and target.idx (< target.idx 0)))
                        : inclusive-op?})
        (set first-jump? false))))

  (local do-action (or user-given-action jump-to!))

  ; Post-pattern loops

  (fn select [targets]
    (local |groups| (if (not targets.label-set)
                        0
                        (ceil (/ (length targets) (length targets.label-set)))))

    (fn display []
      (local use-no-labels? (or no-labels-to-use? st.repeating-shortcut?))
      ; Do _not_ skip this on initial invocation - we might have skipped
      ; setting the initial label states if using `keys.next_target`.
      (set-beacons targets {:group-offset st.group-offset :phase st.phase
                            : use-no-labels?})
      (local (start end) (get-highlighted-idx-range targets use-no-labels?))
      (with-highlight-chores
        #(light-up-beacons targets start end)))

    (fn loop [first-invoc?]
      (display)
      (when first-invoc?
        (exec-user-autocmds :LeapSelectPre))
      (case (get-char)
        input
        (let [switch-group? (or (contains? keys.next_group input)
                                (and (contains? keys.prev_group input)
                                     (not first-invoc?)))]
          (if (and switch-group? (> |groups| 1))
              (let [shift (if (contains? keys.next_group input) 1 -1)
                    max-offset (dec |groups|)]
                (set st.group-offset (clamp (+ st.group-offset shift)
                                            0
                                            max-offset))
                (loop false))
              input))))

    (loop true))


  (fn traversal-get-new-idx [idx in targets]
    ; Wrap around in both directions.
    (if (contains? keys.next_target in)
        (if (= (inc idx) (length targets)) (length targets)
            (% (inc idx) (length targets)))

        (contains? keys.prev_target in)
        (if (<= idx 1) (length targets) (dec idx))))


  (fn traverse [targets start-idx {: use-no-labels?}]

    (fn on-first-invoc []
      (if use-no-labels?
          (each [_ t (ipairs targets)]
            (set t.label nil))

          ; Remove all the subsequent label groups if needed.
          (not (empty? opts.safe_labels))
          (let [last-labeled (inc (length opts.safe_labels))]  ; skipped the first
            (for [i (inc last-labeled) (length targets)]
              (set (. targets i :label) nil)
              (set (. targets i :beacon) nil)))))

    (fn display []
      (set-beacons targets {:group-offset st.group-offset :phase st.phase
                            : use-no-labels?})
      (local (start end) (get-highlighted-idx-range targets use-no-labels?))
      (with-highlight-chores
        #(light-up-beacons targets start end)))

    (fn loop [idx first-invoc?]
      (when first-invoc? (on-first-invoc))
      (set st.curr-idx idx)  ; `display` depends on it!
      (display)
      (case (get-char)
        in
        (case (traversal-get-new-idx idx in targets)
          new-idx (do
                    (do-action (. targets new-idx))
                    (loop new-idx false))
          ; We still want the labels (if there are) to function.
          _ (case (get-target-with-active-label targets in)
              target (do-action target)
              _ (vim.fn.feedkeys in :i)))))

    (loop start-idx true))

  ; //> Helper functions END


  ; After all the stage-setting, here comes the main action you've all been
  ; waiting for:

  (exec-user-autocmds :LeapEnter)

  (local need-in1? (or keyboard-input?
                       (and invoked-repeat?
                            (not
                              (or (= (type state.repeat.pattern) :string)
                                  (= state.repeat.inputlen 0))))
                       (and invoked-dot-repeat?
                            (not
                              (or (= (type state.dot_repeat.pattern) :string)
                                  (= state.dot_repeat.inputlen 0)
                                  state.dot_repeat.targets)))))

  (local (in1 ?in2) (when need-in1?
                      (if keyboard-input?
                          (if st.phase
                              ; This might call `get-repeat-input`, and
                              ; also return `?in2`, if using `next_target`.
                              (get-first-pattern-input)  ; REDRAW
                              (get-full-pattern-input))  ; REDRAW

                          invoked-repeat?
                          (get-repeat-input)

                          invoked-dot-repeat?
                          (values state.dot_repeat.in1 state.dot_repeat.in2))))

  (when (and need-in1? (not in1))
    (exit-early))

  (local user-given-targets* (or user-given-targets
                                 (and invoked-dot-repeat?
                                      state.dot_repeat.targets)))
  (local targets
    (if user-given-targets* (get-user-given-targets user-given-targets*)
        (let [pattern* (or user-given-pattern
                           (and invoked-repeat? state.repeat.pattern)
                           (and invoked-dot-repeat? state.dot_repeat.pattern))
              pattern (if (= (type pattern*) :string) pattern*

                          (= (type pattern*) :function)
                          (pattern* (if in1 (prepare-pattern in1 ?in2) "")
                                    [in1 ?in2])

                          (prepare-pattern in1 ?in2))]
          ; TODO: refactor errmsg-handling
          (get-targets pattern in1 ?in2))))
  (when-not targets
    (exit-early))

  (when invoked-dot-repeat?
    (case (. targets state.dot_repeat.target_idx)
      target (do (do-action target) (exit))
      _ (exit-early)))

  (local need-in2? (and (= inputlen 2)
                        (not (or ?in2 st.repeating-shortcut?))))

  (do
    (local preview? need-in2?)
    (local use-no-labels? (or no-labels-to-use? st.repeating-shortcut?))
    (if preview?
        (do
          (populate-sublists targets)
          (each [_ sublist (pairs targets.sublists)]
            (prepare-labeled-targets* sublist)
            (set-beacons targets {:phase st.phase}))
          (when (= st.phase 1)
            (resolve-conflicts targets)))
        (if use-no-labels?
            (set targets.autojump? true)
            (prepare-labeled-targets* targets))))

  (local ?in2 (or ?in2
                  (and need-in2? (get-second-pattern-input targets))))  ; REDRAW
  (when (and need-in2? (not ?in2))
    (exit-early))

  (when st.phase (set st.phase 2))

  ; Jump eagerly to the first/count-th match on the whole unfiltered
  ; target list?
  (local shortcut? (or st.repeating-shortcut?
                       (contains-safe? keys.next_target ?in2)))

  ; Do this now - repeat can succeed, even if we fail this time.
  (update-repeat-state in1 (when-not shortcut? ?in2))

  (when shortcut?
    (local n (or count 1))
    (local target (. targets n))
    (when-not target
      (exit-early))
    ; Do this before `do-action`, because it might erase forced motion.
    ; (The `:normal` command in `jump.jump-to!` can change the state of
    ; `mode()`. See vim/vim#9332.)
    (set-dot-repeat in1 nil (if target.idx target.idx n))
    (do-action target)
    (when (can-traverse? targets)
      (traverse targets 1 {:use-no-labels? true}))  ; REDRAW (LOOP)
    (exit))

  (exec-user-autocmds :LeapPatternPost)

  ; Get the sublist for ?in2, and work with that from here on (except if
  ; we've been given custom targets).
  (local targets* (if targets.sublists (. targets.sublists ?in2) targets))
  (when-not targets*
    ; (Note: at this point, ?in2 might only be nil if
    ; `st.repeating-shortcut?` is true; that case implies there
    ; are no sublists, and there _are_ targets.)
    (set st.errmsg (.. "not found: " in1 ?in2))
    (exit-early))
  (when (and (not= targets* targets) (. targets* 1 :idx))
    (normalize-indexes-for-dot-repeat targets*))

  (fn exit-with-action-on* [idx]
    (local target (. targets* idx))
    (set-dot-repeat in1 ?in2 (if target.idx target.idx idx))
    (do-action target)
    (exit*))

  (macro exit-with-action-on [idx]
    `(do (exit-with-action-on* ,idx) (lua :return)))

  (if count
      (if (> count (length targets*))
          (exit-early)
          (exit-with-action-on count))

      (and invoked-repeat? (not (can-traverse? targets*)))
      (exit-with-action-on 1))

  (when targets*.autojump?
    (if (= (length targets*) 1)
        (exit-with-action-on 1)
        (do
          (do-action (. targets* 1))
          (set st.curr-idx 1))))

  (local in-final (select targets*))  ; REDRAW (LOOP)
  (if (not in-final)
      (exit-early)

      ; Traversal - `prev_target` can also start it, wrapping backwards.
      (and (can-traverse? targets*)
           (or (contains? keys.next_target in-final)
               (contains? keys.prev_target in-final)))
      (let [use-no-labels? (or no-labels-to-use?
                               st.repeating-shortcut?
                               (not targets*.autojump?))
            ; Note: `traverse` will set `st.curr-idx` to `new-idx`.
            new-idx (traversal-get-new-idx st.curr-idx in-final targets*)]
        (do-action (. targets* new-idx))
        (traverse targets* new-idx {: use-no-labels?})  ; REDRAW (LOOP)
        (exit))

      ; `next_target` accepts the first match if the cursor hasn't moved
      ; yet (no autojump).
      (and (contains? keys.next_target in-final)
           (= st.curr-idx 0))
      (exit-with-action-on 1)

      ; Otherwise try to get a labeled target, and feed the key to
      ; Normal mode if no success.
      (case (get-target-with-active-label targets* in-final)
        (target idx) (exit-with-action-on idx)
        _ (do (vim.fn.feedkeys in-final :i)
              (exit))))

  ; Do return something here, otherwise Fennel automatically inserts
  ; return statements into the tail-positioned if branches above,
  ; conflicting with the exit forms, and leading to compile error.
  nil)


; Init ///1


(fn init-highlight []
  (hl:init)
  ; Colorscheme plugins might clear out our highlight definitions,
  ; without defining their own, so we re-init the highlight on every
  ; change.
  (api.nvim_create_autocmd "ColorScheme"
    {:group "LeapDefault"
     ; Wrap it - do not pass on event data as argument.
     :callback (fn [_] (hl:init))}))


(fn manage-vim-opts []
  (local get-opt api.nvim_get_option_value)
  (local set-opt api.nvim_set_option_value)
  (var saved-vim-opts {})

  (fn set-vim-opts [t]
    (let [wins (or (. state.args :target_windows) [(api.nvim_get_current_win)])]
      (set saved-vim-opts {})
      (each [opt val (pairs t)]
        (let [[scope name] (vim.split opt "." {:plain true})]
          (case scope
            :wo (each [_ win (ipairs wins)]
                  (local saved-val (get-opt name {:scope "local" :win win}))
                  (set (. saved-vim-opts [:wo win name]) saved-val)
                  (set-opt name val {:scope "local" :win win}))
            :bo (each [_ win (ipairs wins)]
                  (local buf (api.nvim_win_get_buf win))
                  (local saved-val (get-opt name {:buf buf}))
                  (set (. saved-vim-opts [:bo buf name]) saved-val)
                  (set-opt name val {:buf buf}))
            :go (do
                  (local saved-val (get-opt name {:scope "global"}))
                  (set (. saved-vim-opts name) saved-val)
                  (set-opt name val {:scope "global"})))))))

  (fn restore-vim-opts []
    (each [key val (pairs saved-vim-opts)]
      (case key
        [:wo win name] (when (api.nvim_win_is_valid win)
                         (set-opt name val {:scope "local" :win win}))
        [:bo buf name] (when (api.nvim_buf_is_valid buf)
                         (set-opt name val {:buf buf}))
        name (set-opt name val {:scope "global"}))))

  (api.nvim_create_autocmd "User"
    {:pattern "LeapEnter"
     :group "LeapDefault"
     :callback (fn [_] (set-vim-opts opts.vim_opts))})

  (api.nvim_create_autocmd "User"
    {:pattern "LeapLeave"
     :group "LeapDefault"
     :callback (fn [_] (restore-vim-opts))}))


(fn init []
  ; The equivalence class table can be potentially huge - let's do this
  ; here, and not each time `leap` is called, at least for the defaults.
  (set opts.default.eqv_class_of
       (to-membership-lookup opts.default.equivalence_classes))
  (api.nvim_create_augroup "LeapDefault" {})
  (init-highlight)
  (manage-vim-opts))


(init)


; Module ///1

{: state
 : leap}


; vim: foldmethod=marker foldmarker=///,//>
