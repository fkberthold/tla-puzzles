------------------------------ MODULE TxnCoord -----------------------------
(***************************************************************************)
(* Apache Kafka KAFKA-20090, modelled at the APPLICATION level.            *)
(*                                                                         *)
(* A coordinator owns one client's transaction state machine and fences the *)
(* client by bumping a monotone epoch counter.  Two predicates over that    *)
(* one counter disagree at exactly one value, and the value is the ceiling. *)
(*                                                                         *)
(* THE FOUR STEPS, quoted from the issue body:                             *)
(*                                                                         *)
(*   1. The fencing abort on transactional timeout bumps the epoch to max   *)
(*   2. The EndTxn request with max epoch - 1 is considered a "retry" and   *)
(*      we return max epoch                                                *)
(*   3. The producer can start a transaction since we don't check epochs    *)
(*      on starting transactions                                           *)
(*   4. We cannot commit this transaction ... It is stuck in Ongoing        *)
(*      forever.                                                           *)
(*                                                                         *)
(* WHAT THE REQUEST CHANNEL COSTS: nothing.  There is no message set and no *)
(* epoch field on a request.  A client sitting in pState = "ending" IS an   *)
(* EndTxn in flight, and the epoch it carries is pEpoch -- which no action  *)
(* changes while pState = "ending", because only the coordinator's response *)
(* changes pEpoch and the response is the step out of "ending".  So the     *)
(* "late request carrying the previous epoch" needs no variable of its own. *)
(* That is the whole of the application-versus-mechanism saving here.       *)
(*                                                                         *)
(* WHAT IS COLLAPSED AWAY, and it is one thing: the producer id.  The real  *)
(* coordinator renews an exhausted epoch by ROTATING THE PRODUCER ID and    *)
(* resetting the epoch to 0 ("If epoch is max - 1, then rotate producer     *)
(* id, set epoch to 0" -- alivshits on the issue).  EndRotate below is that *)
(* rotation with the id dropped and only the reset kept.  The cost is that  *)
(* epochs REPEAT across a rotation, which this module's properties cannot   *)
(* see and which sources/spikes/fencing/FencedRestart.tla shows is its own  *)
(* safety bug.  See REPORT.md.                                             *)
(***************************************************************************)
EXTENDS Naturals

CONSTANT MaxEpoch

ASSUME MaxEpoch \in Nat /\ MaxEpoch >= 2

Epochs       == 0..MaxEpoch
TxnStates    == {"Empty", "Ongoing", "PrepareAbort", "CompleteAbort"}
ClientStates == {"ready", "inTxn", "ending"}

VARIABLES txn, cEpoch, pEpoch, pState

vars == << txn, cEpoch, pEpoch, pState >>

TypeOK ==
    /\ txn    \in TxnStates
    /\ cEpoch \in Epochs
    /\ pEpoch \in Epochs
    /\ pState \in ClientStates

Init ==
    /\ txn    = "Empty"
    /\ cEpoch = 0
    /\ pEpoch = 0
    /\ pState = "ready"

(***************************************************************************)
(* THE TWO PREDICATES OVER THE ONE COUNTER.                                *)
(*                                                                         *)
(* CanBump is the ending rule: under TV2 every transaction end bumps the    *)
(* epoch, so an end is possible only while a bump is.                      *)
(*                                                                         *)
(* Exhausted is the rotation threshold.  At max - 1 the normal end path     *)
(* renews instead of bumping, so the normal path NEVER leaves the counter   *)
(* at the ceiling -- "thus we never have epoch==max in completed state".   *)
(*                                                                         *)
(* IsRetry is the retry predicate.  It reads one epoch behind the           *)
(* coordinator as a duplicate of an end already handled.  It asks nothing   *)
(* about the ceiling, and that is the disagreement.                        *)
(***************************************************************************)
CanBump    == cEpoch < MaxEpoch
Exhausted  == cEpoch = MaxEpoch - 1
IsRetry(e) == cEpoch > 0 /\ e = cEpoch - 1
TxnFree    == txn \in {"Empty", "CompleteAbort"}

-----------------------------------------------------------------------------
\* The client.

\* AddPartitionsToTxn. It checks that the client's epoch is CURRENT -- a
\* stale epoch is fenced here -- and it does not ask whether that current
\* epoch is EXHAUSTED. Step 3 of the issue body, and the gap the issue
\* thread proposes closing "on transaction entry requests ... using a
\* ProducerEpochExhausted error".
Begin ==
    /\ pState = "ready"
    /\ TxnFree
    /\ pEpoch = cEpoch
    /\ txn'    = "Ongoing"
    /\ pState' = "inTxn"
    /\ UNCHANGED << cEpoch, pEpoch >>

\* EndTxn leaves the client. From here on pEpoch is the epoch on the wire.
RequestEnd ==
    /\ pState = "inTxn"
    /\ pState' = "ending"
    /\ UNCHANGED << txn, cEpoch, pEpoch >>

\* InitProducerId, case 1 of alivshits's walkthrough on the issue: no ongoing
\* transaction, so "if epoch is max - 1, then rotate producer id, set epoch to
\* 0", else bump. A client that has learnt its epoch is stale re-initialises
\* here. Without this action a refused client sits in "ready" with a stale
\* epoch and nothing enabled, and TLC reports a deadlock about a client that
\* in reality just calls InitProducerId again.
ReInit ==
    /\ pState = "ready"
    /\ TxnFree
    /\ pEpoch # cEpoch
    /\ CanBump
    /\ txn' = "Empty"
    /\ \/ /\ Exhausted
          /\ cEpoch' = 0
          /\ pEpoch' = 0
       \/ /\ ~Exhausted
          /\ cEpoch' = cEpoch + 1
          /\ pEpoch' = cEpoch + 1
    /\ UNCHANGED pState

-----------------------------------------------------------------------------
\* The coordinator.

\* The normal end, below the rotation threshold: bump, and hand the client
\* the bumped epoch.
\* SEEDED BUG: the ~Exhausted guard is gone, so the normal end path can bump
\* onto the ceiling instead of deferring to EndRotate.
EndBump ==
    /\ pState = "ending"
    /\ txn    = "Ongoing"
    /\ pEpoch = cEpoch
    /\ CanBump
    /\ cEpoch' = cEpoch + 1
    /\ pEpoch' = cEpoch + 1
    /\ txn'    = "Empty"
    /\ pState' = "ready"

\* The normal end AT the rotation threshold: renew rather than bump. This is
\* the producer-id rotation with the id collapsed away.
EndRotate ==
    /\ pState = "ending"
    /\ txn    = "Ongoing"
    /\ pEpoch = cEpoch
    /\ Exhausted
    /\ cEpoch' = 0
    /\ pEpoch' = 0
    /\ txn'    = "Empty"
    /\ pState' = "ready"

\* THE FIX, and all of it: the fencing abort rotates like any other abort.
\* This is `!isEpochFence` removed from the real condition, which is the fix
\* alivshits proposed on the issue -- "the `!isEpochFence` prevents the
\* proper producer id rotation and we end up in this state. I think just
\* removing the `!isEpochFence` condition should fix the issue."
\*
\* Nothing else in the module changes. EndRetry still asks nothing about the
\* ceiling, and Begin still admits a current epoch without asking whether it
\* is exhausted. Both are harmless now, because cEpoch can no longer reach
\* MaxEpoch at all -- MCFenceRotatesCeiling.cfg measures that.
TimeoutFence ==
    /\ txn = "Ongoing"
    /\ CanBump
    /\ txn'    = "PrepareAbort"
    /\ \/ /\ Exhausted
          /\ cEpoch' = 0
       \/ /\ ~Exhausted
          /\ cEpoch' = cEpoch + 1
    /\ UNCHANGED << pEpoch, pState >>

CompleteAbort ==
    /\ txn  = "PrepareAbort"
    /\ txn' = "CompleteAbort"
    /\ UNCHANGED << cEpoch, pEpoch, pState >>

\* THE DEFECT, and all of it. A late EndTxn one epoch behind, against an
\* abort state, is read as a retry and answered Errors.NONE carrying the
\* CURRENT epoch. No bump, no rotation, and no question asked about the
\* ceiling. Step 2 of the issue body.
EndRetry ==
    /\ pState = "ending"
    /\ txn \in {"PrepareAbort", "CompleteAbort"}
    /\ IsRetry(pEpoch)
    /\ pEpoch' = cEpoch
    /\ pState' = "ready"
    /\ UNCHANGED << txn, cEpoch >>

\* Everything else in flight is refused and the client is told so. Without
\* this the client hangs in "ending" and TLC reports a deadlock that is a
\* false alarm about a coordinator doing the right thing -- the Reject
\* action in sources/spikes/fencing/Fenced.tla exists for the same reason.
\* It leaves txn alone: refusing a request does not close a transaction.
EndRefused ==
    /\ pState = "ending"
    /\ ~(txn = "Ongoing" /\ pEpoch = cEpoch /\ CanBump)
    /\ ~(txn \in {"PrepareAbort", "CompleteAbort"} /\ IsRetry(pEpoch))
    /\ pState' = "ready"
    /\ UNCHANGED << txn, cEpoch, pEpoch >>

Next ==
    \/ Begin
    \/ RequestEnd
    \/ ReInit
    \/ EndBump
    \/ EndRotate
    \/ EndRetry
    \/ EndRefused
    \/ CompleteAbort
    \/ TimeoutFence

Spec == Init /\ [][Next]_vars

\* The fairness conjunct every liveness config here uses. Without it
\* TxnEventuallyEnds is violated by a behaviour that simply stops, which is
\* a true counterexample and a useless one. MCBrokenNoFair.cfg is that
\* mistake, run on purpose.
FairSpec == Spec /\ WF_vars(Next)

-----------------------------------------------------------------------------

(***************************************************************************)
(* THE REQUIREMENT. "Every transaction can eventually be committed or       *)
(* aborted."  It is a liveness property, so a model that checks only        *)
(* invariants comes back clean and proves nothing.                         *)
(***************************************************************************)
TxnEventuallyEnds == (txn = "Ongoing") ~> (txn # "Ongoing")

(***************************************************************************)
(* THE DEFECT'S OWN SIGNATURE, and it is a STATE PREDICATE.                *)
(*                                                                         *)
(* The coordinator never leaves the client holding an epoch that no bump    *)
(* can move off.  EndBump hands out at most max - 1, EndRotate hands out 0, *)
(* and EndRetry is the only action in the module that can put MaxEpoch into *)
(* pEpoch.  So this invariant is violated by the defect and by nothing      *)
(* else, which is what TxnEventuallyEnds cannot manage -- see REPORT.md,    *)
(* and see TxnBeginChecks.tla, where the liveness property holds and this   *)
(* one still fails.                                                        *)
(***************************************************************************)
NoExhaustedEpochHeld == pEpoch # MaxEpoch

(***************************************************************************)
(* The terminal trap as a state predicate.  Sound here rather than in       *)
(* general: once cEpoch = MaxEpoch no action in Next changes cEpoch, since  *)
(* every write to it is guarded by CanBump or by Exhausted, so a state      *)
(* matching this one can never leave the trap.                             *)
(***************************************************************************)
NoStuckTxn == ~(txn = "Ongoing" /\ cEpoch = MaxEpoch)

-----------------------------------------------------------------------------
(***************************************************************************)
(* VACUITY WITNESSES.  Each is FALSE on a healthy model, and each           *)
(* counterexample is the evidence that the named thing really happens.  A   *)
(* clean result that is clean because nothing moves is worthless, and these *)
(* are what rule that out.  Every one of them is expected at rc=12.        *)
(***************************************************************************)
(***************************************************************************)
(* NORMALISATION FOR THE TRACE DUMP.  seeded-bugs.sh passes this as          *)
(* `ALIAS Alias`, so the counterexample TLC dumps carries the normalised     *)
(* record rather than the raw variables.  It lives in the SPEC and not in a  *)
(* property module because the oracle run and the submission run must        *)
(* normalise identically or the comparison means nothing, and a property     *)
(* module could not supply it to the oracle run at all.                      *)
(*                                                                          *)
(* The values below are never diffed.  Only the action-name sequence and the *)
(* trace length are -- see the header of harness/seeded-bugs.sh.             *)
(***************************************************************************)
TxnCode(s) ==
    IF   s = "Empty"         THEN 0
    ELSE IF s = "Ongoing"       THEN 1
    ELSE IF s = "PrepareAbort"  THEN 2
    ELSE IF s = "CompleteAbort" THEN 3
    ELSE 9

ClientCode(s) ==
    IF   s = "ready"  THEN 0
    ELSE IF s = "inTxn"  THEN 1
    ELSE IF s = "ending" THEN 2
    ELSE 9

Alias == [ state  |-> TxnCode(txn),
           client |-> ClientCode(pState),
           coord  |-> cEpoch,
           prod   |-> pEpoch ]

WitnessOngoing  == txn # "Ongoing"            \* a transaction opens
WitnessAborted  == txn # "CompleteAbort"       \* the abort branch runs
WitnessRotation == cEpoch # MaxEpoch - 1       \* the epoch climbs to the
                                               \* rotation threshold, so the
                                               \* normal path really ran
WitnessCeiling  == cEpoch # MaxEpoch           \* the ceiling is REACHABLE.
                                               \* rc=0 here is the whole
                                               \* family being dead.
=============================================================================
