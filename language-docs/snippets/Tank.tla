---- MODULE Tank ----
EXTENDS Integers
CONSTANT Capacity
ASSUME Capacity \in Nat

VARIABLE tank

Init == tank = 0
Pour == tank < Capacity /\ tank' = tank + 1
Drain == tank > 0 /\ tank' = tank - 1
Next == Pour \/ Drain
Spec == Init /\ [][Next]_<<tank>>
=====================
