\* a lift held at the ground floor by a service lock, so the lift cannot move. what one step of this machine does is the thing left out.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES level, lamp
vars == <<level, lamp>>
Init == level = 0 /\ lamp = 0
Act ==
__ANSWER__
Next == Act
Spec == Init /\ [][Next]_vars
Guard == level = 0
Shape ==
__CHECK__
====
