----------------------- MODULE SafetyViolation -----------------------
(***************************************************************************)
(* rc=12 fixture.  x counts 0,1,2,3 and the INVARIANT asserts x < 3, so the *)
(* fourth state violates it.  Bounded, so the run terminates promptly with  *)
(* a counterexample rather than exhausting the timeout.                     *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE x

Init == x = 0
Next == IF x < 3 THEN x' = x + 1 ELSE UNCHANGED x
Spec == Init /\ [][Next]_x

Inv == x < 3

=============================================================================
