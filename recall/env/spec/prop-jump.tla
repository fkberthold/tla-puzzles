\* an express lift that skips the first floor: one move takes it from the ground to the second and it stays there, with a lamp flashing beside it.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES level, lamp
vars == <<level, lamp>>
Init == level = 0 /\ lamp = 0
Raise == level = 0 /\ level' = 2 /\ lamp' = lamp
Blink == lamp' = 1 - lamp /\ level' = level
Next == Raise \/ Blink
Spec == Init /\ [][Next]_vars /\ WF_vars(Raise) /\ WF_vars(Blink)
Checked ==
__ANSWER__
====
