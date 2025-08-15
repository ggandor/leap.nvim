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

(fn get-cursor-pos []
  [(vim.fn.line ".") (vim.fn.col ".")])


(fn get-enterable-windows []
  (let [wins (api.nvim_tabpage_list_wins 0)
        curr-win (api.nvim_get_current_win)]
    (filter #(let [config (api.nvim_win_get_config $)]
               (and config.focusable
                    ; Exclude auto-closing hover popups (e.g. LSP) (#137).
                    (= config.relative "")
                    (not= $ curr-win)))
            wins)))


(fn get-focusable-windows []
  [(vim.api.nvim_get_current_win) (unpack (get-enterable-windows))])


; Equivalence classes

; NOTE: Lua's string.lower/upper are only for ASCII,
; use vim.fn.tolower/toupper everywhere.

(fn get-eqv-class [ch]
  (if opts.case_sensitive
      (. opts.eqv_class_of ch)
      (or (. opts.eqv_class_of (vim.fn.tolower ch))
          (. opts.eqv_class_of (vim.fn.toupper ch)))))


(fn get-representative-char [ch]
  ; We choose the first one from an equivalence class (arbitrary).
  (local ch* (or (?. (get-eqv-class ch) 1) ch))
  (if opts.case_sensitive ch* (vim.fn.tolower ch*)))


(fn char-list-to-branching-regexp [chars]
  ; 1. Actual `\n` chars should appear as raw `\` + `n` in the pattern.
  ; 2. `\` itself might appear in the class, needs to be escaped.
  (local branches (vim.tbl_map #(case $ "\n" "\\n" "\\" "\\\\" ch ch) chars))
  (local pattern (table.concat branches "\\|"))
  (.. "\\(" pattern "\\)"))


(fn get-eqv-pattern [char]                ; <-- 'a'
  (-?> (get-eqv-class char)               ; --> {'a','á','ä'}
       (char-list-to-branching-regexp)))  ; --> '\\(a\\|á\\|ä\\)'


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
 : get-eqv-pattern
 : get-representative-char
 : get-char
 : get-char-keymapped}
