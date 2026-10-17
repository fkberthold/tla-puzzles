\* a lift whose top stop was never wired, so it carries on past the second floor to a third, with a lamp flashing beside it.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES level, lamp
vars == <<level, lamp>>
Init == level = 0 /\ lamp = 0
Raise == level < 3 /\ level' = level + 1 /\ lamp' = lamp
Blink == lamp' = 1 - lamp /\ level' = level
Next == Raise \/ Blink
Spec == Init /\ [][Next]_vars /\ WF_vars(Raise) /\ WF_vars(Blink)
Checked ==
__ANSWER__
====
