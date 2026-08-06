----------------------------- MODULE Ok -----------------------------
(***************************************************************************)
(* rc=0 fixture: a trivially-satisfied spec.                                *)
(*                                                                          *)
(* Five distinct states (0..4) so that Gate!NonVacuous (>= 4 distinct) is   *)
(* TRUE -- this fixture doubles as the positive control for the             *)
(* -postCondition channel that PostCondFalse.tla exercises negatively.      *)
(* Next is total, so there is no deadlock even with deadlock checking on.   *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE x

Init == x = 0
Next == x' = (x + 1) % 5
Spec == Init /\ [][Next]_x

TypeOK == x \in 0..4

=============================================================================
