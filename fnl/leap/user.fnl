; Convenience functions for users.

(fn setup [user-opts]
  (each [k v (pairs user-opts)]
    (tset (require "leap.opts") k v)))

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
              ; Otherwise only set the keymaps if:
              ; 1. (A keyseq starting with) `lhs` is not already mapped
              ;    to something else.
              ; 2. There is no existing mapping to the <Plug> key.
              (and (= (vim.fn.mapcheck lhs mode) "")
                   (= (vim.fn.hasmapto rhs mode) 0)))
      (vim.keymap.set mode lhs rhs {:silent true}))))

{: setup
 :set_default_keymaps set-default-keymaps}
