(local M {:default {:case_sensitive false
                    :equivalence_classes [" \t\r\n"]
                    :preview_filter nil
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
                                   :prev_group "<backspace>"}
                    :vim_opts {:wo.scrolloff 0  ; keep the view when auto-jumping
                               :wo.sidescrolloff 0
                               :wo.conceallevel 0
                               :bo.modeline false}  ; lightspeed#81
                    :show_label_on_start_of_match false
                    ; Deprecated options.
                    :highlight_unlabeled_phase_one_targets false
                    :max_highlighted_traversal_targets 10
                    :substitute_chars {}}
          ; Will be updated by `leap` on invocation.
          :current_call {}})

(setmetatable M
  {:__index (fn [self key]
              ; Try to look up everything in the `current_call` table
              ; first, so that we can override settings on a per-call
              ; basis.
              (case (. self.current_call key)
                ; Checking for `nil`, as `false` should be returned too.
                nil (. self.default key)
                val (if (and (= (type val) :table)
                             (not (vim.isarray val))
                             (not= (?. (getmetatable val) :merge) false))
                        ; On the first access, we automatically merge
                        ; map-like nested tables with the defaults.
                        ; This way users can set the relevant values
                        ; only, without having to deepcopy the whole
                        ; subtable from `default`, and then modify it.
                        (do
                          (each [k v (pairs (. self.default key))]
                            (when (= (. val k) nil)
                              (set (. val k) v)))
                          ; The metatable is used as a convenient flag.
                          ; It can also be used by users to prevent
                          ; merging in the first place.
                          (setmetatable val {:merge false}))
                        val)))})
