(local util (require "leap.util"))

(local {: inc : dec} util)
(local api vim.api)
(local map vim.tbl_map)


(local M {:ns (api.nvim_create_namespace "")
          :group {:label-primary "LeapLabelPrimary"
                  :label-secondary "LeapLabelSecondary"
                  :match "LeapMatch"
                  :backdrop "LeapBackdrop"}
          :priority {:label 65535
                     :cursor 65534
                     :backdrop 65533}})


(fn M.cleanup [self affected-windows]
  (each [_ wininfo (ipairs affected-windows)]
    (api.nvim_buf_clear_namespace
      wininfo.bufnr self.ns (dec wininfo.topline) wininfo.botline))
  ; Safety measure for scrolloff > 0: we always clean up the current view too.
  (api.nvim_buf_clear_namespace 0 self.ns
                                (dec (vim.fn.line "w0"))
                                (vim.fn.line "w$")))


(fn M.apply-backdrop [self backward? ?target-windows]
  (match (pcall api.nvim_get_hl_by_name self.group.backdrop nil)  ; group exists?
    (true _)
    (if ?target-windows
        (each [_ win (ipairs ?target-windows)]
          (vim.highlight.range win.bufnr self.ns self.group.backdrop
                               [(dec win.topline) 0]
                               [(dec win.botline) -1]
                               {:priority self.priority.backdrop}))
        (let [[curline curcol] (map dec [(vim.fn.line ".") (vim.fn.col ".")])
              [win-top win-bot] [(dec (vim.fn.line "w0")) (dec (vim.fn.line "w$"))]
              [start finish] (if backward?
                                 [[win-top 0] [curline curcol]]
                                 [[curline (inc curcol)] [win-bot -1]])]
          ; Expects 0,0-indexed args; `finish` is exclusive.
          (vim.highlight.range 0 self.ns self.group.backdrop start finish
                               {:priority self.priority.backdrop})))))


(fn M.highlight-cursor [self ?pos]
  "The cursor is down on the command line during `getchar`,
so we set a temporary highlight on it to see where we are."
  (let [[line col &as pos] (or ?pos (util.get-cursor-pos))
        ; nil means the cursor is on an empty line.
        ch-at-curpos (or (util.get-char-at pos {}) " ")]  ; get-char-at needs 1,1-idx
    ; (Ab)using extmarks even here, to be able to highlight the cursor on empty lines too.
    (api.nvim_buf_set_extmark 0 self.ns (dec line) (dec col)
                              {:virt_text [[ch-at-curpos :Cursor]]
                               :virt_text_pos "overlay"
                               :hl_mode "combine"
                               :priority self.priority.cursor})))


(fn M.init-highlight [self force?]
  (let [bg vim.o.background
        defaults {self.group.match {:fg (match bg
                                          :light "#222222"
                                          _ "#ccff88")
                                    :ctermfg "red"
                                    :underline true
                                    :nocombine true}
                  self.group.label-primary {:fg "black"
                                            :bg (match bg
                                                  :light "#ff8877"
                                                  _ "#ccff88")
                                            :ctermfg "black"
                                            :ctermbg "red"
                                            :nocombine true}
                  self.group.label-secondary {:fg "black"
                                              :bg (match bg
                                                    :light "#77aaff"
                                                    _ "#99ccff")
                                              :ctermfg "black"
                                              :ctermbg "blue"
                                              :nocombine true}}]
    (each [group-name def-map (pairs defaults)]
      (when (not force?) (tset def-map :default true))
      (api.nvim_set_hl 0 group-name def-map))))


M
