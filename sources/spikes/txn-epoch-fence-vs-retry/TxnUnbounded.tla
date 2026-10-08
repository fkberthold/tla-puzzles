----------------------------- MODULE TxnUnbounded ---------------------------
(***************************************************************************)
(* THE CONTROL THE BRIEF ASKS FOR BY NAME: "a spike that lets the counter   *)
(* keep climbing never reaches the bug".                                   *)
(*                                                                         *)
(* TxnBroken.tla with the ceiling deleted.  CanBump is TRUE everywhere and  *)
(* Exhausted is FALSE everywhere, so there is no value for the two          *)
(* predicates to disagree at and the trap predicate is UNSATISFIABLE rather *)
(* than merely unviolated.  Every other line is byte-identical to           *)
(* TxnBroken.tla, including the defect in EndRetry.                        *)
(*                                                                         *)
(* The state space is INFINITE: cEpoch climbs without bound.  `Bound` is a  *)
(* CONSTRAINT bound and not a ceiling -- nothing in the next-state relation *)
(* reads it.  Keeping those two roles in separate names is the point of the *)
(* module: a ceiling changes what the system DOES, a constraint changes     *)
(* only how much of it TLC LOOKS AT.                                       *)
(*                                                                         *)
(* What a green run here establishes, exactly: no violation among the       *)
(* states reachable without cEpoch passing `Bound`.  Not a proof.          *)
(***************************************************************************)
EXTENDS Naturals

CONSTANT Bound

TxnStates    == {"Empty", "Ongoing", "PrepareAbort", "CompleteAbort"}
ClientStates == {"ready", "inTxn", "ending"}

VARIABLES txn, cEpoch, pEpoch, pState

vars == << txn, cEpoch, pEpoch, pState >>

TypeOK ==
    /\ txn    \in TxnStates
    /\ cEpoch \in Nat
    /\ pEpoch \in Nat
    /\ pState \in ClientStates

Init ==
    /\ txn    = "Empty"
    /\ cEpoch = 0
    /\ pEpoch = 0
    /\ pState = "ready"

\* THE DELETION, and all of it.
CanBump    == TRUE
Exhausted  == FALSE
IsRetry(e) == cEpoch > 0 /\ e = cEpoch - 1
TxnFree    == txn \in {"Empty", "CompleteAbort"}

\* The CONSTRAINT operator. Named separately from anything above so it can
\* never be mistaken for a guard.
InBound == cEpoch <= Bound

-----------------------------------------------------------------------------

Begin ==
    /\ pState = "ready"
    /\ TxnFree
    /\ pEpoch = cEpoch
    /\ txn'    = "Ongoing"
    /\ pState' = "inTxn"
    /\ UNCHANGED << cEpoch, pEpoch >>

RequestEnd ==
    /\ pState = "inTxn"
    /\ pState' = "ending"
    /\ UNCHANGED << txn, cEpoch, pEpoch >>

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

EndBump ==
    /\ pState = "ending"
    /\ txn    = "Ongoing"
    /\ pEpoch = cEpoch
    /\ CanBump
    /\ ~Exhausted
    /\ cEpoch' = cEpoch + 1
    /\ pEpoch' = cEpoch + 1
    /\ txn'    = "Empty"
    /\ pState' = "ready"

EndRotate ==
    /\ pState = "ending"
    /\ txn    = "Ongoing"
    /\ pEpoch = cEpoch
    /\ Exhausted
    /\ cEpoch' = 0
    /\ pEpoch' = 0
    /\ txn'    = "Empty"
    /\ pState' = "ready"

TimeoutFence ==
    /\ txn = "Ongoing"
    /\ CanBump
    /\ cEpoch' = cEpoch + 1
    /\ txn'    = "PrepareAbort"
    /\ UNCHANGED << pEpoch, pState >>

CompleteAbort ==
    /\ txn  = "PrepareAbort"
    /\ txn' = "CompleteAbort"
    /\ UNCHANGED << cEpoch, pEpoch, pState >>

\* The defect is still here, unmodified. It just has nothing to bite on.
EndRetry ==
    /\ pState = "ending"
    /\ txn \in {"PrepareAbort", "CompleteAbort"}
    /\ IsRetry(pEpoch)
    /\ pEpoch' = cEpoch
    /\ pState' = "ready"
    /\ UNCHANGED << txn, cEpoch >>

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

Spec     == Init /\ [][Next]_vars
FairSpec == Spec /\ WF_vars(Next)

-----------------------------------------------------------------------------

TxnEventuallyEnds == (txn = "Ongoing") ~> (txn # "Ongoing")

(***************************************************************************)
(* The trap, stated MECHANICALLY rather than against a number.             *)
(*                                                                         *)
(* `~(txn = "Ongoing" /\ cEpoch = MaxEpoch)` would be meaningless here,     *)
(* since there is no MaxEpoch, and stating it against `Bound` would report  *)
(* the CONSTRAINT as the bug.  This form is the same predicate TxnBroken's  *)
(* NoStuckTxn names, written so it transfers: a transaction is open and no   *)
(* bump is available.  With CanBump = TRUE it is unsatisfiable, which is    *)
(* the whole finding.                                                      *)
(***************************************************************************)
NoStuckTxn == ~(txn = "Ongoing" /\ ~CanBump)

\* Vacuity witnesses, so a green run is not green because nothing moved.
WitnessOngoing == txn # "Ongoing"
WitnessAborted == txn # "CompleteAbort"
WitnessClimb   == cEpoch < Bound
=============================================================================
