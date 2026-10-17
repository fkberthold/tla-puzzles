\* a tank that fills and a pump that primes, each a step at a time, with a lamp flipping beside them that can go on forever and gets nothing ready.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES tank, pump, lamp
vars == <<tank, pump, lamp>>
Init == tank = 0 /\ pump = 0 /\ lamp = 0
Fill == tank < 2 /\ tank' = tank + 1 /\ pump' = pump /\ lamp' = lamp
Prime == pump < 2 /\ pump' = pump + 1 /\ tank' = tank /\ lamp' = lamp
Blink == lamp' = 1 - lamp /\ tank' = tank /\ pump' = pump
Next == Fill \/ Prime \/ Blink
Fair ==
__ANSWER__
Spec == Init /\ [][Next]_vars /\ Fair
Ready == <>(tank = 2 /\ pump = 2)
====
