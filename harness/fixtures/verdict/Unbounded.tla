-------------------------- MODULE Unbounded --------------------------
(***************************************************************************)
(* rc=124 fixture.  x counts up with no bound and the .cfg carries no       *)
(* CONSTRAINT, so the state space is infinite and TLC never terminates.     *)
(* Run under a short timeout, this exits 124 -- which the harness treats as *)
(* its OWN verdict, not as a failure, because "we ran out of budget" and    *)
(* "the spec is wrong" are different facts about a submission.              *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE x

Init == x = 0
Next == x' = x + 1
Spec == Init /\ [][Next]_x

=============================================================================
