\* a baton passed back and forth between two hands, and a catch that only the right hand can make. the passing is already promised; the catching is not.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES hand, held
vars == <<hand, held>>
Init == hand = 0 /\ held = 0
Pass == hand' = 1 - hand /\ held' = held
Grab == hand = 1 /\ held = 0 /\ held' = 1 /\ hand' = hand
Next == Pass \/ Grab
Fair ==
__ANSWER__
Spec == Init /\ [][Next]_vars /\ WF_vars(Pass) /\ Fair
Caught == <>(held = 1)
====
