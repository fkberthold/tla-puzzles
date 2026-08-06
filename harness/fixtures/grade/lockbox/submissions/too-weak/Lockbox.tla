---------------------------- MODULE Lockbox ----------------------------
(***************************************************************************)
(* SUBMISSION: too weak. The cap is 5, so the lockbox reaches levels the    *)
(* reference forbids.                                                       *)
(*                                                                          *)
(* Expected: UNDER-constrained only. One reference obligation unmet (the    *)
(* capacity one), one still met -- this is the partial-credit fixture.      *)
(* Nothing here is too strict: every reference observation is reachable and *)
(* the stated requirement below holds of the reference.                     *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE level

Init == level = 0

Put  == level < 5 /\ level' = level + 1
Take == level > 0 /\ level' = level - 1

Next == Put \/ Take

Spec == Init /\ [][Next]_level

Observe == [level |-> level]

=============================================================================
