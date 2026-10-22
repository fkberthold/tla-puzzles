---- MODULE Apply ----
EXTENDS Integers
VARIABLE n

\* Op(_) is a higher-order parameter. MapTwo takes an operator, not a value.
MapTwo(Op(_), a, b) == <<Op(a), Op(b)>>

Twice(k) == k * 2

\* A custom binary operator, taken from TLA+'s fixed set of spare symbols.
a ++ b == a + b * 2

Init == n = 0
Next == n < 2 /\ n' = n + 1
Spec == Init /\ [][Next]_<<n>>

\* A named operator passed by name, with no argument list after it.
Named == MapTwo(Twice, n, n + 1) = <<n * 2, n * 2 + 2>>

\* The same operator written inline.
Inline == MapTwo(LAMBDA k: k * 2, n, n + 1) = <<n * 2, n * 2 + 2>>

\* The custom infix operator, used in a state predicate.
Infix == (n ++ 3) = n + 6
========================
