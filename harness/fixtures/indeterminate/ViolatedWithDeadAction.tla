------------------- MODULE ViolatedWithDeadAction -------------------
(***************************************************************************)
(* THE SITE-2 FIXTURE for bead tla-hl96.                                   *)
(*                                                                         *)
(* One module carrying TWO independent faults, because the defect is that  *)
(* the first fault HIDES the second:                                       *)
(*                                                                         *)
(*   1. `Bounded` is violated. counter reaches 4 and Bounded stops at 2,   *)
(*      so vacuity.sh's probe 2 exits 12 rather than 0.                    *)
(*   2. `Overflow` can never fire, because `Up` caps counter at 4. Under   *)
(*      -coverage 1 its row reads a TOTAL of 0 -- the same predicate       *)
(*      fixtures/vacuity/DeadGuard.tla pins.                               *)
(*                                                                         *)
(* Fault 2 alone is VACUOUS_DEAD_ACTION, caught today. Add fault 1 and     *)
(* probes 4, 5 and 6 never run at all, because each is guarded on          *)
(* `nv_rc = 0`. Before tla-hl96 the run then reported NON_VACUOUS rc 0 --   *)
(* a pass over three probes that did not happen, on a module that would    *)
(* have failed one of them.                                                *)
(*                                                                         *)
(* So this fixture is NOT "a module with a dead action". It is the         *)
(* MASKING PAIR, and both halves have to stay for it to test anything.     *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE counter

Init     == counter = 0
Up       == counter < 4 /\ counter' = counter + 1
Overflow == counter > 100 /\ counter' = 0
Next     == Up \/ Overflow
Spec     == Init /\ [][Next]_counter

(* Violated at counter = 3.  Reached after three Up steps, so the run has *)
(* generated real states before it stops -- the space is manifestly       *)
(* healthy, which is what makes the masking interesting rather than just  *)
(* a broken spec.                                                        *)
Bounded == counter \in 0..2

=============================================================================
