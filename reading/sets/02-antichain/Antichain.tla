---- MODULE Antichain ----
EXTENDS Naturals, FiniteSets

CONSTANT Item
ASSUME Cardinality(Item) % 2 = 0

Family == SUBSET Item

Nests(a, b) == a \subseteq b \/ b \subseteq a

Middle == {s \in Family : 2 * Cardinality(s) = Cardinality(Item)}

VARIABLE chosen
vars == <<chosen>>

TypeOK == chosen \subseteq Family

Init == chosen = {}

Open == {s \in Family : \A t \in chosen : ~Nests(s, t)}

Add(s) ==
  /\ s \in Open
  /\ chosen' = chosen \cup {s}

Next == \E s \in Family : Add(s)

Spec == Init /\ [][Next]_vars

Crossing == {p \in chosen \X chosen : Nests(p[1], p[2])}

Diagonal == Cardinality(Crossing) = Cardinality(chosen)

Widest == Cardinality(chosen) <= Cardinality(Middle)

Narrowing == [][Open' \subseteq Open]_vars
====
