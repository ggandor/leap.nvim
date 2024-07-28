(local api vim.api)


(fn get-nodes []
  (if (not (pcall vim.treesitter.get_parser))
      (values nil "No treesitter parser for this filetype.")
      (case (vim.treesitter.get_node)
        node
        (let [nodes [node]]
          (var parent (node:parent))
          (while parent
            (table.insert nodes parent)
            (set parent (parent:parent)))
          nodes))))


(fn nodes->targets [nodes]
  (local linewise? (: (vim.fn.mode true) :match "V"))
  (local targets [])
  ; To skip duplicate ranges.
  (var prev-range [])
  (var prev-line-range [])
  (each [_ node (ipairs nodes)]
    (let [(startline startcol endline endcol) (node:range)  ; (0,0)
          range [startline startcol endline endcol]
          line-range [startline endline]
          remove-prev? (if linewise?
                           (vim.deep_equal line-range prev-line-range)
                           (vim.deep_equal range prev-range))]
      (when (not (and linewise? (= startline endline)))
        (when remove-prev?
          (table.remove targets))
        (set prev-range range)
        (set prev-line-range line-range)
        (var endline* endline)
        (var endcol* endcol)
        (when (= endcol 0)  ; exclusive
          ; Go to the end of the previous line.
          (set endline* (- endline 1))
          (set endcol* (length (vim.fn.getline endline))))  ; (getline 1-indexed)
        (table.insert targets  ; (0,0) -> (1,1)
                      {:pos [(+ startline 1) (+ startcol 1)]
                       ; `endcol` is exclusive, but we want to put the
                       ; inline labels after it, so still +1.
                       :endpos [(+ endline* 1) (+ endcol* 1)]}))))
  (when (> (length targets) 0)
    targets))


(fn get-targets []
  (local (nodes err) (get-nodes))
  (if (not nodes) (values nil err)
      (nodes->targets nodes)))


(fn select-range [target]
  ; Enter Visual mode.
  (local mode (vim.fn.mode true))
  (when (mode:match "no?")
    (vim.cmd (.. "normal! " (or (mode:match "[V\22]") "v"))))
  ; Do the rest without leaving Visual mode midway, so that leap-remote
  ; can keep working.
  ; Move the cursor to the start of the Visual area if needed.
  (when (or (not= (vim.fn.line "v") (vim.fn.line "."))
            (not= (vim.fn.col "v") (vim.fn.col ".")))
    (vim.cmd "normal! o"))
  (vim.fn.cursor (unpack target.pos))
  (vim.cmd "normal! o")
  (local (endline endcol) (unpack target.endpos))
  (vim.fn.cursor endline (- endcol 1))
  ; Move to the start. This might be more intuitive for incremental
  ; selection, when the whole range is not visible - nodes are usually
  ; harder to identify at their end.
  (vim.cmd "normal! o"))


(local ns (api.nvim_create_namespace ""))

(fn clear-fill []
  (api.nvim_buf_clear_namespace 0 ns 0 -1))

; Fill the gap left by the cursor (which is down on the command line).
; Note: redrawing the cursor with nvim__redraw() is not a satisfying
; solution, since the cursor might still appear in a wrong place
; (thanks to inline labels).
(fn fill-cursor-pos [targets start-idx]
  (clear-fill)
  (let [[line col] [(vim.fn.line ".") (vim.fn.col ".")]
        line-str (vim.fn.getline line)
        ch-at-curpos (vim.fn.strpart line-str (- col 1) 1 true)
        ; On an empty line, add space.
        text (if (= ch-at-curpos "") " " ch-at-curpos)]
    ; Problem: If there is an inline label for the same position, this
    ; extmark will not be shifted.
    (local conflict? (case (. targets start-idx)  ; the first labeled node
                       {:pos [line* col*]} (and (= line* line) (= col* col))))
    ; Solution (hack): Shift by the number of labels on the given line.
    ; Note: Getting the cursor's screenpos would not work, as it has not
    ; moved yet.
    ; TODO: What if there are other inline extmarks, besides our ones?
    (var shift 1)
    (when conflict?
      (var loop? true)
      (var idx (+ start_idx 1))
      (while loop?
        (case (. targets idx)
          nil (set loop? false)
          {:pos [line* _]} (if (= line* line)
                               (do (set shift (+ shift 1))
                                   (set idx (+ idx 1)))
                               (set loop? false)))))
    (api.nvim_buf_set_extmark 0 ns (- line 1) (- col 1)
      {:virt_text [[text :Visual]]
       :virt_text_pos "overlay"
       :virt_text_win_col (when conflict? (+ col shift -1))
       :hl_mode "combine"}))
  ; Continue with the native function body.
  true)


(fn select [kwargs]
  (let [kwargs (or kwargs {})
        leap (require "leap")
        op-mode? (: (vim.fn.mode true) :match "o")
        inc-select? (not op-mode?)]
    ; Add `;` and `,` as traversal keys.
    (local sk (vim.deepcopy leap.opts.special_keys))
    (set sk.next_target (vim.fn.flatten
                          (vim.list_extend [";"] [sk.next_target])))
    (set sk.prev_target (vim.fn.flatten
                          (vim.list_extend [","] [sk.prev_target])))

    (local (ok? context) (pcall require "treesitter-context"))
    (local context? (and ok? (context.enabled)))
    (when context? (context.disable))

    (leap.leap {:target_windows [(api.nvim_get_current_win)]
                :targets get-targets
                :action select-range
                :traversal inc-select?  ; allow traversal for the custom action
                :opts (vim.tbl_extend :keep
                        (or kwargs.opts {})
                        {:labels (when inc-select? "")  ; force autojump
                         :on_beacons (when inc-select? fill-cursor-pos)
                         :virt_text_pos "inline"
                         :special_keys sk})})

    (when inc-select? (clear-fill))
    (when context? (context.enable))))


{: select}
