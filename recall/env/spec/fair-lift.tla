\* a goods lift standing beside a lamp. the lift rises twice and then has nowhere left to go; the lamp flips for ever, so something can always move.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES level, lamp
vars == <<level, lamp>>
Init == level = 0 /\ lamp = 0
Raise == level < 2 /\ level' = level + 1 /\ lamp' = lamp
Blink == lamp' = 1 - lamp /\ level' = level
Next == Raise \/ Blink
Fair ==
__ANSWER__
Spec == Init /\ [][Next]_vars /\ Fair
Tops == <>(level = 2)
====
