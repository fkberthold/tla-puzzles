---- MODULE Matching ----
EXTENDS Naturals, FiniteSets

CONSTANT Node

VARIABLE mate
vars == <<mate>>

TypeOK == mate \in [Node -> Node]

Init == mate = [n \in Node |-> n]

Pair(a, b) ==
  /\ a # b
  /\ mate[a] = a
  /\ mate[b] = b
  /\ mate' = [mate EXCEPT ![a] = b, ![b] = a]

Unpair(a, b) ==
  /\ a # b
  /\ mate[a] = b
  /\ mate[b] = a
  /\ mate' = [mate EXCEPT ![a] = a, ![b] = b]

Next == \E a, b \in Node : Pair(a, b) \/ Unpair(a, b)

Spec == Init /\ [][Next]_vars

Involution == \A n \in Node : mate[mate[n]] = n

EvenlyPaired ==
  Cardinality({n \in Node : mate[n] # n}) % 2 = 0
====
