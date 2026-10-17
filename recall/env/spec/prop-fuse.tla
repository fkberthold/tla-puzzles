\* a lift whose lamp comes on once and then blows, so it is out for good. the lamp reads 0 dark, 1 lit, 2 blown, and the lift rises to the second floor and stays.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES level, lamp
vars == <<level, lamp>>
Init == level = 0 /\ lamp = 0
Raise == level < 2 /\ level' = level + 1 /\ lamp' = lamp
Blink == lamp < 2 /\ lamp' = lamp + 1 /\ level' = level
Next == Raise \/ Blink
Spec == Init /\ [][Next]_vars /\ WF_vars(Raise) /\ WF_vars(Blink)
Checked ==
__ANSWER__
====
