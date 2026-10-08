------------------------------ MODULE Rollout -------------------------------
(***************************************************************************)
(* An ordered rollout of one commit across a fleet of member applications, *)
(* in named cohorts, one cohort at a time.  Modelled after                 *)
(* argoproj/argo-cd#29410.                                                  *)
(*                                                                          *)
(* THE MODELLING DECISION THIS MODULE IS BUILT ON                           *)
(*                                                                          *)
(* This models the APPLICATION, not the mechanism.  Nothing here is a       *)
(* reconciliation loop, a manifest renderer, a health assessor, a resource  *)
(* hook or a work queue.  The whole of the mechanism that matters is three  *)
(* sentences:                                                               *)
(*                                                                          *)
(*   1. An application's published status is a COPY of its real state,      *)
(*      taken at some earlier moment by a refresh loop.                     *)
(*   2. The controller's step-completion predicate reads the COPY.          *)
(*   3. While the controller owns a member app, the controller is the only  *)
(*      thing that can make the app converge.  Automated sync is off.       *)
(*                                                                          *)
(* The published copy is (obsRev, obsSynced): the revision the comparison   *)
(* was made against, and whether it came back Synced.  That is Argo CD's    *)
(* `status.sync.comparedTo` and `status.sync.status`, and it is the pair     *)
(* the proposed fix (PR #29418) compares.                                   *)
(*                                                                          *)
(* NO `none` MARKER.  Revisions and cohort indices are naturals throughout, *)
(* so there is no model value beside an integer and no cross-type           *)
(* comparison for TLC to abort on.                                          *)
(*                                                                          *)
(* THIS MODULE DEFINES NO INVARIANT.  The obligations live in Props.tla,    *)
(* and this file doubles as the reference spec of the seeded-bug matrix     *)
(* under matrix/, where a submitted property module EXTENDS it and          *)
(* redefining an inherited name would be a SANY error.                      *)
(***************************************************************************)
EXTENDS Naturals

(***************************************************************************)
(*   NumApps  member applications, one per rollout step                    *)
(*   MaxRev   highest revision the model may reach                         *)
(*   Strict   TRUE: step completion compares revisions, the fix.           *)
(*            FALSE: it reads health alone, the reported bug.              *)
(***************************************************************************)
CONSTANTS NumApps, MaxRev, Strict

Apps     == 1 .. NumApps
NumSteps == NumApps
Cohort(a) == a          (* one member app per cohort, the minimal witness  *)
Revs     == 0 .. MaxRev
Idle     == NumSteps + 1

(***************************************************************************)
(* The five variables, documented here rather than inline.  A comment       *)
(* inside the VARIABLES block makes harness/spike-measure.sh report 36      *)
(* variables for the 5 declared below.  The discrepancy section of           *)
(* REPORT.md and probe-vars-comment/ carry the isolation.                    *)
(*                                                                          *)
(*   target     the revision being rolled out                               *)
(*   step       the step the controller is working on.  Idle means done     *)
(*   live       live[a]: the revision application a has actually applied    *)
(*   obsRev     obsRev[a]: revision a's published status compared against   *)
(*   obsSynced  obsSynced[a]: whether that comparison came back Synced      *)
(***************************************************************************)
VARIABLES target, step, live, obsRev, obsSynced

vars == << target, step, live, obsRev, obsSynced >>

(***************************************************************************)
(* The fleet starts settled: every app has applied revision 0 and every     *)
(* published status says so.  The controller is idle, which is what the     *)
(* issue's repro sketch starts from -- "let both apps reach Synced/Healthy  *)
(* at revision N".                                                          *)
(***************************************************************************)
Init ==
    /\ target = 0
    /\ step = Idle
    /\ live = [a \in Apps |-> 0]
    /\ obsRev = [a \in Apps |-> 0]
    /\ obsSynced = [a \in Apps |-> TRUE]

(***************************************************************************)
(* A commit lands that changes a template value affecting every cohort, so  *)
(* every member app is now out of date.  The rollout restarts at step 1.    *)
(*                                                                          *)
(* THE SOURCE IS SILENT on whether a new target revision restarts the       *)
(* rollout from step 1 or leaves the step pointer where it is.  Restarting  *)
(* is modelled here.  RolloutNoRestart.tla is the other choice, measured.   *)
(***************************************************************************)
Commit ==
    /\ target < MaxRev
    /\ target' = target + 1
    /\ step' = 1
    /\ UNCHANGED << live, obsRev, obsSynced >>

(***************************************************************************)
(* The controller syncs a member app of the step it is working on.  This is *)
(* the ONLY action that moves `live`, which is the model's whole statement  *)
(* of "progressive sync turns automated sync off for the member apps".      *)
(* An app the step pointer has walked past has nothing left to sync it.     *)
(***************************************************************************)
SyncApp(a) ==
    /\ step <= NumSteps
    /\ Cohort(a) = step
    /\ live[a] # target
    /\ live' = [live EXCEPT ![a] = target]
    /\ UNCHANGED << target, step, obsRev, obsSynced >>

(***************************************************************************)
(* The status refresh loop publishes a fresh comparison for one app: the    *)
(* revision it compared against, and the verdict.                           *)
(*                                                                          *)
(* NOTHING GUARDS THIS BY STEP BOUNDARY.  A refresh may land part way       *)
(* through a cohort, which is the reachable case and the one the issue's    *)
(* "the window is the app-status refresh interval" describes.  The source   *)
(* never says whether a refresh can land mid-cohort.  This choice is the    *)
(* reason the inversion is reachable at all, and the NoMidCohortRefresh     *)
(* probe is the witness that it does happen here.                           *)
(*                                                                          *)
(* The guard is "it would change something", so the model has no self-loop  *)
(* edges and a settled fleet is a terminal state.                           *)
(***************************************************************************)
Refresh(a) ==
    /\ \/ obsRev[a] # target
       \/ obsSynced[a] # (live[a] = target)
    /\ obsRev' = [obsRev EXCEPT ![a] = target]
    /\ obsSynced' = [obsSynced EXCEPT ![a] = (live[a] = target)]
    /\ UNCHANGED << target, step, live >>

(***************************************************************************)
(* THE DEFECT IS ONE CLAUSE.                                                *)
(*                                                                          *)
(* `obsSynced[a]` alone is "the member app reports Synced/Healthy".  It     *)
(* says nothing about WHICH revision that verdict was reached against, so   *)
(* a verdict computed before the commit satisfies it.                       *)
(*                                                                          *)
(* The issue's own statement of the rule: "A step should only be considered *)
(* complete when its member apps have synced (or been confirmed unchanged)  *)
(* at the revision being rolled out."  That is the Strict clause.           *)
(***************************************************************************)
StepComplete(s) ==
    \A a \in Apps :
        Cohort(a) = s - 1 =>
            /\ obsSynced[a]
            /\ (Strict => obsRev[a] = target)

Advance ==
    /\ step <= NumSteps
    /\ StepComplete(step)
    /\ step' = step + 1
    /\ UNCHANGED << target, live, obsRev, obsSynced >>

Next ==
    \/ Commit
    \/ Advance
    \/ \E a \in Apps : SyncApp(a)
    \/ \E a \in Apps : Refresh(a)

Spec == Init /\ [][Next]_vars

(***************************************************************************)
(* Normalisation for the trace dump the seeded-bug matrix compares.  It is  *)
(* defined by the SPEC rather than by a property module because the oracle  *)
(* run and the submission run have to normalise identically, and a property *)
(* module could not supply it to the oracle run at all.  Its VALUES are     *)
(* never diffed -- only the action-name sequence and the trace length are.  *)
(***************************************************************************)
Alias ==
    [ target |-> target,
      step |-> step,
      live |-> live,
      obsRev |-> obsRev,
      obsSynced |-> obsSynced ]

=============================================================================
