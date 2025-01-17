(local {: inc
        : dec
        : get-cursor-pos}
       (require "leap.util"))

(local api vim.api)
(local map vim.tbl_map)
(local empty? vim.tbl_isempty)


(fn has-hl-group? [name]
  (not (empty? (api.nvim_get_hl 0 {: name}))))


(local M {:ns (api.nvim_create_namespace "")
          :extmarks []
          :group (setmetatable
                   {:match "LeapMatch"
                    :backdrop "LeapBackdrop"}
                   {:__index (fn [_ key]
                               (if (= key :label)
                                   (if (has-hl-group? "LeapLabelPrimary")
                                       "LeapLabelPrimary"
                                       "LeapLabel")
                                   (= key :label-dimmed)
                                   (if (has-hl-group? "LeapLabelSecondary")
                                       "LeapLabelSecondary"
                                       "LeapLabelDimmed")))})
          :priority {:label 65535
                     :cursor 65534
                     :backdrop 65533}})


(fn M.cleanup [self affected-windows]
  ; Clear beacons & cursor.
  (each [_ [bufnr id] (ipairs self.extmarks)]
    (when (api.nvim_buf_is_valid bufnr)
      (api.nvim_buf_del_extmark bufnr self.ns id)))
  (set self.extmarks [])
  ; Clear backdrop.
  (when (has-hl-group? self.group.backdrop)
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
  (when (has-hl-group? self.group.backdrop)
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


(fn blend [color1 color2 weight]
  ; n = (r + g + b), as returned by `nvim_get_hl`
  (fn ->rgb [n]
    (let [r (math.floor (/ n 0x10000))
          g (math.floor (% (/ n 0x100) 0x100))
          b (% n 0x100)]
      (values r g b)))

  (let [(r1 g1 b1) (->rgb color1)
        (r2 g2 b2) (->rgb color2)
        r (+ (* r1 (- 1 weight)) (* r2 weight))
        g (+ (* g1 (- 1 weight)) (* g2 weight))
        b (+ (* b1 (- 1 weight)) (* b2 weight))]
    (string.format "#%02x%02x%02x" r g b)))


(fn M.init-highlight [self force?]
  (let [name vim.g.colors_name
        bg vim.o.background
        ; vscode-neovim has a problem with linking to built-in groups.
        default? (or (= name "default") vim.g.vscode)
        defaults {self.group.label
                  (if (and default? (= bg "light"))
                      {:fg "#eef1f0"  ; NvimLightGrey1
                       :bg "#5588aa"
                       :bold true
                       :nocombine true
                       :ctermfg "red"}

                      (and default? (= bg "dark"))
                      {:fg "black"
                       :bg "#ccff88"
                       :nocombine true
                       :ctermfg "black"
                       :ctermbg "red"}

                      {:link "IncSearch"})

                  self.group.match
                  (if (and default? (= bg "light"))
                      {:bg "#eef1f0"  ; NvimLightGrey1
                       :ctermfg "black"
                       :ctermbg "red"}

                      (and default? (= bg "dark"))
                      {:fg "#ccff88"
                       :underline true
                       :nocombine true
                       :ctermfg "red"}

                      {:link "Search"})}]
    (when (or force?
              ; Otherwise LeapLabel would take priority, and override
              ; the legacy group, `default` does not help in this case.
              (not (has-hl-group? "LeapLabelPrimary")))
      (each [group-name def-map (pairs defaults)]
        (when (not force?) (set def-map.default true))
        (api.nvim_set_hl 0 group-name def-map)))
    ; Define LeapLabelDimmed.
    (let [normal (vim.api.nvim_get_hl 0 {:name "Normal" :link false})
          label* (vim.api.nvim_get_hl 0 {:name self.group.label :link false})]
      ; `bg` can be nil (transparent background), and e.g. the old default
      ; color scheme (`vim`) does not define Normal at all.
      ; Also, `nvim_get_hl()` apparently does not guarantee to return numeric
      ; values in the table (#260).
      (when (= (type normal.bg) "number")
        (when (= (type label*.bg) "number")
          (set label*.bg (blend label*.bg normal.bg 0.7)))
        (when (= (type label*.fg) "number")
          (set label*.fg (blend label*.fg normal.bg 0.5))))
      (vim.api.nvim_set_hl 0 self.group.label-dimmed label*))))


M
