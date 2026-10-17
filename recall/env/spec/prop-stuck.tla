\* a lift that never leaves the ground, though nothing is holding it there, with a lamp that keeps flashing beside it for ever.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES level, lamp
vars == <<level, lamp>>
Init == level = 0 /\ lamp = 0
Raise == level < 2 /\ level' = level + 1 /\ lamp' = lamp
Blink == lamp' = 1 - lamp /\ level' = level
Next == Blink
Spec == Init /\ [][Next]_vars /\ WF_vars(Blink)
Checked ==
__ANSWER__
====
