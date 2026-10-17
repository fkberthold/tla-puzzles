\* a lift that goes round its three floors for ever, beside a lamp that comes on once and then never moves again. the subscript tuple is left out.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES level, lamp
vars ==
__ANSWER__
Init == level = 0 /\ lamp = 0
Raise == level' = (level + 1) % 3 /\ lamp' = lamp
Blink == lamp = 0 /\ lamp' = 1 /\ level' = level
Next == Raise \/ Blink
Spec == Init /\ [][Next]_vars /\ WF_<<level, lamp>>(Raise)
Busy == []<><<Next>>_vars
====
