---------------------- MODULE LivenessViolation ----------------------
(***************************************************************************)
(* rc=13 fixture.  Spec carries NO fairness, so the behaviour that stutters *)
(* forever at x = 0 is legal and violates <>(x = 1).                        *)
(*                                                                          *)
(* This is the PROPERTY channel, which V2-PLAN.md section 5.4 also uses for *)
(* refinement (Refines == Abstract!Spec is checked as a PROPERTY), so       *)
(* rc=13 is the refinement-failure code too.                                *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE x

Init == x = 0
Next == x' = 1 - x
Spec == Init /\ [][Next]_x

EventuallyOne == <>(x = 1)

=============================================================================
