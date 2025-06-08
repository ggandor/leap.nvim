(local M {:default {:preview_filter nil
                    :highlight_unlabeled_phase_one_targets false  ; deprecated
                    :max_highlighted_traversal_targets 10
                    :case_sensitive false
                    :keep_conceallevel false
                    :equivalence_classes [" \t\r\n"]
                    :substitute_chars {}                          ; deprecated
                    :safe_labels ["s" "f" "n" "u" "t" "/"
                                  "S" "F" "N" "L" "H" "M" "U" "G" "T" "Z" "?"]
                    :labels ["s" "f" "n"
                             "j" "k" "l" "h" "o" "d" "w" "e" "i" "m" "b" "u"
                             "y" "v" "r" "g" "t" "a" "q" "p" "c" "x" "z" "/"
                             "S" "F" "N"
                             "J" "K" "L" "H" "O" "D" "W" "E" "I" "M" "B" "U"
                             "Y" "V" "R" "G" "T" "A" "Q" "P" "C" "X" "Z" "?"]
                    :special_keys {:next_target "<enter>"
                                   :prev_target "<backspace>"
                                   :next_group "<space>"
                                   :prev_group "<backspace>"}}
          ; Will be updated by `leap` on invocation.
          :current_call {}})

; First try to look up everything in the `current_call` table,
; so that we can override settings on a per-call basis.
(setmetatable M
              {:__index (fn [self key]
                          (case (. self.current_call key)
                            nil (. self.default key)
                            val val  ; `false` should be returned too
                            ))})
