--------------------------- MODULE MoveRef ---------------------------
(***************************************************************************)
(* A STAND-IN reference for `imap-move-partial-failure`, built for bead     *)
(* tla-8kgj. That problem is at step 5 and its reference is frozen at step  *)
(* 6, so there is no shipped reference to grade against yet and this is not *)
(* one. What it carries is the statement's frozen Observe interface and the *)
(* mechanism the problem is about, taken from the spike's own reference at  *)
(* sources/spikes/imap-move-partial-failure/matrix/reference/.              *)
(*                                                                          *)
(* THE MECHANISM IS PARTIAL FAILURE OVER THE SET, which is rule 4 of the    *)
(* statement: the transfer promises nothing about the set, only about each  *)
(* member on her own. So the clerk moves one member at a time and may       *)
(* report a flat refusal between any two moves, and a reading in which one  *)
(* member has gone over while another is still at her old branch is a       *)
(* reading this system reaches.                                            *)
(*                                                                          *)
(* THE CARRIER SET IS A LOCAL OPERATOR AND NOT A CONSTANT, on purpose. The  *)
(* Adequacy runs EXTEND a submission's spec beside MoveRefObl, so a name    *)
(* declared in both would be ambiguous there. `empty-at-instance` records   *)
(* the same hazard beside its own Roster.                                   *)
(***************************************************************************)

Roll == {"m1", "m2"}

VARIABLES sending, receiving, answer

vars == <<sending, receiving, answer>>

(***************************************************************************)
(* Rule 2's opening: every member holds a whole entry on the sending roll   *)
(* and no entry at all on the receiving one.                               *)
(***************************************************************************)
Init ==
  /\ sending   = [m \in Roll |-> "on"]
  /\ receiving = [m \in Roll |-> "off"]
  /\ answer    = "waiting"

(***************************************************************************)
(* One member, transferred whole. Rule 3 says the three pen strokes read as *)
(* a single act from the secretary's side, and that a part entry which      *)
(* stands is a breach, so a conforming clerk never shows one.               *)
(***************************************************************************)
MoveOne(m) ==
  /\ answer = "waiting"
  /\ sending[m] = "on"
  /\ receiving[m] = "off"
  /\ sending'   = [sending   EXCEPT ![m] = "off"]
  /\ receiving' = [receiving EXCEPT ![m] = "on"]
  /\ UNCHANGED answer

AllOver == \A m \in Roll : receiving[m] = "on"

ReportDone ==
  /\ answer = "waiting"
  /\ AllOver
  /\ answer' = "done"
  /\ UNCHANGED <<sending, receiving>>

(***************************************************************************)
(* The flat refusal of rule 5, available at any moment. This is the whole   *)
(* of the partial-failure mechanism: she stops where she is, the rolls      *)
(* stand as she left them, and the answer says nothing about which members  *)
(* she got to.                                                              *)
(***************************************************************************)
ReportRefused ==
  /\ answer = "waiting"
  /\ answer' = "refused"
  /\ UNCHANGED <<sending, receiving>>

Next == (\E m \in Roll : MoveOne(m)) \/ ReportDone \/ ReportRefused

Spec == Init /\ [][Next]_vars

Observe == [sending |-> sending, receiving |-> receiving, answer |-> answer]

=============================================================================
