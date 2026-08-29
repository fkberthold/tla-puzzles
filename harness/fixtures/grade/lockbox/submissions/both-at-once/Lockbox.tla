---------------------------- MODULE Lockbox ----------------------------
(***************************************************************************)
(* SUBMISSION: too strong AND too weak at the same time. This is the        *)
(* fixture the bead's RED line names, and 23.6% of wrong models are this    *)
(* shape -- a design that treats the two failures as exclusive misgrades a  *)
(* quarter of them.                                                         *)
(*                                                                          *)
(* Reachable levels are {0, 1, 2, 5}:                                       *)
(*   TOO WEAK   level 5 is reachable and the reference forbids it, so the   *)
(*              reference's capacity obligation is unmet.                   *)
(*   TOO STRONG level 3 is unreachable, and the requirement stated in       *)
(*              LockboxObl.tla rules it out on purpose -- the reference     *)
(*              reaches it, so that requirement is refuted.                 *)
(*                                                                          *)
(* Expected: BOTH witnesses, one of each kind.                              *)
(*                                                                          *)
(* `Take` is guarded to 1..2 rather than to level > 0 on purpose. With the   *)
(* looser guard the box walks 5 -> 4 -> 3 and level 3 becomes reachable      *)
(* after all, which makes the submission's own stated requirement false of   *)
(* its own spec -- incoherent as a learner artifact, and it quietly turns    *)
(* the landmark member of the Relational suite green. The first draft of     *)
(* this fixture had exactly that bug and the grader is what found it.        *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE level

Init == level = 0

Put    == level < 2 /\ level' = level + 1
Take   == level \in 1..2 /\ level' = level - 1
Stuff  == level = 2 /\ level' = 5
Unload == level = 5 /\ level' = 2

Next == Put \/ Take \/ Stuff \/ Unload

Spec == Init /\ [][Next]_level

(* The `full` flag is part of the graded interface (see LockboxRef.tla). The *)
(* reachable levels are {0, 1, 2, 5}, so the flag is FALSE throughout and    *)
(* Req_fullflag holds. The capacity obligation is the one that is unmet.     *)
Observe == [level |-> level, full |-> (level = 3)]

=============================================================================
