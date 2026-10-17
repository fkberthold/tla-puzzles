\* a lift, a lamp and a service latch. every move is written down; the line that says what the machine's state is made of is not.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
__ANSWER__
vars == <<level, lamp, latch>>
Init == level = 0 /\ lamp = 0 /\ latch = 0
Raise == latch = 0 /\ level < 2 /\ level' = level + 1 /\ lamp' = lamp /\ latch' = latch
Blink == lamp' = 1 - lamp /\ level' = level /\ latch' = latch
Lock == latch = 0 /\ latch' = 1 /\ level' = level /\ lamp' = lamp
Next == Raise \/ Blink \/ Lock
Spec == Init /\ [][Next]_vars
Guard == level \in 0..2 /\ lamp \in 0..1 /\ latch \in 0..1
Shape ==
__CHECK__
====
