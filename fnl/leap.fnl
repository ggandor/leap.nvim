; Imports & aliases ///1

(local api vim.api)
(local empty? vim.tbl_isempty)
(local map vim.tbl_map)
(local {: abs : ceil : max : min : pow} math)


; Fennel utils ///1

(macro one-of? [x ...]
  "Expands to an `or` form, like (or (= x y1) (= x y2) ...)"
  `(or ,(unpack
          (icollect [_ y (ipairs [...])]
            `(= ,x ,y)))))

(macro when-not [cond ...]
  `(when (not ,cond) ,...))

(fn clamp [val min max]
  (if (< val min) min
      (> val max) max
      :else val))

(fn inc [x] (+ x 1))

(fn dec [x] (- x 1))


; Nvim utils ///1

(fn echo [msg]
  (vim.cmd :redraw) (api.nvim_echo [[msg]] false []))

(fn replace-keycodes [s]
  (api.nvim_replace_termcodes s true false true))

(local <ctrl-v> (replace-keycodes "<c-v>"))
(local <esc> (replace-keycodes "<esc>"))

(fn get-motion-force [mode]
  (match (when (mode:match :o) (mode:sub -1))
    last-ch (when (one-of? last-ch <ctrl-v> :V :v) last-ch)))

(fn get-cursor-pos [] [(vim.fn.line ".") (vim.fn.col ".")])

(fn char-at-pos [[line byte-col] {: char-offset}]  ; expects (1,1)-indexed input
  "Get character at the given position in a multibyte-aware manner.
An optional offset argument can be given to get the nth-next screen
character instead."
  (let [line-str (vim.fn.getline line)
        char-idx (vim.fn.charidx line-str (dec byte-col))  ; charidx expects 0-indexed col
        char-nr (vim.fn.strgetchar line-str (+ char-idx (or char-offset 0)))]
    (when (not= char-nr -1)
      (vim.fn.nr2char char-nr))))

(fn get-fold-edge [lnum reverse?]
  (match ((if reverse? vim.fn.foldclosed vim.fn.foldclosedend) lnum)
    -1 nil
    fold-edge fold-edge))


; Setup ///1

(local safe-labels ["s" "f" "n"
                    "u" "t"
                    "/" "F" "L" "N" "H" "G" "M" "U" "T" "?" "Z"])

(local labels ["s" "f" "n"
               "j" "k" "l" "o" "d" "w" "e" "h" "m" "v" "g"
               "u" "t"
               "c" "." "z"
               "/" "F" "L" "N" "H" "G" "M" "U" "T" "?" "Z"])

(var opts {:case_insensitive true
           :safe_labels safe-labels
           :labels labels
           :special_keys {:next_match_group "<space>"
                          :prev_match_group "<tab>"
                          :repeat "<enter>"
                          :revert "<tab>"}})

(fn setup [user-opts]
  (set opts (-> user-opts (setmetatable {:__index opts}))))

(fn user-forced-autojump? []
  (or (not opts.labels) (empty? opts.labels)))

(fn user-forced-no-autojump? []
  (or (not opts.safe_labels) (empty? opts.safe_labels)))


; Highlight ///1

(local hl
  {:group {:label-primary "LeapLabelPrimary"
           :label-secondary "LeapLabelSecondary"
           :match "LeapMatch"
           :backdrop "LeapBackdrop"}
   :priority {:label 65535
              :cursor 65534
              :backdrop 65533}
   :ns (api.nvim_create_namespace "")
   :cleanup (fn [self ?target-windows]
              (when ?target-windows
                (each [_ w (ipairs ?target-windows)]
                  (api.nvim_buf_clear_namespace w.bufnr self.ns (dec w.topline) w.botline)))
              ; We need to clean up the cursor highlight in the current window anyway.
              (api.nvim_buf_clear_namespace 0 self.ns
                                            (dec (vim.fn.line "w0"))
                                            (vim.fn.line "w$")))})


(fn init-highlight [force?]
  (local bg vim.o.background)
  (each [name def-map
         (pairs 
          {hl.group.backdrop        {:gui "none"
                                     :cterm "none"}
           hl.group.match           {:guifg (match bg
                                             :light "#222222"
                                             _ "#ccff88")
                                     :guibg "none"
                                     :gui "underline,nocombine"
                                     :ctermfg "red"
                                     :ctermbg "none"
                                     :cterm "underline,nocombine" }
           hl.group.label-primary   {:guifg "black"
                                     :guibg (match bg
                                              :light "#ff8877"
                                              _ "#ccff88")
                                     :gui "none"
                                     :ctermfg "black"
                                     :ctermbg "red"
                                     :cterm "none"}
           hl.group.label-secondary {:guifg "black"
                                     :guibg (match bg
                                              :light "#77aaff"
                                              _ "#99ccff")
                                     :gui "none"
                                     :ctermfg "black"
                                     :ctermbg "blue"
                                     :cterm "none"}})]
    (let [attr-str (-> (icollect [k v (pairs def-map)] (.. k "=" v))
                       (table.concat " "))]
      (vim.cmd (.. "highlight " (if force? "" "default ") name " " attr-str)))))


(fn apply-backdrop [reverse? ?target-windows]
  (if ?target-windows
      (each [_ win (ipairs ?target-windows)]
        (vim.highlight.range win.bufnr hl.ns hl.group.backdrop
                             [(dec win.topline) 0]
                             [(dec win.botline) -1]
                             {:priority hl.priority.backdrop}))
      (let [[curline curcol] (map dec (get-cursor-pos))
            [win-top win-bot] [(dec (vim.fn.line "w0")) (dec (vim.fn.line "w$"))]
            [start finish] (if reverse?
                               [[win-top 0] [curline curcol]]
                               [[curline (inc curcol)] [win-bot -1]])]
        ; Expects 0,0-indexed args; `finish` is exclusive.
        (vim.highlight.range 0 hl.ns hl.group.backdrop start finish
                             {:priority hl.priority.backdrop}))))


; Utils ///1

(fn echo-no-prev-search [] (echo "no previous search"))

(fn echo-not-found [s] (echo (.. "not found: " s)))


(fn push-cursor! [direction]
  "Push cursor 1 character to the left or right, possibly beyond EOL."
  (vim.fn.search "\\_." (match direction :fwd "W" :bwd "bW")))


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
  (pcall api.nvim_exec_autocmd "CursorMoved" {:group "matchparen"})
  ; If vim-matchup is installed, it can similarly be forced to refresh
  ; by triggering a CursorMoved event. (The same caveats apply.)
  (pcall api.nvim_exec_autocmd "CursorMoved" {:group "matchup_matchparen"}))


(fn cursor-before-eof? []
  (and (= (vim.fn.line ".") (vim.fn.line "$"))
       (= (vim.fn.virtcol ".") (dec (vim.fn.virtcol "$")))))


(fn add-restore-virtualedit-autocmd [saved-val]
  (api.nvim_create_autocmd
    [:CursorMoved :WinLeave :BufLeave :InsertEnter :CmdlineEnter :CmdwinEnter]
    {:callback #(set vim.o.virtualedit saved-val) :once true}))


(fn jump-to!* [target {: mode : reverse? : inclusive-motion?
                       : add-to-jumplist? : adjust}]
  (let [op-mode? (string.match mode :o)
        motion-force (get-motion-force mode)
        virtualedit-saved vim.o.virtualedit]
    ; Note: <C-o> will ignore this if the line has not changed (neovim#9874).
    (when add-to-jumplist? (vim.cmd "norm! m`"))
    (vim.fn.cursor target)
    ; Adjust position after the jump (for x-mode).
    (adjust)
    (when-not op-mode? (force-matchparen-refresh))
    ; Simulating inclusive/exclusive behaviour for operator-pending mode by
    ; adjusting the cursor position.
    ; For operators, our jump is always interpreted by Vim as an exclusive
    ; motion, so whenever we'd like to behave as an inclusive one, an
    ; additional push is needed to even that out (:h inclusive).
    ; (This is only relevant in the forward direction.)
    (when (and op-mode? (not reverse?) inclusive-motion?)
      (match motion-force
        ; In the normal case (no modifier), we should push the cursor forward
        ; (next column as exclusive = target column as inclusive).
        nil (if (not (cursor-before-eof?)) (push-cursor! :fwd)
                ; The EOF edge case requires some hackery.
                ; Note: No need to undo the `l` afterwards, as the cursor will
                ; be moved to the end of the operated area anyway.
                (do (set vim.o.virtualedit :onemore)
                    (vim.cmd "norm! l")
                    (add-restore-virtualedit-autocmd virtualedit-saved)))
        ; We should _never_ push the cursor in the linewise case, as we might
        ; push it beyond EOL, and that would add another line to the selection.
        :V nil
        ; Blockwise (<c-v>) itself makes the motion inclusive, we're done.
        <ctrl-v> nil
        ; We want the `v` modifier to behave in the native way, that is, to
        ; toggle between inclusive/exclusive if applied to a charwise
        ; motion (:h o_v). As our jump is technically - i.e., from Vim's
        ; perspective - an exclusive motion, `v` will change it to
        ; _inclusive_, so we should push the cursor back to "undo" that.
        ; (Previous column as inclusive = target column as exclusive.)
        :v (push-cursor! :bwd)))))


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
  "Return to previous mode and adjust cursor position if needed after
