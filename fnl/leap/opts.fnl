(local current_call {})  ; will be updated by `leap` on invocation

(local default
       {:max_aot_targets nil
        :max_highlighted_traversal_targets 10
        :highlight_unlabeled false
        :case_sensitive false
        :equivalence_classes [" \t\r\n"]
        :safe_labels ["s" "f" "n" "u" "t" "/"
                      "S" "F" "N" "L" "H" "M" "U" "G" "T" "?" "Z"]
        :labels ["s" "f" "n"
                 "j" "k" "l" "h" "o" "d" "w" "e" "m" "b"
                 "u" "y" "v" "r" "g" "t" "c" "x" "/" "z"
                 "S" "F" "N"
                 "J" "K" "L" "H" "O" "D" "W" "E" "M" "B"
                 "U" "Y" "V" "R" "G" "T" "C" "X" "?" "Z"]
        :special_keys {:repeat_search "<enter>"
                       :next_aot_match "<enter>"
                       :next_match [";" "<enter>"]
                       :prev_match ["," "<tab>"]
                       :next_group "<space>"
                       :prev_group "<tab>"
                       :multi_accept "<enter>"
                       :multi_revert "<backspace>"}})

; First try to look up everything in the `current_call` table,
; so that we can override settings on a per-call basis.
(-> {: current_call
     : default}
    (setmetatable {:__index (fn [self k]
                              (match (. self.current_call k)
                                v v  ; `false` should be returned too
                                _ (. self.default k)))}))
