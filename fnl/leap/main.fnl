; Imports & aliases ///1

(local hl (require "leap.highlight"))
(local opts (require "leap.opts"))

(local {: get-targets} (require "leap.search"))

(local {: inc
        : dec
        : clamp
        : echo
        : replace-keycodes
        : get-cursor-pos
        : push-cursor!}
       (require "leap.util"))

(local api vim.api)
(local empty? vim.tbl_isempty)
(local map vim.tbl_map)
(local {: abs : ceil : max : min : pow} math)

(local <bs> (replace-keycodes "<bs>"))
(local <cr> (replace-keycodes "<cr>"))
(local <esc> (replace-keycodes "<esc>"))


; Fennel utils ///1

(macro when-not [cond ...]
  `(when (not ,cond) ,...))


; Utils ///1

; Misc.

(fn user-forced-autojump? []
  (or (not opts.labels) (empty? opts.labels)))

(fn user-forced-noautojump? []
  (or (not opts.safe_labels) (empty? opts.safe_labels)))


; For `leap` only.

(fn echo-no-prev-search []
  (echo "no previous search"))

(fn echo-not-found [s]
  (echo (.. "not found: " s)))

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
(fn set-dot-repeat []
  ; Note: dot-repeatable (i.e. non-yank) operation is assumed, we're not
  ; checking it here.
  (let [op vim.v.operator
        cmd (replace-keycodes
              "<cmd>lua require'leap'.leap {['dot-repeat?'] = true}<cr>")
        ; We cannot getreg('.') at this point, since the change has not
        ; happened yet - therefore the below hack (thx Sneak).
        change (when (= op :c) (replace-keycodes "<c-r>.<esc>"))
        seq (.. op cmd (or change ""))]
    ; Using pcall, since vim-repeat might not be installed.
    ; Use the same register for the repeated operation.
    (pcall vim.fn.repeat#setreg seq vim.v.register)
    ; Note: we're feeding count inside the seq itself.
    (pcall vim.fn.repeat#set seq -1)))


; Input ///1

(fn get-input []
  (local (ok? ch) (pcall vim.fn.getcharstr))  ; pcall for <C-c>
  ; <esc> should cleanly exit anytime.
  (when (and ok? (not= ch <esc>)) ch))


; :help mbyte-keymap
; prompt = {:str <val>} (pass by reference hack)
(fn get-input-by-keymap [prompt]

  (fn echo-prompt [seq]
    (api.nvim_echo [[prompt.str] [(or seq "") :ErrorMsg]] false []))

  (fn accept [ch]
    (set prompt.str (.. prompt.str ch))
    (echo-prompt)
    ch)

  (fn loop [seq]
    (local |seq| (length (or seq "")))
    ; Arbitrary limit (`mapcheck` will continue to give back a candidate
    ; if the start of `seq` matches, need to cut the gibberish somewhere).
    (when (<= 1 |seq| 5)
      (echo-prompt seq)
      (let [rhs-candidate (vim.fn.mapcheck seq :l)
            rhs (vim.fn.maparg seq :l)]
        (if (= rhs-candidate "") (accept seq)   ; implies |seq|=1 (no recursion here)
            (= rhs rhs-candidate) (accept rhs)  ; seq is the longest LHS match
            (match (get-input)
              <bs> (loop (if (> |seq| 1) (seq:sub 1 (dec |seq|)) seq))
              <cr> (if (not= rhs "") (accept rhs)  ; <enter> can accept a shorter one
                       (= |seq| 1) (accept seq)
                       (loop seq))
              ch (loop (.. seq ch)))))))

  (if (not= vim.bo.iminsert 1) (get-input)  ; no keymap is active
      (do (echo-prompt)
          (match (loop (get-input))
            in in
            _ (echo "")))))


; Processing targets ///1

(fn populate-sublists [targets]
  "Populate a sub-table in `targets` containing lists that allow for
easy iteration through each subset of targets with a given successor
char separately."
  (set targets.sublists {})
  ; Setting a metatable to handle case insensitivity and user-defined
  ; character classes (in both cases: multiple keys -> one value).
  (fn ->common-key [k]
    (or (. opts.character_class_of k)  ; the common key will be the table itself
        (when-not opts.case_sensitive (k:lower))
        k))
  (setmetatable targets.sublists
    ; If the key is not found, try to get the sublist for a common key:
    ; the character class that k belongs to (if there is one), or the
    ; lowercased verison of k (if case insensivity is set).
    {:__index (fn [t k] (rawget t (->common-key k)))
    ; And it will not be found in the above cases, since we also
    ; redirect to the common keys when inserting a new sublist:
     :__newindex (fn [t k v] (rawset t (->common-key k) v))})
  ; Filling the sublists.
  (each [_ {:pair [_ ch2] &as target} (ipairs targets)]
    (when-not (. targets :sublists ch2)
      (tset targets :sublists ch2 []))
    (table.insert (. targets :sublists ch2) target)))


(fn set-autojump [sublist force-noautojump?]
  "Set a flag indicating whether we should autojump to the first target
if selecting `sublist` with the 2nd input character.
Note that there is no one-to-one correspondence between this flag and
the `label-set` field set by `attach-label-set`. No-autojump might be
forced implicitly, regardless of using safe labels."
  (tset sublist :autojump?
        (and (not (or force-noautojump?
                      (user-forced-noautojump?)))
             (or (user-forced-autojump?)
                 (>= (length opts.safe_labels)
                     (dec (length sublist)))))))  ; skipping the first if autojumping


(fn attach-label-set [sublist]
  "Set a field referencing the target label set to be used for
`sublist`. `set-autojump` should be called before this function."
  (tset sublist :label-set
        (if (user-forced-autojump?) opts.safe_labels
            (user-forced-noautojump?) opts.labels
            sublist.autojump? opts.safe_labels
            opts.labels)))


(fn set-sublist-attributes [sublist {: force-noautojump?}]
  (set-autojump sublist force-noautojump?)
  (attach-label-set sublist))


(fn set-labels [sublist]
  "Assign label characters to each target, by going through the sublists
one by one, using the given sublist's `label-set` repeated indefinitely.
Note: `label` is a once and for all fixed attribute - whether and how it
should actually be displayed depends on the `label-state` flag."
  (when (> (length sublist) 1)  ; else we jump unconditionally
    (local {: autojump? : label-set} sublist)
    (each [i target (ipairs sublist)]
      ; Skip labeling the first target if autojump is set.
      (local i* (if autojump? (dec i) i))
      (when (> i* 0)
        (tset target :label
              (match (% i* (length label-set))
                0 (. label-set (length label-set))
                n (. label-set n)))))))


(fn set-label-states [sublist {: group-offset}]
  (let [|label-set| (length sublist.label-set)
        offset (* group-offset |label-set|)
        primary-start (+ offset (if sublist.autojump? 2 1))
        primary-end (+ primary-start (dec |label-set|))
        secondary-start (inc primary-end)
        secondary-end (+ primary-end |label-set|)]
    (each [i target (ipairs sublist)]
      (when target.label
        (tset target :label-state
              (if (<= primary-start i primary-end) :active-primary
                  (<= secondary-start i secondary-end) :active-secondary
                  (> i secondary-end) :inactive))))))


(fn set-initial-label-states [targets]
  (each [_ sublist (pairs targets.sublists)]
    (set-label-states sublist {:group-offset 0})))


(fn inactivate-labels [target-list]
  (each [_ target (ipairs target-list)]
    (tset target :label-state :inactive)))


; Display ///1

; "Beacon" is an umbrella term for any kind of visual overlay tied to
; targets - in practice, either a label character, or a highlighting of
; the match itself. Technically an [offset virtualtext] tuple, where
; `offset` is counted from the match position, and `virtualtext` is a
; list of [text hl-group] tuples (the kind that `nvim_buf_set_extmark`
; expects).

; Handling multibyte characters.
(fn get-label-offset [target]
  (let [{:pair [ch1 ch2] : edge-pos?} target]
    (+ (ch1:len) (if edge-pos? 0 (ch2:len)))))


(fn set-beacon-for-labeled [target user-given-targets?]
  (let [offset (if user-given-targets? 0 (get-label-offset target))
        virttext (match target.label-state
                   :active-primary [[target.label hl.group.label-primary]]
                   :active-secondary [[target.label hl.group.label-secondary]]
                   :inactive (when-not opts.highlight_unlabeled
                               ; In this case, "no highlight" should
                               ; unambiguously signal "no further keystrokes
                               ; needed", so it is mandatory to show all labeled
                               ; positions in some way.
                               [[" " hl.group.label-secondary]]))]
    (tset target :beacon (when virttext [offset virttext]))))


(fn set-beacon-to-match-hl [target]
  (let [{:pair [ch1 ch2]} target
        virttext [[(.. ch1 ch2) hl.group.match]]]
    (tset target :beacon [0 virttext])))


(fn set-beacon-to-empty-label [target]
  (tset target :beacon 2 1 1 " "))


(fn resolve-conflicts [target-list]
  "After setting the beacons in a context-unaware manner, the following
conflicts can occur:
A: A label occupies a position that also belongs to an unlabeled match.
   Fix: Highlight the unlabeled match to make the user aware ('Label
   underneath!').
B: Two labels occupy the same position (this can occur at EOL or window
   edge, where labels need to be shifted left).
   Fix: Display an 'empty' label at the position."
  (let [unlabeled-match-positions {}  ; {"<buf> <win> <lnum> <col>" : target}
        label-positions {}]           ; - " -
    (each [i target (ipairs target-list)]
      (let [{:pos [lnum col] :pair [ch1 _] :wininfo {: bufnr : winid}} target]
        (macro make-key [col*]
          `(.. bufnr " " winid " " lnum " " ,col*))
        (if (or (not target.beacon)
                (and opts.highlight_unlabeled
                     (= (. target.beacon 2 1 2) hl.group.match)))
            ; Unlabeled target.
            (let [keys [(make-key col) (make-key (+ col (ch1:len)))]]
              (each [_ k (ipairs keys)]
                (match (. label-positions k)
                  ; A1 - current covers other's label
                  other (do (set other.beacon nil)
                            (set-beacon-to-match-hl target)))
                (tset unlabeled-match-positions k target)))
            ; Labeled target.
            (let [label-offset (. target.beacon 1)
                  k (make-key (+ col label-offset))]
              (match (. unlabeled-match-positions k)
                ; A2 - unlabeled covers current's label
                other (do (set target.beacon nil)
                          (set-beacon-to-match-hl other))
                _ (match (. label-positions k)
                    ; B - conflicting labels
                    other (do (set target.beacon nil)
                              (set-beacon-to-empty-label other))))
              (tset label-positions k target)))))))


