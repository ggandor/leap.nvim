(local api vim.api)


(fn cursor-before-eol? []
  (not= (vim.fn.search "\\_." "Wn") (vim.fn.line ".")))


(fn cursor-before-eof? []
  (and (= (vim.fn.line ".") (vim.fn.line "$"))
       (= (vim.fn.virtcol ".") (- (vim.fn.virtcol "$") 1))))


(fn push-cursor! [dir]
  "Push cursor 1 character to the left or right, possibly beyond EOL."
  (vim.fn.search "\\_." (case dir :fwd "W" :bwd "bW")))


(fn add-offset! [offset]
  (if (< offset 0) (push-cursor! :bwd)
      ; Safe first forward push for pre-EOL matches.
      (> offset 0) (do (when (not (cursor-before-eol?)) (push-cursor! :fwd))
                       (when (> offset 1) (push-cursor! :fwd)))))


(fn push-beyond-eof! []
  (local saved vim.o.virtualedit)
  (set vim.o.virtualedit :onemore)
  ; Note: No need to undo this afterwards, the cursor will be moved to
  ; the end of the operated area anyway.
  (vim.cmd "norm! l")
  (api.nvim_create_autocmd
    [:CursorMoved :WinLeave :BufLeave :InsertEnter :CmdlineEnter :CmdwinEnter]
    {:callback #(set vim.o.virtualedit saved) :once true}))


(fn simulate-inclusive-op! [mode]
  "When applied after an exclusive motion (like setting the cursor via
the API), make the motion appear to behave as an inclusive one."
  (case (vim.fn.matchstr mode "^no\\zs.")  ; get forcing modifier
    ; In the normal case (no modifier), we should push the cursor
    ; forward. (The EOF edge case requires some hackery though.)
    "" (if (cursor-before-eof?) (push-beyond-eof!) (push-cursor! :fwd))
    ; We also want the `v` modifier to behave in the native way, that
    ; is, to toggle between inclusive/exclusive if applied to a charwise
    ; motion (:h o_v). As `v` will change our (technically) exclusive
    ; motion to inclusive, we should push the cursor back to undo that.
    :v (push-cursor! :bwd)
    ; Blockwise (<c-v>) itself makes the motion inclusive, do nothing in
    ; that case.
    ))


(fn force-matchparen-refresh []
  ; HACK: :DoMatchParen turns matchparen on simply by triggering
  ; CursorMoved events (see matchparen.vim). We can do the same, which
  ; is cleaner for us than calling :DoMatchParen directly, since that
  ; would wrap this in a `windo`, and might visit another buffer,
  ; breaking our visual selection (and thus also dot-repeat,
  ; apparently). (See :h visual-start, and lightspeed#38.)
  ; Programming against the API would be more robust of course, but in
  ; the unlikely case that the implementation details would change, this
  ; still cannot do any damage on our side if called with pcall (the
  ; feature just ceases to work then).
  (pcall api.nvim_exec_autocmds "CursorMoved" {:group "matchparen"})
  ; If vim-matchup is installed, it can similarly be forced to refresh
  ; by triggering a CursorMoved event. (The same caveats apply.)
  (pcall api.nvim_exec_autocmds "CursorMoved" {:group "matchup_matchparen"}))


(fn jump-to! [[lnum col]
              {: winid : add-to-jumplist? : mode : offset
               : backward? : inclusive-op?}]
  (local op-mode? (mode:match :o))
  ; Note: <C-o> will ignore this if the line has not changed (neovim#9874).
  (when add-to-jumplist? (vim.cmd "norm! m`"))
  (when (not= winid (api.nvim_get_current_win))
    (api.nvim_set_current_win winid))

  (api.nvim_win_set_cursor 0 [lnum (- col 1)])  ; (1,1) -> (1,0)
  (pcall api.nvim__redraw {:cursor true})  ; EXPERIMENTAL

  (when offset (add-offset! offset))
  ; Since Vim interprets our jump as an exclusive motion (:h exclusive),
  ; we need custom tweaks to behave as an inclusive one. (This is only
  ; relevant in the forward direction, as inclusiveness applies to the
  ; end of the selection.)
  (when (and op-mode? inclusive-op? (not backward?))
    (simulate-inclusive-op! mode))
  (when (not op-mode?) (force-matchparen-refresh)))


{: jump-to!}
