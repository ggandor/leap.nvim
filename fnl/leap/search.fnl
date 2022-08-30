(local opts (require "leap.opts"))

(local {: inc
        : dec
        : replace-keycodes
        : get-cursor-pos
        : push-cursor!
        : get-char-at}
       (require "leap.util"))

(local api vim.api)
(local empty? vim.tbl_isempty)
(local {: abs : pow} math)


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


(fn to-next-in-window-pos! [backward? left-bound right-bound stopline]
  ; virtcol = like `col`, starting from the beginning of the line in the
  ; buffer, but every char counts as the #of screen columns it occupies
  ; (or would occupy), instead of the #of bytes.
  (let [forward? (not backward?)
        [line virtcol] [(vim.fn.line ".") (vim.fn.virtcol ".")]
        left-off? (< virtcol left-bound)
        right-off? (> virtcol right-bound)]
    (match (if (and left-off? backward?) [(dec line) right-bound]
               (and left-off? forward?) [line left-bound]
               (and right-off? backward?) [line right-bound]
               (and right-off? forward?) [(inc line) left-bound])
      [line* virtcol*]
      (if (or (and (= line line*) (= virtcol virtcol*))
              (and backward? (< line* stopline))
              (and forward? (> line* stopline)))
          :dead-end
          ; HACK: vim.fn.cursor expects bytecol, but we only have `right-bound`
          ; as virtcol (at least until `virtcol2col()` is not ported); so simply
          ; start crawling to the right, checking the virtcol... (When targeting
          ; the left bound, we might undershoot too - the virtcol of a position
          ; is always <= the bytecol of it -, but in that case it's no problem,
          ; just some unnecessary work afterwards, as we're still outside the
          ; on-screen area).
          (do (vim.fn.cursor [line* virtcol*])
              (when backward?
                (while (and (< (vim.fn.virtcol ".") right-bound)
                            (not (>= (vim.fn.col ".") (dec (vim.fn.col "$")))))  ; reached EOL
                  (vim.cmd "norm! l"))))))))


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
              (not (or vim.wo.wrap
                       (<= left-bound (vim.fn.virtcol ".") right-bound)))
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
      (match (get-char-at pos {})  ; EOL might fail (make this future-proof)
        ch1  ; not necessarily = `input` (if case-insensitive or input mapping)
        (let [(ch2 eol?) (match (get-char-at pos {:char-offset +1})
                           nil (values "\n" true)
                           ch ch)
              same-char-triplet? (and (= ch2 prev-match.ch2)
                                      (= line prev-match.line)
                                      (= col ((if backward? dec inc) prev-match.col)))]
          (set prev-match {: line : col : ch2})
          (when (not same-char-triplet?)
            (table.insert targets {: wininfo : pos :pair [ch1 ch2]
                                   ; TODO: `right-bound` = virtcol, but `col` = byte col!
                                   :edge-pos? (or eol? (= col right-bound))})))))
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


{: get-targets}
