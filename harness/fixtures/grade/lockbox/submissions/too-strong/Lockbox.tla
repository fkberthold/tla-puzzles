---------------------------- MODULE Lockbox ----------------------------
(***************************************************************************)
(* SUBMISSION: too strong. The cap is 1, so levels 2 and 3 are unreachable. *)
(*                                                                          *)
(* Expected: OVER-constrained only. Every reference obligation still holds  *)
(* -- a spec that admits fewer behaviours satisfies MORE properties, which  *)
(* is precisely why obligation 1 alone cannot see this failure and why      *)
(* whole-spec refinement against a gold reference cannot either.            *)
(*                                                                          *)
(* Both members of the Relational suite catch it: the stated requirement    *)
(* below is false of the reference, AND the landmark observation is         *)
(* unreachable here.                                                        *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE level

Init == level = 0

Put  == level < 1 /\ level' = level + 1
Take == level > 0 /\ level' = level - 1

Next == Put \/ Take

Spec == Init /\ [][Next]_level

Observe == [level |-> level]

=============================================================================
