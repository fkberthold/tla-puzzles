-------------------------- MODULE EmptyInit --------------------------
(***************************************************************************)
(* VACUITY VECTOR 1: an unsatisfiable Init.                                 *)
(*                                                                          *)
(* Bare TLC on this module reports "No error has been found", "0 states     *)
(* generated", and exits 0. Deadlock checking does NOT catch it: there is   *)
(* no reachable state to deadlock in. Every invariant in the .cfg holds     *)
(* trivially over the empty set, so a learner who submits this scores full  *)
(* marks for a spec that models nothing at all.                             *)
(*                                                                          *)
(* The shape is a plausible learner mistake rather than a literal `{}`: the *)
(* declared range and the guard cannot both hold, which is the same error   *)
(* as an off-by-one on a bound.                                             *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE counter

Init == counter \in 0..3 /\ counter > 10
Next == counter' = counter + 1
Spec == Init /\ [][Next]_counter

Bounded == counter <= 100

=============================================================================
