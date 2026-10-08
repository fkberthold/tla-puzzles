-------------------------- MODULE MoveRefObl --------------------------
(***************************************************************************)
(* The reference obligations for the `imap-move` degenerate-model package.  *)
(* Variable-free by construction, so harness/grade.sh can EXTEND it beside  *)
(* either spec.                                                             *)
(*                                                                          *)
(* The three Req_* are the statement's three requirements, which the        *)
(* faithful clerk satisfies. The landmark is the addition, and it is the    *)
(* whole point of the package: it is a REACHABILITY claim, and the step 5   *)
(* report's finding is that none of the statement's three requirements is   *)
(* one.                                                                     *)
(*                                                                          *)
(* Every obligation quantifies over `DOMAIN o.sending` rather than over a   *)
(* named carrier set, so a submission is free to name its own members and   *)
(* this module never has to agree with it about what they are called.       *)
(***************************************************************************)

ObsRoll   == {"m1", "m2"}
ObsCond   == {"off", "part", "on"}
ObsAnswer == {"waiting", "done", "refused"}

(***************************************************************************)
(* The declared observation domain. The chaos probe ranges over this, and   *)
(* the `part` condition is what gives it room: chaos reaches a roll         *)
(* carrying a part entry, and Req_no_part is false there.                   *)
(***************************************************************************)
ObsDomain == [sending:   [ObsRoll -> ObsCond],
              receiving: [ObsRoll -> ObsCond],
              answer:    ObsAnswer]

(***************************************************************************)
(* PHI_1, requirement 3. Nobody is on both rolls. First in sort order, and  *)
(* that matters only for how fast the chaos probe gets its answer: chaos    *)
(* reaches a member whole on both rolls, so the probe refuses on one run    *)
(* rather than three.                                                       *)
(***************************************************************************)
Req_both_rolls(o) ==
  \A m \in DOMAIN o.sending : ~(o.sending[m] = "on" /\ o.receiving[m] = "on")

(***************************************************************************)
(* PHI_2, requirement 2. Nobody is off both rolls. A member who holds       *)
(* nothing but part entries has no branch, so a whole entry is what counts. *)
(***************************************************************************)
Req_neither_roll(o) ==
  \A m \in DOMAIN o.sending : o.sending[m] = "on" \/ o.receiving[m] = "on"

(***************************************************************************)
(* PHI_3, requirement 1. Nothing stands half-made.                          *)
(***************************************************************************)
Req_no_part(o) ==
  \A m \in DOMAIN o.sending : o.sending[m] # "part" /\ o.receiving[m] # "part"

(***************************************************************************)
(* THE LANDMARK, AND THE ONLY THING IN THIS PACKAGE THAT CATCHES THE        *)
(* DEGENERATE MODEL. One member carried over while another is still at her  *)
(* old branch, which is rule 4's partial failure read off the rolls.        *)
(*                                                                          *)
(* The statement's own traces note asks for the same thing in prose: "If    *)
(* your model can't produce both allowed runs, it's over-constrained,       *)
(* however green your checks are." A landmark is that note wired to a gate. *)
(***************************************************************************)
Landmark_mixed(o) ==
  \E m, n \in DOMAIN o.sending :
     /\ m # n
     /\ o.receiving[m] = "on"
     /\ o.sending[n] = "on"

=============================================================================
