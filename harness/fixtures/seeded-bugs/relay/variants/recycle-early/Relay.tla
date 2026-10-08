------------------------------- MODULE Relay --------------------------------
(***************************************************************************)
(* SEEDED VARIANT: Recycle fires from any non-zero position, not only from  *)
(* the last one.  One definition changed; everything else is the reference. *)
(*                                                                          *)
(* `stage = 2` is still REACHABLE, so no state predicate over a single      *)
(* state can tell this variant from the reference.  What the mutation adds  *)
(* is the cycle 0 -> 1 -> 0, which a fair behaviour may take for ever       *)
(* without ever reaching position 2.  Only a temporal formula sees it, and  *)
(* TLC refutes it through the liveness channel at rc=13.                    *)
(*                                                                          *)
(* Still deadlock-free: position 1 has two successors and positions 0 and 2 *)
(* have one each.                                                            *)
(***************************************************************************)
EXTENDS Naturals

VARIABLES stage

vars == << stage >>

Stages == 0 .. 2

Init == stage = 0

Advance == stage < 2 /\ stage' = stage + 1
Recycle == stage > 0 /\ stage' = 0

Next == Advance \/ Recycle

Spec == Init /\ [][Next]_vars

FairSpec == Spec /\ WF_vars(Next)

Alias == [ position |-> stage ]

=============================================================================
