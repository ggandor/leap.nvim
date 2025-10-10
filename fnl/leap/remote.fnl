(local api vim.api)


(fn action [kwargs]
  (local kwargs (or kwargs {}))
  (local {: jumper : input :count use-count?} kwargs)
  (local use-count? (not= use-count? false))
  (local mode (vim.fn.mode true))

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

  (fn to-normal-mode []
    (if (state.mode:match "no")
        ; I'm just cargo-culting this TBH, but the combination of the two
        ; indeed seems to work reliably.
        (do (api.nvim_feedkeys (vim.keycode "<C-\\><C-N>") "nx" false)
            (api.nvim_feedkeys (vim.keycode "<esc>") "n" false))

        (state.mode:match "[vV]")
        (api.nvim_feedkeys state.mode "n" false)))

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
      (leap {:opts (when (or (and input (> (length input) 0))
                             (not= mode "n"))
                     {:safe_labels ""})
             :windows (util.get_focusable_windows)})))

  (local jumper (or jumper default-jumper))

  (fn cursor-moved? []
    (not
      (and (= (vim.fn.win_getid) src-win)
           (= (vim.fn.line ".") saved-view.lnum)
           (= (vim.fn.col ".") (+ saved-view.col 1)))))

  (fn back-to-pending-action []
    (if (state.mode:match "o")
        (let [count (if (and use-count? (> state.count 0)) state.count "")
              register (.. "\"" state.register)
              op vim.v.operator
              force (state.mode:sub 3)]
          (api.nvim_feedkeys (.. count register op force) "n" false))

        (state.mode:match "[vV]")
        (api.nvim_feedkeys state.mode "n" false)))

  (fn restore-cursor []
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

  (fn on-finish []
    (var op-canceled? false)
    (local ns-id (vim.on_key
                   (fn [key typed]
                     (when (cancels? key)
                       (set op-canceled? true)))))
    ; Apparently, schedule wrap here inside is necessary if we want to
    ; v/V/-force the selector motion itself later, instead of the
    ; operation right away (which is definitely QoL).
    (local callback (vim.schedule_wrap
                      (fn []
                        (restore-cursor)
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

  (to-normal-mode)  ; feedkeys...
  ; Push the rest into the main event loop (wait for keys sent by
  ; `feedkeys` to be actually processed).
  (vim.schedule
    (fn []
      (fn after-jump []
        (when (cursor-moved?)
          ; Add target postion to jumplist.
          (vim.cmd "norm! m`")
          (back-to-pending-action)  ; feedkeys...
          ; No 'n' flag, custom mappings should work here.
          (when input (api.nvim_feedkeys input "" false))
          (vim.schedule on-finish)))

      ; Note on the API: A jumper function could of course call
      ; `feedkeys` itself, but then we would still have to tell `action`
      ; via some parameter to wait for `CmdlineLeave` (see below).
      (if (= (type jumper) :string)
          (api.nvim_feedkeys jumper "n" false)
          (jumper))

      ; Wait for the jumper to finish its business.
      (vim.schedule
        (fn []
          (if (= (type jumper) :string)
              ; Wait for finishing the search command.
              (api.nvim_create_autocmd :CmdlineLeave
                {:once true
                 ; Wait for actually leaving the command line.
                 :callback (vim.schedule_wrap after-jump)})
              (after-jump)))))))


{: action}
