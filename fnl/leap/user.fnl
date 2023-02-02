; Convenience functions for users.

(fn add-default-mappings [force?]
  (each [_ [modes lhs rhs desc]
         (ipairs
          [[[:n :x :o] "s"  "<Plug>(leap-forward-to)" "Leap forward to"]
           [[:n :x :o] "S"  "<Plug>(leap-backward-to)" "Leap backward to"]
           [   [:x :o] "x"  "<Plug>(leap-forward-till)" "Leap forward till"]
           [   [:x :o] "X"  "<Plug>(leap-backward-till)" "Leap backward till"]
           [[:n :x :o] "gs" "<Plug>(leap-cross-window)" "Leap cross window"]])]
    (each [_ mode (ipairs modes)]
      (when (or force?
                ; Otherwise only set the keymaps if:
                ; 1. (A keyseq starting with) `lhs` is not already mapped
                ;    to something else.
                ; 2. There is no existing mapping to the <Plug> key.
                (and (= (vim.fn.mapcheck lhs mode) "")
                     (= (vim.fn.hasmapto rhs mode) 0)))
        (vim.keymap.set mode lhs rhs {:silent true :desc desc})))))

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
 :set_default_keymaps set-default-keymaps
 : setup}
