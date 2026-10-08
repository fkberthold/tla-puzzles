------------------------- MODULE SubmissionNoTypeOK -------------------------
(***************************************************************************)
(* The three DOMAIN invariants with no type invariant, graded as a separate  *)
(* submission.                                                              *)
(*                                                                          *)
(* This is here to be failed.  A spike that reported "the matrix is green"   *)
(* without ever watching it go red would be reporting an instrument it had   *)
(* not seen work.  The `commit-overshoots` variant is caught by a type       *)
(* invariant and by nothing else in the set, so this submission should come  *)
(* back PROPERTY_TOO_WEAK at rc=40 and name that variant.                    *)
(***************************************************************************)
EXTENDS Rollout

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
    /\ NoStepInversion
    /\ NoSilentDivergence
    /\ NoStrandedApp

=============================================================================
