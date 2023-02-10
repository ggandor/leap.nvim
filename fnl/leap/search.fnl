(local {: inc
        : dec
        : replace-keycodes
        : get-cursor-pos
        : push-cursor!
        : get-char-at
        : ->representative-char}
       (require "leap.util"))

(local api vim.api)
(local empty? vim.tbl_isempty)
(local {: abs : pow} math)


(fn get-horizontal-bounds []
  "
 [--------------------]  window-width
 (--------]              offset-in-win
 [--]                    textoff (e.g. foldcolumn)
     (----]              offset-in-editable-win
+----------------------+
|XXXX                  |
|XXXX     C            |
|XXXX                  |
+----------------------+
"
  (let [textoff (. (vim.fn.getwininfo (vim.fn.win_getid)) 1 :textoff)
        offset-in-win (dec (vim.fn.wincol))
        offset-in-editable-win (- offset-in-win textoff)
        ; I.e., screen column of the first visible column in the editable area.
        left-bound (- (vim.fn.virtcol ".") offset-in-editable-win)
        window-width (api.nvim_win_get_width 0)
        right-bound (+ left-bound (dec (- window-width textoff)))]
    [left-bound right-bound]))  ; screen columns


(fn to-next-in-window-pos! [backward? left-bound right-bound stopline]
  ; virtcol = like `col`, starting from the beginning of the line in the
  ; buffer, but every char counts as the #of screen columns it occupies
  ; (or would occupy), instead of the #of bytes.
  (let [forward? (not backward?)
        [line virtcol] [(vim.fn.line ".") (vim.fn.virtcol ".")]
        left-off? (< virtcol left-bound)
        right-off? (> virtcol right-bound)]
    (match (if (and left-off? backward?)  [(dec line) right-bound]
               (and left-off? forward?)   [line left-bound]
               (and right-off? backward?) [line right-bound]
               (and right-off? forward?)  [(inc line) left-bound])
      [line* virtcol*]
      (if (or (and (= line line*) (= virtcol virtcol*))
              (and backward? (< line* stopline))
              (and forward? (> line* stopline)))
          :dead-end
          (do
            (vim.fn.cursor [line* virtcol*])
            ; HACK: vim.fn.cursor expects bytecol, but we only have
            ; `right-bound` as virtcol (at least until `virtcol2col()`
            ; is not ported); so simply start crawling to the right,
            ; checking the virtcol... (When targeting the left bound, we
            ; might undershoot too - the virtcol of a position is always
            ; <= the bytecol of it -, but in that case it's no problem,
            ; just some unnecessary work afterwards, as we're still
            ; outside the on-screen area).
            (when backward?
              (while (and (< (vim.fn.virtcol ".") right-bound)
                          (< (vim.fn.col ".") (dec (vim.fn.col "$"))))
                (vim.cmd "norm! l"))))))))


(fn get-match-positions [pattern [left-bound right-bound]
                         {: backward? : whole-window?}]
  "Return all visible positions of `pattern` in the current window."
  (let [wintop (vim.fn.line "w0")
        winbot (vim.fn.line "w$")
        stopline (if backward? wintop winbot)
        saved-view (vim.fn.winsaveview)
        saved-cpo vim.o.cpo
        cleanup (fn []
                  (vim.fn.winrestview saved-view)
                  (set vim.o.cpo saved-cpo)
                  nil)]

    (var match-at-curpos? false)
    (when whole-window?
      (vim.fn.cursor [wintop left-bound])
      (set match-at-curpos? true))
    (vim.opt.cpo:remove "c")  ; do not skip overlapping matches

    (local res [])
    (fn loop []
      (local flags (.. (if backward? "b" "") (if match-at-curpos? "c" "")))
      (set match-at-curpos? false)
      (match (vim.fn.searchpos pattern flags stopline)
        [line col &as pos]
        (if
          ; No match found?
          (= line 0)
          (cleanup)

          ; Horizontally offscreen? => move
          (not (or vim.wo.wrap (<= left-bound (vim.fn.virtcol ".") right-bound)))
          (match (to-next-in-window-pos! backward? left-bound right-bound stopline)
            :dead-end (cleanup)  ; = on the first/last line in the window
            _ (do (set match-at-curpos? true) (loop)))

          ; In a closed fold? => move
          (not= (vim.fn.foldclosed line) -1)
          (do (if backward?
                  (vim.fn.cursor (vim.fn.foldclosed line) 1)
                  (do (vim.fn.cursor (vim.fn.foldclosedend line) 0)
                      (vim.fn.cursor 0 (vim.fn.col "$"))))
              (loop))

          ; We have a match!
          (do (table.insert res pos) (loop)))))
    (loop)
    res))


