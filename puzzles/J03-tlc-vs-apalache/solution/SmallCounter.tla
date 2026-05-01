---- MODULE SmallCounter ----
\* A tiny counter that increments up to a CONSTANT bound.
\* The same spec can be checked by TLC (enumerative) or Apalache (symbolic).
\* TLC: every CONSTANT must be a concrete value.
\* Apalache: variables and constants are TYPE-ANNOTATED; CONSTANT can be left
\* symbolic (with --cinit) and the bound can be much larger because the SMT
\* solver reasons about it abstractly.
EXTENDS Integers, TLC

CONSTANT MaxN

(* Apalache type annotations (ignored by TLC, used by Apalache):
   \* @type: Int;
   variable n
   \* @type: Int;
   constant MaxN
*)

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

\* Safety: the counter never exceeds its bound.
NeverOverflow == n <= MaxN
================================
