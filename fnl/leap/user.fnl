; Convenience functions for users.

(fn with-traversal-keys [fwd-key bwd-key]
  "Returns a table can be used as or merged with `opts`, with
`keys.next_target`, `keys.prev_target`, and `safe_labels` set
appropriately."
  (local leap (require "leap"))
  (local keys (vim.deepcopy leap.opts.keys))

  (fn with-key [t key]
    (local t (case (type t) :table t _ [t]))
    (table.insert t key)
    t)

  (local keys* {:next_target (with-key keys.next_target fwd-key)
                :prev_target (with-key keys.prev_target bwd-key)})

  ; Remove the "prev" key from `safe_labels`, and use the "next" key as
  ; the first label.
  (var safe-labels (vim.deepcopy leap.opts.safe_labels))
  (when (= (type safe-labels) :string)
    (set safe-labels (vim.fn.split safe-labels "\\zs")))

  (local safe-labels*
         (icollect [_ l (ipairs safe-labels) :into [fwd-key]]
           (when (and (not= l fwd-key) (not= l bwd-key))
             l)))

  {:keys keys*
   :safe_labels safe-labels*})


(fn set-repeat-keys [fwd-key bwd-key opts*]
  (local opts* (or opts* {}))
  (local modes (or opts*.modes [:n :x :o]))
  (local relative-directions? opts*.relative_directions)

  (fn leap-repeat [backward-invoc?]  ; = started with `bdw-key` (rel. or abs.)
    (let [leap (require "leap")
          opts {:keys (vim.tbl_extend "force" leap.opts.keys
                        ; Just overwrite the fields, one wouldn't want to
                        ; switch to another key after starting with one.
                        {:next_target (if backward-invoc? bwd-key fwd-key)
                         :prev_target (if backward-invoc? fwd-key bwd-key)})}
          backward (if relative-directions?
                       (if backward-invoc?
                           (not leap.state.repeat.backward)
                           leap.state.repeat.backward)
                       backward-invoc?)]
      (leap.leap {:repeat true : opts : backward})))

  (vim.keymap.set modes fwd-key #(leap-repeat false)
                  {:silent true
                   :desc (if relative-directions?
                             "Repeat leap in the previous direction"
                             "Repeat leap forward")})
  (vim.keymap.set modes bwd-key #(leap-repeat true)
                  {:silent true
                   :desc (if relative-directions?
                             "Repeat leap in the opposite direction"
                             "Repeat leap backward")}))


; Deprecated.
(fn set-default-mappings []
  (each [_ [modes lhs rhs desc]
         (ipairs
          [[[:n :x :o] "s" "<Plug>(leap)" "Leap"]
           [[:n]       "S" "<Plug>(leap-from-window)" "Leap from window"]
           ])]
    (each [_ mode (ipairs modes)]
      (local rhs* (vim.fn.mapcheck lhs mode))
      (if (= rhs* "")
          (vim.keymap.set mode lhs rhs {:silent true :desc desc})
          (when (not= rhs* rhs)  ; make the call idempotent
            (local msg (.. "leap.nvim: set_default_mappings() "
                           "found conflicting mapping for " lhs ": " rhs*))
            (vim.notify msg vim.log.levels.WARN))))))


; Deprecated.
(fn create-default-mappings []
  (each [_ [modes lhs rhs desc]
         (ipairs
          [[[:n :x :o] "s"  "<Plug>(leap-forward)" "Leap forward"]
           [[:n :x :o] "S"  "<Plug>(leap-backward)" "Leap backward"]
           [[:n :x :o] "gs" "<Plug>(leap-from-window)" "Leap from window"]
           ])]
    (each [_ mode (ipairs modes)]
      (local rhs* (vim.fn.mapcheck lhs mode))
      (if (= rhs* "")
          (vim.keymap.set mode lhs rhs {:silent true :desc desc})
          (when (not= rhs* rhs)  ; make the call idempotent
            (local msg (.. "leap.nvim: create_default_mappings() "
                           "found conflicting mapping for " lhs ": " rhs*))
            (vim.notify msg vim.log.levels.WARN))))))


; Deprecated.
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
  (local opts (. (require "leap.opts") :default))
  (each [k v (pairs user-opts)]
    (set (. opts k) v)))


{:with_traversal_keys with-traversal-keys
 :set_repeat_keys set-repeat-keys
 :get_enterable_windows #((. (require "leap.util") :get_enterable_windows))
 :get_focusable_windows #((. (require "leap.util") :get_focusable_windows))
 ; ---
 :set_default_mappings set-default-mappings
 :create_default_mappings create-default-mappings
 :add_repeat_mappings set-repeat-keys
 :add_default_mappings add-default-mappings
 :set_default_keymaps set-default-keymaps
 :setup setup}