; TODO: User-given targets cannot get a match highlight at the moment.
(fn set-beacons [target-list {: force-no-labels? : user-given-targets?}]
  (if (and force-no-labels? (not user-given-targets?))
      (each [_ target (ipairs target-list)]
        (set-beacon-to-match-hl target))
      (do (each [_ target (ipairs target-list)]
            (if target.label
                (set-beacon-for-labeled target user-given-targets?)

                (and opts.highlight_unlabeled (not user-given-targets?))
                (set-beacon-to-match-hl target)))
          ; User-given targets mean no two-phase processing, i.e., no conflicts.
          (when-not user-given-targets?
            (resolve-conflicts target-list)))))


(fn light-up-beacons [target-list ?start]
  (for [i (or ?start 1) (length target-list)]
    (local target (. target-list i))
    (match target.beacon
      [offset virttext]
      (let [[lnum col] (map dec target.pos)]  ; 1/1 -> 0/0 indexing
        (api.nvim_buf_set_extmark target.wininfo.bufnr hl.ns lnum (+ col offset)
                                  {:virt_text virttext
                                   :virt_text_pos "overlay"
                                   :hl_mode "combine"
                                   :priority hl.priority.label})))))


; Jump ///1

(fn cursor-before-eol? []
  (not= (vim.fn.search "\\_." "Wn") (vim.fn.line ".")))

