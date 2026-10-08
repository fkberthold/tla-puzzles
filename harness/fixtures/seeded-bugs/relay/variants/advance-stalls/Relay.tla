------------------------------- MODULE Relay --------------------------------
(***************************************************************************)
(* SEEDED VARIANT: Advance leaves the position where it found it.  One      *)
(* definition changed; everything else is the reference.                    *)
(*                                                                          *)
(* The relay never leaves position 0, so this is the stronger of the two    *)
(* variants: the reachable state space is one state rather than three.  It  *)
(* is here because the two mutations fail DIFFERENTLY -- recycle-early      *)
(* keeps position 2 reachable and loses the recurrence, while this one      *)
(* makes position 2 unreachable outright -- and a matrix with only the      *)
(* first could be satisfied by a property that merely asserted              *)
(* reachability.                                                            *)
(*                                                                          *)
(* Still deadlock-free: Advance is enabled at position 0 and maps it to     *)
(* itself, so the state has a successor and TLC never reaches rc=11.  That  *)
(* successor is a real Next step rather than a stuttering step, so          *)
(* WF_vars(Next) is satisfied by the behaviour that violates the oracle --  *)
(* which is what makes this a statement about the relay and not about       *)
(* fairness.                                                                 *)
(***************************************************************************)
EXTENDS Naturals

VARIABLES stage

vars == << stage >>

Stages == 0 .. 2

Init == stage = 0

Advance == stage < 2 /\ stage' = stage
Recycle == stage = 2 /\ stage' = 0

Next == Advance \/ Recycle

Spec == Init /\ [][Next]_vars

FairSpec == Spec /\ WF_vars(Next)

Alias == [ position |-> stage ]

=============================================================================
