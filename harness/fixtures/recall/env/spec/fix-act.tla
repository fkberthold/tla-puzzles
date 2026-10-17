\* a fixture machine: a counter and a flag that is held at nothing, so the flag cannot move. what one step of this machine does is the thing left out.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES n, flag
vars == <<n, flag>>
Init == n = 0 /\ flag = 0
Act ==
__ANSWER__
Next == Act
Spec == Init /\ [][Next]_vars
Guard == flag = 0
Shape ==
__CHECK__
====
