\* a lift and a lamp wired together, so the lamp has to read lit on the odd floors and out on the even ones. what one step of this machine does is left out.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES level, lamp
vars == <<level, lamp>>
Init == level = 0 /\ lamp = 0
Act ==
__ANSWER__
Next == Act
Spec == Init /\ [][Next]_vars
Guard == level \in 0..2 /\ lamp = level % 2
Shape ==
__CHECK__
====
