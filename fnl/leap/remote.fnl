(local api vim.api)


(fn default-jumper []
  (let [util (require "leap.util")
        leap (. (require "leap") :leap)]
    ; We are in Normal mode when this call is executed, so we should
    ; tell Leap it is _not_ OK to autojump.
    (leap {:opts {:safe_labels ""}
           :target_windows (util.get_focusable_windows)})))


(fn action [kwargs]
  (local {: jumper : input} (or kwargs {}))
  (local jumper (or jumper default-jumper))
  ; `jumper` can mess with these.
  (local state {:mode (vim.fn.mode true)
                :count vim.v.count
                :register vim.v.register})

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
    (local anch-pos (api.nvim_buf_get_extmark_by_id 0  anch-ns  anch-id  {}))
    (api.nvim_win_set_cursor 0 [(+ (. anch-pos 1) 1) (. anch-pos 2)])
    (api.nvim_buf_clear_namespace 0 anch-ns  0 -1))

  (fn cancels? [key]
    (local mode (vim.fn.mode true))
    (or (= key (vim.keycode "<esc>"))
        (= key (vim.keycode "<c-c>"))
        (and (or (= mode "v") (= mode "V") (= mode ""))
             (= key mode))))

  (fn restore-on-finish []
    (var op-canceled? false)
    (local ns-id (vim.on_key
                   (fn [key _]
                     (when (cancels? key)
                       (set op-canceled? true)))))
    (api.nvim_create_autocmd :ModeChanged
      {:pattern "*:n"
       :once true
       ; Without schedule, we cannot use e.g. leap() itself to select.
       :callback (vim.schedule_wrap
                   (fn []
                     (restore)
                     (vim.on_key nil ns-id)  ; remove listener
                     (when (not op-canceled?)
                       (api.nvim_exec_autocmds :User
                         {:pattern "RemoteOperationDone"
                          :data state}))))}))

  (fn feed [seq]
    (api.nvim_feedkeys seq "n" false)
    ; Remap keys, custom motions and text objects should work too.
    (when input (api.nvim_feedkeys input "" false)))

  ; Return to Normal mode.
  (if (state.mode:match "no")
      (do (api.nvim_feedkeys (vim.keycode "<C-\\><C-N>") "nx" false)
          ; Either schedule the rest, or put this after the jump.
          (api.nvim_feedkeys (vim.keycode "<esc>") "n" false))

      (state.mode:match "[vV]")
      (api.nvim_feedkeys state.mode "n" false))

  ; Execute "spooky" action: jump - operate - restore.
  (vim.schedule
    (fn []
      (jumper)
      ; Add target postion to jumplist.
      (vim.cmd "norm! m`")
      (if
        ; From Operator-pending: re-trigger the operation.
        (state.mode:match "no")
        (let [count (if (> state.count 0) state.count "")
              reg (.. "\"" state.register)
              force (state.mode:sub 3)]
          (feed (.. count reg vim.v.operator force)))

        ; From Visual: start the corresponding Visual mode again.
        (state.mode:match "[vV]")
        (feed state.mode)

        ; From Normal: start charwise Visual mode.
        (feed "v"))
      ; Set autocommand to restore state.
      (restore-on-finish))))


{: action}