(fn cursor-before-eof? []
  (and (= (vim.fn.line ".") (vim.fn.line "$"))
       (= (vim.fn.virtcol ".") (dec (vim.fn.virtcol "$")))))


(fn add-offset! [offset]
  (if (< offset 0) (push-cursor! :bwd)
      ; Safe first forward push for pre-EOL matches.
      (> offset 0) (do (when-not (cursor-before-eol?) (push-cursor! :fwd))
                       (when (> offset 1) (push-cursor! :fwd)))))


(fn push-beyond-eof! []
  (local saved vim.o.virtualedit)
  (set vim.o.virtualedit :onemore)
  ; Note: No need to undo this afterwards, the cursor will be
  ; moved to the end of the operated area anyway.
  (vim.cmd "norm! l")
  (api.nvim_create_autocmd
    [:CursorMoved :WinLeave :BufLeave :InsertEnter :CmdlineEnter :CmdwinEnter]
    {:callback #(set vim.o.virtualedit saved)
     :once true}))


(fn simulate-inclusive-op! [mode]
  "When applied after an exclusive motion (like setting the cursor via
the API), make the motion appear to behave as an inclusive one."
  (match (vim.fn.matchstr mode "^no\\zs.")  ; get forcing modifier
    ; In the normal case (no modifier), we should push the cursor
    ; forward. (The EOF edge case requires some hackery though.)
    "" (if (cursor-before-eof?) (push-beyond-eof!) (push-cursor! :fwd))
    ; We also want the `v` modifier to behave in the native way, that
    ; is, to toggle between inclusive/exclusive if applied to a charwise
    ; motion (:h o_v). As `v` will change our (technically) exclusive
    ; motion to inclusive, we should push the cursor back to undo that.
    :v (push-cursor! :bwd)
    ; Blockwise (<c-v>) itself makes the motion inclusive, do nothing in
    ; that case.
    ))


