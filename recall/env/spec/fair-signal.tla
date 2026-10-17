\* a signal that goes green and red again on its own, and a train that may only move on a green. the switching is already promised; the moving is not.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES light, train
vars == <<light, train>>
Init == light = 0 /\ train = 0
Switch == light' = 1 - light /\ train' = train
Go == light = 1 /\ train = 0 /\ train' = 1 /\ light' = light
Next == Switch \/ Go
Fair ==
__ANSWER__
Spec == Init /\ [][Next]_vars /\ WF_vars(Switch) /\ Fair
Through == <>(train = 1)
====
