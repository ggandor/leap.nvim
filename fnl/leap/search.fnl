(local opts (require "leap.opts"))

(local {: get-cursor-pos
        : get-eq-class-of
        : ->representative-char}
       (require "leap.util"))

(local api vim.api)
(local empty? vim.tbl_isempty)
(local {: abs : pow} math)


(fn get-horizontal-bounds []
  "Return the first and last visible virtual column of the editable
window area.

+----------------------+
|XXXX                  |
|XXXX     C            |
|XXXX                  |
+----------------------+
 [--------------------]  window-width
 [--]                    textoff (e.g. foldcolumn)
 (--------]              offset-in-win
     (----]              offset-in-editable-win
"
  (let [window-width (api.nvim_win_get_width 0)
        textoff (. (vim.fn.getwininfo (api.nvim_get_current_win)) 1 :textoff)
        offset-in-win (- (vim.fn.wincol) 1)
        offset-in-editable-win (- offset-in-win textoff)
        ; Screen column of the first visible column in the editable area.
        left-bound (- (vim.fn.virtcol ".") offset-in-editable-win)
        right-bound (+ left-bound (- window-width textoff 1))]
    [left-bound right-bound]))


(fn get-match-positions [pattern [left-bound right-bound]
                         {: backward? : whole-window?}]
  "Return all visible positions of `pattern` in the current window."
  (let [horizontal-bounds (if vim.wo.wrap ""
                              (.. "\\%>" (- left-bound 1) "v"
                                  "\\%<" (+ right-bound 1) "v"))
        pattern (.. horizontal-bounds pattern)
        flags (if backward? "b" "")
        stopline (vim.fn.line (if backward? "w0" "w$"))
        saved-view (vim.fn.winsaveview)
        saved-cpo vim.o.cpo]

    (var match-at-curpos? whole-window?)

    (vim.opt.cpo:remove "c")  ; do not skip overlapping matches
    (when whole-window?
      (vim.fn.cursor [(vim.fn.line "w0") 1]))

    (local match-positions [])
    (local edge-pos-idx? {})  ; set of indexes (in `match-positions`)
    (var idx 0)  ; ~ match count

    ((fn loop []
       (local flags (or (and match-at-curpos? (.. flags "c")) flags))
       (set match-at-curpos? false)
       (local [line &as pos] (vim.fn.searchpos pattern flags stopline))
       (if (= line 0)   ; no match found
           (do (vim.fn.winrestview saved-view)
               (set vim.o.cpo saved-cpo))

           (not= (vim.fn.foldclosed line) -1)  ; in a closed fold
           (do (if backward?
                   (vim.fn.cursor (vim.fn.foldclosed line) 1)
                   (do (vim.fn.cursor (vim.fn.foldclosedend line) 0)
                       (vim.fn.cursor 0 (vim.fn.col "$"))))
               (loop))

           (do (table.insert match-positions pos)
               (set idx (+ idx 1))
               (when (= (vim.fn.virtcol ".") right-bound)
                 (tset edge-pos-idx? idx true))
               (loop)))))

    (values match-positions edge-pos-idx?)))


