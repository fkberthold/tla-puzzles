------------------------- MODULE AssumeFalse -------------------------
(***************************************************************************)
(* rc=10 fixture, ASSUME arm.  Everything else about the spec is fine; the  *)
(* only defect is the failing assumption, so the exit code isolates the     *)
(* ASSUME channel rather than any model-checking outcome.                   *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE x

ASSUME FALSE

Init == x = 0
Next == x' = (x + 1) % 5
Spec == Init /\ [][Next]_x

=============================================================================
