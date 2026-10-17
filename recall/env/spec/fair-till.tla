\* a shop till with two customers waiting and a drawer that can be opened and shut for ever without serving anybody.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES queue, drawer
vars == <<queue, drawer>>
Init == queue = 2 /\ drawer = 0
Serve == queue > 0 /\ queue' = queue - 1 /\ drawer' = drawer
Rattle == drawer' = 1 - drawer /\ queue' = queue
Next == Serve \/ Rattle
Fair ==
__ANSWER__
Spec == Init /\ [][Next]_vars /\ Fair
Cleared == <>(queue = 0)
====
