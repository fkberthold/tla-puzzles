---- MODULE Order ----
EXTENDS Integers, OrderStates

VARIABLE order

vars == << order >>

Init == order = "new"

Next == \E t \in States : ValidTransition(order, t) /\ order' = t

Spec == Init /\ [][Next]_vars

TypeOK == order \in States

====
