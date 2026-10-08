--------------------------- MODULE RolloutInflight --------------------------
(***************************************************************************)
(* THE SAME SYSTEM WITH A SECOND STALENESS CHANNEL, built to measure what    *)
(* the extra channel costs and whether it finds anything the primary model   *)
(* misses.                                                                   *)
(*                                                                          *)
(* Rollout.tla makes a sync ATOMIC, so the only thing that can be stale is   *)
(* the revision a comparison was made against.  Here a sync has a window:    *)
(* `busy[a]` is an operation in flight, and the published status carries a    *)
(* stale copy of it in `obsBusy[a]` -- the Progressing/Healthy channel the   *)
(* issue also says was stale.  Seven variables against five.                 *)
(*                                                                          *)
(* The completion predicate reads BOTH observed channels, which is the       *)
(* literal reading of "Step 1's app was still reporting Synced/Healthy from  *)
(* before the commit".                                                       *)
(***************************************************************************)
EXTENDS Naturals

CONSTANTS NumApps, MaxRev, Strict

Apps      == 1 .. NumApps
NumSteps  == NumApps
Cohort(a) == a
Revs      == 0 .. MaxRev
Idle      == NumSteps + 1

VARIABLES target, step, live, busy, obsRev, obsSynced, obsBusy

vars == << target, step, live, busy, obsRev, obsSynced, obsBusy >>

TypeOK ==
    /\ target \in Revs
    /\ step \in 1 .. Idle
    /\ live \in [Apps -> Revs]
    /\ busy \in [Apps -> BOOLEAN]
    /\ obsRev \in [Apps -> Revs]
    /\ obsSynced \in [Apps -> BOOLEAN]
    /\ obsBusy \in [Apps -> BOOLEAN]

Init ==
    /\ target = 0
    /\ step = Idle
    /\ live = [a \in Apps |-> 0]
    /\ busy = [a \in Apps |-> FALSE]
    /\ obsRev = [a \in Apps |-> 0]
    /\ obsSynced = [a \in Apps |-> TRUE]
    /\ obsBusy = [a \in Apps |-> FALSE]

Commit ==
    /\ target < MaxRev
    /\ target' = target + 1
    /\ step' = 1
    /\ UNCHANGED << live, busy, obsRev, obsSynced, obsBusy >>

BeginSync(a) ==
    /\ step <= NumSteps
    /\ Cohort(a) = step
    /\ ~busy[a]
    /\ live[a] # target
    /\ busy' = [busy EXCEPT ![a] = TRUE]
    /\ UNCHANGED << target, step, live, obsRev, obsSynced, obsBusy >>

FinishSync(a) ==
    /\ busy[a]
    /\ live' = [live EXCEPT ![a] = target]
    /\ busy' = [busy EXCEPT ![a] = FALSE]
    /\ UNCHANGED << target, step, obsRev, obsSynced, obsBusy >>

Refresh(a) ==
    /\ \/ obsRev[a] # target
       \/ obsSynced[a] # (live[a] = target)
       \/ obsBusy[a] # busy[a]
    /\ obsRev' = [obsRev EXCEPT ![a] = target]
    /\ obsSynced' = [obsSynced EXCEPT ![a] = (live[a] = target)]
    /\ obsBusy' = [obsBusy EXCEPT ![a] = busy[a]]
    /\ UNCHANGED << target, step, live, busy >>

StepComplete(s) ==
    \A a \in Apps :
        Cohort(a) = s =>
            /\ obsSynced[a]
            /\ ~obsBusy[a]
            /\ (Strict => obsRev[a] = target)

Advance ==
    /\ step <= NumSteps
    /\ StepComplete(step)
    /\ step' = step + 1
    /\ UNCHANGED << target, live, busy, obsRev, obsSynced, obsBusy >>

Next ==
    \/ Commit
    \/ Advance
    \/ \E a \in Apps : BeginSync(a)
    \/ \E a \in Apps : FinishSync(a)
    \/ \E a \in Apps : Refresh(a)

Spec == Init /\ [][Next]_vars

(***************************************************************************)
(* The obligations, with "started" now meaning busy OR converged -- the      *)
(* in-flight window is exactly what gives the inversion a second shape: a    *)
(* later cohort can be MID-SYNC while an earlier one is untouched, which the *)
(* atomic model cannot express.                                              *)
(***************************************************************************)
Started(a) == busy[a] \/ live[a] = target

NoStepInversion ==
    \A a \in Apps : \A b \in Apps :
        (Cohort(a) < Cohort(b) /\ Started(b)) => live[a] = target

NoSilentDivergence ==
    (step > NumSteps) => (\A a \in Apps : live[a] = target)

CanStillConverge(a) ==
    \/ target < MaxRev
    \/ busy[a]
    \/ step <= Cohort(a)

NoStrandedApp ==
    \A a \in Apps : (live[a] # target) => CanStillConverge(a)

=============================================================================
