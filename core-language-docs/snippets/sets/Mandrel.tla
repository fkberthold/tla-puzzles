---- MODULE Mandrel ----
EXTENDS Integers
VARIABLE racked

Mandrels == 1..3

Init == racked = {}
Rack == \E m \in Mandrels \ racked : racked' = racked \cup {m}
Next == Rack
Spec == Init /\ [][Next]_<<racked>>

NotFull == Cardinality(racked) < 3
========================
