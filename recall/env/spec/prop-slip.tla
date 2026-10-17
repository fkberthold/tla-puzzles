\* a lift that rises to the second floor, drops straight back to the ground and starts again, over and over, with a lamp flashing beside it.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES level, lamp
vars == <<level, lamp>>
Init == level = 0 /\ lamp = 0
Raise == level < 2 /\ level' = level + 1 /\ lamp' = lamp
Drop == level = 2 /\ level' = 0 /\ lamp' = lamp
Blink == lamp' = 1 - lamp /\ level' = level
Next == Raise \/ Drop \/ Blink
Spec == Init /\ [][Next]_vars /\ WF_vars(Raise) /\ WF_vars(Drop) /\ WF_vars(Blink)
Checked ==
__ANSWER__
====
