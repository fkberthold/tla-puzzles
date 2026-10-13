---- MODULE Fences ----
EXTENDS Integers, FiniteSets

---- MODULE Seg ----
CONSTANTS Lo, Hi
ASSUME Lo <= Hi
LOCAL Span == Hi - Lo
Cells == Lo..Hi
Count == IF Span < 0 THEN 0 ELSE Span + 1
====

CONSTANT N
ASSUME N \in 2..9

VARIABLES a, b
vars == <<a, b>>

Below == INSTANCE Seg WITH Lo <- 1,     Hi <- a - 1
Mid   == INSTANCE Seg WITH Lo <- a + 1, Hi <- b - 1
Above == INSTANCE Seg WITH Lo <- b + 1, Hi <- N

Gates == {a, b}
Open  == Below!Cells \cup Mid!Cells \cup Above!Cells

TypeOK ==
  /\ a \in 1..N
  /\ b \in 1..N
  /\ a <= b

Init == a = 1 /\ b = N

MoveA == a' \in 1..b /\ UNCHANGED b

MoveB == b' \in a..N /\ UNCHANGED a

Next == MoveA \/ MoveB

Spec == Init /\ [][Next]_vars

Covered == Open \cup Gates = 1..N

Counted ==
  Below!Count + Mid!Count + Above!Count = N - Cardinality(Gates)

MidEmptyWhenAdjacent == (b <= a + 1) => Mid!Cells = {}
====
