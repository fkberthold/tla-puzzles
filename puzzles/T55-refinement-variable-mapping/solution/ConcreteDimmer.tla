---- MODULE ConcreteDimmer ----
EXTENDS Integers

VARIABLE brightness

vars == << brightness >>

Init == brightness = 0

StepUp   == brightness < 3 /\ brightness' = brightness + 1
StepDown == brightness > 0 /\ brightness' = brightness - 1
OffSwitch == brightness > 0 /\ brightness' = 0
OnSwitch  == brightness = 0 /\ brightness' = 1

Next == StepUp \/ StepDown \/ OffSwitch \/ OnSwitch

Spec == Init /\ [][Next]_vars

TypeOK == brightness \in 0..3

\* Refinement mapping: the abstract sees lampOn = (brightness > 0).
L0 == INSTANCE AbstractLight WITH lampOn <- (brightness > 0)
Refines == L0!Spec

====
