------------------------------- MODULE Props --------------------------------
(***************************************************************************)
(* The obligations over Rollout.tla.                                        *)
(*                                                                          *)
(* Named separately rather than conjoined, per .claude/rules/tla-practice.md *)
(* section 1: a named obligation is a label in TLC's failure report, and     *)
(* merging two throws the label away.  TypeOK is the attested exception --   *)
(* its arms are the per-variable clauses of a type invariant.                *)
(***************************************************************************)
EXTENDS Rollout

TypeOK ==
    /\ target \in Revs
    /\ step \in 1 .. Idle
    /\ live \in [Apps -> Revs]
    /\ obsRev \in [Apps -> Revs]
    /\ obsSynced \in [Apps -> BOOLEAN]

(***************************************************************************)
(* FAILURE 1 -- the ordering inversion.                                     *)
(*                                                                          *)
(* "prod-cohort apps rolled first".  No member of a later cohort is at the  *)
(* revision being rolled out while a member of an earlier cohort is not.    *)
(*                                                                          *)
(* A state invariant rather than an action property, because `live` carries  *)
(* the evidence forward: an app that has applied the target stays applied    *)
(* to it until the target moves, and when the target moves the premise and   *)
(* the conclusion move together.                                             *)
(***************************************************************************)
NoStepInversion ==
    \A a \in Apps : \A b \in Apps :
        (Cohort(a) < Cohort(b) /\ live[b] = target) => live[a] = target

(***************************************************************************)
(* FAILURE 2 -- silent permanent divergence.                                *)
(*                                                                          *)
(* "the skipped app then sat OutOfSync indefinitely (no retrigger)".        *)
(*                                                                          *)
(* Two separate claims, so two names.                                        *)
(*                                                                          *)
(* NoSilentDivergence is about the REPORT: the controller does not reach     *)
(* Idle while a member app is behind.                                        *)
(*                                                                          *)
(* NoStrandedApp is about the PERMANENCE, and it is the stronger and         *)
(* earlier-firing of the two: an app that is behind must still have          *)
(* something that could converge it.  CanStillConverge enumerates exactly    *)
(* the two routes by which `live[a]` can move again --                       *)
(*                                                                          *)
(*   - the step pointer has not passed a's cohort, so SyncApp(a) is          *)
(*     reachable (Advance only increments `step`, so once it is past, only   *)
(*     a Commit brings it back)                                              *)
(*   - a later commit is still possible, and Commit restarts the rollout.    *)
(*                                                                          *)
(* The enumeration over-approximates reachability, which is the safe         *)
(* direction: a violation is a genuine violation, and the invariant is       *)
(* merely weaker than the tightest possible statement.                        *)
(***************************************************************************)
NoSilentDivergence ==
    (step > NumSteps) => (\A a \in Apps : live[a] = target)

CanStillConverge(a) ==
    \/ target < MaxRev
    \/ step <= Cohort(a)

NoStrandedApp ==
    \A a \in Apps : (live[a] # target) => CanStillConverge(a)

=============================================================================
