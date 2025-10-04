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
  (each [_ node (ipairs nodes)]
    (local (startline startcol endline endcol) (node:range))  ; (0,0)
    (when (not (and linewise? (= startline endline)))
      ; Adjust the end position if necessary. (It is exclusive, so if we
      ; are on the very first column, move to the end of the previous
      ; line, to the newline character.)
      (var endline* endline)
      (var endcol* endcol)
      (when (= endcol 0)
        (set endline* (- endline 1))
        ; Include EOL (+1) (also, `getline` is 1-indexed).
        (set endcol* (+ (length (vim.fn.getline (+ endline* 1))) 1)))
      ; Check duplicates based on the adjusted ranges (relevant for
      ; linewise mode)!
      (local range (if linewise?
                       [startline endline*]
                       [startline startcol endline* endcol*]))
      ; Instead of skipping, keep this (the outer one), and remove the
      ; previous (better for linewise mode).
      (when (vim.deep_equal range prev-range)
        (table.remove targets))
      (set prev-range range)
      ; Create target ((0,0) -> (1,1)).
      ; `endcol` is exclusive, but we want to put the inline labels
      ; after it, so still +1.
      (local target {:pos [(+ startline 1) (+ startcol 1)]
                     :endpos [(+ endline* 1) (+ endcol* 1)]})
      (table.insert targets target)))
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
  (vim.cmd "normal! o")
  ; Force redrawing the selection if the text has been scrolled.
  (pcall api.nvim__redraw {:flush true}))  ; EXPERIMENTAL


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
    (local (ok? context) (pcall require "treesitter-context"))
    (local context? (and ok? (context.enabled)))
    (when context? (context.disable))

    (leap.leap {:windows [(api.nvim_get_current_win)]
                :targets get-targets
                :action select-range
                :traversal inc-select?  ; allow traversal for the custom action
                :opts (vim.tbl_extend :keep
                        (or kwargs.opts {})
                        {:labels (when inc-select? "")  ; force autojump
                         :on_beacons (when inc-select? fill-cursor-pos)
                         :virt_text_pos "inline"})})

    (when inc-select? (clear-fill))
    (when context? (context.enable))))


{: select}
