; We're exposing some fields from other modules here so that they can be
; accessed directly as `require('leap').foo`. Using a metatable is a convenient
; way to avoid requiring the modules ahead of time.

(setmetatable {}
  {:__index
   (fn [_ k]
     (case k
       :opts (. (require "leap.opts") :default)
       :leap (. (require "leap.main") :leap)
       :state (. (require "leap.main") :state)
       :init_hl (fn [...]
                  (: (require "leap.highlight") :init ...))
       :setup (. (require "leap.user") :setup)
       :set_default_mappings (. (require "leap.user") :set_default_mappings)
       ; deprecated ones
       :init_highlight (fn [...]
                         (: (require "leap.highlight") :init ...))
       :create_default_mappings (. (require "leap.user") :create_default_mappings)
       :add_repeat_mappings (. (require "leap.user") :add_repeat_mappings)
       :add_default_mappings (. (require "leap.user") :add_default_mappings)
       :set_default_keymaps (. (require "leap.user") :set_default_keymaps)
       ))})
