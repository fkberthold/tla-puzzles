---- MODULE SmallCounter ----
\* A tiny counter that increments up to a CONSTANT bound.
\* The same spec can be checked by TLC (enumerative) or Apalache (symbolic).
\* TLC: every CONSTANT must be a concrete value.
\* Apalache: variables and constants are TYPE-ANNOTATED; CONSTANT can be left
\* symbolic (with --cinit) and the bound can be much larger because the SMT
\* solver reasons about it abstractly.
EXTENDS Integers, TLC

CONSTANT
  \* @type: Int;
  MaxN

VARIABLES
  \* @type: Int;
  n

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

\* Safety: the counter never exceeds its bound.
NeverOverflow == n <= MaxN

\* For Apalache: parameterize MaxN symbolically over a small range so the
\* SMT solver can verify NeverOverflow for ALL values at once.
ConstInit ==
  MaxN \in 1..1000
================================
