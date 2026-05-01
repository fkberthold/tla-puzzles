---- MODULE Bag ----
EXTENDS Naturals, FiniteSets

CONSTANT Beads

VARIABLE inside

Init == inside = {}

AddBead ==
  /\ inside # Beads
  /\ \E b \in Beads \ inside : inside' = inside \cup {b}

Next == AddBead

vars == << inside >>

Spec == Init /\ [][Next]_vars

TypeOK == inside \subseteq Beads

\* Refinement mapping: the abstract Counter sees the bag's CARDINALITY as n.
C == INSTANCE Counter WITH n <- Cardinality(inside), Max <- Cardinality(Beads)

\* Bag refines Counter: every Bag behavior is a Counter behavior under the mapping.
CounterSpec == C!Spec
================================
