(local hl (require "leap.highlight"))
(local opts (require "leap.opts"))
(local {: dec} (require "leap.util"))

(local api vim.api)
(local map vim.tbl_map)


; "Beacon" is an umbrella term for any kind of visual overlay tied to
; targets - in practice, either a label character, or a highlighting of
; the match itself. Technically an [offset virtualtext] tuple, where
; `offset` is counted from the match position, and `virtualtext` is a
; list of [text hl-group] tuples (the kind that `nvim_buf_set_extmark`
; expects).


(fn set-beacon-to-match-hl [target]
  (local virttext (table.concat
                    (map #(or (. opts.substitute_chars $) $) target.chars)))
  (set target.beacon [0 [[virttext hl.group.match]]]))


; Handling multibyte characters.
(fn get-label-offset [target]
  (let [{:chars [ch1 ch2]} target]
    (if (= ch1 "\n") 0  ; on EOL
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
        virttext (if (= relative-group 1)
                     [[(.. label pad) hl.group.label-primary]]

                     (= relative-group 2)
                     [[(if ?phase (.. label pad) (.. opts.concealed_label pad))
                       hl.group.label-secondary]]

                     (> relative-group 2)
                     (when (and ?phase (not opts.highlight_unlabeled_phase_one_targets))
                       ; In this case, "no highlight" should unambiguously
                       ; signal "no further keystrokes needed", so it is
                       ; mandatory to show all labeled positions in some way.
                       ; (Note: We're keeping this on even after phase one -
                       ; sudden visual changes should be avoided as much as
                       ; possible.)
                       [[(.. opts.concealed_label pad) hl.group.label-secondary]]))]
    ; Set nil too (= switching off a beacon).
    (set target.beacon (when virttext [offset virttext]))))


(fn set-beacons [targets {: group-offset : use-no-labels? : phase}]
  (if use-no-labels?
      (when (. targets 1 :chars)  ; user-given targets might not have :chars
        (each [_ target (ipairs targets)]
          (set-beacon-to-match-hl target)))
      (each [_ target (ipairs targets)]
        (if target.label
            (set-beacon-for-labeled target group-offset phase)

            (and (= phase 1) opts.highlight_unlabeled_phase_one_targets)
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
  (fn set-beacon-to-empty-label [target]
    (when target.beacon
      (tset target :beacon 2 1 1 opts.concealed_label)))

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

        (if (and target.label target.beacon) ; inactive label has nil beacon

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
                          (set-beacon-to-empty-label target)))
              ; Register positions.
              ; NOTE: We should NOT register the label position before
              ; checking case A, as we don't want to chase our own tail,
              ; that is, getting ourselves as a labeled `other` (false
              ; positive).
              (tset label-positions (->key col-label) target))

            ; Unlabeled target.
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
                          (set-beacon-to-empty-label other)))
                ; Register positions.
              (tset unlabeled-match-positions (->key col-ch1) target)
              (tset unlabeled-match-positions (->key col-ch2) target)))))))


(fn light-up-beacons [targets ?start ?end]
  (when (or (not opts.on_beacons)
            (opts.on_beacons targets ?start ?end))
    (for [i (or ?start 1) (or ?end (length targets))]
      (local target (. targets i))
      (case target.beacon
        [offset virttext]
        (let [bufnr target.wininfo.bufnr
              [lnum col] (map dec target.pos)  ; 1/1 -> 0/0 indexing
              id (api.nvim_buf_set_extmark bufnr hl.ns lnum (+ col offset)
                                           {:virt_text virttext
                                            :virt_text_pos "overlay"
                                            :hl_mode "combine"
                                            :priority hl.priority.label})]
          ; Register each newly set extmark in a table, so that we can
          ; delete them one by one, without needing any further contextual
          ; information. This is relevant if we process user-given targets
          ; and have no knowledge about the boundaries of the search area.
          (table.insert hl.extmarks [bufnr id]))))))


{: set-beacons
 : resolve-conflicts
 : light-up-beacons}
