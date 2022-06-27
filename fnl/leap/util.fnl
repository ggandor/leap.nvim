(local api vim.api)
(local filter vim.tbl_filter)

(fn inc [x] (+ x 1))

(fn dec [x] (- x 1))

(fn clamp [x min max]
  (if (< x min) min
      (> x max) max
      x))


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
  (let [mode (. (api.nvim_get_mode) :mode)
        wins (api.nvim_tabpage_list_wins 0)
        curr-win (api.nvim_get_current_win)
        curr-buf (api.nvim_get_current_buf)
        visual|op-mode? (not= mode :n)]
    (filter #(and (. (api.nvim_win_get_config $) :focusable)
                  (not= $ curr-win)
                  (not (and visual|op-mode?  ; no sense in buffer switching then
                            (not= (api.nvim_win_get_buf $) curr-buf))))
            wins)))


{: inc
 : dec
 : clamp
 : get-char-at
 :get_enterable_windows get-enterable-windows}
