------------------------------- MODULE Oracle -------------------------------
(***************************************************************************)
(* THE AUTHOR'S OWN PROPERTY -- the matrix's instrument, not a submission.   *)
(*                                                                          *)
(* It is deliberately STRONGER than the obligation set the problem would     *)
(* ship (Submission.tla).  That asymmetry is what phases 3 and 4 need: the   *)
(* oracle's job is to prove the VARIANT SET is sound, so a variant it cannot *)
(* catch is reported as our defect (VARIANT_INERT) rather than billed to a   *)
(* submission.  An oracle no stronger than the submission makes phase 3 and  *)
(* phase 4 the same question asked twice.                                    *)
(*                                                                          *)
(* The last two conjuncts are the extra strength.  Neither belongs in the    *)
(* shipped set: StepPrefixConverged restates the controller's own internal   *)
(* bookkeeping rather than anything a user could observe, and ObsSound is a   *)
(* fact about the refresh loop that holds on the broken system too, so        *)
(* neither would teach a learner anything about the defect.                   *)
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

(* Every cohort the step pointer has walked past really did converge. *)
StepPrefixConverged ==
    \A a \in Apps : Cohort(a) < step => live[a] = target

(* A published status that is BOTH fresh and Synced is telling the truth.   *)
(* This is a fact about the refresh loop, not about the completion          *)
(* predicate, so it holds on the broken system as well.                     *)
ObsSound ==
    \A a \in Apps :
        (obsRev[a] = target /\ obsSynced[a]) => live[a] = target

Inv ==
    /\ TypeOK
    /\ NoStepInversion
    /\ NoSilentDivergence
    /\ NoStrandedApp
    /\ StepPrefixConverged
    /\ ObsSound

=============================================================================
