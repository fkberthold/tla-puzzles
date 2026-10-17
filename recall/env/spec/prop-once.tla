\* a lift that rises to the second floor once, drops to the ground and is then locked out of service, with a lamp still flashing beside it.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES level, lamp, latch
vars == <<level, lamp, latch>>
Init == level = 0 /\ lamp = 0 /\ latch = 0
Raise == latch = 0 /\ level < 2 /\ level' = level + 1 /\ lamp' = lamp /\ latch' = latch
Drop == level = 2 /\ level' = 0 /\ lamp' = lamp /\ latch' = 1
Blink == lamp' = 1 - lamp /\ level' = level /\ latch' = latch
Next == Raise \/ Drop \/ Blink
Spec == Init /\ [][Next]_vars /\ WF_vars(Raise) /\ WF_vars(Drop) /\ WF_vars(Blink)
Checked ==
__ANSWER__
====
