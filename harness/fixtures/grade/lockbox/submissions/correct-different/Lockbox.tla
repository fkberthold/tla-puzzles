---------------------------- MODULE Lockbox ----------------------------
(***************************************************************************)
(* SUBMISSION: correct, and structurally unlike the reference.              *)
(*                                                                          *)
(* This is the fixture that reference-comparison grading gets wrong         *)
(* (V2-PLAN.md 3.5). The reference counts parcels with a number; this       *)
(* models them as a SET of parcel tokens and derives the count. Different   *)
(* variable, different type, different state count (8 states against 4),    *)
(* different action structure. Same system, same observations, correct.     *)
(*                                                                          *)
(* It must grade PASS. If a future change to grade.sh makes this fail, the  *)
(* change has re-introduced reference comparison.                           *)
(***************************************************************************)
EXTENDS Naturals, FiniteSets

Parcels == {"p1", "p2", "p3"}

VARIABLE held

Init == held = {}

Deposit  == \E p \in Parcels \ held : held' = held \cup {p}
Withdraw == \E p \in held : held' = held \ {p}

Next == Deposit \/ Withdraw

Spec == Init /\ [][Next]_held

(* The `full` flag is part of the graded interface (see LockboxRef.tla), and *)
(* it is derived from this module's own representation rather than copied    *)
(* from the reference's. That is the point of the fixture one field over.    *)
Observe == [level |-> Cardinality(held), full |-> (Cardinality(held) = 3)]

=============================================================================
