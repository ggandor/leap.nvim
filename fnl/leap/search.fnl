(local {: inc
        : dec
        : get-cursor-pos
        : ->representative-char
        : get-char-from}
       (require "leap.util"))

(local api vim.api)
(local empty? vim.tbl_isempty)
(local {: abs : pow} math)


(fn get-horizontal-bounds []
  "Return the first an last visible virtual column of the editable
window area.

 [--------------------]  window-width
 [--]                    textoff (e.g. foldcolumn)
 (--------]              offset-in-win
     (----]              offset-in-editable-win
+----------------------+
|XXXX                  |
|XXXX     C            |
|XXXX                  |
+----------------------+
"
  (let [window-width (api.nvim_win_get_width 0)
        textoff (. (vim.fn.getwininfo (vim.fn.win_getid)) 1 :textoff)
        offset-in-win (dec (vim.fn.wincol))
        offset-in-editable-win (- offset-in-win textoff)
        ; Screen column of the first visible column in the editable area.
        left-bound (- (vim.fn.virtcol ".") offset-in-editable-win)
        right-bound (+ left-bound (dec (- window-width textoff)))]
    [left-bound right-bound]))


(fn get-match-positions [pattern [left-bound right-bound]
                         {: backward? : whole-window?}]
  "Return all visible positions of `pattern` in the current window."
  (let [horizontal-bounds (or (and (not vim.wo.wrap)
                                   (.. "\\%>" (- left-bound 1) "v"
                                       "\\%<" (+ right-bound 1) "v"))
                              "")
        pattern (.. horizontal-bounds pattern)
        stopline (vim.fn.line (if backward? "w0" "w$"))
        saved-view (vim.fn.winsaveview)
        saved-cpo vim.o.cpo
        cleanup #(do (vim.fn.winrestview saved-view)
                     (set vim.o.cpo saved-cpo))]

    (vim.opt.cpo:remove "c")  ; do not skip overlapping matches

    (var match-at-curpos? false)
    (when whole-window?
      (vim.fn.cursor [(vim.fn.line "w0") 1])
      (set match-at-curpos? true))

    (var i 0)  ; match count
    (local at-right-bound? {})  ; set of indices (1-indexed)
    (local match-positions [])
    ((fn loop []
       (local flags (.. (if backward? "b" "") (if match-at-curpos? "c" "")))
       (set match-at-curpos? false)
       (local [line col &as pos] (vim.fn.searchpos pattern flags stopline))
       (if (= line 0)   ; No match ([0,0])?
           (cleanup)

           (not= (vim.fn.foldclosed line) -1)  ; In a closed fold?
           (do (if backward?
                   (vim.fn.cursor (vim.fn.foldclosed line) 1)
                   (do (vim.fn.cursor (vim.fn.foldclosedend line) 0)
                       (vim.fn.cursor 0 (vim.fn.col "$"))))
               (loop))

           (do (table.insert match-positions pos)
               (set i (+ i 1))
               (when (= (vim.fn.virtcol ".") right-bound)
                 (tset at-right-bound? i true))
               (loop)))))

    (values match-positions at-right-bound?)))


