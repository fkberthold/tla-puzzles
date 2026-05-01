---- MODULE Relational ----
\* Side B: pure TLA+ — natural for "any of N actions can fire" relational systems.
\* A small key-value store: any client may Put or Delete any key at any time.
\* No control flow — just a set of allowed transitions.
EXTENDS Integers, TLC

CONSTANT Keys, Values

VARIABLE store

TypeOK == store \in [Keys -> Values \cup {"<absent>"}]

Init == store = [k \in Keys |-> "<absent>"]

Put(k, v) ==
  /\ v \in Values
  /\ store' = [store EXCEPT ![k] = v]

Delete(k) ==
  /\ store[k] # "<absent>"
  /\ store' = [store EXCEPT ![k] = "<absent>"]

Next ==
  \/ \E k \in Keys, v \in Values : Put(k, v)
  \/ \E k \in Keys              : Delete(k)

Spec == Init /\ [][Next]_store
================================
