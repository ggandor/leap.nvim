(local opts (require "leap.opts"))

(local api vim.api)

; Mind that lua string.lower/upper are ASCII only.
(local lower vim.fn.tolower)
(local upper vim.fn.toupper)


(fn inc [x] (+ x 1))

(fn dec [x] (- x 1))

(fn clamp [x min max]
  (if (< x min) min
      (> x max) max
      x))

(fn echo [msg]
  (api.nvim_echo [[msg]] false []))

(fn get-cursor-pos []
  [(vim.fn.line ".") (vim.fn.col ".")])


(fn get-enterable-windows []
  (let [wins (api.nvim_tabpage_list_wins 0)
        curr-win (api.nvim_get_current_win)]
    (vim.tbl_filter
      #(let [config (api.nvim_win_get_config $)]
         (and config.focusable
              ; Exclude auto-closing hover popups (e.g. LSP) (#137).
              (= config.relative "")
              (not= $ curr-win)))
      wins)))


(fn get-focusable-windows []
  [(vim.api.nvim_get_current_win) (unpack (get-enterable-windows))])


; Equivalence classes

(fn get-equivalence-class [ch]
  (if opts.case_sensitive
      (. opts.eqv_class_of ch)
      (or (. opts.eqv_class_of (lower ch))
          (. opts.eqv_class_of (upper ch)))))


(fn get-representative-char [ch]
  ; We choose the first one from an equivalence class (arbitrary).
  (local ch* (or (?. (get-equivalence-class ch) 1)
                 ch))
  (if opts.case_sensitive ch* (lower ch*)))


(fn char-list-to-branching-regexp [chars]
  ; 1. Actual `\n` chars should appear as raw `\` + `n` in the pattern.
  ; 2. `\` itself might appear in the class, needs to be escaped.
  (let [prepare #(case $ "\n" "\\n" "\\" "\\\\" ch ch)
        branches (vim.tbl_map prepare chars)]
    (.. "\\(" (table.concat branches "\\|") "\\)")))


(fn char-to-search-pattern [char]                ; <-- 'a'
  (-> (or (get-equivalence-class char) [char])   ; --> {'a','á','ä'}
      (char-list-to-branching-regexp)))          ; --> '\\(a\\|á\\|ä\\)'


; Input

(local <bs> (vim.keycode "<bs>"))
(local <cr> (vim.keycode "<cr>"))
(local <esc> (vim.keycode "<esc>"))


(fn get-char []
  (local (ok? ch) (pcall vim.fn.getcharstr))  ; pcall for <C-c>
  ; <esc> should cleanly exit anytime.
  (when (and ok? (not= ch <esc>)) ch))


(fn get-char-keymapped [prompt]
  "Waits for keymapped sequences (see :help mbyte-keymap).
Gets and returns a `prompt` value, so that multiple calls can be
sequenced."
  (var prompt (or prompt ">"))

  (fn echo-prompt [seq]
    (api.nvim_echo [[prompt] [(or seq "") :ErrorMsg]] false []))

  (fn accept [ch]
    (set prompt (.. prompt ch))
    (echo-prompt)
    ch)

  (fn loop [seq]  ; actual input characters so far (str)
    (local |seq| (length (or seq "")))
    ; Arbitrary limit (`mapcheck` will continue to give back a candidate
    ; if the start of `seq` matches, need to cut the gibberish somewhere).
    (when (<= 1 |seq| 5)
      (echo-prompt seq)
      (let [candidate-rhs (vim.fn.mapcheck seq :l)
            matching-rhs (vim.fn.maparg seq :l)]
        (if (= candidate-rhs "")
            ; Accept the sole input character as it is
            ; (implies |seq|=1, no recursion here).
            (accept seq)

            (= matching-rhs candidate-rhs)
            (accept matching-rhs)

            (case (get-char)
              (where (= <bs>))
              ; Delete back a character.
              (loop
                (if (>= |seq| 2)
                    (seq:sub 1 (dec |seq|))
                    seq))

              (where (= <cr>))
              ; Force accepting the current input.
              (if (not= matching-rhs "")
                  (accept matching-rhs)

                  (= |seq| 1)
                  (accept seq)

                  (loop seq))

              ; Else consume and continue.
              ch (loop (.. seq ch)))))))

  (if (not= vim.bo.iminsert 1)  ; no keymap is active
      (get-char)
      (do
        (echo-prompt)
        (case (loop (get-char))
          input (values input prompt)
          _ (echo "")))))


{: inc
 : dec
 : clamp
 : echo
 : get-cursor-pos
 :get_enterable_windows get-enterable-windows
 :get_focusable_windows get-focusable-windows
 : char-to-search-pattern
 : get-representative-char
 : get-char
 : get-char-keymapped}
