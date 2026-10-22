---- MODULE NamedLambda ----
EXTENDS Integers
VARIABLE n

\* A LAMBDA is only ever an argument. Binding one to a name is not TLA+.
Double == LAMBDA k: k * 2

Init == n = 0
Next == n < 2 /\ n' = n + 1
Spec == Init /\ [][Next]_<<n>>

Ok == n >= 0
============================
