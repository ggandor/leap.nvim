(local hl (require "leap.highlight"))
(local opts (require "leap.opts"))

(local api vim.api)


; "Beacon" is an umbrella term for any kind of visual overlay tied to
; targets - in practice, either a label character, or a highlighting of
; the match itself. Technically an [offset extmark-opts] tuple, where
; `offset` is counted from the match position, and `exmark-opts` is an
; option table expected by `nvim_buf_set_extmark`.


(fn set-beacon-to-match-hl [target]
  (local {:chars [ch1 ch2]} target)
  (if (= ch1 "\n")
      (set target.beacon [0 {:virt_text [[" " hl.group.match]]}])
      (do
        (local col (. target.pos 2))
        (local len (+ (ch1:len)
                      (or (and ch2 (not= ch2 "\n") (ch2:len))
                          0)))
        (set target.beacon
             [0 {:end_col (+ col len -1) :hl_group hl.group.match}]))))


; Handling multibyte characters.
(fn get-label-offset [target]
  (let [{:chars [ch1 ch2]} target]
    (if (or opts.show_label_on_start_of_match (= ch1 "\n")) 0  ; user option or on EOL
        (or target.edge-pos? (= ch2 "\n")) (ch1:len)  ; window edge (right) or before EOL
        (+ (ch1:len) (ch2:len)))))


(fn set-beacon-for-labeled [target ?group-offset ?phase]
  (let [offset (if (and target.chars ?phase) (get-label-offset target) 0)
        pad (if (and (not= opts.max_phase_one_targets 0)
                     (not ?phase)
                     target.chars (. target.chars 2))
                " "
                "")
        label (or (. opts.substitute_chars target.label) target.label)
        relative-group (- target.group (or ?group-offset 0))
        ; In unlabeled matches are not highlighted, then "no highlight"
        ; should be the very signal for "no further keystrokes needed",
        ; so in that case it is mandatory to show all labeled positions
        ; in some way.
        ; (Note: We're keeping this on even after phase one - sudden
        ; visual changes should be avoided as much as possible.)
        show-all? (and ?phase (not opts.highlight_unlabeled_phase_one_targets))
        vtext (if (= relative-group 1)
                  [[(.. label pad) hl.group.label]]

                  (= relative-group 2)
                  [[(.. opts.concealed_label pad) hl.group.label-dimmed]]

                  (and (> relative-group 2) show-all?)
                  [[(.. opts.concealed_label pad) hl.group.label-dimmed]])]
    ; Set nil too (= switching off a beacon).
    (set target.beacon (when vtext [offset {:virt_text vtext}]))))


(fn set-beacons [targets {: group-offset : use-no-labels? : phase}]
  (if use-no-labels?
      (when (. targets 1 :chars)  ; user-given targets might not have :chars
        (each [_ target (ipairs targets)]
          (set-beacon-to-match-hl target)))
      (each [_ target (ipairs targets)]
        (if target.label
            (when (or (not= phase 1) target.previewable?)
              (set-beacon-for-labeled target group-offset phase))

            (and (= phase 1) target.previewable?
                 opts.highlight_unlabeled_phase_one_targets)
            (set-beacon-to-match-hl target)))))


