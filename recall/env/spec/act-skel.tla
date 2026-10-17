\* a lift that rises twice beside a flashing lamp. the opening state and the step relation are both written down; what a whole run of the machine is, is not.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES level, lamp
vars == <<level, lamp>>
Init == level = 0 /\ lamp = 0
Raise == level < 2 /\ level' = level + 1 /\ lamp' = lamp
Blink == lamp' = 1 - lamp /\ level' = level
Next == Raise \/ Blink
Spec ==
__ANSWER__
Guard == level \in 0..2 /\ lamp \in 0..1
Shape ==
__CHECK__
====