(fn get-targets-in-current-window [pattern  ; assumed to match 2 logical chars
                                   {: targets : backward? : whole-window?
                                    : match-last-overlapping? : skip-curpos?}]
  "Return a table that will store the positions and other metadata of
all in-window pairs that match `pattern`, in the order of discovery. A
target element in its final form has the following fields (the latter
ones might be set by subsequent functions):

Static attributes (set once and for all)
pos          : [lnum col]  1/1-indexed
chars        : [char+]
edge-pos?    : bool
?wininfo     : `vim.fn.getwininfo` dict
?label       : char

Dynamic attributes
?label-state :   'active-primary'
               | 'active-secondary'
               | 'selected'
               | 'inactive'
?beacon      : [col-offset [[char hl-group]]]
"
  (let [targets (or targets [])
        wininfo (. (vim.fn.getwininfo (vim.fn.win_getid)) 1)
        [curline curcol] (get-cursor-pos)
        [left-bound right-bound*] (get-horizontal-bounds)
        right-bound (dec right-bound*)  ; the whole match should be visible
        match-positions (get-match-positions pattern [left-bound right-bound]
                                             {: backward? : whole-window?})
        register-target (fn [target]
                          (set target.wininfo wininfo)
                          (table.insert targets target))]
    (var prev-match {})  ; to find overlaps
    (each [_ [line col &as pos] (ipairs match-positions)]
      (when (not (and skip-curpos? (= line curline) (= col curcol)))
        (match (get-char-at pos {})
          nil
          ; `get-char-at` works on "inner" lines, it cannot get \n.
          ; We provide it here for empty lines...
          (when (= col 1)
            (register-target {: pos :chars ["\n"] :empty-line? true}))

          ch1
          (let [ch2 (or (get-char-at pos {:char-offset +1})
                        "\n")  ; ...and for pre-\n chars
                ; TODO: `right-bound` = virtcol, but `col` = byte col!
                edge-pos? (or (= ch2 "\n") (= col right-bound))
                overlap? (and (= line prev-match.line)
                              (if backward?
                                  ; |     |ch1 |ch2
                                  ; |ch1  |ch2 |
                                  ; curr  prev       <---
                                  (= (- prev-match.col col) (ch1:len))
                                  ; |ch1  |ch2 |
                                  ; |     |ch1 |ch2
                                  ; prev  curr       --->
                                  (= (- col prev-match.col) (prev-match.ch1:len)))
                              (= (->representative-char ch2)
                                 (->representative-char (or prev-match.ch2 ""))))]
            (set prev-match {: line : col : ch1 : ch2})
            (when (or (not overlap?) match-last-overlapping?)
              (when (and overlap? match-last-overlapping?)
                (table.remove targets))  ; replace the previous one
              (register-target {: pos :chars [ch1 ch2] : edge-pos?}))))))
    (when (not (empty? targets))
      targets)))


(fn distance [[l1 c1] [l2 c2]]
  (let [editor-grid-aspect-ratio 0.3  ; arbitrary (make it configurable? get it programmatically?)
        [dx dy] [(abs (- c1 c2)) (abs (- l1 l2))]
         dx (* dx editor-grid-aspect-ratio)]
    (pow (+ (pow dx 2) (pow dy 2)) 0.5)))


(fn get-targets [pattern
                 {: backward? : match-last-overlapping? : target-windows}]
  (if (not target-windows)
      (get-targets-in-current-window pattern
                                     {: backward? : match-last-overlapping?})
      (let [targets []
            cursor-positions {}
            source-winid (vim.fn.win_getid)
            curr-win-only? (match target-windows
                             [{:winid source-winid} nil] true)]
        (each [_ wininfo (ipairs target-windows)]
          (let [winid wininfo.winid]
            (when (not curr-win-only?)
              (api.nvim_set_current_win winid))
            (tset cursor-positions winid (get-cursor-pos))
            ; Fill up the provided `targets`, instead of returning a new table.
            (get-targets-in-current-window pattern
                                           {: targets :whole-window? true
                                            : match-last-overlapping?
                                            :skip-curpos? (= winid source-winid)})))
        (when (not curr-win-only?)
          (api.nvim_set_current_win source-winid))
        (when (not (empty? targets))
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


{: get-horizontal-bounds
 : get-match-positions
 : get-targets}
