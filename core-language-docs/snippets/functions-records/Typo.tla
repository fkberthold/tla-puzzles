---- MODULE Typo ----
EXTENDS Integers
VARIABLE r

Init == r = [hits |-> 0, misses |-> 0]

\* "hit" is not a field of r. The clause is dropped, @ is never evaluated,
\* and the record stays where it started.
Next == r' = [r EXCEPT !.hit = @ + 1]

Spec == Init /\ [][Next]_<<r>>
=====================
