-------------------------- MODULE DeadGuard --------------------------
(***************************************************************************)
(* VACUITY VECTOR 3: a genuinely unreachable guard.                         *)
(*                                                                          *)
(* The state space is healthy (5 distinct states) and the .cfg configures a *)
(* real invariant, so BOTH Gate!NonVacuous and Gate!InvariantConfigured     *)
(* pass. What is empty here is neither the state space nor the obligation   *)
(* but one disjunct of Next: `Overflow` can never fire, because `counter`   *)
(* is capped at 4 by `Up`.                                                  *)
(*                                                                          *)
(* Under -coverage 1 the Overflow line reports a TOTAL of 0. That is the    *)
(* predicate. `distinct == 0` is NOT -- see TerminatingPcal.tla.            *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE counter

Init     == counter = 0
Up       == counter < 4 /\ counter' = counter + 1
Overflow == counter > 100 /\ counter' = 0
Next     == Up \/ Overflow
Spec     == Init /\ [][Next]_counter

Bounded == counter \in 0..4

=============================================================================
