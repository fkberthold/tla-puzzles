--------------------------- MODULE Stepwise ---------------------------
(***************************************************************************)
(* SUBMISSION: correct, and structurally unlike the reference.              *)
(*                                                                          *)
(* The V2-PLAN.md 3.5 fixture, restated under the step channel. The         *)
(* reference counts parcels with a number and this models them as a SET of  *)
(* tokens: different variable, different type, twice the states, different  *)
(* action structure. Same system, same observations, correct.               *)
(*                                                                          *)
(* It exists here because a two-state obligation is the point in the design *)
(* where reference comparison is easiest to re-introduce by accident. A     *)
(* step obligation is an authored requirement about observations, checked   *)
(* against the SUBMISSION; the reference spec is not involved in judging    *)
(* it. If a future change makes this fixture fail, that is what has gone    *)
(* wrong.                                                                   *)
(***************************************************************************)
EXTENDS Naturals, FiniteSets

Parcels == {"p1", "p2", "p3"}

VARIABLE held

Init == held = {}

Deposit  == \E p \in Parcels \ held : held' = held \cup {p}
Withdraw == \E p \in held : held' = held \ {p}

Next == Deposit \/ Withdraw

Spec == Init /\ [][Next]_held

Observe == [level |-> Cardinality(held)]

=============================================================================
