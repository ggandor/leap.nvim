; Imports & aliases ///1

(local hl (require "leap.highlight"))
(local opts (require "leap.opts"))

(local {: inc
        : dec
        : clamp
        : echo
        : replace-keycodes
        : get-eq-class-of
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

(fn exec-user-autocmds [pattern]
  (api.nvim_exec_autocmds "User" {: pattern :modeline false}))


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
  ; Note: dot-repeatable (i.e. non-yank) operation is assumed, we're not
  ; checking it here.
  (let [op vim.v.operator
        cmd (replace-keycodes
              "<cmd>lua require'leap'.leap { dot_repeat = true }<cr>")
        ; We cannot getreg('.') at this point, since the change has not
        ; happened yet - therefore the below hack (thx Sneak).
        change (when (= op :c) (replace-keycodes "<c-r>.<esc>"))
        seq (.. op cmd (or change ""))]
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


(fn set-labels [targets multi-select?]
  "Assign label characters to each target, using the given label set
repeated indefinitely.
Note: `label` is a once and for all fixed attribute - whether and how it
should actually be displayed depends on the `label-state` flag."
  (when (or (> (length targets) 1) multi-select?)  ; else we jump unconditionally
    (local {: autojump? : label-set} targets)
    (each [i target (ipairs targets)]
      ; Skip labeling the first target if autojump is set.
      (local i* (if autojump? (dec i) i))
      (when (> i* 0)
        (set target.label (case (% i* (length label-set))
                            0 (. label-set (length label-set))
                            n (. label-set n)))))))


(fn set-label-states [targets {: group-offset}]
  (let [|label-set| (length targets.label-set)
        offset (* group-offset |label-set|)
        primary-start (+ offset (if targets.autojump? 2 1))
        primary-end (+ primary-start (dec |label-set|))
        secondary-start (inc primary-end)
        secondary-end (+ primary-end |label-set|)]
    (each [i target (ipairs targets)]
      (when (and target.label (not= target.label-state :selected))
        (set target.label-state
             (if (<= primary-start i primary-end) :active-primary
                 (<= secondary-start i secondary-end) :active-secondary
                 (> i secondary-end) :inactive))))))


; Two-step processing

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
  ; Setting a metatable to handle case insensitivity and equivalence
  ; classes (in both cases: multiple keys -> one value).
  ; If `ch` is not found, try to get a sublist belonging to some common
  ; key: the equivalence class that `ch` belongs to (if there is one),
  ; or, if case insensivity is set, the lowercased verison of `ch`.
  ; (And in the above cases, `ch` will not be found, since we also
  ; redirect to the common keys when inserting a new sublist.)
  (set targets.sublists
       (setmetatable {}
         {:__index (fn [self ch] (rawget self (->representative-char ch)))
          :__newindex (fn [self ch sublist]
                        (rawset self (->representative-char ch) sublist))}))
  ; Filling the sublists.
  (each [_ {:chars [_ ch2] &as target} (ipairs targets)]
    ; "\n"-s after empty lines don't have a `ch2`. Still, we put these
    ; targets into the sublist for "\n", so that they can be targeted
    ; with <key><key> (as if there would be another "\n" after them).
    (local ch2 (or ch2 "\n"))
    (when-not (. targets.sublists ch2) (tset targets.sublists ch2 []))
    (table.insert (. targets.sublists ch2) target)))


(fn set-initial-label-states [targets]
  (each [_ sublist (pairs targets.sublists)]
    (set-label-states sublist {:group-offset 0})))


; Display ///1

; "Beacon" is an umbrella term for any kind of visual overlay tied to
; targets - in practice, either a label character, or a highlighting of
; the match itself. Technically an [offset virtualtext] tuple, where
; `offset` is counted from the match position, and `virtualtext` is a
; list of [text hl-group] tuples (the kind that `nvim_buf_set_extmark`
; expects).


; Handling multibyte characters.
(fn get-label-offset [target]
  (let [{:chars [ch1 ch2]} target]
    (if target.empty-line? 0
        target.edge-pos? (ch1:len)
        (+ (ch1:len) (ch2:len)))))


(fn set-beacon-for-labeled [target {: user-given-targets? : aot?}]
  (let [offset (if aot? (get-label-offset target) 0)  ; user-given-targets implies (not aot)
        pad (if (or user-given-targets? aot?) "" " ")
        label (or (. opts.substitute_chars target.label) target.label)
        text (.. label pad)
        virttext (case target.label-state
                   :selected [[text hl.group.label-selected]]
                   :active-primary [[text hl.group.label-primary]]
                   :active-secondary [[text hl.group.label-secondary]]
                   :inactive (if (and aot? (not opts.highlight_unlabeled_phase_one_targets))
                                 ; In this case, "no highlight" should
                                 ; unambiguously signal "no further keystrokes
                                 ; needed", so it is mandatory to show all labeled
                                 ; positions in some way.
                                 [[(.. " " pad) hl.group.label-secondary]]
                                 :else nil))]
    (set target.beacon (when virttext [offset virttext]))))


(fn set-beacon-to-match-hl [target]
  (local virttext (->> target.chars
                       (map #(or (. opts.substitute_chars $) $))
                       table.concat))
  (set target.beacon [0 [[virttext hl.group.match]]]))


(fn set-beacon-to-empty-label [target]
  (tset target :beacon 2 1 1 " "))


(fn resolve-conflicts [targets]
  "After setting the beacons in a context-unaware manner, the following
conflicts can occur:

(A) An unlabeled match covers a label.
    Fix: Force highlighting of the unlabeled match, to make the user
    aware ('Label underneath!').

(B) An unlabeled match (X) touches the label of another match (Y)
    (possible at EOL or window edge, where labels need to be shifted
    left). This is unacceptable - it looks like the label is for X:
          y1 ylabel |
       x1 x2        |
       -----------------
       -3 -2 -1     edge-pos

    Fix: Force highlighting of the unlabeled match, to avoid confusion.

(C) Two labels on top of each other. (Possible if one of the
    labels is shifted, like above.)
    Fix: Display an 'empty' label at the position.

Note: The three cases are mutually exclusive. Case A implies the label
is not shifted (if there is a match after us, we cannot be at the edge).
And if we have a target with a shifted label, then the conflicting other
is either labeled (C) or not (B).
"
  ; Tables to help us check potential conflicts (we'll be filling them
  ; as we go).
  ; { "<bufnr> <winid> <lnum> <col>" = <target> }
  (let [pos-unlabeled-match {}
        pos-labeled-match {}
        pos-label {}]
    ; Note: A1-A2, B1-B2, C1-C2 are all necessary, as we do only one
    ; traversal run, and we don't assume anything about the direction
    ; and the ordering; we always resolve the conflict at the second
    ; target - at that point, the first one has already been registered
    ; as a potential source of conflict.
    (each [_ target (ipairs targets)]
      (when-not target.empty-line?
        (local {: bufnr : winid} target.wininfo)
        (local [lnum col] target.pos)
        (local col-ch2 (+ col (string.len (. target.chars 1))))
        (macro ->key [col*]
          `(.. bufnr " " winid " " lnum " " ,col*))
        ; Beacon can be nil (if label-state is inactive).
        (if (and target.label target.beacon)
            (let [label-offset (. target.beacon 1)
                  col-label (+ col label-offset)
                  shifted-label? (= col-label col-ch2)]
              ; ------------------------------
              ; (A1)
              ;   [a][b][L][-]  --> nil       | current
              ;   [-][-][a][c]  --> match-hl  | other
              ;          ^                    | column to check
              ; or
              ;   [a][a][L]     --> nil
              ;   [-][a][b]     --> match-hl
              ;          ^
              (case (. pos-unlabeled-match (->key col-label))
                other (do (set target.beacon nil)
                          (set-beacon-to-match-hl other)))
              ; ------------------------------
              ; (B1)
              ;   [-][a][L]|
              ;   [a][a][-]|    --> match-hl
              ;       ^
              (when shifted-label?
                (case (. pos-unlabeled-match (->key col))
                  other (set-beacon-to-match-hl other)))
              ; ------------------------------
              ; (C)
              ;   [-][a][L]|    --> nil
              ;   [a][a][L]|    --> empty
              ;          ^
              ; or
              ;   [a][a][L]|    --> nil
              ;   [-][a][L]|    --> empty
              ;          ^
              (case (. pos-label (->key col-label))
                other (do (set target.beacon nil)
                          (set-beacon-to-empty-label other)))
              ; ------------------------------
              ; NOTE: We should register the label position _after_
              ; checking case C, as we don't want to literally chase our
              ; own tail, i.e., our own label.
              (tset pos-label (->key col-label) target)
              (tset pos-labeled-match (->key col) target)
              (when-not shifted-label?
                (tset pos-labeled-match (->key col-ch2) target)))

            (not target.label)
            (do
              (each [_ key (ipairs [(->key col) (->key col-ch2)])]
                (tset pos-unlabeled-match key target)
                ; ------------------------------
                ; (A2)
                ;   [-][-][a][b]  --> match-hl
                ;   [a][c][L][-]  --> nil
                ;          ^
                ; and
                ;   [-][a][b]     --> match-hl
                ;   [a][a][L]     --> nil
                ;          ^
                (case (. pos-label key)
                  other (do (set other.beacon nil)
                            (set-beacon-to-match-hl target))))
              ; ------------------------------
              ; (B2)
              ;   [a][a][-]|      --> match-hl
              ;   [-][a][L]|
              ;          ^
              (local col-after (+ col-ch2 (string.len (. target :chars 2))))
              (case (. pos-label (->key col-after))
                other (set-beacon-to-match-hl target))))))))


(fn set-beacons [targets {: no-labels? : user-given-targets? : aot?}]
  (if (and no-labels? (. targets 1 :chars))  ; user-given targets might not have :chars
      (each [_ target (ipairs targets)]
        (set-beacon-to-match-hl target))
      (do (each [_ target (ipairs targets)]
            (if target.label
                (set-beacon-for-labeled target {: user-given-targets? : aot?})

                (and aot? opts.highlight_unlabeled_phase_one_targets)
                (set-beacon-to-match-hl target)))
          (when aot?
            (resolve-conflicts targets)))))


(fn light-up-beacons [targets ?start ?end]
  (for [i (or ?start 1) (or ?end (length targets))]
    (local target (. targets i))
    (case target.beacon
      [offset virttext]
      (let [bufnr target.wininfo.bufnr
            [lnum col] (map dec target.pos)  ; 1/1 -> 0/0 indexing
            id (api.nvim_buf_set_extmark bufnr hl.ns lnum (+ col offset)
                                         {:virt_text virttext
                                          :virt_text_pos "overlay"
                                          :hl_mode "combine"
                                          :priority hl.priority.label})]
        ; Register each newly set extmark in a table, so that we can
        ; delete them one by one, without needing any further contextual
        ; information. This is relevant if we process user-given targets
        ; and have no knowledge about the boundaries of the search area.
        (table.insert hl.extmarks [bufnr id])))))


; Main ///1

; State that is persisted between invocations.
(local state {:args nil  ; arguments passed to the current call
              :source_window nil
              :repeat {:in1 nil
                       :in2 nil}
              :dot_repeat {:in1 nil
                           :in2 nil
                           :target_idx nil
                           :backward nil
                           :inclusive_op nil
                           :offset nil}
              :saved_editor_opts {}})


(fn leap [kwargs]
  "Entry point for Leap motions."
  (local {:dot_repeat dot-repeat?
          :target_windows target-windows
          :opts user-given-opts
          :targets user-given-targets
          :action user-given-action
          :multiselect multi-select?}
         kwargs)
  (local {:backward backward?
          : match-xxx*-at-the-end?
          :inclusive_op inclusive-op?
          : offset}
         (if dot-repeat? state.dot_repeat kwargs))

  ; Do this before accessing `opts`.
  (set opts.current_call (or user-given-opts {}))
  (set opts.current_call.eq_class_of
       (-?> opts.current_call.equivalence_classes
            eq-classes->membership-lookup))

  (local directional? (not target-windows))
  (local empty-label-lists? (and (empty? opts.labels)
                                 (empty? opts.safe_labels)))

  (when (and (not directional?) empty-label-lists?)
    (echo "no labels to use")
    (lua :return))
  (when (and target-windows (empty? target-windows))
    (echo "no targetable windows")
    (lua :return))
  (when (and multi-select? (not user-given-action))
    (echo "error: multiselect mode requires user-provided `action` callback")
    (lua :return))

  (local curr-winid (vim.fn.win_getid))

  (set state.args kwargs)
  (set state.source_window curr-winid)

  (local ?target-windows target-windows)
  (local hl-affected-windows (icollect [_ winid (ipairs (or ?target-windows []))
                                        &into [curr-winid]]  ; cursor is always highlighted
                               winid))
  ; We need to save the mode here, because the `:normal` command in
  ; `jump.jump-to!` can change the state. See vim/vim#9332.
  (local mode (. (api.nvim_get_mode) :mode))
  (local op-mode? (mode:match :o))
  (local change-op? (and op-mode? (= vim.v.operator :c)))
  (local dot-repeatable-op? (and op-mode? directional? (not= vim.v.operator :y)))
  (local count (if (not directional?) nil
                   (= vim.v.count 0) (if (and op-mode? empty-label-lists?) 1 nil)
                   vim.v.count))
  (local max-phase-one-targets (or opts.max_phase_one_targets math.huge))
  (local user-given-targets? user-given-targets)
  (local prompt {:str ">"})  ; pass by reference hack (for input fns)

  (local spec-keys (do (fn __index [_ k]
                         (case (. opts.special_keys k)
                           v (if (or (= k :next_target) (= k :prev_target))
                                 ; Force those into a table.
                                 (case (type v)
                                   :table (icollect [_ str (ipairs v)]
                                            (replace-keycodes str))
                                   :string [(replace-keycodes v)])
                                 (replace-keycodes v))))
                       (setmetatable {} {: __index})))

  ; Ephemeral state (current call).
  (local vars {:aot?
               ; Show beacons (labels & match highlights) ahead of time,
               ; right after the first input?
               (not (or (= max-phase-one-targets 0)
                        empty-label-lists?
                        multi-select?
                        user-given-targets?))
               :curr-idx 0  ; for traversal mode
               :errmsg nil})

  ; Macros

  (macro exit []
    `(do (hl:cleanup hl-affected-windows)
         (exec-user-autocmds :LeapLeave)
         (lua :return)))

  ; Be sure not to call the macro twice accidentally,
  ; `handle-interrupted-change-op!` moves the cursor!
  (macro exit-early []
    `(do (when change-op? (handle-interrupted-change-op!))
         (when vars.errmsg (echo vars.errmsg))
         (exit)))

  (macro with-highlight-chores [...]
    `(do (hl:cleanup hl-affected-windows)
         (when-not count
           (hl:apply-backdrop backward? ?target-windows))
         (do ,...)
         (hl:highlight-cursor)
         (vim.cmd :redraw)))

  ; Helper functions ///

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
        (set vars.errmsg "no targets")))

  (fn expand-to-equivalence-class [in]               ; <-- "b"
    (local chars (get-eq-class-of in))               ; --> ?{"a","b","c"}
    (when chars
      ; (1) `vim.fn.search` cannot interpret actual newline chars in
      ;     the regex pattern, we need to insert them as raw \ + n.
      ; (2) '\' itself might appear in the class, needs to be escaped.
      (each [i ch (ipairs chars)]
        (if (= ch "\n") (tset chars i "\\n")
            (= ch "\\") (tset chars i "\\\\")))
      (.. "\\(" (table.concat chars "\\|") "\\)")))  ; --> "\(a\|b\|c\)"

  ; NOTE: If two-step processing is ebabled (AOT beacons), for any
  ; kind of input mapping (case-insensitivity, character classes,
  ; etc.) we need to tweak things in two different places:
  ;   1. For the first input, we modify the search pattern itself
  ;      (here).
  ;   2. For the second input, we need to play with the sublist keys
  ;      (see `populate-sublists`).
  (fn prepare-pattern [in1 ?in2]
    (let [pat1 (or (expand-to-equivalence-class in1)
                   ; Sole '\' needs to be escaped even for \V.
                   (in1:gsub "\\" "\\\\"))
          pat2 (or (and ?in2 (expand-to-equivalence-class ?in2))
                   ?in2
                   "\\_.")  ; match anything, including EOL
          potential-\n\n? (and (pat1:match "\\n")
                               (or (not ?in2) (pat2:match "\\n")))
          ; If \n\n is a possible sequence to appear, add |^\n to the
          ; pattern, to make our convenience feature - targeting empty
          ; lines by typing the newline alias twice - work.
          ; This hack is always necessary for single-step processing,
          ; when we already have the full pattern (this includes
          ; repeating the previous search), but also for two-step
          ; processing, in the special case of targeting the very last
          ; line in the file (normally, `search.get-targets` takes care
          ; of this situation, but the pattern `\n\_.` does not match
          ; `\n$` if it's on the last line).
          pat (if potential-\n\n?
                  (.. pat1 pat2 "\\|\\^\\n")
                  (.. pat1 pat2))]
      (.. "\\V" (if opts.case_sensitive "\\C" "\\c") pat)))

  (fn get-targets [in1 ?in2]
    (let [search (require :leap.search)
          pattern (prepare-pattern in1 ?in2)
          kwargs {: backward? : match-xxx*-at-the-end?
                  :target-windows ?target-windows}
          targets (search.get-targets pattern kwargs)]
      (or targets (set vars.errmsg (.. "not found: " in1 (or ?in2 ""))))))

  (fn prepare-targets [targets]
    (let [funny-edge-case?
          ; <-----  backward search
          ;   ab    target #1
          ; abl     target #2 (labeled)
          ;   ^     auto-jump would move the cursor here (covering the label)
          (and backward?
               (case targets
                 [{:pos [l1 c1]} {:pos [l2 c2]}]
                 (and (= l1 l2) (= c1 (+ c2 2)))))
          force-noautojump? (or op-mode?             ; should be able to select a target
                                multi-select?        ; likewise
                                (not directional?)   ; potentially disorienting
                                user-given-action    ; no jump, doing sg else
                                funny-edge-case?)]   ; see above
      (doto targets
        (set-autojump force-noautojump?)
        (attach-label-set)
        (set-labels multi-select?))))

  (fn get-target-with-active-primary-label [sublist input]
    (var res [])
    (each [idx {: label : label-state &as target} (ipairs sublist)
           &until (or (next res) (= label-state :inactive))]
      (when (and (= label input) (= label-state :active-primary))
        (set res [idx target])))
    res)

  (fn update-repeat-state [state*]
    (when-not user-given-targets?
      (set state.repeat state*)))

  (fn set-dot-repeat [in1 in2 target_idx]
    (when (and dot-repeatable-op?
               (not (or dot-repeat? (= (type user-given-targets) :table))))
      (set state.dot_repeat {:in1 (and (not user-given-targets) in1)
                             :in2 (and (not user-given-targets) in2)
                             :callback user-given-targets
                             : target_idx
                             : offset
                             : match-xxx*-at-the-end?
                             ; Mind the naming conventions.
                             :backward backward?
                             :inclusive_op inclusive-op?})
      (set-dot-repeat*)))

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

  ; When traversing without labels, keep highlighting the same one group
  ; of targets, and do not shift until reaching the end of the group - it
  ; is less disorienting if the "snake" does not move continuously, on
  ; every jump.
  (fn get-number-of-highlighted-targets []
    (case opts.max_highlighted_traversal_targets
      group-size
      ; Assumption: being here means we are after an autojump, and
      ; started highlighting from the 2nd target (no `count`).
      ; Thus, we can use `vars.curr-idx` as the reference, instead of
      ; some separate counter (but only because of the above).
      (let [consumed (% (dec vars.curr-idx) group-size)
            remaining (- group-size consumed)]
        ; Switch just before the whole group gets eaten up.
        (if (= remaining 1) (inc group-size)
            (= remaining 0) group-size
            remaining))))

  (fn get-highlighted-idx-range [targets no-labels?]
    (if (and no-labels? (= opts.max_highlighted_traversal_targets 0))
        (values 0 -1)  ; empty range
        (let [start (inc vars.curr-idx)
              end (when no-labels?
                    (-?> (get-number-of-highlighted-targets)
                         (+ (dec start))
                         (min (length targets))))]
          (values start end))))

  (fn get-first-pattern-input []
    (with-highlight-chores (echo ""))  ; clean up the command line
    (case (get-input-by-keymap prompt)
      ; Here we can handle any other modifier key as "zeroth" input,
      ; if the need arises.
      (where (= spec-keys.repeat_search))
      (if state.repeat.in1
          (do (set vars.aot? false)
              (values state.repeat.in1 state.repeat.in2))
          (set vars.errmsg "no previous search"))

      in1 in1))

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


  (fn post-pattern-input-loop [targets ?group-offset first-invoc?]
    (local |groups| (if (not targets.label-set) 0
                        (ceil (/ (length targets)
                                 (length targets.label-set)))))
    ; ---
    (fn display [group-offset]
      (local no-labels? empty-label-lists?)
      ; Do _not_ skip this on initial invocation - we might have skipped
      ; setting the initial label states if using `spec-keys.repeat_search`.
      (when targets.label-set
        (set-label-states targets {: group-offset}))
      (set-beacons targets {:aot? vars.aot? : no-labels? : user-given-targets?})
      (with-highlight-chores
        (local (start end) (get-highlighted-idx-range targets no-labels?))
        (light-up-beacons targets start end)))
    ; ---
    (fn loop [group-offset first-invoc?]
      (display group-offset)
      (case (get-input)
        input
        (let [switch-group? (and (> |groups| 1)
                                 (or (= input spec-keys.next_group)
                                     (and (= input spec-keys.prev_group)
                                          (not first-invoc?))))]
          (if switch-group?
              (let [inc/dec (if (= input spec-keys.next_group) inc dec)
                    max-offset (dec |groups|)
                    group-offset* (-> group-offset inc/dec (clamp 0 max-offset))]
                (loop group-offset* false))
              ; Otherwise return with input.
              (values input group-offset)))))
    ; ---
    (loop (or ?group-offset 0) (not= first-invoc? false)))


  (local multi-select-loop
    (do
      (local selection [])
      (var group-offset 0)
      (var first-invoc? true)
      ; ---
      (fn loop [targets]
        (case (post-pattern-input-loop targets group-offset first-invoc?)
          (where (= spec-keys.multi_accept))
          (if (not (empty? selection))
              selection
              (loop targets))

          (where (= spec-keys.multi_revert))
          (do (-?> (table.remove selection)
                   (tset :label-state nil))
              (loop targets))

          (in group-offset*)
          (do (set group-offset group-offset*)
              (set first-invoc? false)
              (case (get-target-with-active-primary-label targets in)
                [_ target] (when-not (contains? selection target)
                             (table.insert selection target)
                             (set target.label-state :selected)))
              (loop targets))))))


  (fn traversal-loop [targets start-idx {: no-labels?}]
    ; ---
    (fn on-first-invoc []
      (if no-labels?
          (each [_ t (ipairs targets)]
            (set t.label-state :inactive))

          (not (empty? opts.safe_labels))
          ; Remove all the subsequent label groups if needed.
          (let [last-labeled (inc (length opts.safe_labels))]  ; skipped the first
            (for [i (inc last-labeled) (length targets)]
              (doto (. targets i) (tset :label nil) (tset :beacon nil))))))
    ; ---
    (fn display []
      (set-beacons targets {: no-labels? :aot? vars.aot? : user-given-targets?})
      (with-highlight-chores
        (local (start end) (get-highlighted-idx-range targets no-labels?))
        (light-up-beacons targets start end)))
    ; ---
    (fn get-new-idx [idx in]
      (if (contains? spec-keys.next_target in) (min (inc idx) (length targets))
          (contains? spec-keys.prev_target in) (max (dec idx) 1)))
    ; ---
    (fn loop [idx first-invoc?]
      (when first-invoc? (on-first-invoc))
      (set vars.curr-idx idx)  ; `display` depends on it!
      (display)
      (case (get-input)
        in
        (case (get-new-idx idx in)
          new-idx (do (case (?. targets new-idx :chars 2)  ; user-given targets might not have `chars`
                        ; We need to do this, in case we have entered
                        ; traversal mode after the first input (i.e.,
                        ; traversing all matches, not just a given sublist)!
                        ch2 (set state.repeat.in2 ch2))
                      (jump-to! (. targets new-idx))
                      (loop new-idx false))
            ; We still want the labels (if there are) to function.
          _ (case (get-target-with-active-primary-label targets in)
              [_ target] (jump-to! target)
              _ (vim.fn.feedkeys in :i)))))
    ; ---
    (loop start-idx true))

  ; //> Helper functions END


  (local do-action (or user-given-action jump-to!))

  ; After all the stage-setting, here comes the main action you've all been
  ; waiting for:

  (exec-user-autocmds :LeapEnter)

  (local (in1 ?in2) (if dot-repeat? (if state.dot_repeat.callback
                                        (values true true)
                                        (values state.dot_repeat.in1
                                                state.dot_repeat.in2))
                        user-given-targets? (values true true)
                        ; This might also return in2 too, if using the
                        ; `repeat_search` key.
                        vars.aot? (get-first-pattern-input)  ; REDRAW
                        (get-full-pattern-input)))  ; REDRAW
  (when-not in1
    (exit-early))

  (local targets (if (and dot-repeat? state.dot_repeat.callback)
                     (get-user-given-targets state.dot_repeat.callback)

                     user-given-targets?
                     (get-user-given-targets user-given-targets)

                     (get-targets in1 ?in2)))
  (when-not targets
    (exit-early))

  (when dot-repeat?
    (case (. targets state.dot_repeat.target_idx)
      target (do (do-action target) (exit))
      _ (exit-early)))

  (if ?in2
      (if empty-label-lists?
          (set targets.autojump? true)
          (prepare-targets targets))
      (do
        (when (> (length targets) max-phase-one-targets)
          (set vars.aot? false))
        (populate-sublists targets)
        (each [_ sublist (pairs targets.sublists)]
           (prepare-targets sublist))
        (doto targets
          (set-initial-label-states)
          (set-beacons {:aot? vars.aot?}))))
  (local in2 (or ?in2 (get-second-pattern-input targets)))  ; REDRAW
  (when-not in2
    (exit-early))

  ; Jump eagerly to the count-th match (without giving the full pattern)?
  (when (= in2 spec-keys.next_phase_one_target)
    (local n (or count 1))
    (local target (. targets n))
    (when-not target
      (exit-early))
    (local in2* (. target :chars 2))
    (update-repeat-state {: in1 :in2 in2*})
    (do-action target)
    (local can-traverse? (and (not op-mode?) (not user-given-action)
                              directional? (> (length targets) 1)))
    (if can-traverse?
        (traversal-loop targets n {:no-labels? true})  ; REDRAW (LOOP)
        (set-dot-repeat in1 in2* n))
    (exit))

  ; Do this now - repeat can succeed, even if we fail this time.
  (update-repeat-state {: in1 : in2})

  ; Get the sublist for in2, and work with that from here on (except if
  ; we've been given custom targets).
  (local targets* (if targets.sublists (. targets.sublists in2) targets))
  (when-not targets*
    (set vars.errmsg (.. "not found: " in1 in2))
    (exit-early))

  (when multi-select?
    (case (multi-select-loop targets*)
      targets**
      ; The action callback should expect a list in this case.
      ; It might also get user input, so keep the beacons highlighted.
      (do (with-highlight-chores (light-up-beacons targets**))
          (do-action targets**)))
    (exit))

  (macro exit-with-action-on [idx]
    `(do (set-dot-repeat in1 in2 ,idx)
         (do-action (. targets* ,idx))
         (exit)))

  (if count (if (> count (length targets*))
                (exit-early)
                (exit-with-action-on count))
      (= (length targets*) 1) (exit-with-action-on 1))

  (when targets*.autojump?
    (set vars.curr-idx 1)
    (do-action (. targets* 1)))

  ; This sets label states (i.e., modifies targets*) in each cycle.
  (local in-final (post-pattern-input-loop targets*))  ; REDRAW (LOOP)
  (when-not in-final
    (exit-early))

  ; Jump to the first match on the [rest of the] target list?
  (when (contains? spec-keys.next_target in-final)
    (local can-traverse? (and (not op-mode?) (not user-given-action)
                              directional?))
    (if can-traverse?
        (let [new-idx (inc vars.curr-idx)]
          (do-action (. targets* new-idx))
          (traversal-loop targets* new-idx  ; REDRAW (LOOP)
                          {:no-labels? (or empty-label-lists?
                                           (not targets*.autojump?))})
          (exit))
        (exit-with-action-on 1)))  ; (implied no autojump)

  (local [idx _] (get-target-with-active-primary-label targets* in-final))
  (if idx (exit-with-action-on idx)
      targets*.autojump? (do (vim.fn.feedkeys in-final :i)
                             (exit))
      (exit-early))

  ; Do return something here, otherwise Fennel automatically inserts
  ; return statements into the tail-positioned if branches above,
  ; conflicting with the exit forms, and leading to compile error.
  nil)


; Init ///1

; The equivalence class table can be potentially huge - let's do this
; here, and not each time `leap` is called, at least for the defaults.
(set opts.default.eq_class_of (-?> opts.default.equivalence_classes
                                   eq-classes->membership-lookup))


(api.nvim_create_augroup "LeapDefault" {})


; Highlight

(hl:init-highlight)
; Colorscheme plugins might clear out our highlight definitions, without
; defining their own, so we re-init the highlight on every change.
(api.nvim_create_autocmd "ColorScheme" {:callback #(hl:init-highlight)
                                        :group "LeapDefault"})


; Editor options

(fn set-editor-opts [t]
  (set state.saved_editor_opts {})
  (local wins (or state.args.target_windows [state.source_window]))
  (each [opt val (pairs t)]
    (let [[scope name] (vim.split opt "." {:plain true})]
      (case scope
        :w (each [_ w (ipairs wins)]
             (->> (api.nvim_win_get_option w name)
                  (tset state.saved_editor_opts [:w w name]))
             (api.nvim_win_set_option w name val))
        :b (each [_ w (ipairs wins)]
             (local b (api.nvim_win_get_buf w))
             (->> (api.nvim_buf_get_option b name)
                  (tset state.saved_editor_opts [:b b name]))
             (api.nvim_buf_set_option b name val))
        _ (do (->> (api.nvim_get_option name)
                   (tset state.saved_editor_opts name))
              (api.nvim_set_option name val))))))


(fn restore-editor-opts []
  (each [key val (pairs state.saved_editor_opts)]
    (case key
      [:w w name] (api.nvim_win_set_option w name val)
      [:b b name] (api.nvim_buf_set_option b name val)
      name (api.nvim_set_option name val))))


(local temporary-editor-opts {:w.conceallevel 0
                              :g.scrolloff 0
                              :w.scrolloff 0
                              :g.sidescrolloff 0
                              :w.sidescrolloff 0
                              :b.modeline false})  ; lightspeed#81

(api.nvim_create_autocmd "User" {:pattern "LeapEnter"
                                 :callback #(set-editor-opts temporary-editor-opts)
                                 :group "LeapDefault"})

(api.nvim_create_autocmd "User" {:pattern "LeapLeave"
                                 :callback #(restore-editor-opts)
                                 :group "LeapDefault"})


; Module ///1

{: state : leap}


; vim: foldmethod=marker foldmarker=///,//>
