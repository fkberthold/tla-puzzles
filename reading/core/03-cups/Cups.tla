---- MODULE Cups ----
EXTENDS Integers, FiniteSets

Place == 1..5

VARIABLE up
vars == <<up>>

TypeOK == up \subseteq Place

Init == up = {}

\* The only move turns over two cups with one cup between them.
Turn(i) ==
  LET pair == {i, i + 2}
  IN  up' = (up \ pair) \cup (pair \ up)

Next == \E i \in 1..3 : Turn(i)

Spec == Init /\ [][Next]_vars

EvenAmong(Pick(_)) ==
  Cardinality({i \in up : Pick(i)}) % 2 = 0

OddPlaces == EvenAmong(LAMBDA i : i % 2 = 1)

EvenPlaces == EvenAmong(LAMBDA i : i % 2 = 0)

NoMixedPair ==
  \A i, j \in Place : (i + j) % 2 = 1 => up # {i, j}
====
