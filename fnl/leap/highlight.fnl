(local api vim.api)

(fn dec [x] (- x 1))

(local M {:group {:label-primary "LeapLabelPrimary"
                  :label-secondary "LeapLabelSecondary"
                  :match "LeapMatch"
                  :backdrop "LeapBackdrop"}
          :priority {:label 65535
                     :cursor 65534
                     :backdrop 65533}
          :ns (api.nvim_create_namespace "")})

(fn M.cleanup [self ?target-windows]
  (when ?target-windows
    (each [_ wininfo (ipairs ?target-windows)]
      (api.nvim_buf_clear_namespace
        wininfo.bufnr self.ns (dec wininfo.topline) wininfo.botline)))
  ; We need to clean up the cursor highlight in the current window anyway.
  (api.nvim_buf_clear_namespace 0 self.ns
                                (dec (vim.fn.line "w0"))
                                (vim.fn.line "w$")))

(fn M.apply-backdrop [self reverse? ?target-windows]
  (match (pcall api.nvim_get_hl_by_name self.group.backdrop nil)  ; group exists?
    (true _)
    (if ?target-windows
        (each [_ win (ipairs ?target-windows)]
          (vim.highlight.range win.bufnr self.ns self.group.backdrop
                               [(dec win.topline) 0]
                               [(dec win.botline) -1]
                               {:priority self.priority.backdrop}))
        (let [[curline curcol] (map dec (get-cursor-pos))
              [win-top win-bot] [(dec (vim.fn.line "w0")) (dec (vim.fn.line "w$"))]
              [start finish] (if reverse?
                                 [[win-top 0] [curline curcol]]
                                 [[curline (inc curcol)] [win-bot -1]])]
          ; Expects 0,0-indexed args; `finish` is exclusive.
          (vim.highlight.range 0 self.ns self.group.backdrop start finish
                               {:priority self.priority.backdrop})))))

(fn M.init-highlight [self force?]
  (local bg vim.o.background)
  (local def-maps
         {self.group.match
          {:fg (match bg :light "#222222" _ "#ccff88")
           :ctermfg "red"
           :underline true
           :nocombine true}
          self.group.label-primary
          {:fg "black"
           :bg (match bg :light "#ff8877" _ "#ccff88")
           :ctermfg "black"
           :ctermbg "red"
           :nocombine true}
          self.group.label-secondary
          {:fg "black"
           :bg (match bg :light "#77aaff" _ "#99ccff")
           :ctermfg "black"
           :ctermbg "blue"
           :nocombine true}})
  (each [name def-map (pairs def-maps)]
    (when (not force?) (tset def-map :default true))
    (api.nvim_set_hl 0 name def-map)))

M
