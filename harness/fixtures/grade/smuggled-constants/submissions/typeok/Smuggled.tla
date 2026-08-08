--------------------------- MODULE Smuggled ---------------------------
(***************************************************************************)
(* SUBMISSION: correct, and it happens to define an operator called TypeOK. *)
(*                                                                          *)
(* Against the reference's obligations this spec is right: it never holds   *)
(* more than three parcels, and it reaches the landmark. Graded on its own  *)
(* merits it is a PASS.                                                     *)
(*                                                                          *)
(* Its TypeOK is deliberately WRONG about its own spec -- `0..2` where the  *)
(* box holds up to three. A learner's half-finished type invariant is a     *)
(* completely ordinary thing to find in a submission, and it is none of the *)
(* grader's business: nothing in V2-PLAN.md 5.2 checks it. It is here only  *)
(* so that the invariant smuggled through the reference's constants.cfg     *)
(* actually FIRES, which is what turns a hidden directive into a wrong      *)
(* grade rather than a harmless one.                                        *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE level

Init == level = 0

Fill  == level < 3 /\ level' = level + 1
Empty == level > 0 /\ level' = level - 1

Next == Fill \/ Empty

Spec == Init /\ [][Next]_level

Observe == [level |-> level]

TypeOK == level \in 0..2

=============================================================================
