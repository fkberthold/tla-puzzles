--------------------------- MODULE OnCallOracle ---------------------------
EXTENDS SnapshotOracle, Sequences

\* THE APPLICATION, written once against the oracle's API. Nothing here
\* mentions versions, timestamps or chains. Adapted from
\* sources/spikes/isolation/OnCallSnapshot.tla.

VARIABLE pc

vars == <<pc>> \o IsoVars

Doctor == Key

InitStore == [d \in Doctor |-> "on"]

TypeOK ==
    /\ IsoTypeOK
    /\ pc \in [Txn -> {"begin", "check", "finish", "done"}]

Init ==
    /\ IsoInit(InitStore)
    /\ pc = [t \in Txn |-> "begin"]

DoBegin(t) ==
    /\ pc[t] = "begin"
    /\ Begin(t)
    /\ pc' = [pc EXCEPT ![t] = "check"]

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

OnCall == {d \in Doctor : store[d] = "on"}

AtLeastOneOnCall == OnCall # {}

===========================================================================
