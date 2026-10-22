---- MODULE NoRecursive ----
EXTENDS Integers
VARIABLE n

\* No RECURSIVE declaration, so the Sum on the right is not in scope yet.
Sum(k) == IF k = 0 THEN 0 ELSE k + Sum(k - 1)

Init == n = 0
Next == n < 2 /\ n' = n + 1
Spec == Init /\ [][Next]_<<n>>

Small == Sum(3) = 6
============================
