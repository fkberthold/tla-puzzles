---------------------------- MODULE FrozenMapping ---------------------------
(***************************************************************************)
(* THE TRAPDOOR, shown open on this probe's own material rather than on a   *)
(* harness fixture. It is here so the probe gate proves the closure holds   *)
(* for p1-commit and not only for harness/fixtures/refinement.             *)
(*                                                                         *)
(* The concrete spec below is honest. The mapping is not: it sends the      *)
(* abstract rmState to a constant, so TCommit's action formula unfolds to   *)
(* TCNext \/ UNCHANGED rmState and the right disjunct is true at every      *)
(* step. A naive refinement check exits 0 having never evaluated TCNext.    *)
(*                                                                         *)
(* EXPECTED VERDICT: FROZEN_MAPPING, exit 20.                               *)
(***************************************************************************)
CONSTANT RM

VARIABLE rmState

vars == <<rmState>>

Init == rmState = [rm \in RM |-> "working"]

Next ==
  \E rm \in RM :
    /\ rmState[rm] = "working"
    /\ rmState' = [rmState EXCEPT ![rm] = "prepared"]

Spec == Init /\ [][Next]_vars

TC == INSTANCE TCommit
        WITH RM <- RM,
             rmState <- [rm \in RM |-> "working"]

Refines == TC!TCSpec

=============================================================================
