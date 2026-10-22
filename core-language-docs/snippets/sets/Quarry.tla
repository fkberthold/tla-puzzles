---- MODULE Quarry ----
EXTENDS Integers
VARIABLE atChute

Chutes == 1..3

Init == atChute \in Chutes
Next == \E c \in Chutes : atChute' = c
Spec == Init /\ [][Next]_<<atChute>>

OneChuteOnly == atChute = 1
=======================
