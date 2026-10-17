\* a lift with the power off. nothing moves: the lift stays on the ground and the lamp stays out, for ever.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES level, lamp
vars == <<level, lamp>>
Init == level = 0 /\ lamp = 0
Raise == level < 2 /\ level' = level + 1 /\ lamp' = lamp
Blink == lamp' = 1 - lamp /\ level' = level
Next == UNCHANGED vars
Spec == Init /\ [][Next]_vars
Checked ==
__ANSWER__
====
