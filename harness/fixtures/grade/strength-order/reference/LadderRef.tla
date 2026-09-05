--------------------------- MODULE LadderRef ---------------------------
(***************************************************************************)
(* The reference spec PHI for the `strength-order` fixture, bead tla-nyrb.  *)
(*                                                                          *)
(* THE SYSTEM: a document collects up to three approvals and is issued only *)
(* once it has all three. Approvals never come off again.                    *)
(*                                                                          *)
(* THE APPROVALS ARE COUNTED RATHER THAN NAMED, and that is what keeps the  *)
(* fixture small. The point here is the ORDER between two answers, so a     *)
(* number is enough to state one answer that implies the other.             *)
(*                                                                          *)
(* `Issue` stays enabled once the count is full, which is what stops the    *)
(* system deadlocking after it fires.                                       *)
(***************************************************************************)
EXTENDS Naturals

VARIABLES issued, approvals

Init == issued = FALSE /\ approvals = 0

Approve == approvals < 3 /\ approvals' = approvals + 1 /\ UNCHANGED issued
Issue   == approvals = 3 /\ issued' = TRUE /\ UNCHANGED approvals

Next == Approve \/ Issue

Spec == Init /\ [][Next]_<<issued, approvals>>

(***************************************************************************)
(* The observation. `sealed` is derived from `issued`, so it says nothing   *)
(* that `issued` does not, and it is the second field the chaos probe needs *)
(* an obligation to relate. Bead tla-x8s.                                   *)
(***************************************************************************)
Observe == [issued |-> issued, sealed |-> issued, approvals |-> approvals]

=============================================================================
