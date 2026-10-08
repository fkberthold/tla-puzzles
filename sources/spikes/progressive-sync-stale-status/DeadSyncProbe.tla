--------------------------- MODULE DeadSyncProbe ----------------------------
(***************************************************************************)
(* A DELIBERATELY BROKEN COPY, so the dead-action probe can be watched      *)
(* failing rather than taken on trust.                                      *)
(*                                                                          *)
(* It is Rollout.tla with one token changed: SyncApp's guard reads           *)
(* `target > MaxRev`, which is never true, so no application ever converges *)
(* and the action is a disjunct of Next that never fires.  V2-PLAN.md        *)
(* section 5.3 records the predicate as `total == 0` and NEVER               *)
(* `distinct == 0`, and harness/vacuity.sh should return rc=5                *)
(* VACUOUS_DEAD_ACTION here.                                                *)
(*                                                                          *)
(* Self-contained rather than EXTENDS Rollout, because the point is to       *)
(* change a guard inside the next-state relation and an extending module     *)
(* cannot redefine an inherited name -- TLA+ makes that a SANY error.        *)
(***************************************************************************)
EXTENDS Naturals

CONSTANTS NumApps, MaxRev

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
    /\ step = Idle
    /\ live = [a \in Apps |-> 0]
    /\ obsRev = [a \in Apps |-> 0]
    /\ obsSynced = [a \in Apps |-> TRUE]

Commit ==
    /\ target < MaxRev
    /\ target' = target + 1
    /\ step' = 1
    /\ UNCHANGED << live, obsRev, obsSynced >>

(* THE DEAD GUARD.  `target > MaxRev` is unsatisfiable. *)
SyncApp(a) ==
    /\ target > MaxRev
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
    \A a \in Apps : Cohort(a) = s => obsSynced[a]

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

=============================================================================
