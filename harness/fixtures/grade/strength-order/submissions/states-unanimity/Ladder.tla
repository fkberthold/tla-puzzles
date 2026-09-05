---------------------------- MODULE Ladder ----------------------------
(***************************************************************************)
(* THE SPEC THE LEARNER WAS HANDED, and it is byte for byte the same file   *)
(* in both submissions of this package. It issues a document on a single    *)
(* approval, which is the deficiency the problem asks about.                *)
(*                                                                          *)
(* WHAT THE LEARNER HANDS BACK IS THE OBLIGATIONS MODULE, not this. The     *)
(* pilot's column-C answer form asks for a conjunct, so the two submissions *)
(* differ in LadderObl.tla and nowhere else. Holding the spec fixed is what *)
(* makes the strength of that conjunct the only thing left to grade on.     *)
(***************************************************************************)
EXTENDS Naturals

VARIABLES issued, approvals

Init == issued = FALSE /\ approvals = 0

Approve == approvals < 3 /\ approvals' = approvals + 1 /\ UNCHANGED issued
Issue   == approvals >= 1 /\ issued' = TRUE /\ UNCHANGED approvals

Next == Approve \/ Issue

Spec == Init /\ [][Next]_<<issued, approvals>>

Observe == [issued |-> issued, sealed |-> issued, approvals |-> approvals]

=============================================================================
