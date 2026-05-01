---- MODULE Flat ----
\* Side A: a single-level spec.
\* A small counter that grows from 0 to MaxN and resets.
\* Everything we want to check is at one level — no abstract / concrete split.
EXTENDS Integers, TLC

CONSTANT MaxN

VARIABLE n

TypeOK == n \in 0..MaxN

Init == n = 0

Inc ==
  /\ n < MaxN
  /\ n' = n + 1

Reset ==
  /\ n > 0
  /\ n' = 0

Next == Inc \/ Reset

Spec == Init /\ [][Next]_n

Bounded == n <= MaxN
================================
