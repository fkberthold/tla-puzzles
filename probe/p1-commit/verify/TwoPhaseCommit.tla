--------------------------- MODULE TwoPhaseCommit ---------------------------
(***************************************************************************)
(* REFERENCE SOLUTION for probe item p1-commit. Written for this probe,    *)
(* not copied from any published module. Withheld from the delivered tree.  *)
(*                                                                         *)
(* THE DECISION THIS MODULE MAKES, and it is the decision the brief forces: *)
(* a resource manager keeps its right to abort on its own only while it has *)
(* not yet voted. RMChooseToAbort is guarded by rmState[rm] = "working".    *)
(* Once it votes, the only thing that moves it is the coordinator's         *)
(* decision. verify/wrong/ holds the other reading and the verdict it gets. *)
(***************************************************************************)
EXTENDS FiniteSets

CONSTANT RM

VARIABLES rmState, tmState, tmPrepared, msgs

vars == <<rmState, tmState, tmPrepared, msgs>>

Message == [type : {"Prepared"}, rm : RM] \cup [type : {"Commit", "Abort"}]

TypeOK ==
  /\ rmState \in [RM -> {"working", "prepared", "committed", "aborted"}]
  /\ tmState \in {"waiting", "committed", "aborted"}
  /\ tmPrepared \subseteq RM
  /\ msgs \subseteq Message

Init ==
  /\ rmState = [rm \in RM |-> "working"]
  /\ tmState = "waiting"
  /\ tmPrepared = {}
  /\ msgs = {}

-----------------------------------------------------------------------------
(* The resource managers. *)

RMPrepare(rm) ==
  /\ rmState[rm] = "working"
  /\ rmState' = [rmState EXCEPT ![rm] = "prepared"]
  /\ msgs' = msgs \cup {[type |-> "Prepared", rm |-> rm]}
  /\ UNCHANGED <<tmState, tmPrepared>>

RMChooseToAbort(rm) ==
  /\ rmState[rm] = "working"
  /\ rmState' = [rmState EXCEPT ![rm] = "aborted"]
  /\ UNCHANGED <<tmState, tmPrepared, msgs>>

RMRcvCommit(rm) ==
  /\ [type |-> "Commit"] \in msgs
  /\ rmState[rm] = "prepared"
  /\ rmState' = [rmState EXCEPT ![rm] = "committed"]
  /\ UNCHANGED <<tmState, tmPrepared, msgs>>

RMRcvAbort(rm) ==
  /\ [type |-> "Abort"] \in msgs
  /\ rmState[rm] \in {"working", "prepared"}
  /\ rmState' = [rmState EXCEPT ![rm] = "aborted"]
  /\ UNCHANGED <<tmState, tmPrepared, msgs>>

-----------------------------------------------------------------------------
(* The coordinator. None of its actions touches rmState, so every one of    *)
(* them maps to an abstract stuttering step.                                *)

TMRcvPrepared(rm) ==
  /\ tmState = "waiting"
  /\ [type |-> "Prepared", rm |-> rm] \in msgs
  /\ tmPrepared' = tmPrepared \cup {rm}
  /\ UNCHANGED <<rmState, tmState, msgs>>

TMCommit ==
  /\ tmState = "waiting"
  /\ tmPrepared = RM
  /\ tmState' = "committed"
  /\ msgs' = msgs \cup {[type |-> "Commit"]}
  /\ UNCHANGED <<rmState, tmPrepared>>

TMAbort ==
  /\ tmState = "waiting"
  /\ tmState' = "aborted"
  /\ msgs' = msgs \cup {[type |-> "Abort"]}
  /\ UNCHANGED <<rmState, tmPrepared>>

-----------------------------------------------------------------------------

Next ==
  \/ \E rm \in RM :
       \/ RMPrepare(rm)
       \/ RMChooseToAbort(rm)
       \/ RMRcvCommit(rm)
       \/ RMRcvAbort(rm)
       \/ TMRcvPrepared(rm)
  \/ TMCommit
  \/ TMAbort

Spec == Init /\ [][Next]_vars

Consistent ==
  \A rm1, rm2 \in RM :
    ~(rmState[rm1] = "aborted" /\ rmState[rm2] = "committed")

-----------------------------------------------------------------------------
(* The refinement mapping. Every name TCommit declares is stated, including *)
(* the one the substitution would have found on its own.                   *)

TC == INSTANCE TCommit WITH RM <- RM, rmState <- rmState

Refines == TC!TCSpec

=============================================================================
