---- MODULE RecurseOp ----
EXTENDS Integers
VARIABLE n

\* The operator form of the same definition, with no RECURSIVE declaration.
\* This does not parse.
Fact(i) == IF i = 0 THEN 1 ELSE i * Fact(i - 1)

Init == n = Fact(3)
Next == UNCHANGED n
Spec == Init /\ [][Next]_<<n>>
=========================
