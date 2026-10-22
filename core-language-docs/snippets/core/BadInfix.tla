---- MODULE BadInfix ----
EXTENDS Integers
VARIABLE n

\* An invented name in infix position. TLA+ has a fixed symbol set.
a plus b == a + b * 2

Init == n = 0
Next == n < 2 /\ n' = n + 1
Spec == Init /\ [][Next]_<<n>>

Ok == n >= 0
=========================
