------------------------ MODULE WrongUnilateralAbort ------------------------
(***************************************************************************)
(* DELIBERATELY WRONG solution for probe item p1-commit, and the reason the *)
(* grader is worth running at all. A grader that passes everything measures *)
(* nothing.                                                                 *)
(*                                                                         *)
(* It is TwoPhaseCommit with one guard widened. RMChooseToAbort reads       *)
(* rmState[rm] \in {"working", "prepared"} rather than "working", which is  *)
(* the other reading of the two requirements the brief puts next to each    *)
(* other: a resource manager may give up on its own at any time before it   *)
(* commits.                                                                 *)
(*                                                                         *)
(* It costs the transaction its consistency. Once the coordinator has       *)
(* committed, one resource manager can take the commit message and another  *)
(* can walk away, so two managers reach opposite decisions. TCommit admits  *)
(* no such step, so the refinement is violated.                            *)
(*                                                                         *)
(* EXPECTED VERDICT: REFINEMENT_VIOLATED, exit 22.                          *)
(***************************************************************************)
EXTENDS FiniteSets

CONSTANT RM

VARIABLES rmState, tmState, tmPrepared, msgs

vars == <<rmState, tmState, tmPrepared, msgs>>

Message == [type : {"Prepared"}, rm : RM] \cup [type : {"Commit", "Abort"}]

Init ==
  /\ rmState = [rm \in RM |-> "working"]
  /\ tmState = "waiting"
  /\ tmPrepared = {}
  /\ msgs = {}

RMPrepare(rm) ==
  /\ rmState[rm] = "working"
  /\ rmState' = [rmState EXCEPT ![rm] = "prepared"]
  /\ msgs' = msgs \cup {[type |-> "Prepared", rm |-> rm]}
  /\ UNCHANGED <<tmState, tmPrepared>>

\* THE ONE LINE THAT DIFFERS from the reference solution.
RMChooseToAbort(rm) ==
  /\ rmState[rm] \in {"working", "prepared"}
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

TC == INSTANCE TCommit WITH RM <- RM, rmState <- rmState

Refines == TC!TCSpec

=============================================================================
