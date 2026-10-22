------------------------ MODULE InvariantFalse ------------------------
(***************************************************************************)
(* The SECOND meaning of rc=151, found 2026-10-22 on bead tla-ry2y.         *)
(*                                                                          *)
(* ConfigError.cfg covers the documented meaning: the .cfg parses and names *)
(* an operator the spec does not define. This module covers the other one.  *)
(* A declared invariant whose body mentions no variable is folded to a      *)
(* constant before TLC walks any state, and when that constant is FALSE     *)
(* TLC exits 151 as well, printing                                          *)
(*                                                                          *)
(*     Error: The invariant of DiffSet is equal to FALSE                     *)
(*                                                                          *)
(* with no state and no trace. Every name in the .cfg resolves, so nothing  *)
(* about the documented meaning applies, and a caller reading the verdict   *)
(* token alone cannot tell the two apart.                                   *)
(*                                                                          *)
(* The spec itself is deliberately healthy and identical to Ok.tla's, so    *)
(* the only thing under test is the shape of the obligation.                *)
(*                                                                          *)
(* SameSet is the control. It is the same shape and it is TRUE, so it exits *)
(* 0 and reads like any ordinary pass. That asymmetry is why this went      *)
(* unnoticed: the shape only misreports when it is wrong, and a corpus of   *)
(* passing fixtures never exercises it.                                      *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE x

Init == x = 0
Next == x' = (x + 1) % 5
Spec == Init /\ [][Next]_x

SameSet == {1, 2} = {2, 1, 1}

DiffSet == {1, 2} = {1, 2, 3}

=============================================================================
