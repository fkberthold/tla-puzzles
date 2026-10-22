---- MODULE Gauge ----
EXTENDS Integers
VARIABLES lamp, ticks
vars == <<lamp, ticks>>

Init == lamp = 0 /\ ticks = 0
Flip == lamp' = 1 - lamp /\ ticks' = ticks + 1
Next == Flip
Spec == Init /\ [][Next]_vars

Budget == ticks <= 5

\* The non-default view. It drops the counter, so two states that differ only
\* in how long they took get one fingerprint.
LampOnly == <<lamp>>

NotThree == ticks # 3
=======================
