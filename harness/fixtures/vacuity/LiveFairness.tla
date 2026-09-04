------------------------- MODULE LiveFairness -------------------------
(***************************************************************************)
(* THE NEGATIVE CONTROL FOR VECTOR 4. Nothing is wrong with this spec, and  *)
(* the satisfiability probe must not flag it.                              *)
(*                                                                         *)
(* It is UnsatFairness.tla with ONE disjunct restored: `Reset` is back in   *)
(* `Next`. Every other line is identical, including both fairness           *)
(* conjuncts and the `Liveness` property. So a probe that fires here is     *)
(* firing on the fairness conjuncts themselves rather than on the mismatch  *)
(* between fairness and `Next`, and the differential is what says which.    *)
(*                                                                         *)
(*   - the cycle 0 -> 1 -> 2 -> 3 -> 4 -> 0 -> ... satisfies both           *)
(*     `WF_counter(Up)` and `WF_counter(Reset)`, so `Spec` has behaviours.  *)
(*   - `Liveness` holds on all of them: `WF_counter(Up)` drives counter to  *)
(*     4 from anywhere below it, and `Reset` is the only way back down.     *)
(*                                                                         *)
(* `AlwaysBad` is the same always-false temporal formula UnsatFairness.tla  *)
(* carries, and it exists for the same mechanism-pinning row. Here `Spec`   *)
(* HAS behaviours, so the formula is refuted and TLC exits 13. There it is  *)
(* satisfied over the empty set and TLC exits 0. That pair of numbers is    *)
(* the probe.                                                              *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE counter

Init  == counter = 0
Up    == counter < 4 /\ counter' = counter + 1
Reset == counter = 4 /\ counter' = 0

Next  == Up \/ Reset
Spec  == Init /\ [][Next]_counter /\ WF_counter(Up) /\ WF_counter(Reset)

Bounded  == counter \in 0..4
Liveness == []<>(counter = 4)

AlwaysBad == []<>(counter # counter)

=============================================================================
