---- MODULE Josephus ----
EXTENDS Integers, Sequences

CONSTANT Max
ASSUME Max \in 1..12

\* Where the survivor stands in a circle of k, counting places from 1.
\* A circle of k - 1 is this one with its first two places spent, so
\* the formula shifts the answer for k - 1 back onto this circle.
RECURSIVE Survivor(_)
Survivor(k) ==
  IF k = 1 THEN 1 ELSE ((Survivor(k - 1) + 1) % k) + 1

\* The largest power of two that doesn't exceed k.
RECURSIVE Pow2Below(_)
Pow2Below(k) == IF k < 2 THEN 1 ELSE 2 * Pow2Below(k \div 2)

Closed(k) == 2 * (k - Pow2Below(k)) + 1

VARIABLES ring, size
vars == <<ring, size>>

TypeOK ==
  /\ size \in 1..Max
  /\ Len(ring) \in 1..size
  /\ \A i \in 1..Len(ring) : ring[i] \in 1..size

\* Everybody present, in their own place, and the count starts at the
\* front of the sequence.
Init ==
  \E k \in 1..Max :
    /\ size = k
    /\ ring = [i \in 1..k |-> i]

\* The place at the front counts one and goes to the back of the
\* circle. The place behind it counts two and leaves for good.
Eliminate ==
  /\ Len(ring) > 1
  /\ ring' = Append(Tail(Tail(ring)), Head(ring))
  /\ size' = size

Next == Eliminate

Spec == Init /\ [][Next]_vars

Recurrence == Len(ring) = 1 => Head(ring) = Survivor(size)

Binary == Len(ring) = 1 => Head(ring) = Closed(size)

Shrinks == [][Len(ring') = Len(ring) - 1]_vars
====
