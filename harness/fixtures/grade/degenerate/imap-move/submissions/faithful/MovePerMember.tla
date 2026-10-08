--------------------------- MODULE MovePerMember ---------------------------
(***************************************************************************)
(* THE CONTROL, and the reason the `set-atomic` result is evidence of       *)
(* anything. It is MoveRef's text under another module name, so it reaches  *)
(* the landmark and must grade PASS.                                        *)
(*                                                                          *)
(* A landmark nothing reaches refuses every submission alike, and a         *)
(* Relational suite that always fails is not a measurement. Deleting this   *)
(* directory leaves the set-atomic assertion green and takes the evidence   *)
(* for it away.                                                            *)
(*                                                                          *)
(* It also pins the 3.5 rule from the other side. Grading here is against   *)
(* the observation, so a submission is free to be the reference and free to *)
(* be nothing like it, and `correct-different` in the lockbox matrix is the *)
(* second half of the same claim.                                           *)
(*                                                                          *)
(* THE MECHANISM IS PARTIAL FAILURE OVER THE SET, which is rule 4 of the    *)
(* statement: the transfer promises nothing about the set, only about each  *)
(* member on her own. So the clerk moves one member at a time and may       *)
(* report a flat refusal between any two moves, and a reading in which one  *)
(* member has gone over while another is still at her old branch is a       *)
(* reading this system reaches.                                            *)
(*                                                                          *)
(* THE CARRIER SET IS A LOCAL OPERATOR AND NOT A CONSTANT, on purpose. The  *)
(* Adequacy runs EXTEND a submission's spec beside MovePerMemberObl, so a name    *)
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
