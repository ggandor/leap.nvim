; Convenience functions for users.

(fn add-default-mappings [force?]
  (each [_ [modes lhs rhs desc]
         (ipairs
          [[[:n :x :o] "s"  "<Plug>(leap-forward-to)" "Leap forward to"]
           [[:n :x :o] "S"  "<Plug>(leap-backward-to)" "Leap backward to"]
           [   [:x :o] "x"  "<Plug>(leap-forward-till)" "Leap forward till"]
           [   [:x :o] "X"  "<Plug>(leap-backward-till)" "Leap backward till"]
           [[:n :x :o] "gs" "<Plug>(leap-from-window)" "Leap from window"]
           [[:n :x :o] "gs" "<Plug>(leap-cross-window)" "Leap from window"]  ; deprecated
           ])]
    (each [_ mode (ipairs modes)]
      (when (or force?
                ; Otherwise only set the keymaps if:
                ; 1. (A keyseq starting with) `lhs` is not already mapped
                ;    to something else.
                ; 2. There is no existing mapping to the <Plug> key.
                (and (= (vim.fn.mapcheck lhs mode) "")
                     (= (vim.fn.hasmapto rhs mode) 0)))
        (vim.keymap.set mode lhs rhs {:silent true :desc desc})))))

(fn add-repeat-mappings [forward-key backward-key kwargs]
  (local kwargs (or kwargs {}))
  (local modes (or kwargs.modes [:n :x :o]))
  (local relative-directions? kwargs.relative_directions)

  (fn do-repeat [backward?]
    (let [state (. (require "leap.main") :state)
          sk (. (require "leap") :opts :special_keys)
          leap (. (require "leap") :leap)]
      (local id (vim.api.nvim_create_autocmd "User"
                  {:pattern "LeapPatternPost" :once true
                   :callback (fn []
                               (set state.saved_next_target sk.next_target)
                               (set state.saved_prev_target sk.prev_target)
                               (set sk.next_target
                                    (if backward? backward-key forward-key))
                               (set sk.prev_target
                                    (if backward? forward-key backward-key))
                               ; We might not reach LeapPatternPost if
                               ; no targets are found!
                               (set state.added_temp_keys true))}))
      (vim.api.nvim_create_autocmd "User"
        {:pattern "LeapLeave" :once true
         :callback (fn []
                     ; We might not have reached LeapPatternPost previously!
                     (pcall vim.api.nvim_del_autocmd id)
                     (when state.added_temp_keys
                       (set sk.next_target state.saved_next_target)
                       (set sk.prev_target state.saved_prev_target)
                       (set state.added_temp_keys false)))})
      (leap {:repeat true
             :backward (if relative-directions?
                           (if backward? (not state.repeat.backward)
                               state.repeat.backward)
                           backward?)})))

  ; TODO: if `relative-directions?`, change `desc` accordingly?
  (vim.keymap.set modes forward-key #(do-repeat)
                  {:silent true :desc "Repeat Leap motion"})
  (vim.keymap.set modes backward-key #(do-repeat true)
                  {:silent true :desc "Repeat Leap motion backward"}))

; Deprecated.
(fn set-default-keymaps [force?]
  (each [_ [mode lhs rhs]
         (ipairs
          [[:n "s"  "<Plug>(leap-forward)"]
           [:n "S"  "<Plug>(leap-backward)"]
           [:x "s"  "<Plug>(leap-forward)"]
           [:x "S"  "<Plug>(leap-backward)"]
           [:o "z"  "<Plug>(leap-forward)"]
           [:o "Z"  "<Plug>(leap-backward)"]
           [:o "x"  "<Plug>(leap-forward-x)"]
           [:o "X"  "<Plug>(leap-backward-x)"]
           [:n "gs" "<Plug>(leap-cross-window)"]
           [:x "gs" "<Plug>(leap-cross-window)"]
           [:o "gs" "<Plug>(leap-cross-window)"]])]
    (when (or force?
              (and (= (vim.fn.mapcheck lhs mode) "")
                   (= (vim.fn.hasmapto rhs mode) 0)))
      (vim.keymap.set mode lhs rhs {:silent true}))))

; Deprecated.
(fn setup [user-opts]
  (each [k v (pairs user-opts)]
    (tset (require "leap.opts") :default k v)))

{:add_default_mappings add-default-mappings
 :add_repeat_mappings add-repeat-mappings
 :set_default_keymaps set-default-keymaps
 : setup}