(fn get-targets-in-current-window [pattern  ; assumed to match 2 logical chars
                                   {: targets : backward? : whole-window?
                                    : match-xxx*-at-the-end? : skip-curpos?}]
  "Fill a table that will store the positions and other metadata of all
in-window pairs that match `pattern`, in the order of discovery. A
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
  (let [wininfo (. (vim.fn.getwininfo (vim.fn.win_getid)) 1)
        [curline curcol] (get-cursor-pos)
        [left-bound right-bound*] (get-horizontal-bounds)
        right-bound (dec right-bound*)  ; the whole 2-char match should be visible
        (match-positions at-right-bound?)
        (get-match-positions pattern [left-bound right-bound]
                             {: backward? : whole-window?})]
    (var line-str nil)
    (var prev-match {})  ; to find overlaps
    (each [i [line col &as pos] (ipairs match-positions)]
      (when (not (and skip-curpos? (= line curline) (= col curcol)))
        (when (not= line prev-match.line)
          (set line-str (vim.fn.getline line)))
        (local start (vim.fn.charidx line-str (- col 1)))
        (case (get-char-from line-str start)
          "" (when (= col 1)  ; on an empty line
               (table.insert targets {: wininfo : pos :chars ["\n"]
                                      :empty-line? true}))
          ch1 (let [ch2 (case (get-char-from line-str (+ start 1))
                          "" "\n"  ; before EOL
                          ch ch)
                    xxx? (and
                           ; Same line?
                           (= line prev-match.line)
                           ; Overlap? (Multibyte chars considered.)
                           (if backward?
                               ; c1 c2
                               ;    p1 p2
                               (= col (- prev-match.col (ch1:len)))
                               ;    c1 c2
                               ; p1 p2
                               (= col (+ prev-match.col (prev-match.ch1:len))))
                            ; Same pair? (Eq-classes & ignorecase considered.)
                            (= (->representative-char ch2)
                               (->representative-char (or prev-match.ch2 ""))))]
                (set prev-match {: line : col : ch1 : ch2})
                (when (or (not xxx?) (and xxx? match-xxx*-at-the-end?))
                  (when (and xxx? match-xxx*-at-the-end?)
                    (table.remove targets))  ; delete the previous one
                  (table.insert targets {: wininfo : pos :chars [ch1 ch2]
                                         :edge-pos? (or (. at-right-bound? i)
                                                        (= ch2 "\n"))}))))))))


(fn distance [[l1 c1] [l2 c2]]
  (let [editor-grid-aspect-ratio 0.3  ; arbitrary (make it configurable? get it programmatically?)
        [dx dy] [(abs (- c1 c2)) (abs (- l1 l2))]
         dx (* dx editor-grid-aspect-ratio)]
    (pow (+ (pow dx 2) (pow dy 2)) 0.5)))


(fn sort-by-distance-from-cursor [targets cursor-positions]
  ; TODO: Check vim.wo.wrap for each window, and calculate accordingly.
  ; TODO: (Performance) vim.fn.screenpos is very costly for a large
  ;       number of targets...
  ;       -> Only get them when at least one line is actually wrapped?
  ;       -> Some FFI magic?
  (let [by-screen-pos? (and vim.o.wrap (< (length targets) 200))]
    (when by-screen-pos?
      ; Update cursor positions to screen positions.
      (each [winid [line col] (pairs cursor-positions)]
        (local {: row : col} (vim.fn.screenpos winid line col))
        (tset cursor-positions winid [row col])))
    (each [_ {:pos [line col] :wininfo {: winid} &as target} (ipairs targets)]
      (when by-screen-pos?
        ; Add a screen position field to each target.
        ; PERF. BOTTLENECK
        (local {: row : col} (vim.fn.screenpos winid line col))
        (set target.screenpos [row col]))
      (set target.rank (distance (or target.screenpos target.pos)
                                 (. cursor-positions winid))))
    (table.sort targets #(< (. $1 :rank) (. $2 :rank)))))


(fn get-targets [pattern
                 {: backward? : match-xxx*-at-the-end? : target-windows}]
  (let [whole-window? target-windows
        source-winid (vim.fn.win_getid)
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
      (get-targets-in-current-window pattern
                                     {: targets : backward? : whole-window?
                                      : match-xxx*-at-the-end?
                                      :skip-curpos? (= winid source-winid)}))
    (when (not curr-win-only?)
      (api.nvim_set_current_win source-winid))
    (when (not (empty? targets))
      (when whole-window?
        (sort-by-distance-from-cursor targets cursor-positions))
      targets)))


{: get-horizontal-bounds
 : get-match-positions
 : get-targets}
