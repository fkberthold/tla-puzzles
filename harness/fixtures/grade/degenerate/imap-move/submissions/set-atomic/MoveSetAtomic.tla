------------------------- MODULE MoveSetAtomic -------------------------
(***************************************************************************)
(* THE DEGENERATE MODEL for `imap-move-partial-failure`: a clerk who never  *)
(* fails partway through the set. Either every named member goes over in    *)
(* one act, or none of them does and she reports a refusal.                 *)
(*                                                                          *)
(* It satisfies all three of the statement's requirements by construction,  *)
(* and that is not a bug in the requirements so much as a fact about what   *)
(* they are: three upper bounds on a single reading of the rolls. A model   *)
(* that never shows a half-done set never shows a reading any of them       *)
(* forbids.                                                                 *)
(*                                                                          *)
(* What it has thrown away is rule 4, which is the whole subject of the     *)
(* problem. The transfer carries no promise about the set, and this clerk   *)
(* makes one. So it is OVER-CONSTRAINED BY OMISSION: it declares no rule    *)
(* that is too tight, it just leaves the mixed outcome out, and obligation  *)
(* 2 has nothing to refute.                                                 *)
(***************************************************************************)

Roll == {"m1", "m2"}

VARIABLES sending, receiving, answer

vars == <<sending, receiving, answer>>

Init ==
  /\ sending   = [m \in Roll |-> "on"]
  /\ receiving = [m \in Roll |-> "off"]
  /\ answer    = "waiting"

(***************************************************************************)
(* The whole set, in one act. This is the step that does the damage.        *)
(***************************************************************************)
MoveAll ==
  /\ answer = "waiting"
  /\ \A m \in Roll : sending[m] = "on"
  /\ sending'   = [m \in Roll |-> "off"]
  /\ receiving' = [m \in Roll |-> "on"]
  /\ answer'    = "done"

RefuseFlat ==
  /\ answer = "waiting"
  /\ answer' = "refused"
  /\ UNCHANGED <<sending, receiving>>

Next == MoveAll \/ RefuseFlat

Spec == Init /\ [][Next]_vars

Observe == [sending |-> sending, receiving |-> receiving, answer |-> answer]

=============================================================================
