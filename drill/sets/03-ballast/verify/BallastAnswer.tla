---- MODULE BallastAnswer ----
\* Reference answer. The state is one set, the full tanks. The voyage starts
\* from any arrangement that obeys the rule, which is a draw from the
\* powerset filtered by the rule, and every fill or pump keeps it.
EXTENDS Naturals, FiniteSets

CONSTANTS Tanks, Port

ASSUME Port \subseteq Tanks

Starboard == Tanks \ Port

VARIABLE full

vars == <<full>>

TypeOK == full \subseteq Tanks

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
