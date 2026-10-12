---- MODULE GrowAnywhere ----
\* Seeded defect: Grow picks any larger capacity, prime or not.
EXTENDS Naturals

CONSTANT MaxCap

VARIABLES cap, load

vars == <<cap, load>>

IsPrime(n) ==
  /\ n >= 2
  /\ \A k \in 2..(n - 1) : n % k /= 0

TypeOK ==
  /\ cap \in 2..MaxCap
  /\ load \in 0..cap

Init ==
  /\ cap = 2
  /\ load = 0

Insert ==
  /\ load < cap
  /\ load' = load + 1
  /\ UNCHANGED cap

Remove ==
  /\ load > 0
  /\ load' = load - 1
  /\ UNCHANGED cap

Grow ==
  /\ 2 * load > cap
  /\ \E p \in (cap + 1)..(2 * cap) :
       /\ p <= MaxCap
       /\ cap' = p
  /\ UNCHANGED load

Next == Insert \/ Remove \/ Grow

Spec == Init /\ [][Next]_vars

CapacityIsPrime == IsPrime(cap)

LoadFits == load <= cap
====
