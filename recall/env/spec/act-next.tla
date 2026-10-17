\* a lift that rises twice beside a flashing lamp. both moves are written down one by one; what the machine as a whole may do in a step is not.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES level, lamp
vars == <<level, lamp>>
Init == level = 0 /\ lamp = 0
Raise == level < 2 /\ level' = level + 1 /\ lamp' = lamp
Blink == lamp' = 1 - lamp /\ level' = level
Next ==
__ANSWER__
Spec == Init /\ [][Next]_vars
Guard == level \in 0..2 /\ lamp \in 0..1
Shape ==
__CHECK__
====