interrupted change-operation."
  ; Cannot really follow why, but this cleanup is needed here, else
  ; there is a short blink on the command line (the cursor jumps ahead,
  ; as if something has been echoed and then erased immediately).
  (echo "")
  (let [curcol (vim.fn.col ".")
        endcol (vim.fn.col "$")
        ?right (if (and (not vim.o.insertmode) (> curcol 1) (< curcol endcol))
                   "<RIGHT>"
                    "")]
    (-> (replace-keycodes (.. "<C-\\><C-G>" ?right))  ; :h CTRL-\_CTRL-G
        (api.nvim_feedkeys :n true))))


(fn doau-when-exists [pattern]
  (when (vim.fn.exists (.. "#User#" pattern))
    (api.nvim_exec_autocmd "User" {:pattern pattern :modeline false})))


(fn get-input []
  (match (pcall vim.fn.getcharstr)     ; pcall for <C-c>
    (where (true ch) (not= ch <esc>))  ; <esc> should cleanly exit anytime
    ch))


; repeat.vim support
; (see the docs in the script:
; https://github.com/tpope/vim-repeat/blob/master/autoload/repeat.vim)
(fn set-dot-repeat [cmd ?count]
  ; Note: dot-repeatable (i.e. non-yank) operation is assumed, we're not
  ; checking it here.
  (let [op vim.v.operator
        ; We cannot getreg('.') at this point, since the change has not
        ; happened yet - therefore the below hack (thx Sneak).
        change (when (= op :c) (replace-keycodes "<c-r>.<esc>"))
        seq (.. op (or ?count "") cmd (or change ""))]
    ; Using pcall, since vim-repeat might not be installed.
    ; Use the same register for the repeated operation.
    (pcall vim.fn.repeat#setreg seq vim.v.register)
    ; Note: we're feeding count inside the seq itself.
    (pcall vim.fn.repeat#set seq -1)))


(fn get-plug-key [reverse? x-mode? dot-repeat?]
  (.. "<Plug>(leap-" (if dot-repeat? "dotrepeat-" "")
      ; Forcing to bools with not-not, as those values can be nils.
      (match [(not (not reverse?)) (not (not x-mode?))]
        [false false] "forward)"
        [true  false] "backward)"
        [false true]  "forward-x)"
        [true  true]  "backward-x)")))


; Getting targets ///1

; Returns wininfo dicts.
(fn get-targetable-windows []
  (let [visual-or-OP-mode? (not= (vim.fn.mode) :n)
        get-wininfo #(. (vim.fn.getwininfo $) 1)
        get-buf api.nvim_win_get_buf
        curr-winid (vim.fn.win_getid)
        ; HACK! The output of vim.fn.winlayout looks sg like:
        ; ['col', [['leaf', 1002], ['row', [['leaf', 1003], ['leaf', 1001]]], ['leaf', 1000]]]
        ; Instead of traversing the window tree, we simply extract the id-s from
        ; the flat string representation.
        ids (string.gmatch (vim.fn.string (vim.fn.winlayout)) "%d+")
        ; TODO: filter on certain window types?
        ids (icollect [id ids]
              (when-not (or (= (tonumber id) curr-winid)
                            ; Targeting a different buffer doesn't make
                            ; sense in these modes.
                            (and visual-or-OP-mode?
                                 (not= (get-buf (tonumber id))
                                       (get-buf curr-winid))))
                id))]
    (map get-wininfo ids)))


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


(fn get-match-positions [pattern
                         {: reverse? : whole-window? : source-winid
                          :bounds [left-bound right-bound]}]
  "Returns an iterator streaming the return values of `searchpos` for
the given pattern, stopping at the window edge; in case of 2-character
search, folds and offscreen parts of non-wrapped lines are skipped too.
Caveat: side-effects take place here (cursor movement, &cpo), and the
clean-up happens only when the iterator is exhausted, so be careful with
early termination in loops."
  (let [reverse? (if whole-window? false reverse?)
        curr-winid (vim.fn.win_getid)
        view (vim.fn.winsaveview)
        cpo vim.o.cpo
        opts (if reverse? "b" "")
        wintop (vim.fn.line "w0")
        winbot (vim.fn.line "w$")
        stopline (if reverse? wintop winbot)
        cleanup #(do (vim.fn.winrestview view) (set vim.o.cpo cpo) nil)]

    ; HACK: vim.fn.cursor expects bytecol, but we want to put the cursor
    ; to `right-bound` as virtcol (screen col); so simply start crawling
    ; to the right, checking the virtcol... (When targeting the left
    ; bound, we might undershoot too - the virtcol of a position is
    ; always <= the bytecol of it -, but in that case it's no problem,
    ; just some unnecessary work afterwards, as we're still outside the
    ; on-screen area).
    (fn reach-right-bound []
      (while (and (< (vim.fn.virtcol ".") right-bound)
                  (not (>= (vim.fn.col ".") (dec (vim.fn.col "$")))))  ; reached EOL
        (vim.cmd "norm! l")))

    (fn skip-to-fold-edge! []
      (match ((if reverse? vim.fn.foldclosed vim.fn.foldclosedend)
              (vim.fn.line "."))
        -1 :not-in-fold
        fold-edge (do (vim.fn.cursor fold-edge 0)
                      (vim.fn.cursor 0 (if reverse? 1 (vim.fn.col "$")))
                      ; ...regardless of whether it _actually_ moved
                      :moved-the-cursor)))

    (fn skip-to-next-in-window-pos! []
      ; virtcol = like `col`, starting from the beginning of the line in the
      ; buffer, but every char counts as the #of screen columns it occupies
      ; (or would occupy), instead of the #of bytes.
      (local [line virtcol &as from-pos] [(vim.fn.line ".") (vim.fn.virtcol ".")])
      (match (if (< virtcol left-bound)
                 (if reverse?
                     (when (>= (dec line) stopline)
                       [(dec line) right-bound])
                       [line left-bound])

                 (> virtcol right-bound)
                 (if reverse?
                     [line right-bound]
                     (when (<= (inc line) stopline)
                       [(inc line) left-bound])))
        to-pos (when (not= from-pos to-pos)
                 (vim.fn.cursor to-pos)
                 (when reverse? (reach-right-bound))
                 :moved-the-cursor)))

    ; Do not skip overlapping matches.
    (set vim.o.cpo (cpo:gsub "c" ""))
    ; To be able to match the top-left or bottom-right corner (see below).
    (var win-enter? nil)
    (var match-count 0)

    (local orig-curpos (get-cursor-pos))
    (when whole-window?
      (set win-enter? true)
      (vim.fn.cursor [wintop left-bound]))

    (fn recur [match-at-curpos?]
      (local match-at-curpos? (or match-at-curpos?
                                  (when win-enter? (set win-enter? false) true)))
      (match (vim.fn.searchpos
               pattern (.. opts (if match-at-curpos? "c" "")) stopline)
        [0 _] (cleanup)
        [line col &as pos]
        (match (skip-to-fold-edge!)
          :moved-the-cursor (recur false)  ; false, as we're still inside the fold
          :not-in-fold
          (if (and (= curr-winid source-winid)
                   ; Do not match at the original cursor position.
                   (= view.lnum line) (= (inc view.col) col))  ; 1/0-indexed!
              (do (push-cursor! :fwd)
                  (recur true))  ; true, as we might be on a match
            
              (or (<= left-bound col right-bound) vim.wo.wrap)
              (do (set match-count (+ match-count 1))
                  pos)

              (match (skip-to-next-in-window-pos!)
                :moved-the-cursor (recur true)
                _ (cleanup))))))))


(fn get-targets* [input {: reverse? : wininfo : targets : source-winid}]
  "Return a table that will store the positions and other metadata of
all on-screen pairs that start with `input`, in the order of discovery.
A target element in its final form has the following fields (the latter
ones might be set by subsequent functions):

Static attributes (set once and for all)
pos          : [lnum col]  1/1-indexed
pair         : [char char]
edge-pos?    : bool
?wininfo     : `vim.fn.getwininfo` dict
?label       : char

Dynamic attributes
?label-state : 'active-primary' | 'active-secondary' | 'inactive'
?beacon      : [col-offset [[char hl-group]]] | 'match-highlight'
"
  (local targets (or targets []))
  (var prev-match {})  ; to find overlaps
  (let [[_ right-bound &as bounds] (get-horizontal-bounds)
        pattern (.. "\\V"
                    (if opts.case_insensitive "\\c" "\\C")
                    (input:gsub "\\" "\\\\")  ; backslash still needs to be escaped for \V
                    "\\_.")]                  ; match anything after it (including EOL)
    (each [[line col &as pos]
           (get-match-positions pattern {: bounds : reverse? : source-winid
                                         :whole-window? wininfo})]
      (let [ch1 (char-at-pos pos {})  ; not necessarily = `input` (if case-insensitive)
            ; <cr> is the expected input for matching line breaks, so
            ; let's convert ch2 to the key for the sublist right away.
            ch2 (or (char-at-pos pos {:char-offset 1}) "\r")
            same-char-triplet? (and (= ch2 prev-match.ch2)
                                    (= line prev-match.line)
                                    (= col ((if reverse? dec inc) prev-match.col)))]
        (set prev-match {: line : col : ch2})
        (when-not same-char-triplet?
          (table.insert targets
                        {: pos :pair [ch1 ch2] :wininfo wininfo
                         ; TODO: `right-bound` = virtcol, but `col` = byte col!
                         :edge-pos? (or (= ch2 "\r") (= col right-bound))}))))
    (when (next targets)
      targets)))


(fn distance [[l1 c1] [l2 c2]]
  (let [editor-grid-aspect-ratio 0.3  ; arbitrary (make it configurable? get it programmatically?)
        [dx dy] [(abs (- c1 c2)) (abs (- l1 l2))]
         dx (* dx editor-grid-aspect-ratio)]
    (pow (+ (pow dx 2) (pow dy 2)) 0.5)))


(fn get-targets [input {: reverse? : target-windows}]
  (if target-windows
      (let [targets []
            cursor-positions {}
            cross-win? (not (and (= (length target-windows) 1)
                                 (= (. target-windows 1 :winid)
                                    (vim.fn.win_getid))))
            source-winid (vim.fn.win_getid)]
        (each [_ w (ipairs target-windows)]
          (when cross-win? (api.nvim_set_current_win w.winid))
          (tset cursor-positions w.winid (get-cursor-pos))
          (get-targets* input {:wininfo w : source-winid : targets}))
        (when cross-win? (api.nvim_set_current_win source-winid))
        (when-not (empty? targets)
          ; Sort targets by their distance from the cursor.
          ; TODO: Performance: vim.fn.screenpos is very costly for a large number of targets
          ; - only get them when at least one line is actually wrapped?
          ; - some FFI magic?
          ; TODO: Check vim.wo.wrap for each window, and calculate accordingly.
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
          targets))
    
      (get-targets* input {: reverse?})))


; Processing targets ///1

(fn populate-sublists [targets]
  "Populate a sub-table in `targets` containing lists that allow for
easy iteration through each subset of targets with a given successor
char separately."
  (tset targets :sublists {})
  (when opts.case_insensitive
    (setmetatable targets.sublists
                  {:__index (fn [self k]
                              (rawget self (k:lower)))
                   :__newindex (fn [self k v]
                                 (rawset self (k:lower) v))}))
  (each [_ {:pair [_ ch2] &as target} (ipairs targets)]
    (when-not (. targets :sublists ch2)
      (tset targets :sublists ch2 []))
    (table.insert (. targets :sublists ch2) target)))


(fn set-autojump [sublist force-no-autojump?]
  "Set a flag indicating whether we should autojump to the first target
if selecting `sublist` with the 2nd input character.
Note that there is no one-to-one correspondence between this flag and
the `label-set` field set by `attach-label-set`. No-autojump might be
forced implicitly, regardless of using safe labels."
  (tset sublist :autojump?
        (and (not (or force-no-autojump? 
                      (user-forced-no-autojump?)))
             (or (user-forced-autojump?)
                 (>= (length opts.safe_labels)
                     (dec (length sublist)))))))  ; skipping the first if autojumping


(fn attach-label-set [sublist]
  "Set a field referencing the target label set to be used for
`sublist`. `set-autojump` should be called before this function."
  (tset sublist :label-set
        (if (user-forced-autojump?) opts.safe_labels
            (user-forced-no-autojump?) opts.labels
            sublist.autojump? opts.safe_labels
            opts.labels)))


(fn set-sublist-attributes [targets {: force-no-autojump?}]
  (each [_ sublist (pairs targets.sublists)]
    (set-autojump sublist force-no-autojump?)
    (attach-label-set sublist)))


(fn set-labels [targets]
  "Assign label characters to each target, by going through the sublists
one by one, using the given sublist's `label-set` repeated indefinitely,
and skipping the first target if `autojump?` is set.
Note: `label` is a once and for all fixed attribute - whether and how it
should actually be displayed depends on the `label-state` flag."
  (each [_ sublist (pairs targets.sublists)]
    (when (> (length sublist) 1)  ; else we'll jump automatically anyway
      (let [autojump? sublist.autojump?
            labels sublist.label-set]
        (each [i target (ipairs sublist)]
          (tset target :label
                (when-not (and autojump? (= i 1))
                  ; In case of `autojump?`, the i-th label is assigned
                  ; to the i+1th position (we skipped the first one).
                  (match (% (if autojump? (dec i) i)
                            (length labels))
                    ; 1-indexing is not a great match for modulo arithmetic.
                    0 (. labels (length labels))
                    n (. labels n)))))))))


(fn set-label-states [sublist {: group-offset}]
  (let [labels sublist.label-set
        |labels| (length labels)
        offset (* group-offset |labels|)
        primary-start (+ offset (if sublist.autojump? 2 1))
        primary-end (+ primary-start (dec |labels|))
        secondary-end (+ primary-end |labels|)]
    (each [i target (ipairs sublist)]
      (when target.label
        (tset target :label-state
              (if (or (< i primary-start) (> i secondary-end)) :inactive
                  (<= i primary-end) :active-primary
                  :active-secondary))))))


(fn set-initial-label-states [targets]
  (each [_ sublist (pairs targets.sublists)]
    (set-label-states sublist {:group-offset 0})))


; Display ///1

(fn set-beacon [target force-no-labels?]
  (let [{:pair [ch1 ch2] : label : label-state : edge-pos?} target
        offset (+ (ch1:len) (if edge-pos? 0 (ch2:len)))]  ; multibyte
    (tset target :beacon
          (if (or (not label-state) force-no-labels?) :match-highlight
              (match label-state
                :active-primary [offset [[label hl.group.label-primary]]]
                :active-secondary [offset [[label hl.group.label-secondary]]]
                :inactive nil)))))


(fn set-beacons [target-list {: force-no-labels?}]
  (each [_ target (ipairs target-list)]
    (set-beacon target force-no-labels?)))


(fn light-up-beacons [target-list ?start-from]
  (local match-hl-positions {})  ; "<bufnr> <lnum> <col>" : true
  (local label-positions {})     ; "<bufnr> <lnum> <col>" : extmark-id

  (macro make-key [bufnr winid lnum col]
    `(.. ,bufnr " " ,winid " " ,lnum " " ,col))

  (for [i (or ?start-from 1) (length target-list)]
    (local target (. target-list i))
    (when target.beacon
      (let [[lnum col] (map dec target.pos)  ; 1/1 -> 0/0 idx
            bufnr (or (?. target.wininfo :bufnr) 0)
            winid (or (?. target.wininfo :winid) 0)]
        (match target.beacon
          :match-highlight
          (let [[ch1 ch2] target.pair
                k1 (make-key bufnr winid lnum col)
                k2 (make-key bufnr winid lnum (+ col (ch1:len)))]
            (each [_ k (ipairs [k1 k2])]
                (tset match-hl-positions k true)
              ; Match highlights always win; remove any label already set.
              (match (. label-positions k)
                id (api.nvim_buf_del_extmark bufnr hl.ns id)))
            (api.nvim_buf_add_highlight bufnr hl.ns hl.group.match
                                        lnum col (+ col (ch1:len) (ch2:len))))

          [label-offset virttext]
          (let [col (+ col label-offset)
                k (make-key bufnr winid lnum col)]
            (match (or (. match-hl-positions k) (. label-positions k))
              ; If the position is occupied by a match highlight, that takes
              ; priority - do nothing.
              true nil
              ; If the position is occupied by another label, remove that.
              id (api.nvim_buf_del_extmark bufnr hl.ns id)
              ; Else set the label, and record its position.
              _ (tset label-positions k
                      (api.nvim_buf_set_extmark bufnr hl.ns lnum col
                                                {:virt_text virttext
                                                 :virt_text_pos "overlay"
                                                 :priority hl.priority.label})))))))))


; Main ///1

; State that is persisted between invocations.
; (Note: we don't need to save `reverse?` and `x-mode?` for the dot
; state, since we hardcode them into the dot-repeat command.)
(local state {:dot-repeat {:in1 nil :in2 nil :target-idx nil}
              :repeat {:in1 nil :in2 nil}})


(fn leap [{: reverse? : x-mode? : omni? : cross-window?
           : dot-repeat? : traversal-state}]
  "Entry point for Leap motions."
  (let [omni? (or cross-window? omni?)
        ; We need to save the mode here, because the `:normal` command
        ; in `jump-to!*` can change the state. Related: vim/vim#9332.
        mode (. (api.nvim_get_mode) :mode)
        visual-mode? (one-of? mode <ctrl-v> :V :v)
        op-mode? (mode:match :o)
        change-op? (and op-mode? (= vim.v.operator :c))
        dot-repeatable-op? (and op-mode? (not omni?) (not= vim.v.operator :y))
        doing-traversal? traversal-state
        ; In operator-pending mode, autojump would execute the operation
        ; without allowing us to select a labeled target.
        force-no-autojump? (or op-mode? (and omni? visual-mode?) cross-window?)
        force-no-labels? (and doing-traversal?
                              (not traversal-state.sublist.autojump?))
        ?target-windows (if cross-window? (get-targetable-windows)
                            omni? [(. (vim.fn.getwininfo (vim.fn.win_getid)) 1)])
        spec-keys (setmetatable {} {:__index
                                    (fn [_ k] (replace-keycodes
                                                (. opts.special_keys k)))})]

    ; Could be set later by `special_keys.repeat` as first input.
    (var new-search? (not (or dot-repeat? doing-traversal?)))

    ; Helpers ///

    ; Note: One of the main purpose of these macros, besides wrapping
    ; cleanup stuff, is to enforce and encapsulate the requirement that
    ; tail-positioned "exit" forms in `match` blocks should always
    ; return nil. (Interop with side-effecting VimL functions can be
    ; dangerous, they might return 0 for example, like `feedkey`, and
    ; with that they can screw up Fennel match forms in a breeze,
    ; resulting in misterious bugs, so it's better to be paranoid.)
    (macro exit [...]
      `(do (when dot-repeatable-op?
             (set-dot-repeat
               (replace-keycodes (get-plug-key reverse? x-mode? true))))
           (do ,...)
           (doau-when-exists :LeapLeave)
           nil))

    (macro exit-early [...]
      `(do
         ; Be sure _not_ to call the macro twice accidentally,
         ; `handle-interrupted-change-op!` might move the cursor twice!
         (when change-op? (handle-interrupted-change-op!))
         ; Putting the form here, after the change-op handler, because
         ; it might feed keys too. (Is that a valid problem? Change-op
         ; can only be interrupted by <c-c> or <esc> I guess...)
         (do ,...)
         (doau-when-exists :LeapLeave)
         nil))

    (macro with-highlight-chores [...]
      `(do (when new-search?
             (apply-backdrop reverse? ?target-windows))
           (do ,...)
           (highlight-cursor)
           (vim.cmd :redraw)))

    (macro with-highlight-cleanup [...]
      `(let [res# (do ,...)]
         (hl:cleanup ?target-windows)
         res#))

    (fn get-first-input []
      (if doing-traversal? state.repeat.in1
          dot-repeat? state.dot-repeat.in1
          (match (or (with-highlight-cleanup (get-input))
                     (exit-early))
            ; Here we can handle any other modifier key as "zeroth" input,
            ; if the need arises.
            spec-keys.repeat (do (set new-search? false)
                                 (or state.repeat.in1
                                     (exit-early (echo-no-prev-search))))
            in in)))

    ; No need to pass in `in1` every time once we have it, so let's curry this.
    (fn update-state* [in1]
      (fn [{: repeat : dot-repeat}]
        (when new-search?
          (when repeat
            (set state.repeat (doto repeat (tset :in1 in1))))
          (when (and dot-repeat dot-repeatable-op?)
            (set state.dot-repeat (doto dot-repeat (tset :in1 in1)))))))

    ; `first-jump?` should only be persisted inside `to` (i.e. the
    ; lifetime is one invocation), and better be managed by the function
    ; itself, so setting up a closure here.
    (local jump-to!
           (do (var first-jump? true)
               (fn [target]
                 (when target.wininfo
                   (api.nvim_set_current_win target.wininfo.winid))
                 (jump-to!* target.pos
                            {: mode : reverse?
                             :inclusive-motion? (and x-mode? (not reverse?))
                             :add-to-jumplist? (and first-jump?
                                                    (not doing-traversal?))
                             :adjust #(when x-mode?
                                        (push-cursor! :fwd)
                                        (when reverse? (push-cursor! :fwd)))})
                 (set first-jump? false))))

    (fn get-last-input [sublist {: display-targets-from}]
      (fn recur [group-offset initial-invoc?]
        (set-beacons sublist {: force-no-labels?})
        (with-highlight-chores
          (light-up-beacons sublist display-targets-from))
        (match (with-highlight-cleanup (get-input))
          input
          (if (and sublist.autojump? (not (user-forced-autojump?)))
              ; If auto-jump has been set heuristically (not forced),
              ; it implies that there are no subsequent groups.
              [input 0]

              (and (not doing-traversal?)
                   (one-of? input 
                     spec-keys.next_match_group
                     ; So that the repeat key can be == prev_match_group key.
                     (when-not initial-invoc? spec-keys.prev_match_group)))
              (let [labels sublist.label-set
                    num-of-groups (ceil (/ (length sublist) (length labels)))
                    max-offset (dec num-of-groups)
                    new-group-offset (-> group-offset
                                         ((match input
                                            spec-keys.next_match_group inc
                                            _ dec))
                                         (clamp 0 max-offset))]
                (set-label-states sublist {:group-offset new-group-offset})
                (recur new-group-offset))

              [input group-offset])))
      (recur 0 true))

    (fn get-traversal-action [in]
      (if (= in spec-keys.repeat) :to-next
          (and doing-traversal? (= in spec-keys.revert)) :to-prev))

    (fn get-target-with-active-primary-label [target-list input]
      (var res nil)
      (each [idx {: label : label-state &as target} (ipairs target-list)
             :until res]
        (when (and (= label input) (= label-state :active-primary))
          (set res [idx target])))
      res)

    ; //> Helpers

    ; After all the stage-setting, here comes the main action you've all been
    ; waiting for:

    (when-not (or dot-repeat? doing-traversal?)
      (doau-when-exists :LeapEnter)
      (echo "")  ; clean up the command line
      (with-highlight-chores nil))

    (match (get-first-input)
      in1
      (let [update-state (update-state* in1)
            prev-in2 (when-not new-search?
                       (if dot-repeat? state.dot-repeat.in2 state.repeat.in2))]
        (match (or (?. traversal-state :sublist)
                   (get-targets in1 {: reverse? :target-windows ?target-windows})
                   (exit-early (echo-not-found (.. in1 (or prev-in2 "")))))
          targets
          (do
            (when-not doing-traversal?
              (doto targets
                (populate-sublists)
                (set-sublist-attributes {: force-no-autojump?})
                (set-labels)
                (set-initial-label-states)))
            (when new-search?
              (set-beacons targets {})
              (with-highlight-chores (light-up-beacons targets)))
            (match (or prev-in2
                       (with-highlight-cleanup (get-input))
                       (exit-early))
              in2
              (do
                ; Should be saved here; a repeated search might have a match.
                (update-state {:repeat {: in2}})
                (match (or (?. traversal-state :sublist)
                           (. targets.sublists in2)
                           (exit-early (echo-not-found (.. in1 in2))))
                  [only nil]
                  (if (and dot-repeat? (not= state.dot-repeat.target-idx 1))
                      (exit-early)
                      (exit (update-state {:dot-repeat {: in2 :target-idx 1}})
                            (jump-to! only)))

                  [first &as sublist]
                  (if dot-repeat? (match (. sublist state.dot-repeat.target-idx)
                                    target (exit (jump-to! target))
                                    _ (exit-early))
                      (do
                        ; Our current position on the sublist.
                        (var curr-idx (or (?. traversal-state :idx) 0))
                        (when-not doing-traversal?
                          (when sublist.autojump? (jump-to! first) (set curr-idx 1)))
                        (match (or (get-last-input
                                     sublist {:display-targets-from (inc curr-idx)})
                                   (exit-early))
                          [in3 group-offset]
                          (match (when-not (or op-mode? omni? (> group-offset 0))
                                   (get-traversal-action in3))
                            action
                            (let [new-idx (match action
                                            :to-next (min (inc curr-idx) (length targets))
                                            :to-prev (max (dec curr-idx) 1))]
                              (jump-to! (. sublist new-idx))
                              (leap {: reverse? : x-mode?
                                     :traversal-state {: sublist :idx new-idx}}))

                            _ (match (when-not force-no-labels?
                                       (get-target-with-active-primary-label sublist in3))
                                [idx target]
                                (exit (update-state {:dot-repeat {: in2 :target-idx idx}})
                                      (jump-to! target))

                                _ (if (or sublist.autojump? doing-traversal?)
                                      (exit (vim.fn.feedkeys in3 :i))
                                      (exit-early))))))))))))))))


; Keymaps ///1

(fn set-default-keymaps [force?]
  (each [_ [mode lhs rhs]
         (ipairs
          [[:n "s"  "<Plug>(leap-forward)"]
           [:n "S"  "<Plug>(leap-backward)"]
           [:x "s"  "<Plug>(leap-forward)"]
           [:x "S"  "<Plug>(leap-backward)"]
           [:o "z"  "<Plug>(leap-forward)"]
           [:o "Z"  "<Plug>(leap-backward)"]
           [:o "x"  "<Plug>(leap-forward-x)"]
           [:o "X"  "<Plug>(leap-backward-x)"]
           [:n "gs" "<Plug>(leap-cross-window)"]
           [:x "gs" "<Plug>(leap-cross-window)"]
           [:o "gs" "<Plug>(leap-cross-window)"]])]
    (when (or force?
              ; Otherwise only set the keymaps if:
              ; 1. (A keyseq starting with) `lhs` is not already mapped
              ;    to something else.
              ; 2. There is no existing mapping to the <Plug> key.
              (and (= (vim.fn.mapcheck lhs mode) "")
                   (= (vim.fn.hasmapto rhs mode) 0)))
      (vim.keymap.set mode lhs rhs {:silent true}))))


; Just for our convenience, to be used here in the script.
(each [lhs rhs
       (pairs
         {"<Plug>(leap-dotrepeat-forward)"
          #(leap {:dot-repeat? true})
          "<Plug>(leap-dotrepeat-backward)"
          #(leap {:dot-repeat? true :reverse? true})
          "<Plug>(leap-dotrepeat-forward-x)"
          #(leap {:dot-repeat? true :x-mode? true})
          "<Plug>(leap-dotrepeat-backward-x)"
          #(leap {:dot-repeat? true :reverse? true :x-mode? true})})]
  (vim.keymap.set :o lhs rhs {:silent true}))


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

(init-highlight)

(api.nvim_create_augroup "LeapDefault" {})

; Colorscheme plugins might clear out our highlight definitions, without
; defining their own, so we re-init the highlight on every change.
(api.nvim_create_autocmd "ColorScheme"
                         {:group "LeapDefault"
                          :callback init-highlight})
(api.nvim_create_autocmd "User"
                         {:group "LeapDefault"
                          :pattern "LeapEnter"
                          :callback #(do (save-editor-opts)
                                         (set-temporary-editor-opts))})
(api.nvim_create_autocmd "User"
                         {:group "LeapDefault"
                          :pattern "LeapLeave"
                          :callback restore-editor-opts})


; Module ///1

{: opts
 : setup
 : state
 : leap
 :init_highlight init-highlight
 :set_default_keymaps set-default-keymaps}


; vim: foldmethod=marker foldmarker=///,//>
