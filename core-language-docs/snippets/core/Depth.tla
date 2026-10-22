---- MODULE Depth ----
EXTENDS Integers
CONSTANT Start
VARIABLE n

\* Walks down by one, so it lands on the base case from any natural number.
RECURSIVE SumDown(_)
SumDown(k) == IF k = 0 THEN 0 ELSE k + SumDown(k - 1)

\* Walks down by two. From an odd number it steps over the base case forever.
RECURSIVE SumEven(_)
SumEven(k) == IF k = 0 THEN 0 ELSE k + SumEven(k - 2)

Init == n = 0
Next == n < 2 /\ n' = n + 1
Spec == Init /\ [][Next]_<<n>>

Counted == SumDown(Start) >= 0
Skipped == SumEven(Start) >= 0
========================
