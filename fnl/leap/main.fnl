; Imports & aliases ///1

(local hl (require "leap.highlight"))
(local opts (require "leap.opts"))

(local api vim.api)
(local empty? vim.tbl_isempty)
(local filter vim.tbl_filter)
(local map vim.tbl_map)
(local {: abs : ceil : max : min : pow} math)


; Fennel utils ///1

(macro when-not [cond ...]
  `(when (not ,cond) ,...))

(fn inc [x] (+ x 1))

(fn dec [x] (- x 1))

(fn clamp [x min max]
  (if (< x min) min
      (> x max) max
      x))


; Nvim utils ///1

(fn echo [msg]
  (api.nvim_echo [[msg]] false []))

(fn replace-keycodes [s]
  (api.nvim_replace_termcodes s true false true))

(fn get-cursor-pos []
  [(vim.fn.line ".") (vim.fn.col ".")])

(fn char-at-pos [[line byte-col] {: char-offset}]  ; expects (1,1)-indexed input
  "Get character at the given position in a multibyte-aware manner.
An optional offset argument can be given to get the nth-next screen
character instead."
  (let [line-str (vim.fn.getline line)
        char-idx (vim.fn.charidx line-str (dec byte-col))  ; expects 0-indexed col
        char-nr (vim.fn.strgetchar line-str (+ char-idx (or char-offset 0)))]
    (when (not= char-nr -1)
      (vim.fn.nr2char char-nr))))


; Utils ///1

(fn user-forced-autojump? []
  (or (not opts.labels) (empty? opts.labels)))

(fn user-forced-noautojump? []
  (or (not opts.safe_labels) (empty? opts.safe_labels)))


(fn echo-no-prev-search []
  (echo "no previous search"))

(fn echo-not-found [s]
  (echo (.. "not found: " s)))

(fn push-cursor! [direction]
  "Push cursor 1 character to the left or right, possibly beyond EOL."
  (vim.fn.search "\\_." (match direction :fwd "W" :bwd "bW")))


; Jump ///

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

; //> Jump


(fn highlight-cursor [?pos]
  "The cursor is down on the command line during `getchar`,
so we set a temporary highlight on it to see where we are."
  (let [[line col &as pos] (or ?pos (get-cursor-pos))
        ; nil means the cursor is on an empty line.
        ch-at-curpos (or (char-at-pos pos {}) " ")]  ; char-at-pos needs 1,1-idx
    ; (Ab)using extmarks even here, to be able to highlight the cursor on empty lines too.
    (api.nvim_buf_set_extmark 0 hl.ns (dec line) (dec col)
                              {:virt_text [[ch-at-curpos :Cursor]]
                               :virt_text_pos "overlay"
                               :hl_mode "combine"
                               :priority hl.priority.cursor})))


(fn handle-interrupted-change-op! []
  "Return to Normal mode and restore the cursor position after an
interrupted change operation."
  (let [seq (.. "<C-\\><C-G>"  ; :h CTRL-\_CTRL-G
                (if (> (vim.fn.col ".") 1) "<RIGHT>" ""))]
    (api.nvim_feedkeys (replace-keycodes seq) :n true)))


(fn exec-user-autocmds [pattern]
  (api.nvim_exec_autocmds "User" {: pattern :modeline false}))


(fn get-input []
  (local (ok? ch) (pcall vim.fn.getcharstr))  ; pcall for <C-c>
  ; <esc> should cleanly exit anytime.
  (when (and ok? (not= ch (replace-keycodes "<esc>"))) ch))


(fn get-input-by-keymap []
  (var input (get-input))
  (when (= vim.bo.iminsert 1) ; keymap is enabled
    (let [converted (vim.fn.mapcheck input :l)]
      (when (> (length converted) 0) ; keymap can return an empty string
        (set input converted))))
  input)


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


; Getting targets ///1

(fn get-other-windows-on-tabpage [mode]
  (let [wins (api.nvim_tabpage_list_wins 0)
        curr-win (api.nvim_get_current_win)
        curr-buf (api.nvim_get_current_buf)
        visual|op-mode? (not= mode :n)]
    (filter #(and (. (api.nvim_win_get_config $) :focusable)
                  (not= $ curr-win)
                  (not (and visual|op-mode?  ; no sense in buffer switching then
                            (not= (api.nvim_win_get_buf $) curr-buf))))
            wins)))


(fn get-horizontal-bounds []
  (let [match-length 2  ; screen columns
        textoff (. (vim.fn.getwininfo (vim.fn.win_getid)) 1 :textoff)
        offset-in-win (dec (vim.fn.wincol))
        offset-in-editable-win (- offset-in-win textoff)
        ; I.e., screen-column of the first visible column in the editable area.
        left-bound (- (vim.fn.virtcol ".") offset-in-editable-win)
        window-width (api.nvim_win_get_width 0)
        right-edge (+ left-bound (dec (- window-width textoff)))
        right-bound (- right-edge (dec match-length))]  ; the whole match should be visible
    [left-bound right-bound]))  ; screen columns


(fn skip-one! [backward?]
  (local new-line (push-cursor! (if backward? :bwd :fwd)))
  (when (= new-line 0) :dead-end))


; Assumes being in a closed fold, no checks!
(fn to-closed-fold-edge! [backward?]
  (local edge-line ((if backward? vim.fn.foldclosed vim.fn.foldclosedend)
                    (vim.fn.line ".")))
  (vim.fn.cursor edge-line 0)
  (local edge-col (if backward? 1 (vim.fn.col "$")))
  (vim.fn.cursor 0 edge-col))


; HACK: vim.fn.cursor expects bytecol, but we want to put the cursor
; to `right-bound` as virtcol (screen col); so simply start crawling
; to the right, checking the virtcol... (When targeting the left
; bound, we might undershoot too - the virtcol of a position is
; always <= the bytecol of it -, but in that case it's no problem,
; just some unnecessary work afterwards, as we're still outside the
; on-screen area).
(fn reach-right-bound! [right-bound]
  (while (and (< (vim.fn.virtcol ".") right-bound)
              (not (>= (vim.fn.col ".") (dec (vim.fn.col "$")))))  ; reached EOL
    (vim.cmd "norm! l")))


(fn to-next-in-window-pos! [backward? left-bound right-bound stopline]
  ; virtcol = like `col`, starting from the beginning of the line in the
  ; buffer, but every char counts as the #of screen columns it occupies
  ; (or would occupy), instead of the #of bytes.
  (let [[line virtcol &as from-pos] [(vim.fn.line ".") (vim.fn.virtcol ".")]
        left-off? (< virtcol left-bound)
        right-off? (> virtcol right-bound)]
    (match (if (and left-off? backward?) (when (>= (dec line) stopline)
                                           [(dec line) right-bound])
               (and left-off? (not backward?)) [line left-bound]
               (and right-off? backward?) [line right-bound]
               (and right-off? (not backward?)) (when (<= (inc line) stopline)
                                                  [(inc line) left-bound]))
      to-pos
      (if (= from-pos to-pos) :dead-end
          (do (vim.fn.cursor to-pos)
              (when backward?
                (reach-right-bound! right-bound)))))))


(fn get-match-positions [pattern [left-bound right-bound]
                         {: backward? : whole-window? : skip-curpos?}]
  "Return an iterator streaming all visible positions of `pattern` in the
current window.
Caveat: side-effects take place here (cursor movement, &cpo), and the
clean-up happens only when the iterator is exhausted, so be careful with
early termination in loops."
  (let [skip-orig-curpos? skip-curpos?
        [orig-curline orig-curcol] (get-cursor-pos)
        wintop (vim.fn.line "w0")
        winbot (vim.fn.line "w$")
        stopline (if backward? wintop winbot)
        saved-view (vim.fn.winsaveview)
        saved-cpo vim.o.cpo
        cleanup #(do (vim.fn.winrestview saved-view)
                     (set vim.o.cpo saved-cpo)
                     nil)]

    (set vim.o.cpo (vim.o.cpo:gsub "c" ""))  ; do not skip overlapping matches
    (var match-count 0)
    (var moved-to-topleft? (when whole-window?
                             (vim.fn.cursor [wintop left-bound])
                             true))

    (fn iter [match-at-curpos?]
      (let [match-at-curpos? (or match-at-curpos? moved-to-topleft?)
            flags (.. (if backward? "b" "") (if match-at-curpos? "c" ""))]
        (set moved-to-topleft? false)
        (match (vim.fn.searchpos pattern flags stopline)
          [line col &as pos]
          (if (= line 0) (cleanup)  ; no match

              ; At the original cursor position (bidirectional search)?
              (and (= line orig-curline) (= col orig-curcol) skip-orig-curpos?)
              (match (skip-one!)
                :dead-end (cleanup)  ; = right before EOF
                _ (iter true))

              ; Horizontally offscreen?
              (and (< col left-bound) (> col right-bound) (not vim.wo.wrap))
              (match (to-next-in-window-pos!
                       backward? left-bound right-bound stopline)
                :dead-end (cleanup)  ; = on the first/last line in the window
                _ (iter true))

              ; In a closed fold?
              (not= (vim.fn.foldclosed line) -1)
              (do (to-closed-fold-edge! backward?)
                  (match (skip-one! backward?)  ; to actually get out of the fold
                    :dead-end (cleanup)  ; = fold starts at the beginning of the buffer,
                                         ;   or reaches till the end
                    _ (iter true)))

              (do (set match-count (+ match-count 1))
                  pos)))))))


(fn get-targets* [pattern  ; assumed to match 2 logical/multibyte chars
                  {: backward? : wininfo : targets : source-winid}]
  "Return a table that will store the positions and other metadata of
all in-window pairs that match `pattern`, in the order of discovery. A
target element in its final form has the following fields (the latter
ones might be set by subsequent functions):

Static attributes (set once and for all)
pos          : [lnum col]  1/1-indexed
pair         : [char char]
edge-pos?    : bool
?wininfo     : `vim.fn.getwininfo` dict
?label       : char

Dynamic attributes
?label-state : 'active-primary' | 'active-secondary' | 'inactive'
?beacon      : [col-offset [[char hl-group]]]
"
  (let [targets (or targets [])
        [_ right-bound &as bounds] (get-horizontal-bounds)
        whole-window? wininfo
        wininfo (or wininfo (. (vim.fn.getwininfo (vim.fn.win_getid)) 1))
        skip-curpos? (and whole-window? (= (vim.fn.win_getid) source-winid))
        match-positions (get-match-positions
                          pattern bounds {: backward? : skip-curpos? : whole-window?})]
    (var prev-match {})  ; to find overlaps
    (each [[line col &as pos] match-positions]
      (let [ch1 (char-at-pos pos {})  ; not necessarily = `input` (if case-insensitive)
            (ch2 eol?) (match (char-at-pos pos {:char-offset 1})
                         char char
                         _ (values (replace-keycodes opts.special_keys.eol) true))
            same-char-triplet? (and (= ch2 prev-match.ch2)
                                    (= line prev-match.line)
                                    (= col ((if backward? dec inc) prev-match.col)))]
        (set prev-match {: line : col : ch2})
        (when-not same-char-triplet?
          (table.insert targets {: wininfo : pos :pair [ch1 ch2]
                                 ; TODO: `right-bound` = virtcol, but `col` = byte col!
                                 :edge-pos? (or eol? (= col right-bound))}))))
    (when (next targets)
      targets)))


(fn distance [[l1 c1] [l2 c2]]
  (let [editor-grid-aspect-ratio 0.3  ; arbitrary (make it configurable? get it programmatically?)
        [dx dy] [(abs (- c1 c2)) (abs (- l1 l2))]
         dx (* dx editor-grid-aspect-ratio)]
    (pow (+ (pow dx 2) (pow dy 2)) 0.5)))


(fn get-targets [pattern {: backward? : target-windows}]
  (if (not target-windows) (get-targets* pattern {: backward?})
      (let [targets []
            cursor-positions {}
            source-winid (vim.fn.win_getid)
            curr-win-only? (match target-windows
                             [{:winid source-winid} nil] true)
            cross-win? (not curr-win-only?)]
        (each [_ {: winid &as wininfo} (ipairs target-windows)]
          (when cross-win?
            (api.nvim_set_current_win winid))
          (tset cursor-positions winid (get-cursor-pos))
          ; Fill up the provided `targets`, instead of returning a new table.
          (get-targets* pattern {: targets : wininfo : source-winid}))
        (when cross-win?
          (api.nvim_set_current_win source-winid))
        (when-not (empty? targets)
          ; Sort targets by their distance from the cursor.
          ; TODO: Check vim.wo.wrap for each window, and calculate accordingly.
          ; TODO: (Performance) vim.fn.screenpos is very costly for a large
          ;       number of targets...
          ;       -> Only get them when at least one line is actually wrapped?
          ;       -> Some FFI magic?
          (local by-screen-pos? (and vim.o.wrap (< (length targets) 200)))
          (when by-screen-pos?
            ; Update cursor positions to screen positions.
            (each [winid [line col] (pairs cursor-positions)]
              (match (vim.fn.screenpos winid line col)
                {: row : col} (tset cursor-positions winid [row col]))))
          (each [_ {:pos [line col] :wininfo {: winid} &as t} (ipairs targets)]
            (when by-screen-pos?
              ; Add a screen position field to each target.
              (match (vim.fn.screenpos winid line col)  ; PERF. BOTTLENECK
                {: row : col} (tset t :screenpos [row col])))
            (tset t :rank (distance (or t.screenpos t.pos)
                                    (. cursor-positions winid))))
          (table.sort targets #(< (. $1 :rank) (. $2 :rank)))
          targets))))


; Processing targets ///1

(fn populate-sublists [targets]
  "Populate a sub-table in `targets` containing lists that allow for
easy iteration through each subset of targets with a given successor
char separately."
  (tset targets :sublists {})
  (when-not opts.case_sensitive
    (setmetatable targets.sublists
                  {:__index (fn [t k] (rawget t (k:lower)))
                   :__newindex (fn [t k v] (rawset t (k:lower) v))}))
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


(fn set-sublist-attributes [targets {: force-noautojump?}]
  (each [_ sublist (pairs targets.sublists)]
    (set-autojump sublist force-noautojump?)
    (attach-label-set sublist)))


(fn set-labels [targets]
  "Assign label characters to each target, by going through the sublists
one by one, using the given sublist's `label-set` repeated indefinitely.
Note: `label` is a once and for all fixed attribute - whether and how it
should actually be displayed depends on the `label-state` flag."
  (each [_ sublist (pairs targets.sublists)]
    (when (> (length sublist) 1)  ; else we jump unconditionally
      (local {: autojump? : label-set} sublist)
      (each [i target (ipairs sublist)]
        ; Skip labeling the first target if autojump is set.
        (local i* (if autojump? (dec i) i))
        (when (> i* 0)
          (tset target :label
                (match (% i* (length label-set))
                  0 (. label-set (length label-set))
                  n (. label-set n))))))))


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

(fn set-beacon-for-labeled [target]
  (let [{:pair [ch1 ch2] : edge-pos? : label} target
        offset (+ (ch1:len) (if edge-pos? 0 (ch2:len)))  ; handling multibyte
        virttext (match target.label-state
                   :active-primary [[label hl.group.label-primary]]
                   :active-secondary [[label hl.group.label-secondary]]
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


(fn set-beacons [target-list {: force-no-labels?}]
  (if force-no-labels?
      (each [_ target (ipairs target-list)]
        (set-beacon-to-match-hl target))
      (do (each [_ target (ipairs target-list)]
            (if target.label (set-beacon-for-labeled target)
                opts.highlight_unlabeled (set-beacon-to-match-hl target)))
          (resolve-conflicts target-list))))


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


; Main ///1

; State that is persisted between invocations.
(local state {:repeat {:in1 nil :in2 nil}
              :dot-repeat {:in1 nil :in2 nil :target-idx nil
                           :backward? nil :inclusive-op? nil :offset? nil}})


(fn leap [{: dot-repeat? : target-windows &as kwargs}]
  "Entry point for Leap motions."
  (let [{: backward? : inclusive-op? : offset} (if dot-repeat? state.dot-repeat
                                                   kwargs)
        ; We need to save the mode here, because the `:normal` command
        ; in `jump-to!*` can change the state. Related: vim/vim#9332.
        mode (. (api.nvim_get_mode) :mode)
        ?target-windows (-?>> (match target-windows
                                [&as t] t
                                true (get-other-windows-on-tabpage mode))
                              (map #(. (vim.fn.getwininfo $) 1)))
        source-window (. (vim.fn.getwininfo (vim.fn.win_getid)) 1)
        directional? (not ?target-windows)
        op-mode? (mode:match :o)
        change-op? (and op-mode? (= vim.v.operator :c))
        dot-repeatable-op? (and op-mode? directional? (not= vim.v.operator :y))
        ; In operator-pending mode, autojump would execute the operation
        ; without allowing us to select a labeled target.
        force-noautojump? (or op-mode? (not directional?))
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
           ; Quick fix: make sure to clean the source window too,
           ; when jumping to another window.
           (hl:cleanup (when ?target-windows
                         (doto ?target-windows
                           (table.insert source-window))))
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
      `(do (hl:cleanup ?target-windows)
           (hl:apply-backdrop backward? ?target-windows)
           (do ,...)
           (highlight-cursor)
           (vim.cmd :redraw)))

    (fn prepare-pattern [in1 ?in2]
      (.. "\\V"
          (if opts.case_sensitive "\\C" "\\c")
          (in1:gsub "\\" "\\\\")  ; backslash needs to be escaped even for \V
          (match ?in2  ; but not here (no arbitrary input after this)
            spec-keys.eol (.. "\\(" ?in2 "\\|\\r\\?\\n\\)")
            _ (or ?in2 "\\_."))))  ; or match anything (including EOL)

    (fn get-target-with-active-primary-label [sublist input]
      (var res nil)
      (each [idx {: label : label-state &as target} (ipairs sublist)
             :until (or res (= label-state :inactive))]
        (when (and (= label input) (= label-state :active-primary))
          (set res [idx target])))
      res)

    (fn update-state [state*]  ; a partial state table
      (when-not dot-repeat?
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
      (set-beacons targets {: force-no-labels?})
      (with-highlight-chores (light-up-beacons targets (inc idx)))
      (match (or (get-input-by-keymap) (exit))
        input
        (if (or (= input spec-keys.next_match) (= input spec-keys.prev_match))
            (let [new-idx (match input
                            spec-keys.next_match (min (inc idx) (length targets))
                            spec-keys.prev_match (max (dec idx) 1))]
              ; Need to save now - we might <esc> next time, exiting above.
              (update-state {:repeat {:in1 state.repeat.in1
                                      :in2 (. targets new-idx :pair 2)}})
              (jump-to! (. targets new-idx))
              (traverse targets new-idx {: force-no-labels?}))
            ; We still want the labels (if there are) to function.
            (match (get-target-with-active-primary-label targets input)
              [_ target] (exit (jump-to! target))
              _ (exit (vim.fn.feedkeys input :i))))))

    (fn get-first-pattern-input []
      (with-highlight-chores (echo ""))  ; clean up the command line
      (match (or (get-input-by-keymap) (exit-early))
        ; Here we can handle any other modifier key as "zeroth" input,
        ; if the need arises.
        spec-keys.repeat_search (if state.repeat.in1
                                    (values state.repeat.in1 state.repeat.in2)
                                    (exit-early (echo-no-prev-search)))
        in1 in1))

    (fn get-second-pattern-input [targets]
      (doto targets
        (set-initial-label-states)
        (set-beacons {}))
      (with-highlight-chores (light-up-beacons targets))
      (or (get-input-by-keymap) (exit-early)))

    (fn get-full-pattern-input []
      (match (get-first-pattern-input)
        (in1 in2) (values in1 in2)
        (in1 nil) (match (get-input-by-keymap)
                    in2 (values in1 in2)
                    _ (exit-early))))

    (fn post-pattern-input-loop [sublist]
      (fn loop [group-offset initial-invoc?]
        (doto sublist
          ; Do _not_ skip this on initial invocation - we might have skipped
          ; setting the initial label states in case of <enter>-repeat.
          (set-label-states {: group-offset})
          (set-beacons {}))
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
    (match-try (if dot-repeat? (values state.dot-repeat.in1 state.dot-repeat.in2)
                   ; This might also return in2 too, if <enter>-repeating.
                   opts.highlight_ahead_of_time (get-first-pattern-input)  ; REDRAW
                   (get-full-pattern-input))  ; REDRAW
      (in1 ?in2) (or (get-targets (prepare-pattern in1 ?in2)
                                  {: backward? :target-windows ?target-windows})
                     (exit-early (echo-not-found (.. in1 (or ?in2 "")))))
      targets (do (doto targets
                    ; Prepare targets (set fixed attributes).
                    (populate-sublists)
                    (set-sublist-attributes {: force-noautojump?})
                    (set-labels))
                  (or ?in2
                      (get-second-pattern-input targets)))  ; REDRAW
      ; From here on, successful exit (jumping to a target) is possible.
      in2 (if dot-repeat?
              (match (. targets state.dot-repeat.target-idx)
                target (exit (jump-to! target))
                _ (exit-early))

              ; Jump to the very first match?
              (and directional? (= in2 spec-keys.next_match))
              (let [in2 (. targets 1 :pair 2)]
                (update-state {:repeat {: in1 : in2}})
                (jump-to! (. targets 1))
                (if (or op-mode? (= (length targets) 1))
                    (exit (update-state {:dot-repeat {: in1 : in2 :target-idx 1}}))
                    (traverse targets 1 {:force-no-labels? true})))  ; REDRAW (LOOP)

              (do
                (update-state {:repeat {: in1 : in2}})  ; save it here (repeat might succeed)
                (local update-dot-repeat-state
                       #(update-state {:dot-repeat {: in1 : in2 :target-idx $}}))
                (match (or (. targets.sublists in2)
                           (exit-early (echo-not-found (.. in1 in2))))
                  [only nil]
                  (exit (update-dot-repeat-state 1)
                        (jump-to! only))

                  sublist
                  (do
                    (when sublist.autojump? (jump-to! (. sublist 1)))
                    ; Sets label states!
                    (match (post-pattern-input-loop sublist)  ; REDRAW (LOOP)
                      in-final
                      (if
                        ; Jump to the first match on the [rest of the] sublist?
                        (and directional? (= in-final spec-keys.next_match))
                        (let [new-idx (if sublist.autojump? 2 1)]
                          (jump-to! (. sublist new-idx))
                          (if op-mode? (exit (update-dot-repeat-state 1))  ; implies no-autojump
                              (traverse sublist new-idx  ; REDRAW (LOOP)
                                        {:force-no-labels? (not sublist.autojump?)})))

                        (match (get-target-with-active-primary-label sublist in-final)
                          [idx target] (exit (update-dot-repeat-state idx)
                                             (jump-to! target))
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
