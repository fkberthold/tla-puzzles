---- MODULE RecDecl ----
EXTENDS Integers
VARIABLE n

Twice(k) == k * 2

\* Trying to say in the declaration that the first parameter is an operator.
RECURSIVE Walk(_(_), _)
Walk(Op(_), k) == IF k = 0 THEN 0 ELSE Op(k) + Walk(Op, k - 1)

Init == n = 0
Next == n < 3 /\ n' = n + 1
Spec == Init /\ [][Next]_<<n>>

Summed == Walk(Twice, n) = n * (n + 1)
========================
