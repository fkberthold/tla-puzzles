---- MODULE BallastSubseteq ----
\* Accepted variant. Init says the full tanks are a subset of the tanks,
\* which reads as a sentence about a value TLC doesn't have yet. TLC takes
\* it as a draw from the powerset and the run matches the answer.
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
  /\ full \subseteq Tanks
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
