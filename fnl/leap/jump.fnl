(local api vim.api)


(fn cursor-before-eol? []
  (= (vim.fn.virtcol ".") (- (vim.fn.virtcol "$") 1)))


(fn cursor-before-eof? []
  (and cursor-before-eol? (= (vim.fn.line ".") (vim.fn.line "$"))))


(fn push-cursor! [dir]
  "Push cursor 1 character forward or backward, possibly beyond EOL."
  (vim.fn.search "\\_." (case dir :fwd "W" :bwd "bW")))


(fn push-beyond-eol! []
  (local saved vim.o.virtualedit)
  (set vim.o.virtualedit :onemore)
  ; Note: No need to undo this afterwards, the cursor will be moved to
  ; the end of the operated area anyway.
  (vim.cmd "norm! l")
  (api.nvim_create_autocmd
    [:CursorMoved :WinLeave :BufLeave :InsertEnter :CmdlineEnter :CmdwinEnter]
    {:callback #(set vim.o.virtualedit saved)
     :once true}))


(fn add-offset! [offset]
  (if (< offset 0) (push-cursor! :bwd)
      (> offset 0) (do (if (cursor-before-eol?) (push-beyond-eol!)
                           (push-cursor! :fwd))
                       (when (> offset 1)  ; deprecated
                         (if (cursor-before-eol?) (push-beyond-eol!)
                             (push-cursor! :fwd))))))


(fn simulate-inclusive-op! [mode]
  "When applied after an exclusive motion (like setting the cursor via
the API), make the motion appear to behave as an inclusive one."
  (case (vim.fn.matchstr mode "^no\\zs.")  ; get forcing modifier
    ; In the normal case (no modifier), we should push the cursor
    ; forward. (The EOF edge case requires some hackery though.)
    "" (if (cursor-before-eof?) (push-beyond-eol!) (push-cursor! :fwd))
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


(fn jump-to! [[lnum col] kwargs]
  (local {: win : add-to-jumplist? : mode : offset : backward? : inclusive?} kwargs)
  (local op-mode? (mode:match :o))
  (when add-to-jumplist?
    ; Note: <C-o> will ignore this on the same line (neovim#9874).
    (vim.cmd "norm! m`"))
  (when (not= win (api.nvim_get_current_win))
    (api.nvim_set_current_win win))

  ; Set cursor.
  (api.nvim_win_set_cursor 0 [lnum (- col 1)])  ; (1,1) -> (1,0)
  (when offset (add-offset! offset))
  (when (and op-mode? inclusive? (not backward?))
    ; Since Vim interprets our jump as exclusive (:h exclusive), we need
    ; custom tweaks to behave as inclusive. (This is only relevant in
    ; the forward direction, as inclusiveness applies to the end of the
    ; selection.)
    (simulate-inclusive-op! mode))

  ; Refresh view.
  (when (not op-mode?)
    (pcall api.nvim__redraw {:cursor true})  ; EXPERIMENTAL
    (force-matchparen-refresh)))


{: jump-to!}