(fn get-targets-in-current-window [pattern targets
                                   {: backward? : offset
                                    : whole-window? : skip-curpos?}]
  "Fill a table that will store the positions and other metadata of all
in-window pairs that match `pattern`, in the order of discovery."
  (local offset (or offset 0))
  (local wininfo (. (vim.fn.getwininfo (api.nvim_get_current_win)) 1))
  (local [curline curcol] (get-cursor-pos))
  (local bounds (get-horizontal-bounds))  ; [left right]
  ; The whole 2-char match should be visible.
  (tset bounds 2 (- (. bounds 2) 1))

  (local (match-positions edge-pos-idx?) (get-match-positions
                                           pattern bounds
                                           {: backward? : whole-window?}))

  ; It is desirable for a same-character sequence to behave as a chunk,
  ; so if `offset` is positive, we want to match at the end, to include
  ; or exclude the whole sequence:

  ; ^ -> match position, | -> cursor with offset
  ; xxxxxxy
  ;     ^|     (forward +1)
  ; xxxxxxy
  ;     ^ |    (backward +2)
  (local match-at-end? (> offset 0))
  (local match-at-start? (not match-at-end?))

  (var line-str nil)
  (var prev-match {:line nil :col nil :ch1 nil :ch2 nil})  ; to find overlaps
  (var add-target? false)

  (each [i [line col &as pos] (ipairs match-positions)]
    (when (not (and skip-curpos? (= line curline) (= col curcol)))
      (when (not= line prev-match.line)
        (set line-str (vim.fn.getline line)))

      ; Extracting the actual characters from the buffer at the match
      ; position.
      (var ch1 (vim.fn.strpart line-str (- col 1) 1 true))
      (var ch2 nil)
      (if (= ch1 "")
          (do
            ; On EOL - in this case, we're adding another, virtual \n after the
            ; real one, so that these can be targeted by pressing a newline
            ; alias twice. (See also `prepare-pattern`.)
            (set ch1 "\n")
            (set ch2 "\n")
            (set add-target? true))
          (do
            (set ch2 (vim.fn.strpart line-str (+ col -1 (ch1:len)) 1 true))
            (when (= ch2 "")  ; = ch1 is right before EOL
              (set ch2 "\n"))
            (local overlap? (and (= line prev-match.line)
                                 (if backward?
                                     ; c1 c2
                                     ;    p1 p2
                                     (= col (- prev-match.col (ch1:len)))
                                     ;    c1 c2
                                     ; p1 p2
                                     (= col (+ prev-match.col (prev-match.ch1:len))))))
            (local triplet? (and overlap?
                                 ; Same pair? (Eq-classes & ignorecase considered.)
                                 (= (->representative-char ch2)
                                    (->representative-char prev-match.ch2))))
            (set prev-match {: line : col : ch1 : ch2})
            (local skip? (and triplet? (if backward? match-at-end? match-at-start?)))
            (if skip?
                (set add-target? false)
                (do
                  (when triplet? (table.remove targets))
                  (set add-target? true)))))

      (when add-target?
        (table.insert
          targets
          {: wininfo
           : pos
           :edge-pos? (. edge-pos-idx? i)
           :chars [ch1 ch2]
           :previewable?
           (or (not opts.preview_filter)
               (if (= ch1 "\n")
                   (opts.preview_filter "" ch1 "")
                   (opts.preview_filter
                     (vim.fn.strpart line-str (- col 2) 1 true) ch1 ch2)))})))))


(fn distance [[l1 c1] [l2 c2]]
  (let [editor-grid-aspect-ratio 0.3  ; arbitrary, should be good enough usually
        dx (* (abs (- c1 c2)) editor-grid-aspect-ratio)
        dy (abs (- l1 l2))]
    (pow (+ (* dx dx) (* dy dy)) 0.5)))


