---- MODULE RecHigher ----
EXTENDS Integers
VARIABLE n

Twice(k) == k * 2

\* One underscore per parameter. The declaration does not say, and cannot say,
\* that the first parameter is itself an operator.
RECURSIVE Walk(_, _)
Walk(Op(_), k) == IF k = 0 THEN 0 ELSE Op(k) + Walk(Op, k - 1)

Init == n = 0
Next == n < 3 /\ n' = n + 1
Spec == Init /\ [][Next]_<<n>>

\* Walk(Twice, n) adds 2k for every k from 1 to n, which is n * (n + 1).
Summed == Walk(Twice, n) = n * (n + 1)
==========================
