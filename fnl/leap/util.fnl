(local opts (require "leap.opts"))

(local api vim.api)
(local filter vim.tbl_filter)


(fn inc [x] (+ x 1))

(fn dec [x] (- x 1))

(fn clamp [x min max]
  (if (< x min) min
      (> x max) max
      x))

(fn get-cursor-pos []
  [(vim.fn.line ".") (vim.fn.col ".")])


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


{: inc
 : dec
 : clamp
 : get-cursor-pos
 : get-char-at
 :get_enterable_windows get-enterable-windows
 : get-eq-class-of
 : ->representative-char}
