\* a lift with a lamp that is switched off at the wall, so the lamp cannot move. what one step of this machine does is the thing left out.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES level, lamp
vars == <<level, lamp>>
Init == level = 0 /\ lamp = 0
Act ==
__ANSWER__
Next == Act
Spec == Init /\ [][Next]_vars
Guard == lamp = 0
Shape ==
__CHECK__
====
