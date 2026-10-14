---- MODULE BallastAnyStart ----
\* The break-it step. Init draws from the whole powerset and the rule is
\* only kept by the actions, so TLC finds a listing ship in the initial
\* states before it takes a step.
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

Init == full \in SUBSET Tanks

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
