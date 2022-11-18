(local opts (require "leap.opts"))

(local api vim.api)
(local filter vim.tbl_filter)


(fn inc [x] (+ x 1))

(fn dec [x] (- x 1))

(fn clamp [x min max]
  (if (< x min) min
      (> x max) max
      x))

(fn echo [msg]
  (api.nvim_echo [[msg]] false []))

(fn replace-keycodes [s]
  (api.nvim_replace_termcodes s true false true))

(fn get-cursor-pos []
  [(vim.fn.line ".") (vim.fn.col ".")])

(fn push-cursor! [direction]
  "Push cursor 1 character to the left or right, possibly beyond EOL."
  (vim.fn.search "\\_." (match direction :fwd "W" :bwd "bW")))


(fn get-char-at [[line byte-col] {: char-offset}]  ; expects (1,1)-indexed input
  "Get character at the given position in a multibyte-aware manner.
An optional offset argument can be given to get the nth-next screen
character instead."
  (let [line-str (vim.fn.getline line)
        char-idx (vim.fn.charidx line-str (- byte-col 1))  ; expects 0-indexed col
        char-nr (vim.fn.strgetchar line-str (+ char-idx (or char-offset 0)))]
    (when (not= char-nr -1)
      (vim.fn.nr2char char-nr))))


(fn get-enterable-windows []
  (let [wins (api.nvim_tabpage_list_wins 0)
        curr-win (api.nvim_get_current_win)
        curr-buf (api.nvim_get_current_buf)]
    (filter #(and (. (api.nvim_win_get_config $) :focusable)
                  (not= $ curr-win))
            wins)))


; NOTE: Lua's string.lower/upper are only for ASCII,
; use vim.fn.tolower/toupper everywhere.

(fn get-eq-class-of [ch]
  (if opts.case_sensitive
      (. opts.eq_class_of ch)
      (or (. opts.eq_class_of (vim.fn.tolower ch))
          (. opts.eq_class_of (vim.fn.toupper ch)))))


(fn ->representative-char [ch]
  ; We choose the first one from an equiv-class (arbitrary).
  (local ch* (or (?. (get-eq-class-of ch) 1) ch))
  (if opts.case_sensitive ch* (vim.fn.tolower ch*)))


; Input

(local <bs> (replace-keycodes "<bs>"))
(local <cr> (replace-keycodes "<cr>"))
(local <esc> (replace-keycodes "<esc>"))


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
              <bs> (loop (if (>= |seq| 2) (seq:sub 1 (dec |seq|)) seq))
              <cr> (if (not= rhs "") (accept rhs)  ; <enter> can accept a shorter one
                       (= |seq| 1) (accept seq)
                       (loop seq))
              ch (loop (.. seq ch)))))))

  (if (not= vim.bo.iminsert 1) (get-input)  ; no keymap is active
      (do (echo-prompt)
          (match (loop (get-input))
            in in
            _ (echo "")))))


{: inc
 : dec
 : clamp
 : echo
 : replace-keycodes
 : get-cursor-pos
 : push-cursor!
 : get-char-at
 :get_enterable_windows get-enterable-windows
 : get-eq-class-of
 : ->representative-char
 : get-input
 : get-input-by-keymap}
