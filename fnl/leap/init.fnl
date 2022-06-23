; We're exposing some fields from other modules here so that they can be
; accessed directly as `require('leap').foo`. Using a metatable is a convenient
; way to avoid requiring the modules ahead of time.

(setmetatable {}
  {:__index
   (fn [t k]
     (match k
       :leap (. (require "leap.main") :leap)
       :state (. (require "leap.main") :state)
       :setup (. (require "leap.user") :setup)
       :opts (require "leap.opts")
       :set_default_keymaps (. (require "leap.user") :set_default_keymaps)
       :init_highlight (fn [...] (: (require "leap.highlight") :init-highlight ...))))})
