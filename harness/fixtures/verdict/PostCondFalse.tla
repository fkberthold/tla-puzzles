------------------------ MODULE PostCondFalse ------------------------
(***************************************************************************)
(* rc=10 fixture, -postCondition arm.  Exactly ONE distinct state, so       *)
(* Gate!NonVacuous (>= 4 distinct) is FALSE.                                *)
(*                                                                          *)
(* This is also the V2-PLAN.md section 5.3 trap in miniature: the run is    *)
(* vacuous, TLC finds no error, and only the postcondition converts that    *)
(* into a nonzero exit code.                                                *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE x

Init == x = 0
Next == UNCHANGED x
Spec == Init /\ [][Next]_x

=============================================================================
