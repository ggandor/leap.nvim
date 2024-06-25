(local {: inc
        : dec
        : get-cursor-pos}
       (require "leap.util"))

(local api vim.api)
(local map vim.tbl_map)


(local M {:ns (api.nvim_create_namespace "")
          :extmarks []
          :group {:match "LeapMatch"
                  :backdrop "LeapBackdrop"}
          :priority {:label 65535
                     :cursor 65534
                     :backdrop 65533}})


(setmetatable M.group
  {:__index (fn [_ key]
              (when (= key :label)
                (if (pcall api.nvim_get_hl_by_name "LeapLabel" false)  ; deprecated
                    "LeapLabel"
                    "LeapLabelPrimary"

                ; (if (vim.tbl_isempty (api.nvim_get_hl 0 {:name "LeapLabel"}))  ; 0.9+
                ;     "LeapLabelPrimary"
                ;     "LeapLabel"
                  )))})


(fn M.cleanup [self affected-windows]
  ; Clear beacons & cursor.
  (each [_ [bufnr id] (ipairs self.extmarks)]
    (when (api.nvim_buf_is_valid bufnr)
      (api.nvim_buf_del_extmark bufnr self.ns id)))
  (set self.extmarks [])
  ; Clear backdrop.
  (when (pcall api.nvim_get_hl_by_name self.group.backdrop false)  ; group exists?
    (each [_ winid (ipairs affected-windows)]
      ; TODO: Edge case: what if the window has become invalid, but the
      ;       buffer is still there?
      (when (api.nvim_win_is_valid winid)
        (local wininfo (. (vim.fn.getwininfo winid) 1))
        (api.nvim_buf_clear_namespace
          wininfo.bufnr self.ns (dec wininfo.topline) wininfo.botline)))
    ; Safety measure for scrolloff > 0: we always clean up the current view too.
    (api.nvim_buf_clear_namespace 0 self.ns
                                  (dec (vim.fn.line "w0"))
                                  (vim.fn.line "w$"))))


(fn M.apply-backdrop [self backward? ?target-windows]
  (when (pcall api.nvim_get_hl_by_name self.group.backdrop false)  ; group exists?
    (if ?target-windows
        (each [_ winid (ipairs ?target-windows)]
          (local wininfo (. (vim.fn.getwininfo winid) 1))
          (vim.highlight.range wininfo.bufnr self.ns self.group.backdrop
                               [(dec wininfo.topline) 0]
                               [(dec wininfo.botline) -1]
                               {:priority self.priority.backdrop}))
        (let [[curline curcol] (map dec (get-cursor-pos))
              [win-top win-bot] (map dec [(vim.fn.line "w0") (vim.fn.line "w$")])
              [start finish] (if backward?
                                 [[win-top 0] [curline curcol]]
                                 [[curline (inc curcol)] [win-bot -1]])]
          ; Expects 0,0-indexed args; `finish` is exclusive.
          (vim.highlight.range 0 self.ns self.group.backdrop start finish
                               {:priority self.priority.backdrop})))))


; NOTE: Can be removed once minimal required nvim version is >= 0.10. (#70)
(fn M.highlight-cursor [self]
  "The cursor is down on the command line during `getchar`,
so we set a temporary highlight on it to see where we are."
  (let [[line col] (get-cursor-pos)
        line-str (vim.fn.getline line)
        ch-at-curpos (case (vim.fn.strpart line-str (dec col) 1 true)
                       "" " "  ; on an emtpy line
                       ch ch)
        id (api.nvim_buf_set_extmark 0 self.ns (dec line) (dec col)
                                     {:virt_text [[ch-at-curpos :Cursor]]
                                      :virt_text_pos "overlay"
                                      :hl_mode "combine"
                                      :priority self.priority.cursor})]
    (table.insert self.extmarks [(api.nvim_get_current_buf) id])))


(fn M.init-highlight [self force?]
  (let [bg vim.o.background
        defaults {self.group.match {:fg (if (= bg "light") "#222222" "#ccff88")
                                    :ctermfg "red"
                                    :underline true
                                    :nocombine true}
                  self.group.label {:fg "black"
                                    :bg (if (= bg "light") "#ffaa99" "#ccff88")
                                    :ctermfg "black"
                                    :ctermbg "red"
                                    :nocombine true}}]
    (each [group-name def-map (pairs defaults)]
      (when (not force?) (set def-map.default true))
      (api.nvim_set_hl 0 group-name def-map))))


M
