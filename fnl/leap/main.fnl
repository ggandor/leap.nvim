; Imports & aliases ///1

(local hl (require "leap.highlight"))
(local opts (require "leap.opts"))

(local {: set-beacons
        : resolve-conflicts
        : light-up-beacons}
        (require "leap.beacons"))

(local {: clamp
        : echo
        : get-char
        : get-char-keymapped}
       (require "leap.util"))

(local api vim.api)
; Mind that lua string.lower/upper are ASCII only.
(local lower vim.fn.tolower)
(local upper vim.fn.toupper)

(local {: abs : ceil : floor : min} math)


; Macros ///1

(macro inc [x] `(+ ,x 1))
(macro dec [x] `(- ,x 1))
(macro when-not [cond ...] `(when (not ,cond) ,...))


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


; Equivalence classes

; Return a char->equivalence-class lookup table.
(fn to-membership-lookup [eqv-classes]
  (let [res {}]
    (each [_ cl (ipairs eqv-classes)]
      ; Do not use `vim.split`, it doesn't handle multibyte chars.
      (let [cl* (if (= (type cl) :string) (vim.fn.split cl "\\zs") cl)]
        (each [_ ch (ipairs cl*)]
          (set (. res ch) cl*))))
    res))

(fn get-equivalence-class [ch]
  (if opts.case_sensitive
      (. opts.eqv_class_of ch)
      (or (. opts.eqv_class_of (lower ch))
          (. opts.eqv_class_of (upper ch)))))

(fn get-representative-char [ch]
  ; We choose the first one from an equivalence class (arbitrary).
  (local ch* (or (?. (get-equivalence-class ch) 1) ch))
  (if opts.case_sensitive ch* (lower ch*)))


; Search pattern ///1

(fn char-list-to-collection [chars]
  (let [prepare #(case $
                   ; lua escape seqs (:h lua-literal)
                   "\a" "\\a"  "\b" "\\b"  "\f" "\\f"
                   "\n" "\\n"  "\r" "\\r"  "\t" "\\t"
                   "\v" "\\v"
                   "\\" "\\\\"
                   ; vim collection magic chars (:h /collection)
                   "]" "\\]"  "^" "\\^"  "-" "\\-"
                   ; else
                   ch ch)]
    (table.concat (vim.tbl_map prepare chars))))


(fn expand-to-eqv-collection [char]             ; <-- 'a'
  (-> (or (get-equivalence-class char) [char])  ; --> {'a','á','ä'}
      (char-list-to-collection)))               ; --> 'aáä'


; NOTE: If preview (two-step processing) is enabled, for any kind of
; input mapping (case-insensitivity, character classes, etc.) we need to
; tweak things in two different places:
;   1. For the first input, we can modify the search pattern itself.
;   2. The second input is only acquired once the search is done; for
;      that, we need to play with the sublist keys (see
;      `populate-sublists`).

(fn prepare-pattern [in1 ?in2 inputlen]
  "Transform user input to the appropriate search pattern."
  (let [prefix (.. "\\V"
                   (if opts.case_sensitive "\\C" "\\c")
                   ; Skip the current line in linewise modes.
                   (if (string.match (vim.fn.mode true) "V")
                       ; Hardcode the line number, we might set the
                       ; cursor before starting the search.
                       (let [cl (vim.fn.line ".")]
                         (.. "\\(\\%<" cl "l\\|\\%>" cl "l\\)"))
                       ""))
        in1* (expand-to-eqv-collection in1)
        pat1 (.. "\\[" in1* "]")
        ^pat1 (.. "\\[^" in1* "]")
        pat2 (and ?in2 (.. "\\[" (expand-to-eqv-collection ?in2) "]"))
        ; Two other convenience features:
        ; 1. Same-character pairs (==) match longer sequences (=====)
        ;    only at the beginning.
        ; 2. EOL can be matched by typing a newline alias twice.
        ;    (See also `populate-sublists`.)
        pattern
        (if pat2
            (if (not= pat1 pat2)
                ; x,y => trivial
                (.. pat1 pat2)
                ; x,x =>
                (.. ; match xx, but only once in xxx* (1)
                    "\\(\\^\\|" ^pat1 "\\)" "\\zs" pat1 pat1
                    ; if x might represent newline, add `$` as a
                    ; separate branch to the whole pattern (2)
                    (if (pat1:match "\\n") "\\|\\$" "")))

            ; x =>
            (.. ; match xx, but only once in xxx* (1)
                "\\(\\^\\|" ^pat1 "\\)" "\\zs" pat1 (if (= inputlen 1) "" pat1)
                "\\|"
                ; or match xY where Y=/=x or Y=$ (2)
                pat1 (if (= inputlen 1) "\\ze" "") "\\(" ^pat1 "\\|\\$\\)"))]
    (.. prefix "\\(" pattern "\\)")))


; Processing targets ///1

; SEE the comment above `prepare-pattern`.
(fn populate-sublists [targets]
  "Populate a sub-table in `targets` containing lists that allow for
easy iteration through each subset of targets with a given successor
char.

  xa  xb  xa  xc
{ T1, T2, T3, T4 } =>
{ T1, T2, T3, T4, sublists = { a = { T1, T3 }, b = { T2 }, c = { T4 } } }
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
         {:__index    (fn [self ch]
                        (rawget self (get-representative-char ch)))
          :__newindex (fn [self ch sublist]
                        (rawset self (get-representative-char ch) sublist))}))
  ; Filling the sublists.
  (each [_ {:chars [ch1 ch2] &as target} (ipairs targets)]
    ; Handle newline matches.
    (local key (if (or (= ch1 "") (= ch2 "")) "\n" ch2))
    (when-not (. targets.sublists key)
      (set (. targets.sublists key) []))
    (table.insert (. targets.sublists key) target)))


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
      "Set a flag indicating whether we can automatically jump to the
      first target, without having to select a label."
      (when (not= opts.safe_labels "")
        (set targets.autojump?
             (or (= opts.labels "")                                         ; forced
                 (>= (length opts.safe_labels) (dec (length targets)))))))  ; smart

    (fn attach-label-set [targets]
      ; Note that there is no one-to-one correspondence between the
      ; `autojump?` flag and this field. No-autojump might be forced
      ; implicitly, regardless of using safe labels.
      (set targets.label-set (if (= opts.labels "") opts.safe_labels
                                 (= opts.safe_labels "") opts.labels
                                 targets.autojump? opts.safe_labels
                                 opts.labels)))

    (fn set-labels [targets]
      "Assign a label to each target, by repeating the given label set
      indefinitely, and register the number of the label group the
      target is part of.
      Note that these are once-and-for-all fixed attributes, regardless
      of the actual UI state ('beacons')."
      (local {: autojump? :label-set labels} targets)
      (local |labels| (length labels))
      (var skipped 0)
      (for [i* (if autojump? 0 1) (length targets)]
        (local target (. targets i*))
        (when target
          (local i (- i* skipped))
          (if target.offscreen? (set skipped (inc skipped))
              (case (% i |labels|)
                0 (do
                    (set target.label (labels:sub |labels| |labels|))
                    (set target.group (floor (/ i |labels|))))
                n (do
                    (set target.label (labels:sub n n))
                    (set target.group (inc (floor (/ i |labels|))))))))))

    (fn [targets force-noautojump? multi-window?]
      (when-not (or force-noautojump?
                    (and multi-window? (not (all-in-the-same-window? targets)))
                    (first-target-covers-label-of-second? targets))
        (set-autojump targets))
      (attach-label-set targets)
      (set-labels targets))))


(fn normalize-directional-indexes [targets]
  "Like: -7 -4 -2  1  3  7 => -3 -2 -1  1  2  3"
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


; Main ///1

; State that is persisted between invocations.
(local state {:repeat {:in1 nil
                       :in2 nil
                       :pattern nil
                       ; For when wanting to repeat in relative direction
                       ; (for "outside" use only).
                       :backward nil
                       :inclusive nil
                       :offset nil
                       :inputlen nil
                       :opts nil}
              :dot_repeat {:targets nil
                           :pattern nil
                           :in1 nil
                           :in2 nil
                           :target_idx nil
                           :backward nil
                           :inclusive nil
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
  ; Handle deprecated field names.
  ; Note: Keep the legacy fields too, do not break user autocommands.
  (when kwargs.target_windows
    (set kwargs.windows kwargs.target_windows))
  (when kwargs.inclusive_op
    (set kwargs.inclusive kwargs.inclusive_op))
  (local {:repeat invoked-repeat?
          :dot_repeat invoked-dot-repeat?
          : windows
          :opts user-given-opts
          :targets user-given-targets
          :action user-given-action
          :traversal action-can-traverse?}
         kwargs)
  (local {:backward backward?}
         (if invoked-dot-repeat? state.dot_repeat
             kwargs))
  (local {:inclusive inclusive?
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

  ; Force the label lists into strings (table support is deprecated).
  (each [_ t (ipairs [:default :current_call])]
    (each [_ k (ipairs [:labels :safe_labels])]
      (when (= (type (. opts t k)) :table)
        (set (. opts t k)
             (table.concat (. opts t k))))))

  (local directional? (not windows))
  (local no-labels-to-use? (and (= opts.labels "")
                                (= opts.safe_labels "")))

  (when (and (not directional?) no-labels-to-use?)
    (echo "no labels to use")
    (lua :return))
  (when (and windows (= (length windows) 0))
    (echo "no targetable windows")
    (lua :return))

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
                                  (= inputlen 0)
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
                              v (vim.tbl_map
                                  vim.keycode
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

  (fn redraw [callback]
    (exec-user-autocmds :LeapRedraw)
    ; Should be called after `LeapRedraw` - the idea is that callbacks
    ; clean up after themselves on that event (next time, that is).
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
    (redraw)
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
      (redraw #(light-up-beacons targets)))
    (get-char-keymapped st.prompt))

  (fn get-full-pattern-input []
    (case (get-first-pattern-input)
      (in1 in2) (values in1 in2)
      (in1 nil) (if (= inputlen 1)
                    in1
                    (case (get-char-keymapped st.prompt)
                      in2 (values in1 in2)))))

  ; Get targets

  (fn get-targets [pattern in1 ?in2]
    (let [errmsg (if in1 (.. "not found: " in1 (or ?in2 "")) "no targets")
          search (require :leap.search)
          kwargs {: backward? : windows : offset : op-mode? : inputlen}
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
            (local wininfo (. (vim.fn.getwininfo (api.nvim_get_current_win)) 1))
            (each [_ t (ipairs targets*)]
              (set t.wininfo wininfo)))
          targets*)))

  ; Sets `autojump` and `label_set` attributes for the target list, plus
  ; `label` and `group` attributes for each individual target.
  (fn prepare-labeled-targets* [targets]
    (let [force-noautojump? (and (not action-can-traverse?)
                                 (or
                                   ; No jump, doing sg else.
                                   user-given-action
                                   ; Should be able to select our target.
                                   (and op-mode? (> (length targets) 1))))
          multi-window? (and windows (> (length windows) 1))]
      (prepare-labeled-targets targets force-noautojump? multi-window?)))

  ; Repeat

  (local repeat-state {:offset kwargs.offset
                       :backward kwargs.backward
                       :inclusive kwargs.inclusive
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

  ; Jump

  (local jump-to!
    (do
      (var first-jump? true)
      (fn [target]
        (local jump (require "leap.jump"))
        (jump.jump-to! target.pos
                       {:win target.wininfo.winid
                        :add-to-jumplist? first-jump?
                        : mode
                        : offset
                        :backward? (or backward?
                                       (and target.idx (< target.idx 0)))
                        : inclusive?})
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
      (redraw
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
    (if (contains? keys.next_target in)
        (min (inc idx) (length targets))

        (contains? keys.prev_target in)
        ; Wrap around backwards.
        (if (<= idx 1) (length targets) (dec idx))))


  (fn traverse [targets start-idx {: use-no-labels?}]

    (fn on-first-invoc []
      (if use-no-labels?
          (each [_ t (ipairs targets)]
            (set t.label nil))

          ; Remove all the subsequent label groups if needed.
          (not= opts.safe_labels "")
          (let [last-labeled (inc (length opts.safe_labels))]  ; skipped the first
            (for [i (inc last-labeled) (length targets)]
              (set (. targets i :label) nil)
              (set (. targets i :beacon) nil)))))

    (fn display []
      (set-beacons targets {:group-offset st.group-offset :phase st.phase
                            : use-no-labels?})
      (local (start end) (get-highlighted-idx-range targets use-no-labels?))
      (redraw
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
                          (pattern*
                            (if in1 (prepare-pattern in1 ?in2 st.inputlen) "")
                            [in1 ?in2])

                          (prepare-pattern in1 ?in2 st.inputlen))]
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
    (normalize-directional-indexes targets*))  ; for dot-repeat

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
    (let [wins (or (. state.args :windows)
                   (. state.args :target_windows)  ; deprecated
                   [(api.nvim_get_current_win)])]
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
