(local opts (require "leap.opts"))

(local {: get-horizontal-bounds
        : get-cursor-pos
        : get-representative-char}
       (require "leap.util"))

(local api vim.api)
(local {: abs : max : pow} math)


(fn get-match-positions [pattern bounds {: backward? : whole-window?}]
  (let [[left-bound right-bound] bounds
        bounds-pat (if vim.wo.wrap ""
                       (.. "\\%>" (- left-bound 1) "v"
                           "\\%<" (+ right-bound 1) "v"))
        pattern (.. bounds-pat pattern)
        flags (if backward? "b" "")
        stopline (vim.fn.line (if backward? "w0" "w$"))
        saved-view (vim.fn.winsaveview)
        saved-cpo vim.o.cpo]

    (var match-at-curpos? whole-window?)

    (vim.opt.cpo:remove "c")  ; do not skip overlapping matches
    (when whole-window?
      (vim.fn.cursor [(vim.fn.line "w0") 1]))

    (local positions [])
    (local win-edge? {})  ; set of indexes (in `positions`)
    (var idx 0)  ; ~ match count

    (while true
      (local flags (or (and match-at-curpos? (.. flags "c")) flags))
      (set match-at-curpos? false)
      (local [line &as pos] (vim.fn.searchpos pattern flags stopline))
      (if (= line 0)   ; no match found
          (do (vim.fn.winrestview saved-view)
              (set vim.o.cpo saved-cpo)
              (lua :break))

          (not= (vim.fn.foldclosed line) -1)  ; in a closed fold
          (do (if backward?
                  (vim.fn.cursor (vim.fn.foldclosed line) 1)
                  (do (vim.fn.cursor (vim.fn.foldclosedend line) 0)
                      (vim.fn.cursor 0 (vim.fn.col "$")))))

          (do (table.insert positions pos)
              (set idx (+ idx 1))
              (when (= (vim.fn.virtcol ".") right-bound)
                (set (. win-edge? idx) true)))))

    (values positions win-edge?)))


(fn get-targets-in-current-window [pattern targets kwargs]
  (local {: backward? : offset : inputlen : whole-window? : skip-curpos?} kwargs)
  (local offset (or offset 0))
  (local wininfo (. (vim.fn.getwininfo (api.nvim_get_current_win)) 1))
  (local [curline curcol] (get-cursor-pos))
  (local bounds (get-horizontal-bounds))  ; [left right]
  ; The whole match should be visible.
  (when inputlen (set (. bounds 2) (- (. bounds 2) (max 0 (- inputlen 1)))))

  (local (match-positions win-edge?)
         (get-match-positions pattern bounds {: backward? : whole-window?}))

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

  (fn previewable? [col ch1 ch2]
    (if (= ch1 "\n")
        (opts.preview_filter "" ch1 "")
        (opts.preview_filter (vim.fn.strpart line-str (- col 2) 1 true) ch1 ch2)))

  (each [i [line col &as pos] (ipairs match-positions)]
    (when (not (and skip-curpos? (= line curline) (= (+ col offset) curcol)))
      (when (not= line prev-match.line)
        (set line-str (vim.fn.getline line)))
      ; Extracting the actual characters from the buffer at the
      ; match position.
      (var ch1 (vim.fn.strpart line-str (- col 1) 1 true))
      (var ch2 nil)
          ; On EOL - in this case, we're adding another, virtual
          ; \n after the real one, so that these can be targeted
          ; by pressing a newline alias twice. (See also
          ; `prepare-pattern` in `main.fnl`.)
      (if (= ch1 "") (do (set ch1 "\n")
                         (when (= inputlen 2)
                           (set ch2 "\n"))
                         (set add-target? true))

          (< inputlen 2) (set add-target? true)

          (do
            (set ch2 (vim.fn.strpart line-str (+ col -1 (ch1:len)) 1 true))
            (when (= ch2 "")  ; = ch1 is right before EOL
              (set ch2 "\n"))
            (local overlap?
                   (and (= line prev-match.line)
                        (if backward?
                            ; c1 c2
                            ;    p1 p2
                            (= col (- prev-match.col (ch1:len)))
                            ;    c1 c2
                            ; p1 p2
                            (= col (+ prev-match.col (prev-match.ch1:len))))))
            (local triplet?
                   (and overlap?
                        ; Same pair? (Eqv-classes & ignorecase considered.)
                        (= (get-representative-char ch2)
                           (get-representative-char prev-match.ch2))))
            (local skip? (and triplet?
                              (if backward? match-at-end? match-at-start?)))
            (set add-target? (not skip?))
            (when (and add-target? triplet?)
              (table.remove targets))
            (set prev-match {: line : col : ch1 : ch2})))

            (when add-target?
              (table.insert targets
                            {: wininfo : pos :chars [ch1 ch2]
                             :win-edge? (. win-edge? i)
                             :previewable? (or (< inputlen 2)
                                               (not opts.preview_filter)
                                               (previewable? col ch1 ch2))})))))


(fn add-directional-indexes [targets cursor-positions src-win]
  (local [curline curcol] (. cursor-positions src-win))
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


(fn euclidean-distance [[l1 c1] [l2 c2]]
  (let [editor-grid-aspect-ratio 0.3  ; arbitrary, should be good enough usually
        dx (* (abs (- c1 c2)) editor-grid-aspect-ratio)
        dy (abs (- l1 l2))]
    (pow (+ (* dx dx) (* dy dy)) 0.5)))


(fn rank [targets cursor-positions src-win]
  (each [_ target (ipairs targets)]
    (let [win target.wininfo.winid
          [line col &as pos] target.pos
          [cur-line cur-col &as cur-pos] (. cursor-positions win)
          distance (euclidean-distance pos cur-pos)
          curr-win-bonus (and (= win src-win) 30)
          curr-line-bonus (and curr-win-bonus (= line cur-line) 999)
          curr-line-fwd-bonus (and curr-line-bonus (> col cur-col) 999)]
      (set target.rank (- distance
                          (or curr-win-bonus 0)
                          (or curr-line-bonus 0)
                          (or curr-line-fwd-bonus 0))))))


(fn get-targets [pattern {: backward? : windows : offset : op-mode? : inputlen}]
  (let [whole-window? windows
        src-win (api.nvim_get_current_win)
        windows (or windows [src-win])
        curr-win-only? (match windows [src-win nil] true)
        cursor-positions {src-win (get-cursor-pos)}
        targets []]
    (each [_ win (ipairs windows)]
      (when (not curr-win-only?)
        (api.nvim_set_current_win win))
      (when whole-window?
        (set (. cursor-positions win) (get-cursor-pos)))
      ; Fill up the provided `targets`, instead of returning a new table.
      (get-targets-in-current-window
        pattern targets
        {: backward? : offset : whole-window? : inputlen
         :skip-curpos? (= win src-win)}))
    (when (not curr-win-only?)
      (api.nvim_set_current_win src-win))
    (when (> (length targets) 0)
      (when whole-window?  ; = bidirectional
        (when (and op-mode? curr-win-only?)
          ; Preserve the original (byte) order for dot-repeat, before sorting.
          (add-directional-indexes targets cursor-positions src-win))
        (rank targets cursor-positions src-win)
        (table.sort targets #(< (. $1 :rank) (. $2 :rank))))
      targets)))


{: get-horizontal-bounds  ; flit.nvim
 : get-match-positions    ; flit.nvim
 : get-targets}
