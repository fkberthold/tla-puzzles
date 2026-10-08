----------------------------- MODULE Submission -----------------------------
(***************************************************************************)
(* THE OBLIGATION SET THIS SPIKE PROPOSES THE PROBLEM SHIP, graded as a     *)
(* submission against the matrix.                                           *)
(*                                                                          *)
(* It is the four invariants of Props.tla, conjoined under `Inv` because     *)
(* harness/seeded-bugs.sh writes a single `INVARIANT <name>` line.  They are *)
(* named separately in Props.tla for the reason                             *)
(* .claude/rules/tla-practice.md section 1 gives: a named obligation is a    *)
(* label in TLC's failure report.  The matrix needs one name, so the         *)
(* conjunction lives here and nowhere else.                                 *)
(*                                                                          *)
(* SubmissionNoTypeOK.tla is the same set with the type invariant removed,   *)
(* kept because the matrix's verdict on it is the finding -- see REPORT.md.  *)
(***************************************************************************)
EXTENDS Rollout

TypeOK ==
    /\ target \in Revs
    /\ step \in 1 .. Idle
    /\ live \in [Apps -> Revs]
    /\ obsRev \in [Apps -> Revs]
    /\ obsSynced \in [Apps -> BOOLEAN]

NoStepInversion ==
    \A a \in Apps : \A b \in Apps :
        (Cohort(a) < Cohort(b) /\ live[b] = target) => live[a] = target

NoSilentDivergence ==
    (step > NumSteps) => (\A a \in Apps : live[a] = target)

CanStillConverge(a) ==
    \/ target < MaxRev
    \/ step <= Cohort(a)

NoStrandedApp ==
    \A a \in Apps : (live[a] # target) => CanStillConverge(a)

Inv ==
    /\ TypeOK
    /\ NoStepInversion
    /\ NoSilentDivergence
    /\ NoStrandedApp

=============================================================================