(fn force-matchparen-refresh []
  ; HACK: :DoMatchParen turns matchparen on simply by triggering
  ; CursorMoved events (see matchparen.vim). We can do the same, which
  ; is cleaner for us than calling :DoMatchParen directly, since that
  ; would wrap this in a `windo`, and might visit another buffer,
  ; breaking our visual selection (and thus also dot-repeat,
  ; apparently). (See :h visual-start, and the discussion at #38.)
  ; Programming against the API would be more robust of course, but in
  ; the unlikely case that the implementation details would change, this
  ; still cannot do any damage on our side if called with pcall (the
  ; feature just ceases to work then).
  (pcall api.nvim_exec_autocmds "CursorMoved" {:group "matchparen"})
  ; If vim-matchup is installed, it can similarly be forced to refresh
  ; by triggering a CursorMoved event. (The same caveats apply.)
  (pcall api.nvim_exec_autocmds "CursorMoved" {:group "matchup_matchparen"}))


(fn jump-to!* [pos {: winid : add-to-jumplist? : mode
                    : offset : backward? : inclusive-op?}]
  (local op-mode? (mode:match :o))
  ; Note: <C-o> will ignore this if the line has not changed (neovim#9874).
  (when add-to-jumplist? (vim.cmd "norm! m`"))
  (when (not= winid (vim.fn.win_getid))
    (api.nvim_set_current_win winid))
  (vim.fn.cursor pos)
  (when offset (add-offset! offset))
  ; Since Vim interprets our jump as an exclusive motion (:h exclusive),
  ; we need custom tweaks to behave as an inclusive one. (This is only
  ; relevant in the forward direction, as inclusiveness applies to the
  ; end of the selection.)
  (when (and op-mode? inclusive-op? (not backward?))
    (simulate-inclusive-op! mode))
  (when-not op-mode? (force-matchparen-refresh)))


; Main ///1

; State that is persisted between invocations.
(local state {:repeat {:in1 nil :in2 nil}
              :dot-repeat {:in1 nil :in2 nil :target-idx nil
                           :backward? nil :inclusive-op? nil :offset? nil}})


(fn leap [{: dot-repeat? : target-windows
           :targets user-given-targets :action user-given-action
           &as kwargs}]
  "Entry point for Leap motions."
  (let [{: backward? : inclusive-op? : offset} (if dot-repeat? state.dot-repeat
                                                   kwargs)
        directional? (not target-windows)
        ->wininfo #(. (vim.fn.getwininfo $) 1)
        ?target-windows (-?>> target-windows (map ->wininfo))
        current-window (->wininfo (vim.fn.win_getid))
        hl-affected-windows (let [t [current-window]]  ; cursor is always highlighted
                              (each [_ w (ipairs (or ?target-windows []))]
                                (table.insert t w))
                              t)
        ; Fill in the wininfo fields if not provided.
        _ (when (and user-given-targets (not (. user-given-targets 1 :wininfo)))
            (->> user-given-targets
                 (map (fn [t] (set t.wininfo current-window)))))
        ; We need to save the mode here, because the `:normal` command
        ; in `jump-to!*` can change the state. Related: vim/vim#9332.
        mode (. (api.nvim_get_mode) :mode)
        op-mode? (mode:match :o)
        change-op? (and op-mode? (= vim.v.operator :c))
        dot-repeatable-op? (and op-mode? directional? (not= vim.v.operator :y))
        ; In operator-pending mode, autojump would execute the operation
        ; without allowing us to select a labeled target.
        force-noautojump? (or user-given-action op-mode? (not directional?))
        prompt {:str ">"}  ; pass by reference hack (for input fns)
        spec-keys (setmetatable {} {:__index
                                    (fn [_ k] (replace-keycodes
                                                (. opts.special_keys k)))})]

    ; Helpers ///

    ; Note: One of the main purpose of these macros, besides wrapping
    ; cleanup stuff, is to enforce and encapsulate the requirement that
    ; tail-positioned "exit" forms in `match` blocks should always
    ; return nil. (Interop with side-effecting VimL functions can be
    ; dangerous, they might return 0 for example, like `feedkey`, and
    ; with that they can screw up Fennel match forms in a breeze,
    ; resulting in misterious bugs, so it's better to be paranoid.)
    (macro exit* [...]
      `(do (do ,...)
           (hl:cleanup hl-affected-windows)
           (exec-user-autocmds :LeapLeave)
           nil))

    ; Be sure not to call the macro twice accidentally,
    ; `handle-interrupted-change-op!` moves the cursor!
    (macro exit-early [...]
      `(do (when change-op? (handle-interrupted-change-op!))
           (exit* ,...)))

    (macro exit [...]
      `(do (when dot-repeatable-op? (set-dot-repeat))
           (exit* ,...)))

    (macro with-highlight-chores [...]
      `(do (hl:cleanup hl-affected-windows)
           (hl:apply-backdrop backward? ?target-windows)
           (do ,...)
           (hl:highlight-cursor)
           (vim.cmd :redraw)))

    (fn expand-to-user-defined-character-class [in]
      (match (. opts.character_class_of in)
        chars (.. "\\(" (table.concat chars "\\|") "\\)")))

    (fn prepare-pattern [in1 ?in2]
      (.. "\\V"
          (if opts.case_sensitive "\\C" "\\c")
          (or (expand-to-user-defined-character-class in1)
              (string.gsub in1 "\\" "\\\\"))  ; sole backslash needs to be escaped even for \V
          (or (expand-to-user-defined-character-class ?in2)
              ?in2
              "\\_.")))  ; match anything, including EOL

    (fn get-target-with-active-primary-label [sublist input]
      (var res nil)
      (each [idx {: label : label-state &as target} (ipairs sublist)
             :until (or res (= label-state :inactive))]
        (when (and (= label input) (= label-state :active-primary))
          (set res [idx target])))
      res)

    (fn update-state [state*]  ; a partial state table
      (when-not (or dot-repeat? user-given-targets)
        ; Do not short-circuit on regular repeat: we need to update the
        ; repeat state continuously if we have entered traversal mode
        ; after the first input (i.e., traversing all matches, not just
        ; a given sublist).
        (when state*.repeat
          (set state.repeat state*.repeat))
        (when (and state*.dot-repeat dot-repeatable-op?)
          (set state.dot-repeat
               (vim.tbl_extend :error
                               state*.dot-repeat
                               {: backward? : offset : inclusive-op?})))))

    (local jump-to!
      (do (var first-jump? true)  ; better be managed by the function itself
          (fn [target]
            (jump-to!* target.pos
                       {:winid target.wininfo.winid
                        :add-to-jumplist? first-jump?
                        : mode : offset : backward? : inclusive-op?})
            (set first-jump? false))))

    (fn traverse [targets idx {: force-no-labels?}]
      (when force-no-labels? (inactivate-labels targets))
      (set-beacons targets {: force-no-labels?
                            :user-given-targets? user-given-targets})
      (with-highlight-chores (light-up-beacons targets (inc idx)))
      (match (or (get-input) (exit))
        input
        (if (or (= input spec-keys.next_match) (= input spec-keys.prev_match))
            (let [new-idx (match input
                            spec-keys.next_match (min (inc idx) (length targets))
                            spec-keys.prev_match (max (dec idx) 1))]
              ; Need to save now - we might <esc> next time, exiting above.
              (update-state {:repeat {:in1 state.repeat.in1
                                      ; ?. -> user-given targets might not have :pair
                                      :in2 (?. targets new-idx :pair 2)}})
              (jump-to! (. targets new-idx))
              (traverse targets new-idx {: force-no-labels?}))
            ; We still want the labels (if there are) to function.
            (match (get-target-with-active-primary-label targets input)
              [_ target] (exit (jump-to! target))
              _ (exit (vim.fn.feedkeys input :i))))))

    (fn get-first-pattern-input []
      (with-highlight-chores (echo ""))  ; clean up the command line
      (match (or (get-input-by-keymap prompt) (exit-early))
        ; Here we can handle any other modifier key as "zeroth" input,
        ; if the need arises.
        spec-keys.repeat_search (if state.repeat.in1
                                    (values state.repeat.in1 state.repeat.in2)
                                    (exit-early (echo-no-prev-search)))
        in1 in1))

    (fn get-second-pattern-input [targets]
      (with-highlight-chores (light-up-beacons targets))
      (or (get-input-by-keymap prompt) (exit-early)))

    (fn get-full-pattern-input []
      (match (get-first-pattern-input)
        (in1 in2) (values in1 in2)
        (in1 nil) (match (get-input-by-keymap prompt)
                    in2 (values in1 in2)
                    _ (exit-early))))

    (fn post-pattern-input-loop [sublist]
      (fn loop [group-offset initial-invoc?]
        (doto sublist
          ; Do _not_ skip this on initial invocation - we might have skipped
          ; setting the initial label states in case of <enter>-repeat.
          (set-label-states {: group-offset})
          (set-beacons {:user-given-targets? user-given-targets}))
        (with-highlight-chores
          (light-up-beacons sublist (when sublist.autojump? 2)))
        (match (or (get-input) (exit-early))
          input
          (if (and (or (= input spec-keys.next_group)
                       (and (= input spec-keys.prev_group) (not initial-invoc?)))
                   (or (not sublist.autojump?)
                       ; If auto-jump has been set automatically (not forced),
                       ; it implies that there are no subsequent groups.
                       (user-forced-autojump?)))
              (let [|groups| (ceil (/ (length sublist) (length sublist.label-set)))
                    max-offset (dec |groups|)
                    inc/dec (if (= input spec-keys.next_group) inc dec)
                    new-offset (-> group-offset inc/dec (clamp 0 max-offset))]
                (loop new-offset false))
              input)))
      (loop 0 true))

    ; //> Helpers

    ; After all the stage-setting, here comes the main action you've all been
    ; waiting for:

    (exec-user-autocmds :LeapEnter)

    (local do-action (or user-given-action jump-to!))
    (match-try (if user-given-targets (values true true)
                   dot-repeat? (values state.dot-repeat.in1 state.dot-repeat.in2)
                   ; This might also return in2 too, if using the `repeat_search` key.
                   opts.highlight_ahead_of_time (get-first-pattern-input)  ; REDRAW
                   (get-full-pattern-input))  ; REDRAW
      (in1 ?in2) (or user-given-targets
                     (get-targets (prepare-pattern in1 ?in2)
                                  {: backward? :target-windows ?target-windows})
                     (exit-early (echo-not-found (.. in1 (or ?in2 "")))))
      targets (if dot-repeat? (match (. targets state.dot-repeat.target-idx)
                                target (exit (do-action target))
                                _ (exit-early))
                  (do
                    ; Prepare targets (set fixed attributes).
                    (if user-given-targets
                        (doto targets  ; = user-given-targets
                          (set-sublist-attributes {: force-noautojump?})
                          (set-labels))
                        (do (populate-sublists targets)
                            (each [_ sublist (pairs targets.sublists)]
                              (doto sublist
                                (set-sublist-attributes {: force-noautojump?})
                                (set-labels)))))
                    (or ?in2
                        (do (doto targets
                              (set-initial-label-states)
                              (set-beacons {}))
                            (get-second-pattern-input targets)))))  ; REDRAW
      in2 (if
            ; Jump to the very first match?
            (and directional? (= in2 spec-keys.next_match))
            (let [in2 (. targets 1 :pair 2)]
              (update-state {:repeat {: in1 : in2}})
              (do-action (. targets 1))
              (if (or (= (length targets) 1) op-mode? user-given-action)
                  (exit (update-state {:dot-repeat {: in1 : in2 :target-idx 1}}))
                  (traverse targets 1 {:force-no-labels? true})))  ; REDRAW (LOOP)

            (do
              (fn update-dot-repeat-state [target-idx]
                (update-state {:dot-repeat {: in1 : in2 : target-idx}}))

              (update-state {:repeat {: in1 : in2}})  ; save it here (repeat might succeed)

              (match (or user-given-targets
                         (. targets.sublists in2)
                         (exit-early (echo-not-found (.. in1 in2))))
                [only nil]
                (exit (update-dot-repeat-state 1)
                      (do-action only))

                sublist
                (do
                  (when sublist.autojump? (do-action (. sublist 1)))
                  ; Sets label states (modifies the sublist) in each cycle!
                  (match (post-pattern-input-loop sublist)  ; REDRAW (LOOP)
                    in-final
                    (if
                      ; Jump to the first match on the [rest of the] sublist?
                      (and directional? (= in-final spec-keys.next_match))
                      (let [new-idx (if sublist.autojump? 2 1)]
                        (do-action (. sublist new-idx))
                        (if (or op-mode? user-given-action)
                            (exit (update-dot-repeat-state 1))  ; implies no-autojump
                            (traverse sublist new-idx {:force-no-labels?
                                                       (not sublist.autojump?)})))  ; REDRAW (LOOP)

                      (match (get-target-with-active-primary-label sublist in-final)
                        [idx target]
                        (exit (update-dot-repeat-state idx)
                              (do-action target))

                        _ (if sublist.autojump?
                              (exit (vim.fn.feedkeys in-final :i))
                              (exit-early))))))))))))


; Handling editor options ///1

; TODO: For cross-window mode, we have to rethink how to handle
;       window-local options.
(local temporary-editor-opts {
                              ; :vim.wo.conceallevel 0
                              ; :vim.wo.scrolloff 0
                              ; :vim.wo.sidescrolloff 0
                              ; :vim.o.scrolloff 0
                              ; :vim.o.sidescrolloff 0
                              :vim.bo.modeline false})  ; lightspeed#81

(local saved-editor-opts {})

(fn save-editor-opts []
  (each [opt _ (pairs temporary-editor-opts)]
    (let [[_ scope name] (vim.split opt "." true)]
      (tset saved-editor-opts opt (. _G.vim scope name)))))

(fn set-editor-opts [opts]
  (each [opt val (pairs opts)]
    (let [[_ scope name] (vim.split opt "." true)]
      (tset _G.vim scope name val))))

(fn set-temporary-editor-opts []
  (set-editor-opts temporary-editor-opts))

(fn restore-editor-opts []
  (set-editor-opts saved-editor-opts))


; Init ///1

; Add a char -> char-class lookup table (the relevant one for us).
(tset opts :character_class_of
      (do (local t {})
          (each [_ cc (ipairs (or opts.character_classes []))]
            (local cc* (if (= (type cc) :string)
                           (icollect [char (cc:gmatch ".")] char)
                           cc))
            (each [_ char (ipairs cc*)]
              (tset t char cc*)))
          t))

(hl:init-highlight)

(api.nvim_create_augroup "LeapDefault" {})

; Colorscheme plugins might clear out our highlight definitions, without
; defining their own, so we re-init the highlight on every change.
(api.nvim_create_autocmd "ColorScheme"
                         {:callback #(hl:init-highlight)
                          :group "LeapDefault"})

(api.nvim_create_autocmd "User"
                         {:pattern "LeapEnter"
                          :callback #(do (save-editor-opts)
                                         (set-temporary-editor-opts))
                          :group "LeapDefault"})

(api.nvim_create_autocmd "User"
                         {:pattern "LeapLeave"
                          :callback restore-editor-opts
                          :group "LeapDefault"})


; Module ///1

{: state : leap}


; vim: foldmethod=marker foldmarker=///,//>
