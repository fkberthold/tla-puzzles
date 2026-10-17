\* a lift and a lamp, both free to move, the lift between the ground and the second floor and the lamp between out and lit. what one step does is left out.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES level, lamp
vars == <<level, lamp>>
Init == level = 0 /\ lamp = 0
Act ==
__ANSWER__
Next == Act
Spec == Init /\ [][Next]_vars
Guard == level \in 0..2 /\ lamp \in 0..1
Shape ==
__CHECK__
====
