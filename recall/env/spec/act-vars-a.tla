\* a lift that rises twice and then stops for good, beside a lamp that flashes for ever. the tuple the step relation is subscripted by is left out.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES level, lamp
vars ==
__ANSWER__
Init == level = 0 /\ lamp = 0
Raise == level < 2 /\ level' = level + 1 /\ lamp' = lamp
Blink == lamp' = 1 - lamp /\ level' = level
Next == Raise \/ Blink
Spec == Init /\ [][Next]_vars /\ WF_<<level, lamp>>(Blink)
Busy == []<><<Next>>_vars
====
