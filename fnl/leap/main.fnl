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
(local {: ceil : max : min} math)


; Fennel utils ///1

(macro when-not [cond ...]
  `(when (not ,cond) ,...))


; Utils ///1

(fn handle-interrupted-change-op! []
  "Return to Normal mode and restore the cursor position after an
interrupted change operation."
  (let [seq (.. "<C-\\><C-G>"  ; :h CTRL-\_CTRL-G
                (if (> (vim.fn.col ".") 1) "<RIGHT>" ""))]
    (api.nvim_feedkeys (replace-keycodes seq) :n true)))


; repeat.vim support
; (see the docs in the script:
; https://github.com/tpope/vim-repeat/blob/master/autoload/repeat.vim)
(fn set-dot-repeat* []
  ; Note: We're not checking here whether the operation should be
  ; repeated (see `dot-repeatable-op?` in `leap()`).
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

(fn populate-sublists [targets multi-window?]
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
  (set targets.sublists {})

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
  (setmetatable targets.sublists
    {:__newindex (fn [self ch sublist]
                   (rawset self (->representative-char ch) sublist))
     :__index    (fn [self ch]
                   (rawget self (->representative-char ch)))})

  ; Filling the sublists.
  (if (not multi-window?)
      (each [_ {:chars [_ ch2] &as target} (ipairs targets)]
        (when-not (. targets.sublists ch2)
          (tset targets.sublists ch2 []))
        (table.insert (. targets.sublists ch2) target))
      (each [_ {:chars [_ ch2] :wininfo {: winid} &as target} (ipairs targets)]
        (when-not (. targets.sublists ch2)
          (tset targets.sublists ch2 {:shared-window? winid}))
        (local sublist (. targets.sublists ch2))
        (table.insert sublist target)
        (when (and sublist.shared-window? (not= winid sublist.shared-window?))
          (set sublist.shared-window? nil)))))


; `targets` might be a sublist of an original target list from here on.

(fn set-autojump [targets force-noautojump?]
  "Set a flag indicating whether we should autojump to the first target,
without having to select a label.
Note that there is no one-to-one correspondence between this flag and
the `label-set` field set by `attach-label-set`. No-autojump might be
forced implicitly, regardless of using safe labels."
  (set targets.autojump? (and (not (or force-noautojump?
                                       (empty? opts.safe_labels)))
                              (or (empty? opts.labels)
                                  ; Smart mode.
                                  (>= (length opts.safe_labels)
                                      ; Skipping the first if autojumping.
                                      (dec (length targets)))))))


(fn attach-label-set [targets]
  "Set a field referencing the label set to be used for `targets`.
NOTE: `set-autojump` should be called BEFORE this function."
  ; (assert (not (and (empty? opts.labels) (empty? opts.safe_labels))))
  (set targets.label-set (if (empty? opts.labels) opts.safe_labels
                             (empty? opts.safe_labels) opts.labels
                             targets.autojump? opts.safe_labels
                             opts.labels)))


(fn set-labels [targets]
  "Assign label characters to each target, using the given label set
repeated indefinitely. Note: `label` is a once and for all fixed
attribute - whether and how it should actually be displayed depends on
other parts of the code.

Also sets a `group` attribute (a static one too, not to be updated)."
  (when (or (> (length targets) 1) (empty? opts.safe_labels))
    (local {: autojump? : label-set} targets)
    (local |label-set| (length label-set))
    (each [i* target (ipairs targets)]
      ; Skip labeling the first target if autojump is set.
      (local i (if autojump? (dec i*) i*))
      (when (>= i 1)
        (case (% i |label-set|)
          0 (do
              (set target.label (. label-set |label-set|))
              (set target.group (math.floor (/ i |label-set|))))
          n (do
              (set target.label (. label-set n))
              (set target.group (inc (math.floor (/ i |label-set|))))))))))


(fn prepare-targets [targets {: force-noautojump?}]
  (doto targets
    (set-autojump force-noautojump?)
    (attach-label-set)
    (set-labels)))


; Main ///1

; State that is persisted between invocations.
(local state {:repeat {:in1 nil
                       :in2 nil
                       ; For when wanting to repeat in relative direction
                       ; (for "outside" use only).
                       :backward nil
                       :inclusive_op nil
                       :offset nil
                       :match_same_char_seq_at_end nil}
              :dot_repeat {:callback nil
                           :in1 nil
                           :in2 nil
                           :target_idx nil
                           :backward nil
                           :inclusive_op nil
                           :offset nil
                           :match_same_char_seq_at_end nil}})


(fn leap [kwargs]
  "Entry point for Leap motions."
  (local {:repeat repeating?
          :dot_repeat dot-repeating?
          :target_windows target-windows
          :opts user-given-opts
          :targets user-given-targets
          :action user-given-action}
         kwargs)
  (local {:backward backward?}
         (if dot-repeating? state.dot_repeat
             kwargs))
  (local {:inclusive_op inclusive-op?
          : offset
          :match_same_char_seq_at_end match-same-char-seq-at-end?}
         (if dot-repeating? state.dot_repeat
             repeating? state.repeat
             kwargs))

  ; Deprecated, use event.data in the autocommand callbacks instead.
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
  (local multi-window? (and ?target-windows (> (length ?target-windows) 1)))
  (local curr-winid (api.nvim_get_current_win))
  (local hl-affected-windows (vim.list_extend
                               ; The cursor is always highlighted.
                               [curr-winid] (or ?target-windows [])))
  ; We need to save the mode here, because the `:normal` command in
  ; `jump.jump-to!` can change the state. See vim/vim#9332.
  (local mode (. (api.nvim_get_mode) :mode))
  (local op-mode? (mode:match :o))
  (local change-op? (and op-mode? (= vim.v.operator :c)))
  (local dot-repeatable-op? (and op-mode? directional?
                                 (or (vim.o.cpo:match "y")
                                     (not= vim.v.operator "y"))))
  (local count (if (not directional?) nil
                   (= vim.v.count 0) (if (and op-mode? no-labels-to-use?) 1 nil)
                   vim.v.count))
  (local max-phase-one-targets (or opts.max_phase_one_targets math.huge))
  (local user-given-targets? user-given-targets)
  (local can-traverse? (and directional?
                            (not (or count
                                     op-mode?
                                     user-given-action))))
  (local prompt {:str ">"})  ; pass by reference hack (for input fns)

  (local spec-keys (setmetatable {}
                     {:__index
                      (fn [_ k]
                        (case (. opts.special_keys k)
                          v (if (or (= k :next_target) (= k :prev_target))
                                ; Force those into a table.
                                (map replace-keycodes
                                     (if (= (type v) :string) [v] v))
                                (replace-keycodes v))))}))

  ; Ephemeral state (of the current call) that is not interesting for
  ; the outside world.
  (local _state {; Multi-phase processing (show beacons ahead of time,
                 ; right after the first input)?
                 :phase (if (or repeating?
                                (= max-phase-one-targets 0)
                                no-labels-to-use?
                                user-given-targets?)
                            nil
                            1)
                 ; When repeating a `{char}<enter>` search (started to
                 ; traverse after the first input).
                 :partial-pattern? false
                 ; For traversal mode.
                 :curr-idx 0
                 ; Currently selected label group, 0-indexed
                 ; (`target.group` starts at 1).
                 :group-offset 0
                 :errmsg nil})

  (fn exec-user-autocmds [pattern]
    (api.nvim_exec_autocmds "User"
      {: pattern
       ; NOTE: `{:args kwargs}` would throw an error if any subtable in
       ; `kwargs` contains both integer and string keys (~> msgpack
       ; compat), hence the workaround.
       :data {:args (setmetatable {} {:__index kwargs})}
       :modeline false}))

  ; Macros

  (macro exit []
    `(do (hl:cleanup hl-affected-windows)
         (exec-user-autocmds :LeapLeave)
         (lua :return)))

  ; Be sure not to call the macro twice accidentally,
  ; `handle-interrupted-change-op!` moves the cursor!
  (macro exit-early []
    `(do (when change-op? (handle-interrupted-change-op!))
         (when _state.errmsg (echo _state.errmsg))
         (exit)))

  (macro with-highlight-chores [...]
    `(do (hl:cleanup hl-affected-windows)
         (when-not count
           (hl:apply-backdrop backward? ?target-windows))
         (do ,...)
         (hl:highlight-cursor)
         (vim.cmd :redraw)))

  ; Helper functions ///

  ; Misc. helpers

  ; When traversing without labels, keep highlighting the same one group
  ; of targets, and do not shift until reaching the end of the group - it
  ; is less disorienting if the "snake" does not move continuously, on
  ; every jump.
  (fn get-number-of-highlighted-traversal-targets []
    (case opts.max_highlighted_traversal_targets
      group-size
      ; Assumption: being here means we are after an autojump, and
      ; started highlighting from the 2nd target (no `count`).
      ; Thus, we can use `_state.curr-idx` as the reference, instead of
      ; some separate counter (but only because of the above).
      (let [consumed (% (dec _state.curr-idx) group-size)
            remaining (- group-size consumed)]
        ; Switch just before the whole group gets eaten up.
        (if (= remaining 1) (inc group-size)
            (= remaining 0) group-size
            remaining))))

  (fn get-highlighted-idx-range [targets use-no-labels?]
    (if (and use-no-labels? (= opts.max_highlighted_traversal_targets 0))
        (values 0 -1)  ; empty range
        (let [start (inc _state.curr-idx)
              end (when use-no-labels?
                    (case (get-number-of-highlighted-traversal-targets)
                      n (min (+ (dec start) n) (length targets))))]
          (values start end))))

  (fn get-target-with-active-label [targets input]
    (var res nil)
    (var break? false)
    (each [idx target (ipairs targets) &until (or res break?)]
      (when target.label
        (local relative-group (- target.group _state.group-offset))
        (when (> relative-group 1)  ; we are beyond the currently active group
          (set break? true))
        (when (and (= relative-group 1) (= target.label input))
          (set res (values idx target)))))
    res)

  ; Getting targets

  (fn get-repeat-input []
    (if state.repeat.in1
        (do (when-not state.repeat.in2
              (set _state.partial-pattern? true))
            (values state.repeat.in1 state.repeat.in2))
        (set _state.errmsg "no previous search")))

  (fn get-first-pattern-input []
    (with-highlight-chores (echo ""))  ; clean up the command line
    (case (get-input-by-keymap prompt)
      ; Here we can handle any other modifier key as "zeroth" input,
      ; if the need arises.
      in1
      (if (contains? spec-keys.next_target in1)
          (if state.repeat.in1
              (do (set _state.phase nil)
                  (when-not state.repeat.in2
                    (set _state.partial-pattern? true))
                  (values state.repeat.in1 state.repeat.in2))
              (set _state.errmsg "no previous search"))
          in1)))

  (fn get-second-pattern-input [targets]
    (when (and (<= (length targets) max-phase-one-targets)
               ; Note: `count` does _not_ automatically disable
               ; two-phase processing, as we might want to give
               ; char<enter> partial input (but it implies not needing
               ; to show beacons).
               (not count))
      (with-highlight-chores (light-up-beacons targets)))
    (get-input-by-keymap prompt))

  (fn get-full-pattern-input []
    (case (get-first-pattern-input)
      (in1 in2) (values in1 in2)
      (in1 nil) (case (get-input-by-keymap prompt)
                  in2 (values in1 in2))))

  (fn get-targets [in1 ?in2]
    (let [search (require :leap.search)
          pattern (search.prepare-pattern in1 ?in2)
          kwargs {: backward? : match-same-char-seq-at-end?
                  :target-windows ?target-windows}
          targets (search.get-targets pattern kwargs)]
      (or targets (set _state.errmsg (.. "not found: " in1 (or ?in2 ""))))))

  (fn get-user-given-targets [targets]
    (local targets* (if (= (type targets) :function) (targets) targets))
    (if (and targets* (> (length targets*) 0))
        (do
          ; Fill wininfo-s when not provided.
          (local wininfo (. (vim.fn.getwininfo curr-winid) 1))
          (when-not (. targets* 1 :wininfo)
            (each [_ t (ipairs targets*)]
              (set t.wininfo wininfo)))
          targets*)
        (set _state.errmsg "no targets")))

  (fn prepare-targets* [targets]
    ; Note: As opposed to the checks in `resolve-conflicts`, we can do
    ; this right now, before preparing the list (that is, no need for
    ; duplicate work), since this situation may arise in phase two, when
    ; only the chosen sublist remained.
    ; <-----  backward search
    ;   ab    target #1
    ; abL     target #2 (labeled)
    ;   ^     auto-jump would move the cursor here (covering the label)
    (local funny-edge-case? (and backward?
                                 (case targets
                                   [{:pos [l1 c1]}
                                    {:pos [l2 c2] :chars [ch1 ch2]}]
                                   (and (= l1 l2)
                                        (= c1 (+ c2 (ch1:len) (ch2:len)))))))
    (local force-noautojump? (or funny-edge-case?
                                 ; Should be able to select a target.
                                 op-mode?
                                 ; Disorienting if the chosen target
                                 ; happens to be in (yet) another window.
                                 (and multi-window?
                                      ; see `populate-sublists`
                                      (not targets.shared-window?))
                                 ; No jump, doing sg else.
                                 user-given-action))
    (prepare-targets
      targets {: force-noautojump?}))

  ; Repeat

  (local from-kwargs {: offset
                      ; Mind the naming conventions.
                      :match_same_char_seq_at_end match-same-char-seq-at-end?
                      :backward backward?
                      :inclusive_op inclusive-op?})

  (fn update-repeat-state [in1 in2]
    (when-not (or repeating? user-given-targets?)
      (set state.repeat (vim.tbl_extend :error from-kwargs {: in1 : in2}))))

  (fn set-dot-repeat [in1 in2 target_idx]
    (when (and dot-repeatable-op? (not dot-repeating?)
               (not= (type user-given-targets) :table))
      (set state.dot_repeat (vim.tbl_extend
                              :error
                              from-kwargs
                              {:callback user-given-targets
                               :in1 (and (not user-given-targets) in1)
                               :in2 (and (not user-given-targets) in2)
                               : target_idx}))
      (set-dot-repeat*)))

  ; Jump

  (local jump-to!
    (do
      (var first-jump? true)  ; better be managed by the function itself
      (fn [target]
        (local jump (require "leap.jump"))
        (jump.jump-to! target.pos
                       {:winid target.wininfo.winid
                        :add-to-jumplist? first-jump?
                        : mode : offset : backward? : inclusive-op?})
        (set first-jump? false))))

  ; Target-selection loops

  (fn post-pattern-input-loop [targets]
    (local |groups| (if (not targets.label-set) 0
                        (ceil (/ (length targets)
                                 (length targets.label-set)))))

    (fn display []
      (local use-no-labels? (or no-labels-to-use? _state.partial-pattern?))
      ; Do _not_ skip this on initial invocation - we might have skipped
      ; setting the initial label states if using `spec-keys.next_target`.
      (set-beacons targets {:group-offset _state.group-offset : use-no-labels?
                            : user-given-targets? :phase _state.phase})
      (with-highlight-chores
        (local (start end) (get-highlighted-idx-range targets use-no-labels?))
        (light-up-beacons targets start end)))

    (fn loop [first-invoc?]
      (display)
      (when first-invoc?
        (exec-user-autocmds :LeapSelectPre))
      (case (get-input)
        input
        (let [switch-group? (or (= input spec-keys.next_group)
                                (and (= input spec-keys.prev_group)
                                     (not first-invoc?)))]
          (if (and switch-group? (> |groups| 1))
              (let [shift (if (= input spec-keys.next_group) 1 -1)
                    max-offset (dec |groups|)]
                (set _state.group-offset
                     (clamp (+ _state.group-offset shift) 0 max-offset))
                (loop false))
              input))))

    (loop true))


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
      (set-beacons targets {:group-offset _state.group-offset : use-no-labels?
                            : user-given-targets? :phase _state.phase})
      (with-highlight-chores
        (local (start end) (get-highlighted-idx-range targets use-no-labels?))
        (light-up-beacons targets start end)))

    (fn get-new-idx [idx in]
      (if (contains? spec-keys.next_target in) (min (inc idx) (length targets))
          (contains? spec-keys.prev_target in) (max (dec idx) 1)))

    (fn loop [idx first-invoc?]
      (when first-invoc? (on-first-invoc))
      (set _state.curr-idx idx)  ; `display` depends on it!
      (display)
      (case (get-input)
        in
        (if (and (= idx 1) (contains? spec-keys.prev_target in))
            ; Handy if repeat keys are set.
            (vim.fn.feedkeys in :i)
            (case (get-new-idx idx in)
              new-idx (do
                        (jump-to! (. targets new-idx))
                        (loop new-idx false))
                ; We still want the labels (if there are) to function.
              _ (case (get-target-with-active-label targets in)
                  (_ target) (jump-to! target)
                  _ (vim.fn.feedkeys in :i))))))

    (loop start-idx true))

  ; //> Helper functions END


  (local do-action (or user-given-action jump-to!))

  ; After all the stage-setting, here comes the main action you've all been
  ; waiting for:

  (exec-user-autocmds :LeapEnter)

  (local (in1 ?in2) (if repeating? (get-repeat-input)
                        dot-repeating? (if state.dot_repeat.callback
                                           (values true true)
                                           (values state.dot_repeat.in1
                                                   state.dot_repeat.in2))
                        user-given-targets? (values true true)
                        ; This might also return in2 too, if using the
                        ; `next_target` key.
                        (= _state.phase 1) (get-first-pattern-input)  ; REDRAW
                        (get-full-pattern-input)))  ; REDRAW
  (when-not in1
    (exit-early))

  (local targets (if (and dot-repeating? state.dot_repeat.callback)
                     (get-user-given-targets state.dot_repeat.callback)

                     user-given-targets?
                     (get-user-given-targets user-given-targets)

                     (get-targets in1 ?in2)))
  (when-not targets
    (exit-early))

  (when dot-repeating?
    (case (. targets state.dot_repeat.target_idx)
      target (do (do-action target) (exit))
      _ (exit-early)))

  (if (or ?in2 _state.partial-pattern?)
      (if (or no-labels-to-use? _state.partial-pattern?)
          (set targets.autojump? true)
          (prepare-targets* targets))
      (do
        (when (> (length targets) max-phase-one-targets)
          (set _state.phase nil))
        (populate-sublists targets multi-window?)
        (each [_ sublist (pairs targets.sublists)]
           (prepare-targets* sublist))
        (set-beacons targets {:phase _state.phase})
        (when (= _state.phase 1)
          (resolve-conflicts targets))))

  (local ?in2 (or ?in2
                  (and (not _state.partial-pattern?)
                       (get-second-pattern-input targets))))  ; REDRAW
  (when-not (or _state.partial-pattern? ?in2)
    (exit-early))

  (when _state.phase (set _state.phase 2))

  ; Jump eagerly to the count-th match (without giving the full pattern)?
  (when (contains? spec-keys.next_target ?in2)
    (local n (or count 1))
    (local target (. targets n))
    (when-not target
      (exit-early))
    (update-repeat-state in1 nil)
    ; Do this before `do-action`, because it might erase forced motion.
    ; (The `:normal` command in `jump.jump-to!` can change the state of
    ; `mode()`. See vim/vim#9332.)
    (set-dot-repeat in1 nil n)
    (do-action target)
    (when (and can-traverse? (> (length targets) 1))
      (traversal-loop targets 1 {:use-no-labels? true}))  ; REDRAW (LOOP)
    (exit))

  (exec-user-autocmds :LeapPatternPost)

  ; Do this now - repeat can succeed, even if we fail this time.
  (update-repeat-state in1 ?in2)

  ; Get the sublist for ?in2, and work with that from here on (except if
  ; we've been given custom targets).
  (local targets* (if targets.sublists (. targets.sublists ?in2) targets))
  (when-not targets*
    ; (Note: at this point, ?in2 might only be nil if partial-pattern?
    ; is true; that case implies there are no sublists, and there _are_
    ; targets.)
    (set _state.errmsg (.. "not found: " in1 ?in2))
    (exit-early))

  (macro exit-with-action-on [idx]
    `(do (set-dot-repeat in1 ?in2 ,idx)
         (do-action (. targets* ,idx))
         (exit)))

  (if count
      (if (> count (length targets*))
          (exit-early)
          (exit-with-action-on count))

      (or (and (or repeating? _state.partial-pattern?)
               (or op-mode? (not directional?)))
          ; A sole, unlabeled target.
          (= (length targets*) 1))
      (exit-with-action-on 1))

  (when targets*.autojump?
    (set _state.curr-idx 1)
    (do-action (. targets* 1))
    (when (= (length targets*) 1)
      (exit)))

  ; This sets label states (i.e., modifies targets*) in each cycle.
  (local in-final (post-pattern-input-loop targets*))  ; REDRAW (LOOP)
  (when-not in-final
    (exit-early))

  ; Jump to the first match on the [rest of the] target list?
  (when (contains? spec-keys.next_target in-final)
    (if (and can-traverse? (> (length targets*) 1))
        (let [new-idx (inc _state.curr-idx)]
          (do-action (. targets* new-idx))
          (traversal-loop targets* new-idx  ; REDRAW (LOOP)
                          {:use-no-labels? (or no-labels-to-use?
                                               _state.partial-pattern?
                                               (not targets*.autojump?))})
          (exit))
        (if (not targets*.autojump?)
            (exit-with-action-on 1)
            (do (vim.fn.feedkeys in-final :i) (exit)))))

  (local (idx _) (get-target-with-active-label targets* in-final))
  (if idx
      (exit-with-action-on idx)
      (do (vim.fn.feedkeys in-final :i) (exit)))

  ; Do return something here, otherwise Fennel automatically inserts
  ; return statements into the tail-positioned if branches above,
  ; conflicting with the exit forms, and leading to compile error.
  nil)


; Init ///1


(fn init []
  (api.nvim_create_augroup "LeapDefault" {})

  ; The equivalence class table can be potentially huge - let's do this
  ; here, and not each time `leap` is called, at least for the defaults.
  (set opts.default.eq_class_of
       (-?> opts.default.equivalence_classes
            eq-classes->membership-lookup))

  (fn set-concealed-label []
    (set opts.concealed_label  ; undocumented, might be exposed in the future
         (if (and (= (vim.fn.has "nvim-0.9.1") 1)
                  (. (api.nvim_get_hl 0 {:name "LeapLabelPrimary"}) :bg)
                  (. (api.nvim_get_hl 0 {:name "LeapLabelSecondary"}) :bg))
             " "
             "\u{00b7}")))  ; middle dot (·)

  (api.nvim_create_autocmd "User"
                           {:pattern "LeapEnter"
                            :callback (fn [_] (set-concealed-label))
                            :group "LeapDefault"})

  (hl:init-highlight)
  ; Colorscheme plugins might clear out our highlight definitions,
  ; without defining their own, so we re-init the highlight on every
  ; change.
  (api.nvim_create_autocmd "ColorScheme"
                           {:callback (fn [_] (hl:init-highlight))
                            :group "LeapDefault"})

  (do
    (var saved-editor-opts {})
    (local temporary-editor-opts {:w.conceallevel 0
                                  :g.scrolloff 0
                                  :w.scrolloff 0
                                  :g.sidescrolloff 0
                                  :w.sidescrolloff 0
                                  :b.modeline false})  ; lightspeed#81

    (fn set-editor-opts [event t]
      (set saved-editor-opts {})
      (local wins (or event.data.args.target_windows
                      [(api.nvim_get_current_win)]))
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
                  (api.nvim_set_option name val))))))

    (fn restore-editor-opts []
      (each [key val (pairs saved-editor-opts)]
        (case key
          [:w win name] (api.nvim_win_set_option win name val)
          [:b buf name] (api.nvim_buf_set_option buf name val)
          name (api.nvim_set_option name val))))

    (api.nvim_create_autocmd "User"
                             {:pattern "LeapEnter"
                              :callback (fn [event]
                                          (set-editor-opts
                                            event temporary-editor-opts))
                              :group "LeapDefault"})

    (api.nvim_create_autocmd "User"
                             {:pattern "LeapLeave"
                              :callback (fn [_] (restore-editor-opts))
                              :group "LeapDefault"})))


(init)


; Module ///1

{: state  ; deprecated, not intended to be accessed from the outside anymore
 : leap}


; vim: foldmethod=marker foldmarker=///,//>
