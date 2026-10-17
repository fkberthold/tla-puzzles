\* a lift that rises twice beside a flashing lamp. every move is written down; the line that says what the machine's state is made of is not.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
__ANSWER__
vars == <<level, lamp>>
Init == level = 0 /\ lamp = 0
Raise == level < 2 /\ level' = level + 1 /\ lamp' = lamp
Blink == lamp' = 1 - lamp /\ level' = level
Next == Raise \/ Blink
Spec == Init /\ [][Next]_vars
Guard == level \in 0..2 /\ lamp \in 0..1
Shape ==
__CHECK__
====