(fn sort-by-distance-from-cursor [targets cursor-positions source-winid]
  ; TODO: Check vim.wo.wrap for each window, and calculate accordingly.
  ; TODO: (Performance) vim.fn.screenpos is very costly for a large
  ;       number of targets...
  ;       -> Only get them when at least one line is actually wrapped?
  ;       -> Some FFI magic?
  (let [by-screen-pos? (and vim.o.wrap (< (length targets) 200))
        ; Cursor positions are registered in target windows only (the source
        ; window is not necessarily among them).
        [source-line source-col] (or (. cursor-positions source-winid) [-1 -1])]

    (when by-screen-pos?
      ; Update cursor positions to screen positions.
      (each [winid [line col] (pairs cursor-positions)]
        (local screenpos (vim.fn.screenpos winid line col))
        (tset cursor-positions winid [screenpos.row screenpos.col])))

    ; Set ranks.
    (each [_ {:pos [line col] :wininfo {: winid} &as target} (ipairs targets)]
      (if by-screen-pos?
          (do (local screenpos (vim.fn.screenpos winid line col))
              (set target.rank (distance [screenpos.row screenpos.col]
                                         (. cursor-positions winid))))
          (set target.rank (distance target.pos (. cursor-positions winid))))
      (when (= winid source-winid)
        ; Prioritize the current window a bit.
        (set target.rank (- target.rank 30))
        (when (= line source-line)
          ; In the current window, prioritize the current line.
          (set target.rank (- target.rank 999))
          (when (>= col source-col)
            ; On the current line, prioritize forward direction.
            (set target.rank (- target.rank 999))))))

    (table.sort targets #(< (. $1 :rank) (. $2 :rank)))))


; NOTE: If two-step processing is ebabled (AOT beacons), for any kind of
; input mapping (case-insensitivity, character classes, etc.) we need to
; tweak things in two different places:
;   1. For the first input, we modify the search pattern itself (here).
;   2. For the second input, we play with the sublist keys (see
;   `populate-sublists` in `main.fnl`).
(fn prepare-pattern [in1 ?in2]
  "Transform user input to the appropriate search pattern."

  (fn char-list-to-branching-regexp [chars]
    ; 1. Actual `\n` chars should appear as raw `\` + `n` in the pattern.
    ; 2. `\` itself might appear in the class, needs to be escaped.
    (local branches (vim.tbl_map #(case $ "\n" "\\n" "\\" "\\\\" ch ch) chars))
    (local pattern (table.concat branches "\\|"))
    (.. "\\(" pattern "\\)"))

  (fn expand-to-equivalence-class [char]    ; <-- 'a'
    (-?> (get-eq-class-of char)             ; --> {'a','á','ä'}
         (char-list-to-branching-regexp)))  ; --> '\\(a\\|á\\|ä\\)'

  (local pat1 (or (expand-to-equivalence-class in1)
                  ; Sole '\' needs to be escaped even for \V.
                  (in1:gsub "\\" "\\\\")))
  (local pat2 (or (and ?in2 (expand-to-equivalence-class ?in2))
                  ?in2
                  "\\_."))  ; match anything, including EOL

  ; If `\n\n` is a possible sequence to appear, add `\n` as a separate
  ; branch to the pattern, to make our convenience feature - targeting
  ; EOL positions (including empty lines) by typing the newline alias
  ; twice - work (see `get-targets-in-current-window`).
  ; This hack is always necessary for single-step processing, when we
  ; already have the full pattern (this includes repeating the previous
  ; search), but also for two-step processing, in the special case of
  ; targeting EOF (normally, `get-targets` takes care of this situation,
  ; but the pattern `\n\_.` does not match `\n$` if it's on the last
  ; line of the file).
  ; Note: The condition should be checked after the input patterns are
  ; expanded to include their whole equivalence classes.
  (local potential-nl-nl? (and (pat1:match "\\n")
                               (or (pat2:match "\\n") (not ?in2))))
  (local pattern (.. pat1 pat2 (if potential-nl-nl? "\\|\\n" "")))
  (.. (if opts.case_sensitive "\\C" "\\c") "\\V" pattern))


(fn get-targets [pattern {: backward? : offset : op-mode? : target-windows}]
  (let [whole-window? target-windows
        source-winid (api.nvim_get_current_win)
        target-windows (or target-windows [source-winid])
        curr-win-only? (match target-windows [source-winid nil] true)
        cursor-positions {}
        targets []]
    (each [_ winid (ipairs target-windows)]
      (when (not curr-win-only?)
        (api.nvim_set_current_win winid))
      (when whole-window?
        (tset cursor-positions winid (get-cursor-pos)))
      ; Fill up the provided `targets`, instead of returning a new table.
      (get-targets-in-current-window pattern targets
                                     {: backward? : offset : whole-window?
                                      :skip-curpos? (= winid source-winid)}))
    (when (not curr-win-only?)
      (api.nvim_set_current_win source-winid))
    (when (not (empty? targets))
      (when whole-window?  ; = bidirectional
        ; Preserve directional indexes for dot-repeat...
        (when (and op-mode? curr-win-only?)
          (local [curline curcol] (. cursor-positions source-winid))
          (var first-after (+ 1 (length targets)))  ; first idx after cursor pos
          (var stop? false)
          (each [i t (ipairs targets) &until stop?]
            (when (or (> (. t :pos 1) curline)
                      (and (= (. t :pos 1) curline)
                           (>= (. t :pos 2) curcol)))
              (set first-after i)
              (set stop? true)))
          (for [i 1 (- first-after 1)]
            (set (. targets i :idx) (- i first-after)))
          (for [i first-after (length targets)]
            (set (. targets i :idx) (- i (- first-after 1)))))
        ; ...before sorting.
        (sort-by-distance-from-cursor
          targets cursor-positions source-winid))
      targets)))


{: get-horizontal-bounds
 : get-match-positions
 : prepare-pattern
 : get-targets}
