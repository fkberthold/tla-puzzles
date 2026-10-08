-------------------------- MODULE RolloutNoRestart --------------------------
(***************************************************************************)
(* THE OTHER CHOICE AT THE PLACE THE SOURCE IS SILENT.                      *)
(*                                                                          *)
(* Rollout.tla has Commit set `step' = 1`, so a new target revision restarts *)
(* the ordered rollout.  The issue says nothing about this either way.  This *)
(* module is the same system with the step pointer left where it was, which  *)
(* is the only difference, and the measured consequence is in REPORT.md.     *)
(*                                                                          *)
(* It is a separate module rather than a constant on Rollout.tla so the      *)
(* matrix reference stays byte-identical to the primary model.               *)
(***************************************************************************)
EXTENDS Naturals

CONSTANTS NumApps, MaxRev, Strict

Apps      == 1 .. NumApps
NumSteps  == NumApps
Cohort(a) == a
Revs      == 0 .. MaxRev
Idle      == NumSteps + 1

VARIABLES target, step, live, obsRev, obsSynced

vars == << target, step, live, obsRev, obsSynced >>

TypeOK ==
    /\ target \in Revs
    /\ step \in 1 .. Idle
    /\ live \in [Apps -> Revs]
    /\ obsRev \in [Apps -> Revs]
    /\ obsSynced \in [Apps -> BOOLEAN]

Init ==
    /\ target = 0
    /\ step = 1
    /\ live = [a \in Apps |-> 0]
    /\ obsRev = [a \in Apps |-> 0]
    /\ obsSynced = [a \in Apps |-> TRUE]

(* THE ONE DIFFERENCE: step is UNCHANGED. *)
Commit ==
    /\ target < MaxRev
    /\ target' = target + 1
    /\ UNCHANGED << step, live, obsRev, obsSynced >>

SyncApp(a) ==
    /\ step <= NumSteps
    /\ Cohort(a) = step
    /\ live[a] # target
    /\ live' = [live EXCEPT ![a] = target]
    /\ UNCHANGED << target, step, obsRev, obsSynced >>

Refresh(a) ==
    /\ \/ obsRev[a] # target
       \/ obsSynced[a] # (live[a] = target)
    /\ obsRev' = [obsRev EXCEPT ![a] = target]
    /\ obsSynced' = [obsSynced EXCEPT ![a] = (live[a] = target)]
    /\ UNCHANGED << target, step, live >>

StepComplete(s) ==
    \A a \in Apps :
        Cohort(a) = s =>
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

NoStepInversion ==
    \A a \in Apps : \A b \in Apps :
        (Cohort(a) < Cohort(b) /\ live[b] = target) => live[a] = target

NoSilentDivergence ==
    (step > NumSteps) => (\A a \in Apps : live[a] = target)

(* Without a restart there is no second route, so this collapses to the one *)
(* enabling condition of SyncApp.                                           *)
CanStillConverge(a) == step <= Cohort(a)

NoStrandedApp ==
    \A a \in Apps : (live[a] # target) => CanStillConverge(a)

=============================================================================
