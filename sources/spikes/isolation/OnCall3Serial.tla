--------------------------- MODULE OnCall3Serial ---------------------------
(***************************************************************************)
(* THE APPLICATION. A rostering service.                                    *)
(*                                                                         *)
(* Every doctor is either on call or off call. A doctor who wants to go     *)
(* off call opens a transaction, counts how many doctors are on call, and   *)
(* takes themselves off call only if at least two are. The service must     *)
(* keep at least one doctor on call at all times.                           *)
(*                                                                         *)
(* Nothing below mentions snapshots, versions, locks or commit protocols.   *)
(* The transaction reads with See, writes with Put and ends with Finish,    *)
(* and the isolation level decides what those mean. The three OnCall*.tla   *)
(* files are byte for byte identical apart from the module name and the     *)
(* EXTENDS line.                                                            *)
(***************************************************************************)
EXTENDS IsoSerial, Sequences

VARIABLE pc

vars == <<pc>> \o IsoVars

Doctor == Key

\* The roster starts with everybody on call.
InitStore == [d \in Doctor |-> "on"]

OnCall == {d \in Doctor : store[d] = "on"}

TypeOK == /\ IsoTypeOK
          /\ pc \in [Txn -> {"begin", "check", "finish", "done"}]

Init == /\ IsoInit(InitStore)
        /\ pc = [t \in Txn |-> "begin"]

DoBegin(t) ==
  /\ pc[t] = "begin"
  /\ Begin(t)
  /\ pc' = [pc EXCEPT ![t] = "check"]

\* How many doctors THIS transaction believes are on call.
SeenOnCall(t) == Cardinality({d \in Doctor : See(t, d) = "on"})

DoCheck(t) ==
  /\ pc[t] = "check"
  /\ Running(t)
  /\ \/ /\ SeenOnCall(t) >= 2
        /\ Put(t, t, "off")
     \/ /\ SeenOnCall(t) < 2
        /\ Idle
  /\ pc' = [pc EXCEPT ![t] = "finish"]

DoFinish(t) ==
  /\ pc[t] = "finish"
  /\ Running(t)
  /\ Finish(t)
  /\ pc' = [pc EXCEPT ![t] = "done"]

Next == \E t \in Txn : DoBegin(t) \/ DoCheck(t) \/ DoFinish(t)

Spec == Init /\ [][Next]_vars

\* The requirement the service exists to keep.
AtLeastOneOnCall == OnCall # {}

==========================================================================
