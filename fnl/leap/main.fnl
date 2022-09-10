; Imports & aliases ///1

(local hl (require "leap.highlight"))
(local opts (require "leap.opts"))

(local {: inc
        : dec
        : clamp
        : echo
        : replace-keycodes
        : get-cursor-pos
        : push-cursor!
        : get-input
        : get-input-by-keymap}
       (require "leap.util"))

(local api vim.api)
(local contains? vim.tbl_contains)
(local empty? vim.tbl_isempty)
(local map vim.tbl_map)
(local {: abs : ceil : max : min : pow} math)


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


; Processing targets ///1

(fn set-autojump [targets force-noautojump?]
  "Set a flag indicating whether we should autojump to the first target,
without having to select a label.
Note that there is no one-to-one correspondence between this flag and
the `label-set` field set by `attach-label-set`. No-autojump might be
forced implicitly, regardless of using safe labels."
  (tset targets :autojump?
        (and (not (or force-noautojump? (empty? opts.safe_labels)))
             (or (empty? opts.labels)
                 ; Smart mode.
                 (>= (length opts.safe_labels)
                     (dec (length targets)))))))  ; skipping the first if autojumping


(fn attach-label-set [targets]
  "Set a field referencing the label set to be used for `targets`.
NOTE: `set-autojump` should be called BEFORE this function."
  ; (assert (not (and (empty? opts.labels) (empty? opts.safe_labels))))
  (tset targets :label-set
        (if (empty? opts.labels) opts.safe_labels
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
        (tset target :label
              (match (% i* (length label-set))
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
        (tset target :label-state
              (if (<= primary-start i primary-end) :active-primary
                  (<= secondary-start i secondary-end) :active-secondary
                  (> i secondary-end) :inactive))))))


(fn inactivate-labels [targets]
  (each [_ target (ipairs targets)]
    (tset target :label-state :inactive)))


; Two-step processing

(fn populate-sublists [targets]
  "Populate a sub-table in `targets` containing lists that allow for
easy iteration through each subset of targets with a given successor
char separately.

  at  ar  at  at  ar  ar  an  ar
{ t1, t2, t3, t4, t5, t6, t7, t8 }
-->
{
  t1, t2, t3, t4, t5, t6, t7, t8,
  sublists = {
    ['t'] = { t1, t3, t4 },
    ['r'] = { t2, t5, t6, t8 },
    ['n'] = { t7 }
  },
}
"
  ; Setting a metatable to handle case insensitivity and equivalence
  ; classes (in both cases: multiple keys -> one value).
  ; If `k` is not found, try to get a sublist belonging to some common
  ; key: the equivalence class that `k` belongs to (if there is one),
  ; or, if case insensivity is set, the lowercased verison of `k`.
  ; (And in the above cases, `k` will not be found, since we also
  ; redirect to the common keys when inserting a new sublist.)
  (tset targets :sublists
        (setmetatable {}
          (let [->common-key #(or (. opts.eq_class_of $)
                                  (when-not opts.case_sensitive ($:lower))
                                  $)]
            {:__index (fn [t k] (rawget t (->common-key k)))
             :__newindex (fn [t k v] (rawset t (->common-key k) v))})))
  ; Filling the sublists.
  (each [_ {:chars [_ ch2] &as target} (ipairs targets)]
    (when-not (. targets.sublists ch2)
      (tset targets.sublists ch2 []))
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
  (let [{:chars [ch1 ch2] : edge-pos?} target]
    (+ (ch1:len) (if edge-pos? 0 (ch2:len)))))


(fn set-beacon-for-labeled [target {: user-given-targets? : aot?}]
  (let [offset (if aot? (get-label-offset target) 0)  ; user-given-targets implies (not aot)
        pad (if (or user-given-targets? aot?) "" " ")
        text (.. target.label pad)
        virttext (match target.label-state
                   :selected [[text hl.group.label-selected]]
                   :active-primary [[text hl.group.label-primary]]
                   :active-secondary [[text hl.group.label-secondary]]
                   :inactive (if (and aot? (not opts.highlight_unlabeled))
                                 ; In this case, "no highlight" should
                                 ; unambiguously signal "no further keystrokes
                                 ; needed", so it is mandatory to show all labeled
                                 ; positions in some way.
                                 [[(.. " " pad) hl.group.label-secondary]]
                                 :else nil))]
    (tset target :beacon (when virttext [offset virttext]))))


(fn set-beacon-to-match-hl [target]
  (tset target :beacon
        [0 [[(table.concat target.chars) hl.group.match]]]))


(fn set-beacon-to-empty-label [target]
  (tset target :beacon 2 1 1 " "))


(fn resolve-conflicts [targets]
  "After setting the beacons in a context-unaware manner, the following
conflicts can occur:
(A) An unlabeled match covers a label.
--> Fix: Highlight the unlabeled match to make the user aware ('Label
underneath!').
(B) Two labels on top of each other. (Possible at EOL or window edge,
where labels need to be shifted left).
--> Fix: Display an 'empty' label at the position."
  (let [unlabeled-match-positions {}  ; {"<buf> <win> <lnum> <col>": target}
        label-positions {}]           ; { - " - }
    (each [_ target (ipairs targets)]
      (local {:pos [lnum col] :chars [ch1 _] :wininfo {: bufnr : winid}} target)
      (macro ->key [col*] `(.. bufnr " " winid " " lnum " " ,col*))
      (if target.label
          (when target.beacon  ; can be nil if the label is inactive
            (let [label-offset (. target.beacon 1)
                  key (->key (+ col label-offset))]
              (match (. unlabeled-match-positions key)
                ; A1 - other covers current's label
                other (do (set target.beacon nil)
                          (set-beacon-to-match-hl other))
                _ (match (. label-positions key)
                    ; B - conflicting labels
                    other (do (set target.beacon nil)
                              (set-beacon-to-empty-label other))))
              (tset label-positions key target)))
          (each [_ key (ipairs [(->key col) (->key (+ col (ch1:len)))])]
            (match (. label-positions key)
              ; A2 - current covers other's label
              other (do (set other.beacon nil)
                        (set-beacon-to-match-hl target)))
            (tset unlabeled-match-positions key target))))))


(fn set-beacons [targets {: no-labels? : user-given-targets? : aot?}]
  (if (and no-labels? (. targets 1 :chars))  ; user-given targets might not have :chars
      (each [_ target (ipairs targets)]
        (set-beacon-to-match-hl target))
      (do (each [_ target (ipairs targets)]
            (if target.label
                (set-beacon-for-labeled target {: user-given-targets? : aot?})

                (and aot? opts.highlight_unlabeled)
                (set-beacon-to-match-hl target)))
          (when aot?
            (resolve-conflicts targets)))))


(fn light-up-beacons [targets ?start]
  (for [i (or ?start 1) (length targets)]
    (local target (. targets i))
    (match target.beacon
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
              :repeat {:in1 nil :in2 nil}
              :dot_repeat {:in1 nil :in2 nil
                           :target_idx nil
                           :backward nil
                           :inclusive_op nil
                           :offset nil}
              :saved_editor_opts {}})


(fn leap [kwargs]
  "Entry point for Leap motions."
  (let [{:dot_repeat dot-repeat?
         :target_windows target-windows
         :opts user-given-opts
         :targets user-given-targets
         :action user-given-action
         :multiselect multi-select?}
        kwargs
        {:backward backward?
         :inclusive_op inclusive-op?
         : offset}
        (if dot-repeat? state.dot_repeat kwargs)
        _ (set state.args kwargs)
        _ (set opts.current_call (or user-given-opts {}))
        id->wininfo #(. (vim.fn.getwininfo $) 1)
        curr-winid (vim.fn.win_getid)
        _ (set state.source_window curr-winid)
        curr-win (id->wininfo curr-winid)
        ?target-windows (-?>> target-windows (map id->wininfo))
        hl-affected-windows (icollect [_ w (ipairs (or ?target-windows []))
                                       &into [curr-win]]  ; cursor is always highlighted
                              w)
        directional? (not target-windows)
        ; We need to save the mode here, because the `:normal` command
        ; in `jump.jump-to!` can change the state. See vim/vim#9332.
        mode (. (api.nvim_get_mode) :mode)
        op-mode? (mode:match :o)
        change-op? (and op-mode? (= vim.v.operator :c))
        dot-repeatable-op? (and op-mode? directional? (not= vim.v.operator :y))
        no-labels? (and (empty? opts.labels) (empty? opts.safe_labels))
        count (if (not directional?) nil
                  (= vim.v.count 0) (if (and op-mode? no-labels?) 1 nil)
                  vim.v.count)
        force-noautojump? (or op-mode?            ; should be able to select a target
                              multi-select?       ; likewise
                              (not directional?)  ; potentially disorienting
                              user-given-action)  ; no jump, doing sg else
        max-aot-targets (or opts.max_aot_targets math.huge)
        user-given-targets? user-given-targets
        prompt {:str ">"}  ; pass by reference hack (for input fns)
        spec-keys (setmetatable {} {:__index (fn [_ k]
                                               (-?> (. opts.special_keys k)
                                                    replace-keycodes))})]

    (when (and target-windows (empty? target-windows))
      (echo "no targetable windows")
      (lua :return))
    (when (and (not directional?) no-labels?)
      (echo "no labels to use")
      (lua :return))

    ; Show beacons (labels & match highlights) ahead of time,
    ; right after the first input?
    (var aot? (not (or (= max-aot-targets 0)
                       count
                       no-labels?
                       multi-select?
                       user-given-targets?)))

    ; Helpers ///

    (fn echo-not-found [s] (echo (.. "not found: " s)))

    ; Note: One of the main purpose of these macros, besides wrapping
    ; cleanup stuff, is to enforce and encapsulate the requirement that
    ; tail-positioned "exit" forms in `match` blocks should always
    ; return nil. (Interop with side-effecting VimL functions can be
    ; dangerous, they might return 0 for example, like `feedkey`, and
    ; with that they can screw up Fennel match forms in a breeze,
    ; resulting in misterious bugs, so it's better to be paranoid.)
    (macro exit [...]
      `(do (do ,...)
           (hl:cleanup hl-affected-windows)
           (exec-user-autocmds :LeapLeave)
           nil))

    ; Be sure not to call the macro twice accidentally,
    ; `handle-interrupted-change-op!` moves the cursor!
    (macro exit-early [...]
      `(do (when change-op? (handle-interrupted-change-op!))
           (exit ,...)))

    (macro with-highlight-chores [...]
      `(do (hl:cleanup hl-affected-windows)
           (when-not count
             (hl:apply-backdrop backward? ?target-windows))
           (do ,...)
           (hl:highlight-cursor)
           (vim.cmd :redraw)))

   (fn get-user-given-targets []
     (match (match user-given-targets [&as tbl] tbl func (func))
       ts (when-not (empty? ts)
            ; Fill in the wininfo fields if not provided.
            (when-not (. ts 1 :wininfo)
              (each [_ t (ipairs ts)]
                (set t.wininfo curr-win)))
            ts)))

    (fn expand-to-equivalence-class [in]  ; <-- "b"
      (match (. opts.eq_class_of in)
        chars  ; {"a","b","c"}
        ; `vim.fn.search` cannot interpret actual newline (LF) chars in
        ; the regex pattern, we need to insert them as raw \ + n.
        ; Backslash itself might appear in the class, needs to be escaped.
        (let [chars* (map #(match $ "\n" "\\n" "\\" "\\\\" _ $) chars)]
          (.. "\\(" (table.concat chars* "\\|") "\\)"))))  ; --> "\(a\|b\|c\)"

    ; NOTE: If two-step processing is ebabled (AOT beacons), for any
    ; kind of input mapping (case-insensitivity, character classes,
    ; etc.) we need to tweak things in two different places:
    ;   1. For the first input, we modify the search pattern itself
    ;      (here).
    ;   2. For the second input, we need to play with the sublist keys
    ;      (see `populate-sublists`).
    (fn prepare-pattern [in1 ?in2]
      (.. "\\V"
          (if opts.case_sensitive "\\C" "\\c")
          (or (expand-to-equivalence-class in1)
              (in1:gsub "\\" "\\\\"))  ; sole backslash needs to be escaped even for \V
          (or (expand-to-equivalence-class ?in2)
              ?in2
              "\\_.")))  ; match anything, including EOL

    (fn get-target-with-active-primary-label [sublist input]
      (var res nil)
      (each [idx {: label : label-state &as target} (ipairs sublist)
             &until (or res (= label-state :inactive))]
        (when (and (= label input) (= label-state :active-primary))
          (set res [idx target])))
      res)

    (fn update-repeat-state [state*]
      (when-not user-given-targets?
        (set state.repeat state*)))

    (fn set-dot-repeat [in1 in2 target_idx]
      (when (and dot-repeatable-op?
                 (not (or dot-repeat? user-given-targets?)))
        (set state.dot_repeat {: in1 : in2 : target_idx
                               ; Mind the naming conventions and the
                               ; conversions back and forth.
                               :backward backward? : offset
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

    (fn get-first-pattern-input []
      (with-highlight-chores (echo ""))  ; clean up the command line
      (match (or (get-input-by-keymap prompt) (exit-early))
        ; Here we can handle any other modifier key as "zeroth" input,
        ; if the need arises.
        spec-keys.repeat_search
        (if state.repeat.in1
            (do (set aot? false)
                (values state.repeat.in1 state.repeat.in2))
            (exit-early (echo "no previous search")))

        in1 in1))

    (fn get-second-pattern-input [targets]
      (when (<= (length targets) max-aot-targets)
        (with-highlight-chores (light-up-beacons targets)))
      (or (get-input-by-keymap prompt) (exit-early)))

    (fn get-full-pattern-input []
      (match (get-first-pattern-input)
        (in1 in2) (values in1 in2)
        (in1 nil) (match (get-input-by-keymap prompt)
                    in2 (values in1 in2)
                    _ (exit-early))))

    (fn post-pattern-input-loop [targets ?group-offset first-invoc?]
      (fn loop [group-offset first-invoc?]
        ; Do _not_ skip this on initial invocation - we might have skipped
        ; setting the initial label states if using `spec-keys.repeat_search`.
        (when targets.label-set (set-label-states targets {: group-offset}))
        (set-beacons targets {: aot? : no-labels? : user-given-targets?})
        (with-highlight-chores
          (light-up-beacons targets (when targets.autojump? 2)))
        (match (or (get-input) (exit-early))
          input
          (if (and (or (= input spec-keys.next_group)
                       (and (= input spec-keys.prev_group) (not first-invoc?)))
                   ; Autojump, if it is not forced (by empty `labels`),
                   ; implies that there are no subsequent groups.
                   (or (not targets.autojump?) (empty? opts.labels)))
              (let [inc/dec (if (= input spec-keys.next_group) inc dec)
                    |groups| (ceil (/ (length targets) (length targets.label-set)))
                    max-offset (dec |groups|)
                    group-offset* (-> group-offset inc/dec (clamp 0 max-offset))]
                (loop group-offset* false))
              (values input group-offset))))
      (loop (or ?group-offset 0) (or (= nil first-invoc?) first-invoc?)))

    (local multi-select-loop
      (let [selection []]
        (var group-offset 0)
        (var first-invoc? true)
        (fn loop [targets]
          (match (post-pattern-input-loop targets group-offset first-invoc?)
            spec-keys.multi_accept
            (if (next selection) selection  ; accept selection
                (loop targets))

            spec-keys.multi_revert
            (do (-?> (table.remove selection)
                     (tset :label-state nil))
                (loop targets))

            (in group-offset*)
            (do (set group-offset group-offset*)
                (set first-invoc? false)
                (match (get-target-with-active-primary-label targets in)
                  [_ target] (when-not (contains? selection target)
                                 (table.insert selection target)
                                 (tset target :label-state :selected)))
                (loop targets))))))

    (fn traversal-loop [targets idx {: no-labels?}]
      (when no-labels? (inactivate-labels targets))
      (set-beacons targets {: no-labels? : aot? : user-given-targets?})
      (with-highlight-chores
        (light-up-beacons targets (inc idx)))
      (match (or (get-input) (exit))
        input
        (match (if (= input spec-keys.next_match) (min (inc idx) (length targets))
                   (= input spec-keys.prev_match) (max (dec idx) 1))
          new-idx (do
                    ; We need to update the repeat state continuously, in case
                    ; we have entered traversal mode after the first input
                    ; (i.e., traversing all matches, not just a given sublist)!
                    (update-repeat-state {:in1 state.repeat.in1
                                          ; ?. -> user-given targets might not have :chars
                                          :in2 (?. targets new-idx :chars 2)})
                    (jump-to! (. targets new-idx))
                    (traversal-loop targets new-idx {: no-labels?}))
          ; We still want the labels (if there are) to function.
          _ (match (get-target-with-active-primary-label targets input)
              [_ target] (exit (jump-to! target))
              _ (exit (vim.fn.feedkeys input :i))))))

    ; //> Helpers

    (local do-action (or user-given-action jump-to!))

    ; After all the stage-setting, here comes the main action you've all been
    ; waiting for:

    (exec-user-autocmds :LeapEnter)

    (match-try (if dot-repeat? (values state.dot_repeat.in1 state.dot_repeat.in2)
                   user-given-targets? (values true true)
                   ; This might also return in2 too, if using the `repeat_search` key.
                   aot? (get-first-pattern-input)  ; REDRAW
                   (get-full-pattern-input))  ; REDRAW
      (in1 ?in2) (if user-given-targets? (or (get-user-given-targets)
                                             (exit-early (echo "no targets")))
                     (or (let [search (require "leap.search")
                               pattern (prepare-pattern in1 ?in2)
                               kwargs {: backward? :target-windows ?target-windows}]
                           (search.get-targets pattern kwargs))
                         (exit-early (echo-not-found (.. in1 (or ?in2 ""))))))
      targets (if dot-repeat? (match (. targets state.dot_repeat.target_idx)
                                target (exit (do-action target))
                                _ (exit-early))
                  (let [prepare-targets #(doto $
                                           (set-autojump force-noautojump?)
                                           (attach-label-set)
                                           (set-labels multi-select?))]
                    (if ?in2
                        (if no-labels? (tset targets :autojump? true)
                            (prepare-targets targets))
                        (do (populate-sublists targets)
                            (each [_ sublist (pairs targets.sublists)]
                              (prepare-targets sublist))))
                    (when (> (length targets) max-aot-targets)
                      (set aot? false))
                    (or ?in2
                        (do (doto targets
                              (set-initial-label-states)
                              (set-beacons {: aot?}))
                            (get-second-pattern-input targets)))))  ; REDRAW
      in2 (if
            ; Jump to the very first match?
            (and (= in2 spec-keys.next_match) directional?)
            (let [in2 (. targets 1 :chars 2)]
              (update-repeat-state {: in1 : in2})
              (do-action (. targets 1))
              (if (or (= (length targets) 1) op-mode? user-given-action)
                  (exit (set-dot-repeat in1 in2 1))
                  (traversal-loop targets 1 {:no-labels? true})))  ; REDRAW (LOOP)
            (do
              (update-repeat-state {: in1 : in2})  ; do this now - repeat can succeed
              (match (or (if targets.sublists (. targets.sublists in2) targets)
                         (exit-early (echo-not-found (.. in1 in2))))
                targets*
                (if multi-select? (match (multi-select-loop targets*)
                                    targets** (exit (with-highlight-chores
                                                      (light-up-beacons targets**))
                                                    (do-action targets**)))
                    (let [exit-with-action (fn [idx]
                                             (exit (set-dot-repeat in1 in2 idx)
                                                   (do-action (. targets* idx))))
                          |targets*| (length targets*)]
                      (if (= |targets*| 1) (exit-with-action 1)
                          count (if (<= count |targets*|) (exit-with-action count)
                                    (exit-early))
                          (do
                            (when targets*.autojump?
                              (do-action (. targets* 1)))
                            ; This sets label states (i.e., modifies targets*) in each cycle.
                            (match (post-pattern-input-loop targets*)  ; REDRAW (LOOP)
                              in-final
                              (if
                                ; Jump to the first match on the [rest of the] target list?
                                (and (= in-final spec-keys.next_match) directional?)
                                (if (or op-mode? user-given-action) (exit-with-action 1)  ; (no autojump)
                                    (let [new-idx (if targets*.autojump? 2 1)]
                                      (do-action (. targets* new-idx))
                                      (when (and (empty? opts.labels) (not (empty? opts.safe_labels)))
                                        (for [i (+ (length opts.safe_labels) 2) |targets*|]
                                          (tset targets* i :label nil)
                                          (tset targets* i :beacon nil)))
                                      (traversal-loop targets* new-idx  ; REDRAW (LOOP)
                                                      {:no-labels?
                                                       (or no-labels? (not targets*.autojump?))})))
                                (match (get-target-with-active-primary-label targets* in-final)
                                  [idx _] (exit-with-action idx)
                                  _ (if targets*.autojump? (exit (vim.fn.feedkeys in-final :i))
                                        (exit-early)))))))))))))))


; Init ///1

; Add a char->char-class lookup table (the relevant one for us).
(tset opts :eq_class_of
      (do (local res {})
          (each [_ eqcl (ipairs (or opts.equivalence_classes []))]
            (local eqcl* (if (= (type eqcl) :table) eqcl
                             (icollect [ch (eqcl:gmatch ".")] ch)))
            (each [_ ch (ipairs eqcl*)]
              (tset res ch eqcl*)))
          res))


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
      (match scope
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
    (match key
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
