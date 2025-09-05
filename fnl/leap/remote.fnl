(local api vim.api)


(fn action [kwargs]
  (local kwargs (or kwargs {}))
  (local {: jumper : input :count use-count?} kwargs)
  (local use-count? (not= use-count? false))
  (local mode (vim.fn.mode true))

  (fn default-jumper []
    (let [util (require "leap.util")
          leap (. (require "leap") :leap)]
      ; We are back in Normal mode when this call is executed, so _we_
      ; should tell Leap whether it is OK to autojump.
      ; If `input` is given, all bets are off - before moving on to a
      ; labeled target, we would have to undo whatever action was taken
      ; (practically impossible) -, so in that case we disable autojump
      ; unconditionally.
      ; Visual and Operator-pending mode are also problematic, because
      ; we could only re-trigger them inside the leap() call, with a
      ; custom action, and that would prevent users from customizing the
      ; jumper.
      (leap {:opts (when (or input (not= mode "n"))
                     {:safe_labels ""})
             :target_windows (util.get_focusable_windows)})))

  (local jumper (or jumper default-jumper))
  (local state {:args kwargs
                ; `jumper` can mess with these.
                : mode :count vim.v.count :register vim.v.register})

  (local src-win (vim.fn.win_getid))
  (local saved-view (vim.fn.winsaveview))
  ; Set an extmark as an anchor, so that we can execute remote delete
  ; commands in the backward direction, and move together with the text.
  (local anch-ns (api.nvim_create_namespace ""))
  (local anch-id (api.nvim_buf_set_extmark
                   0 anch-ns (- saved-view.lnum 1) saved-view.col {}))

  (fn restore []
    (when (not= (vim.fn.win_getid) src-win)
      (api.nvim_set_current_win src-win))
    (vim.fn.winrestview saved-view)
    (local anch-pos (api.nvim_buf_get_extmark_by_id 0 anch-ns anch-id {}))
    (api.nvim_win_set_cursor 0 [(+ (. anch-pos 1) 1) (. anch-pos 2)])
    (api.nvim_buf_clear_namespace 0 anch-ns 0 -1))

  (fn cancels? [key]
    (local mode (vim.fn.mode true))
    (or (= key (vim.keycode "<esc>"))
        (= key (vim.keycode "<c-c>"))
        (and (or (= mode "v") (= mode "V") (= mode ""))
             (= key mode))))

  (fn restore-on-finish []
    (var op-canceled? false)
    (local ns-id (vim.on_key
                   (fn [key typed]
                     (when (cancels? key)
                       (set op-canceled? true)))))
    ; Apparently, schedule wrap is necessary for Leap to work as the
    ; selector itself inside the remote action.
    (local callback (vim.schedule_wrap
                      (fn []
                        (restore)
                        (vim.on_key nil ns-id)  ; remove listener
                        (when (not op-canceled?)
                          (api.nvim_exec_autocmds :User
                            {:pattern "RemoteOperationDone"
                             :data state})))))
    (api.nvim_create_autocmd :ModeChanged
      {:pattern "*:*"
       :once true
       :callback (fn []
                   (local mode (vim.fn.mode true))
                   (if (and (mode:match "o") (= vim.v.operator "c"))
                       (api.nvim_create_autocmd :ModeChanged
                         {:pattern "i:n" :once true : callback})
                       (api.nvim_create_autocmd :ModeChanged
                         {:pattern "*:n" :once true : callback})))}))

  ; Execute "spooky" action: jump - operate - restore.

  ; Return to Normal mode.
  (if (state.mode:match "no")
      ; I'm just cargo-culting this TBH, but the combination of the two
      ; indeed seems to work reliably.
      (do (api.nvim_feedkeys (vim.keycode "<C-\\><C-N>") "nx" false)
          (api.nvim_feedkeys (vim.keycode "<esc>") "n" false))

      (state.mode:match "[vV]")
      (api.nvim_feedkeys state.mode "n" false))

  ; Push the rest into the main event loop (wait for keys sent by
  ; `feedkeys` to be actually processed).
  (vim.schedule
    (fn []
      ; Note on the API: A jumper function could of course call
      ; `feedkeys` itself, but then we would still have to tell `action`
      ; via some parameter to wait for `CmdlineLeave` (see below).
      (if (= (type jumper) :string)
          (api.nvim_feedkeys jumper "n" false)
          (jumper))

      ; Again, wait for the jumper to finish its business.
      (vim.schedule
        (fn []
          (fn cbk []
            ; Add target postion to jumplist.
            (vim.cmd "norm! m`")
            ; Re-trigger the previous mode (Visual or O-p).
            (if (state.mode:match "no")
                (let [count (if (and use-count? (> state.count 0)) state.count "")
                      reg (.. "\"" state.register)
                      force (state.mode:sub 3)]
                  (api.nvim_feedkeys
                    (.. count reg vim.v.operator force) "n" false))

                (state.mode:match "[vV]")
                (api.nvim_feedkeys state.mode "n" false))
            (when input
              ; Remap keys, custom motions and text objects should work too.
              (api.nvim_feedkeys input "" false))
            ; Set autocommand to restore state.
            (restore-on-finish))

          (if (= (type jumper) :string)
              ; Wait for finishing the search command.
              (api.nvim_create_autocmd :CmdlineLeave
                                       {:once true :callback cbk})
              (cbk)))))))


{: action}
