---- MODULE Bucket ----
EXTENDS Integers, Apalache

CONSTANT
  \* @type: Int;
  Capacity

VARIABLES
  \* @type: Int;
  tokens
\* @type: <<Int>>;
vars == << tokens >>

Init == tokens := 0

Add ==
  /\ tokens < Capacity
  /\ tokens' := tokens + 1

Take ==
  /\ tokens > 0
  /\ tokens' := tokens - 1

Next == Add \/ Take

Spec == Init /\ [][Next]_vars

NeverNegative == tokens >= 0
NeverOverflow == tokens <= Capacity

\* For Apalache: parameterize Capacity over a finite range.
ConstInit ==
  Capacity \in 1..10
====
