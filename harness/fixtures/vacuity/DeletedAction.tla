------------------------ MODULE DeletedAction ------------------------
(***************************************************************************)
(* THE DEAD-ACTION PROBE'S BLIND SPOT: an action DELETED from `Next`.       *)
(*                                                                         *)
(* `Down` is defined, and reads word for word as it does in Healthy.tla.   *)
(* It is not a disjunct of `Next`. Compare DeadGuard.tla, where `Overflow` *)
(* IS a disjunct and merely carries a guard that is never true.            *)
(*                                                                         *)
(* SAME OBSERVABLE BEHAVIOUR, DIFFERENT COVERAGE. Under -coverage 1 a       *)
(* RESTRICTED action leaves a row reading `0:0`, which is what the          *)
(* `total == 0` predicate matches. A DELETED action leaves no row at all,   *)
(* so there is nothing for that predicate to match and the probe is         *)
(* silent. Deletion evades it. Restriction does not.                       *)
(*                                                                         *)
(* Everything else here is healthy on purpose, so this fixture is only      *)
(* reachable by the coverage probe. There are 5 distinct states, so         *)
(* Gate!NonVacuous passes. There is a real INVARIANT in the .cfg, so        *)
(* Gate!InvariantConfigured passes. `Up` fires, so no surviving row reads   *)
(* zero.                                                                   *)
(*                                                                         *)
(* Shape taken from seedlib step-2 variant V46, which dropped `Return`      *)
(* from `Next` and was recorded uncaught at rc=0 in                         *)
(* authoring/seedlib/reports/step2-variants.md, whose author checked the    *)
(* logs and found the coverage block listing every action except the        *)
(* deleted one.                                                            *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE counter

Init == counter = 0
Up   == counter < 4 /\ counter' = counter + 1
Down == counter > 0 /\ counter' = counter - 1

Next == Up
Spec == Init /\ [][Next]_counter

Bounded == counter \in 0..4

=============================================================================
