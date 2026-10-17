\* a lift whose top stop is out of service, so it only ever reaches the first floor and stays there, with a lamp flashing beside it.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES level, lamp
vars == <<level, lamp>>
Init == level = 0 /\ lamp = 0
Raise == level < 1 /\ level' = level + 1 /\ lamp' = lamp
Blink == lamp' = 1 - lamp /\ level' = level
Next == Raise \/ Blink
Spec == Init /\ [][Next]_vars /\ WF_vars(Raise) /\ WF_vars(Blink)
Checked ==
__ANSWER__
====
