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
        : replace-keycodes
        : ->representative-char
        : get-input
        : get-input-by-keymap}
       (require "leap.util"))

(local api vim.api)
(local contains? vim.tbl_contains)
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
    (replace-keycodes
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
        cmd (replace-keycodes
              "<cmd>lua require'leap'.leap { dot_repeat = true }<cr>")
        ; We cannot getreg('.') at this point, since the change has not
        ; happened yet - therefore the below hack (thx Sneak).
        change (when (= op :c) (replace-keycodes "<c-r>.<esc>"))
        seq (.. op force cmd (or change ""))]
    ; Using pcall, since vim-repeat might not be installed.
    ; Use the same register for the repeated operation.
    (pcall vim.fn.repeat#setreg seq vim.v.register)
    ; Note: we're feeding count inside the seq itself.
    (pcall vim.fn.repeat#set seq -1)))


; Return a char->eq-class lookup table (the relevant one for us).
(fn eq-classes->membership-lookup [eqcls]
  (let [res {}]
    (each [_ eqcl (ipairs eqcls)]
      (let [eqcl* (if (= (type eqcl) :string)
                      (vim.fn.split eqcl "\\zs")
                      eqcl)]
        (each [_ ch (ipairs eqcl*)]
          (tset res ch eqcl*))))
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
  ; NOTE: If two-step processing is ebabled (AOT beacons), for any kind
  ; of input mapping (case-insensitivity, character classes, etc.) we
  ; need to tweak things in two different places:
  ;   1. For the first input, we modify the search pattern itself (see
  ;   `prepare-pattern` in `search.fnl`).
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
                        (rawget self (->representative-char ch)))
          :__newindex (fn [self ch sublist]
                        (rawset self (->representative-char ch) sublist))}))
  ; Filling the sublists.
  (each [_ {:chars [_ ch2] &as target} (ipairs targets)]
    (when-not (. targets.sublists ch2)
      (tset targets.sublists ch2 []))
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
      (local winid (. targets 1 :wininfo :winid))
      (each [_ target (ipairs targets) &until (= same-win? false)]
        (when (not= target.wininfo.winid winid)
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
                       ; For when wanting to repeat in relative direction
                       ; (for "outside" use only).
                       :backward nil
                       :inclusive_op nil
                       :offset nil}
              :dot_repeat {:callback nil
                           :in1 nil
                           :in2 nil
                           :target_idx nil
                           :backward nil
                           :inclusive_op nil
                           :offset nil}

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
          : offset}
         (if invoked-dot-repeat? state.dot_repeat
             invoked-repeat? state.repeat
             kwargs))

  (set state.args kwargs)

  ; Do this before accessing `opts`.
  (set opts.current_call (or user-given-opts {}))

  (set opts.current_call.eq_class_of
       (-?> opts.current_call.equivalence_classes
            eq-classes->membership-lookup))
  ; Force the label lists into tables.
  (each [_ t (ipairs [:default :current_call])]
    (each [_ k (ipairs [:labels :safe_labels])]
      (when (= (type (. opts t k)) :string)
        (tset opts t k (vim.fn.split (. opts t k) "\\zs")))))

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

  (local curr-winid (api.nvim_get_current_win))

  (local hl-affected-windows (if (= (vim.fn.has "nvim-0.10") 0)
                                 ; For pre-0.10, a fake cursor is shown in the
                                 ; source window, since the real one disappears.
                                 ; (See `with-highlight-chores`.)
                                 (vim.list_extend
                                   [curr-winid] (or ?target-windows []))
                                 (or ?target-windows [curr-winid])))

  ; We need to save the mode here, because the `:normal` command in
  ; `jump.jump-to!` can change the state. See vim/vim#9332.
  (local mode (. (api.nvim_get_mode) :mode))
  (local op-mode? (mode:match :o))
  (local change-op? (and op-mode? (= vim.v.operator :c)))

  (local count (if (not directional?) nil
                   (= vim.v.count 0) (if (and op-mode? no-labels-to-use?) 1 nil)
                   vim.v.count))

  (local max-phase-one-targets (or opts.max_phase_one_targets math.huge))
  (local user-given-targets? user-given-targets)

  (local keyboard-input? (not (or invoked-repeat?
                                  invoked-dot-repeat?
                                  user-given-targets)))

  (local prompt {:str ">"})  ; pass by reference hack (for input fns)

  (local spec-keys (setmetatable {}
                     {:__index (fn [_ k]
                                 (case (. opts.special_keys k)
                                   v (map replace-keycodes
                                          ; Force them into a table.
                                          (if (= (type v) :string) [v] v))))}))

  ; Ephemeral state (of the current call) that is not interesting for
  ; the outside world.
  (local st {; Multi-phase processing (show beacons ahead of time,
             ; right after the first input)?
             :phase (when (and keyboard-input?
                               (not= max-phase-one-targets 0)
                               (not no-labels-to-use?))
                      1)
             ; When repeating a `{char}<enter>` search (started to
             ; traverse after the first input).
             :repeating-partial-pattern? false
             ; For traversal mode.
             :curr-idx 0
             ; Currently selected label group, 0-indexed
             ; (`target.group` starts at 1).
             :group-offset 0
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

  (fn with-highlight-chores [f]
    (hl:cleanup hl-affected-windows)
    (when-not count (hl:apply-backdrop backward? ?target-windows))
    (when f (f))
    (when (= (vim.fn.has "nvim-0.10") 0) (hl:highlight-cursor))
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

  ; Getting targets

  (fn get-repeat-input []
    (if state.repeat.in1
        (do (when-not state.repeat.in2
              (set st.repeating-partial-pattern? true))
            (values state.repeat.in1 state.repeat.in2))
        (set st.errmsg "no previous search")))

  (fn get-first-pattern-input []
    (with-highlight-chores nil)
    (case (get-input-by-keymap prompt)
      ; Here we can handle any other modifier key as "zeroth" input,
      ; if the need arises.
      in1 (if (contains? spec-keys.next_target in1)
              (do (set st.phase nil)
                  (get-repeat-input))
              in1)))

  (fn get-second-pattern-input [targets]
    (when (and (<= (length targets) max-phase-one-targets)
               ; Note: `count` does _not_ automatically disable
               ; two-phase processing, as we might want to give
               ; char<enter> partial input (but it implies not needing
               ; to show beacons).
               (not count))
      (with-highlight-chores #(light-up-beacons targets)))
    (get-input-by-keymap prompt))

  (fn get-full-pattern-input []
    (case (get-first-pattern-input)
      (in1 in2) (values in1 in2)
      (in1 nil) (case (get-input-by-keymap prompt)
                  in2 (values in1 in2))))

  (fn get-targets [in1 ?in2]
    (let [search (require :leap.search)
          pattern (search.prepare-pattern in1 ?in2)
          kwargs {: backward? : offset : op-mode?
                  :target-windows ?target-windows}
          targets (search.get-targets pattern kwargs)]
      (or targets (set st.errmsg (.. "not found: " in1 (or ?in2 ""))))))

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
            (local wininfo (. (vim.fn.getwininfo curr-winid) 1))
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

  (local from-kwargs {: offset
                      ; Mind the naming conventions.
                      :backward backward?
                      :inclusive_op inclusive-op?})

  (fn update-repeat-state [in1 in2]
    (when keyboard-input?
      (set state.repeat (vim.tbl_extend :error from-kwargs {: in1 : in2}))))


  (fn set-dot-repeat [in1 in2 target_idx]
    (local dot-repeatable-op? (and op-mode?
                                   (or (vim.o.cpo:match "y")
                                       (not= vim.v.operator "y"))))

    (local dot-repeatable-call? (and dot-repeatable-op?
                                     (not invoked-dot-repeat?)
                                     (not= (type user-given-targets) :table)))

    (fn update-dot-repeat-state []
      (set state.dot_repeat (vim.tbl_extend :error
                              from-kwargs
                              {:callback user-given-targets
                               :in1 (and (not user-given-targets) in1)
                               :in2 (and (not user-given-targets) in2)
                               : target_idx}))
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
                       {:winid target.wininfo.winid
                        :add-to-jumplist? first-jump?
                        : mode
                        : offset
                        : backward?
                        : inclusive-op?})
        (set first-jump? false))))

  (local do-action (or user-given-action jump-to!))

  ; Target-selection loops

  (fn post-pattern-input-loop [targets]
    (local |groups| (if (not targets.label-set)
                        0
                        (ceil (/ (length targets) (length targets.label-set)))))

    (fn display []
      (local use-no-labels? (or no-labels-to-use? st.repeating-partial-pattern?))
      ; Do _not_ skip this on initial invocation - we might have skipped
      ; setting the initial label states if using `spec-keys.next_target`.
      (set-beacons targets {:group-offset st.group-offset :phase st.phase
                            : use-no-labels?})
      (local (start end) (get-highlighted-idx-range targets use-no-labels?))
      (with-highlight-chores
        #(light-up-beacons targets start end)))

    (fn loop [first-invoc?]
      (display)
      (when first-invoc?
        (exec-user-autocmds :LeapSelectPre))
      (case (get-input)
        input
        (let [switch-group? (or (contains? spec-keys.next_group input)
                                (and (contains? spec-keys.prev_group input)
                                     (not first-invoc?)))]
          (if (and switch-group? (> |groups| 1))
              (let [shift (if (contains? spec-keys.next_group input) 1 -1)
                    max-offset (dec |groups|)]
                (set st.group-offset (clamp (+ st.group-offset shift)
                                            0
                                            max-offset))
                (loop false))
              input))))

    (loop true))


  (fn traversal-get-new-idx [idx in targets]
    (if (contains? spec-keys.next_target in)
        (min (inc idx) (length targets))

        (contains? spec-keys.prev_target in)
        ; Wrap around backwards.
        (if (<= idx 1) (length targets) (dec idx))))


  (fn traversal-loop [targets start-idx {: use-no-labels?}]

    (fn on-first-invoc []
      (if use-no-labels?
          (each [_ t (ipairs targets)]
            (set t.label nil))

          ; Remove all the subsequent label groups if needed.
          (not (empty? opts.safe_labels))
          (let [last-labeled (inc (length opts.safe_labels))]  ; skipped the first
            (for [i (inc last-labeled) (length targets)]
              (doto (. targets i)
                (tset :label nil)
                (tset :beacon nil))))))

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
      (case (get-input)
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

  (local (in1 ?in2) (if keyboard-input?
                        (if st.phase
                            ; This might call `get-repeat-input`, and
                            ; also return `?in2`, if using `next_target`.
                            (get-first-pattern-input)  ; REDRAW
                            (get-full-pattern-input))  ; REDRAW

                        invoked-repeat?
                        (get-repeat-input)

                        (and invoked-dot-repeat? (not state.dot_repeat.callback))
                        (values state.dot_repeat.in1 state.dot_repeat.in2)

                        (values true true)))
  (when-not in1
    (exit-early))

  (local targets (if (and invoked-dot-repeat? state.dot_repeat.callback)
                     (get-user-given-targets state.dot_repeat.callback)

                     user-given-targets?
                     (get-user-given-targets user-given-targets)

                     (get-targets in1 ?in2)))
  (when-not targets
    (exit-early))

  (when invoked-dot-repeat?
    (case (. targets state.dot_repeat.target_idx)
      target (do (do-action target) (exit))
      _ (exit-early)))

  (if (or ?in2 st.repeating-partial-pattern?)
      (if (or no-labels-to-use? st.repeating-partial-pattern?)
          (set targets.autojump? true)
          (prepare-labeled-targets* targets))
      (do
        (when (> (length targets) max-phase-one-targets)
          (set st.phase nil))
        (populate-sublists targets)
        (each [_ sublist (pairs targets.sublists)]
          (prepare-labeled-targets* sublist)
          (set-beacons targets {:phase st.phase}))
        (when (= st.phase 1)
          (resolve-conflicts targets))))

  (local ?in2 (or ?in2
                  (and (not st.repeating-partial-pattern?)
                       (get-second-pattern-input targets))))  ; REDRAW
  (when-not (or st.repeating-partial-pattern? ?in2)
    (exit-early))

  (when st.phase (set st.phase 2))

  ; Jump eagerly to the first/count-th match on the whole target list?
  (local partial-pattern? (or st.repeating-partial-pattern?
                              (contains? spec-keys.next_target ?in2)))

  ; Do this now - repeat can succeed, even if we fail this time.
  (update-repeat-state in1 (when-not partial-pattern? ?in2))

  (when partial-pattern?
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
      (traversal-loop targets 1 {:use-no-labels? true}))  ; REDRAW (LOOP)
    (exit))

  (exec-user-autocmds :LeapPatternPost)

  ; Get the sublist for ?in2, and work with that from here on (except if
  ; we've been given custom targets).
  (local targets* (if targets.sublists (. targets.sublists ?in2) targets))
  (when-not targets*
    ; (Note: at this point, ?in2 might only be nil if
    ; `st.repeating-partial-pattern?` is true; that case implies there
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

  (local in-final (post-pattern-input-loop targets*))  ; REDRAW (LOOP)
  (if (not in-final)
      (exit-early)

      ; Traversal - `prev_target` can also start it, wrapping backwards.
      (and (can-traverse? targets*)
           (or (contains? spec-keys.next_target in-final)
               (contains? spec-keys.prev_target in-final)))
      (let [use-no-labels? (or no-labels-to-use?
                               st.repeating-partial-pattern?
                               (not targets*.autojump?))
            ; Note: `traversal-loop` will set `st.curr-idx` to `new-idx`.
            new-idx (traversal-get-new-idx st.curr-idx in-final targets*)]
        (do-action (. targets* new-idx))
        (traversal-loop targets* new-idx {: use-no-labels?})  ; REDRAW (LOOP)
        (exit))

      ; `next_target` accepts the first match if the cursor hasn't moved
      ; yet (no autojump).
      (and (contains? spec-keys.next_target in-final)
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


(fn get-concealed-label []
  (let [leap-label (api.nvim_get_hl 0 {:name hl.group.label :link false})
        middle-dot "\u{00b7}"]
    (if leap-label.bg " " middle-dot)))


(fn init-highlight* []
  (hl:init-highlight)
  ; Undocumented option, might be exposed in the future.
  (set opts.concealed_label (get-concealed-label)))


(fn init-highlight []
  (init-highlight*)
  ; Colorscheme plugins might clear out our highlight definitions,
  ; without defining their own, so we re-init the highlight on every
  ; change.
  (api.nvim_create_autocmd "ColorScheme"
    {:group "LeapDefault"
     :callback init-highlight*}))


(fn manage-editor-opts []
  (local temporary-editor-opts
    {:w.conceallevel 0
     :g.scrolloff 0
     :w.scrolloff 0
     :g.sidescrolloff 0
     :w.sidescrolloff 0
     :b.modeline false})  ; lightspeed#81

  (var saved-editor-opts {})

  (fn set-editor-opts [t]
    (let [wins (or (. state.args :target_windows) [(api.nvim_get_current_win)])]
      (set saved-editor-opts {})
      (each [opt val (pairs t)]
        (let [[scope name] (vim.split opt "." {:plain true})]
          (case scope
            :w (each [_ win (ipairs wins)]
                 (local saved-val (api.nvim_win_get_option win name))
                 (tset saved-editor-opts [:w win name] saved-val)
                 (api.nvim_win_set_option win name val))
            :b (each [_ win (ipairs wins)]
                 (local buf (api.nvim_win_get_buf win))
                 (local saved-val (api.nvim_buf_get_option buf name))
                 (tset saved-editor-opts [:b buf name] saved-val)
                 (api.nvim_buf_set_option buf name val))
            _ (do (local saved-val (api.nvim_get_option name))
                  (tset saved-editor-opts name saved-val)
                  (api.nvim_set_option name val)))))))

  (fn restore-editor-opts []
    (each [key val (pairs saved-editor-opts)]
      (case key
        [:w win name] (when (api.nvim_win_is_valid win)
                        (api.nvim_win_set_option win name val))
        [:b buf name] (when (api.nvim_buf_is_valid buf)
                        (api.nvim_buf_set_option buf name val))
        name (api.nvim_set_option name val))))

  (api.nvim_create_autocmd "User"
    {:pattern "LeapEnter"
     :group "LeapDefault"
     :callback (fn [_] (set-editor-opts temporary-editor-opts))})

  (api.nvim_create_autocmd "User"
    {:pattern "LeapLeave"
     :group "LeapDefault"
     :callback (fn [_] (restore-editor-opts))}))


(fn init []
  ; The equivalence class table can be potentially huge - let's do this
  ; here, and not each time `leap` is called, at least for the defaults.
  (set opts.default.eq_class_of (-?> opts.default.equivalence_classes
                                     eq-classes->membership-lookup))
  (api.nvim_create_augroup "LeapDefault" {})
  (init-highlight)
  (manage-editor-opts))


(init)


; Module ///1

{: state
 : leap}


; vim: foldmethod=marker foldmarker=///,//>
