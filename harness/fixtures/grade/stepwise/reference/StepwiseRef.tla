------------------------- MODULE StepwiseRef -------------------------
(***************************************************************************)
(* The reference PHI for the `stepwise` grading fixture (beads tla-59s and  *)
(* tla-x8s).                                                                *)
(*                                                                          *)
(* THE SYSTEM is the lockbox again -- between zero and three parcels, one   *)
(* in or one out at a time. What is different is that the obligations       *)
(* beside this module state the "one at a time" half as a requirement about *)
(* a PAIR of successive observations, which is the shape the grading engine *)
(* could not express at all until those two beads landed.                   *)
(*                                                                          *)
(* THE REPRESENTATION IS THIS MODULE'S OWN CHOICE and carries no authority  *)
(* (V2-PLAN.md 3.2). The `correct-different` submission counts the same     *)
(* parcels as a SET and must grade PASS.                                    *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE level

Init == level = 0

Fill  == level < 3 /\ level' = level + 1
Empty == level > 0 /\ level' = level - 1

Next == Fill \/ Empty

Spec == Init /\ [][Next]_level

Observe == [level |-> level]

=============================================================================
