------------------------ MODULE UnsatFairness ------------------------
(***************************************************************************)
(* VACUITY VECTOR 4: a fairness conjunct no behaviour can meet.             *)
(*                                                                         *)
(* `Reset` is dropped from `Next` but `WF_counter(Reset)` stays in `Spec`.  *)
(* Fairness then demands a step the next-state relation forbids, so the    *)
(* set of behaviours satisfying `Spec` is EMPTY -- and every temporal       *)
(* obligation holds over nothing.                                          *)
(*                                                                         *)
(* Why no behaviour survives, in two steps:                                *)
(*                                                                         *)
(*   - `WF_counter(Up)` forces counter to reach 4. Up is continuously      *)
(*     enabled while counter < 4, so a behaviour that stalls below 4       *)
(*     violates it.                                                        *)
(*   - from counter = 4 onwards `<<Reset>>_counter` is continuously        *)
(*     enabled and `Next` allows only `Up`, which is now disabled. So the  *)
(*     behaviour stutters forever with Reset enabled and never taken, and  *)
(*     that violates `WF_counter(Reset)`.                                  *)
(*                                                                         *)
(* THE STATE GRAPH IS PERFECTLY HEALTHY. TLC checks invariants over the    *)
(* state graph, and fairness never touches it, so `Bounded` still bites,   *)
(* Gate!NonVacuous still sees 5 distinct states, and                        *)
(* Gate!InvariantConfigured still passes. Only the liveness half goes      *)
(* blind. `Liveness` below holds on LiveFairness.tla for a reason, and     *)
(* holds VACUOUSLY here at rc=0, which is the whole trap.                  *)
(*                                                                         *)
(* NO ACTION READS total == 0 EITHER. `Reset` is not a disjunct of `Next`, *)
(* so it has no coverage row at all rather than a row reading zero.        *)
(*                                                                         *)
(* Shape taken from seedlib step-2 variant V47, which dropped `Close` from *)
(* `Next` and kept `WF_vars(Close)`. It was recorded uncaught at rc=0 in   *)
(* authoring/seedlib/reports/step2-variants.md.                            *)
(*                                                                         *)
(* `AlwaysBad` is here for the mechanism-pinning row in test-vacuity.sh,   *)
(* not for the learner-facing verdict: an always-false TEMPORAL formula is *)
(* the satisfiability probe, and it must be temporal. `[](counter #        *)
(* counter)` over a state predicate is lifted into an INVARIANT by TLC and *)
(* checked against the state graph, which ignores fairness by              *)
(* construction, so that shape cannot see this vector however false it is. *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE counter

Init  == counter = 0
Up    == counter < 4 /\ counter' = counter + 1
Reset == counter = 4 /\ counter' = 0

Next  == Up
Spec  == Init /\ [][Next]_counter /\ WF_counter(Up) /\ WF_counter(Reset)

Bounded  == counter \in 0..4
Liveness == []<>(counter = 4)

AlwaysBad      == []<>(counter # counter)
AlwaysBadState == [](counter # counter)

=============================================================================
