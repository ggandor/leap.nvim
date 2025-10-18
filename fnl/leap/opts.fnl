(local M {:default {:case_sensitive false
                    :equivalence_classes [" \t\r\n"]
                    :preview true
                    :safe_labels "sfnut/SFNLHMUGTZ?"
                    :labels (.. "sfnjklhodweimbuyvrgtaqpcxz/"
                                "SFNJKLHODWEIMBUYVRGTAQPCXZ?")
                    :keys {:next_target "<enter>"
                           :prev_target "<backspace>"
                           :next_group "<space>"
                           :prev_group "<backspace>"}
                    :vim_opts {:wo.scrolloff 0  ; keep the view when auto-jumping
                               :wo.sidescrolloff 0
                               :wo.conceallevel 0
                               :bo.modeline false}  ; lightspeed#81
                    ; Deprecated options.
                    :highlight_unlabeled_phase_one_targets false
                    :max_highlighted_traversal_targets 10
                    :substitute_chars {}}
          ; Will be updated by `leap` on invocation.
          :current_call {}})

; `default` might be accessed directly (see `init.fnl`), need to handle
; the deprecated name here too.
(setmetatable M.default
  {:__index (fn [self key*]
              (local key (case key* :special_keys :keys _ key*))
              (. self key))})

(setmetatable M
  {:__index (fn [self key*]
              (local key (case key* :special_keys :keys _ key*))
              ; Try to look up everything in the `current_call` table
              ; first, so that we can override settings on a per-call
              ; basis.
              (case (. self.current_call key)
                ; Checking for `nil`, as `false` should be returned too.
                nil (rawget self.default key)
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
