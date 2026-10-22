---- MODULE Escapement ----
EXTENDS Integers
VARIABLES hand, bell
vars == <<hand, bell>>

Init == hand = 0 /\ bell = 0

Tick == /\ hand < 2
        /\ hand' = hand + 1
        /\ bell' = bell

Ring == /\ bell < 1
        /\ bell' = bell + 1
        /\ hand' = hand

Settle == hand = 2 /\ bell = 1 /\ UNCHANGED vars
Next == Tick \/ Ring \/ Settle
Spec == Init /\ [][Next]_vars

\* One claim, two subscripts. The body is the same text in both.
Wide == [][bell' = bell]_vars
Narrow == [][bell' = bell]_hand
===========================
