------------------------------- MODULE Probes -------------------------------
(***************************************************************************)
(* VACUITY PROBES.                                                          *)
(*                                                                          *)
(* A clean invariant that is clean because nothing moves is worthless, and  *)
(* so is a dirty one that is dirty for a reason other than the defect.      *)
(* Every operator below is something this model had better be able to do,   *)
(* written as the DENIAL of it, so TLC refutes it and exits 12.  A probe     *)
(* that exits 0 is a finding about the model, not a pass.                    *)
(*                                                                          *)
(* Each one is driven by its own probe-*.cfg through `tlc -config`, so the  *)
(* constants -- and in particular `Strict` -- are set per probe.            *)
(***************************************************************************)
EXTENDS Props

(* The commit happens.  Without it nothing in this model has any reason to  *)
(* move at all.                                                             *)
NeverCommits == target = 0

(* An application converges.  If this held, every obligation over `live`    *)
(* would be about a fleet that never did anything.                          *)
NeverSyncs == \A a \in Apps : live[a] = 0

(* The step pointer moves off step 1.  An ordering obligation over a        *)
(* rollout that never reaches a second step is vacuous.                     *)
NeverAdvances == step # 2

(* The rollout reaches its end state after the commit.  On the FIXED model  *)
(* this is the probe that matters most: a completion predicate that could   *)
(* never be satisfied would make every obligation hold for free.            *)
NeverCompletes == ~(target = MaxRev /\ step > NumSteps)

(* The stale window is reachable: some application's published status was   *)
(* compared against a revision that is no longer the target.  This is the   *)
(* mechanism the whole problem is about, so a model where it never happened *)
(* would be modelling something else.                                       *)
NeverStale == \A a \in Apps : obsRev[a] = target

(* A refresh lands PART WAY THROUGH the rollout, rather than only between  *)
(* cohorts.  The source never says which, and the choice decides whether    *)
(* the inversion is reachable at all, so it gets a probe of its own:        *)
(* refuting this is the evidence that mid-rollout refreshes really occur in *)
(* the state space and not merely in the module text.                       *)
NoMidCohortRefresh ==
    \A a \in Apps :
        obsRev[a] = target => (\A b \in Apps : live[b] = target)

(* THE HAPPY PATH IS STILL REACHABLE IN THE BROKEN MODEL.  The defect is a  *)
(* race on the refresh interval, not an inevitability, and a model in which *)
(* the rollout could only ever fail would overstate the issue.              *)
NeverAllConverged ==
    ~( /\ target = MaxRev
       /\ step > NumSteps
       /\ (\A a \in Apps : live[a] = target) )

(* An application is observed OutOfSync.  If the refresh loop could never   *)
(* publish a negative verdict then `obsSynced` would be a constant TRUE and *)
(* the completion predicate would be reading nothing.                       *)
NeverObservedOutOfSync == \A a \in Apps : obsSynced[a]

(***************************************************************************)
(* TWO NEGATIVE CONTROLS.                                                   *)
(*                                                                          *)
(* Sixteen probes all exiting 12 is also what a probe channel that always   *)
(* exits 12 looks like.  These two are expected to exit 0, so the table      *)
(* carries evidence that the channel can report both ways.                   *)
(*                                                                          *)
(* LiveNeverRunsAhead holds on both systems: `live[a]` is only ever          *)
(* assigned the current target, and the target only increases.               *)
(*                                                                          *)
(* StepPrefixConverged is the discriminating one.  It holds on the FIXED     *)
(* system and fails on the BROKEN one, so one operator shows the channel     *)
(* returning 0 and 12 on the same text with one constant changed.            *)
(***************************************************************************)
LiveNeverRunsAhead == \A a \in Apps : live[a] <= target

StepPrefixConverged ==
    \A a \in Apps : Cohort(a) < step => live[a] = target

=============================================================================