(fn resolve-conflicts [targets]
  "After setting the beacons in a context-unaware manner, the following
conflicts can occur:

(A) Two labels on top of each other (possible at EOL or window edge,
    where labels need to be shifted left).

          x1 x-label |
       y1 y2 y-label |
       ------------------
       -3 -2 -1      edge-pos

(B) An unlabeled match touches the label of another match (possible if
    the label is shifted, just like above). This is unacceptable - it
    looks like the label is for the unlabeled target:
          x1 x-label |
       y1 y2         |
       ------------------
       -3 -2 -1      edge-pos

(C) An unlabeled match covers a label.

Fix: switch the label(s) to an empty one. This keeps things simple from
a UI perspective (no special beacon for marking conflicts). An empty
label next to, or on top of an unlabeled match (case B and C) is not
ideal, but the important thing is to avoid accidents, that is, typing a
label by mistake - a possibly unexpected autojump on these rare
occasions is a relatively minor nuisance. Show the empty label even if
unlabeled targets are set to be highlighted, and remove the match
highlight instead, for a similar reason - to prevent (falsely) expecting
an autojump. (In short: always err on the safe side.)
"
  (fn set-beacon-to-concealed-label [target]
    (local vtext (. target :beacon 2 :virt_text))  ; = labeled target
    (when vtext (set (. vtext 1 1) opts.concealed_label)))

  ; Tables to help us check potential conflicts (we'll be filling
  ; them as we go):
  ; { "<bufnr> <winid> <lnum> <col>" = <target> }
  (var unlabeled-match-positions {})
  (var label-positions {})

  ; We do only one traversal run, and we don't assume anything about the
  ; ordering of the targets; a particular conflict will always be
  ; resolved the second time we encounter the conflicting pair - at that
  ; point, one of them will already have been registered as a potential
  ; source of conflict. That is why we need to check two separate
  ; subcases for both A and B (for C, they are the same).
  (each [_ target (ipairs targets)]
    (local empty-line? (and (= (. target.chars 1) "\n")
                            (= (. target.pos 2) 0)))
    (when (not empty-line?)
      (let [{: bufnr : winid} target.wininfo
            [lnum col-ch1] target.pos
            col-ch2 (+ col-ch1 (string.len (. target.chars 1)))
            key-prefix (.. bufnr " " winid " " lnum " ")]

        (macro ->key [col] `(.. key-prefix ,col))

        (if (and target.label target.beacon)  ; = visible label

            ; Labeled target.
            (let [label-offset (. target.beacon 1)
                  col-label (+ col-ch1 label-offset)
                  shifted-label? (= col-label col-ch2)]
              (case (or
                      ; label on top of label (A)
                      ;   [-][a][L]|     | current
                      ;   [a][a][L]|     | other
                      ;          ^       | column to check
                      ; or
                      ;   [a][a][L]|
                      ;   [-][a][L]|
                      ;          ^
                      (. label-positions (->key col-label))

                      ; label touches unlabeled (B1)
                      ;   [-][a][L]|
                      ;   [a][a][-]|
                      ;       ^
                      (when shifted-label?  ; don't use AND (false would be matched)
                        (. unlabeled-match-positions (->key col-ch1)))

                      ; label covered by unlabeled (C1)
                      ;   [a][b][L][-]
                      ;   [-][-][a][c]
                      ;          ^
                      ; or
                      ;   [a][a][L]
                      ;   [-][a][b]
                      ;          ^
                      (. unlabeled-match-positions (->key col-label)))
                other (do (set other.beacon nil)
                          (set-beacon-to-concealed-label target)))
              ; Register positions.
              ; NOTE: We should NOT register the label position before
              ; checking case A, as we don't want to chase our own tail,
              ; that is, getting ourselves as a labeled `other` (false
              ; positive).
              (tset label-positions (->key col-label) target))

            ; No visible label (unlabeled or inactive).
            (let [col-ch3 (+ col-ch2 (string.len (. target.chars 2)))]
              (case (or
                      ; unlabeled covers label (C2)
                      ;   [-][-][a][b]
                      ;   [a][c][L][-]
                      ;          ^
                      (. label-positions (->key col-ch1))

                      ; unlabeled covers label (C2)
                      ;   [-][a][b]
                      ;   [a][a][L]
                      ;          ^
                      (. label-positions (->key col-ch2))

                      ; unlabeled touches label (B2)
                      ;   [a][a][-]|
                      ;   [-][a][L]|
                      ;          ^
                      (. label-positions (->key col-ch3)))
                other (do (set target.beacon nil)
                          (set-beacon-to-concealed-label other)))
                ; Register positions.
              (tset unlabeled-match-positions (->key col-ch1) target)
              (tset unlabeled-match-positions (->key col-ch2) target)))))))


(fn light-up-beacon [target endpos?]
  (let [[lnum col] (or (and endpos? target.endpos) target.pos)
        bufnr target.wininfo.bufnr
        [offset opts*] target.beacon
        opts (vim.tbl_extend :keep opts*
               {:virt_text_pos (or opts.virt_text_pos "overlay")
                :strict false
                :hl_mode "combine"
                :priority hl.priority.label})]
    (local id (api.nvim_buf_set_extmark
                bufnr hl.ns (- lnum 1) (+ col -1 offset) opts))
    ; Register each newly set extmark in a table, so that we can delete
    ; them one by one, without needing any further contextual
    ; information. This is relevant if we process user-given targets and
    ; have no knowledge about the boundaries of the search area.
    (table.insert hl.extmarks [bufnr id])))


(fn light-up-beacons [targets ?start ?end]
  (when (or (not opts.on_beacons) (opts.on_beacons targets ?start ?end))
    (for [i (or ?start 1) (or ?end (length targets))]
      (local target (. targets i))
      (when target.beacon
        (light-up-beacon target)
        (when target.endpos
          (light-up-beacon target true))))))


{: set-beacons
 : resolve-conflicts
 : light-up-beacons}
