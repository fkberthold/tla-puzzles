---- MODULE BallastBinary ----
\* Wrong neighbor. The powerset keyword used as if it were a subset test
\* between two sets. It's a prefix operator with one operand, so this
\* doesn't parse.
EXTENDS Naturals, FiniteSets

CONSTANTS Tanks, Port

ASSUME Port \subseteq Tanks

Starboard == Tanks \ Port

VARIABLE full

vars == <<full>>

TypeOK == full SUBSET Tanks

Lean(side) == Cardinality(full \cap side)

Balanced ==
  /\ Lean(Port) <= Lean(Starboard) + 1
  /\ Lean(Starboard) <= Lean(Port) + 1

Init ==
  /\ full \in SUBSET Tanks
  /\ Balanced

Fill ==
  \E t \in Tanks \ full :
    /\ full' = full \cup {t}
    /\ Balanced'

Pump ==
  \E t \in full :
    /\ full' = full \ {t}
    /\ Balanced'

Next == Fill \/ Pump

Spec == Init /\ [][Next]_vars

NeverLists == Balanced
====
