---- MODULE TankPlusClock ----
EXTENDS Integers
CONSTANT Capacity
VARIABLES tank, clock
vars == <<tank, clock>>

T == INSTANCE Tank

Init == T!Init /\ clock = 0
Next == T!Next /\ clock' = clock + 1
Spec == Init /\ [][Next]_vars

Cap == clock <= 4
==============================
