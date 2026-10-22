---- MODULE Sieve ----
EXTENDS Integers, FiniteSets
VARIABLE votes

Pubs == {"anchor", "bell"}
Friends == 1..3

Init == votes = {}
Cast ==
  /\ \E f \in Friends, p \in Pubs :
       /\ \A v \in votes : v[1] /= f
       /\ votes' = votes \cup {<<f, p>>}
Next == Cast
Spec == Init /\ [][Next]_<<votes>>

FilterFor(p) == {v \in votes : v[2] = p}
MapFor(p) == {v[2] = p : v \in votes}

NoLandslideFilter == \A p \in Pubs : Cardinality(FilterFor(p)) < 3
NoLandslideMap == \A p \in Pubs : Cardinality(MapFor(p)) < 3
MapIsBoolean == \A p \in Pubs : MapFor(p) \subseteq BOOLEAN
======================
