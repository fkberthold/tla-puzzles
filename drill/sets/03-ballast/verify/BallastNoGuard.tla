---- MODULE BallastNoGuard ----
\* Mutant. Fill no longer checks the rule on the new arrangement, so two
\* fills down one side list the ship and the rule reports it.
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
    full' = full \cup {t}

Pump ==
  \E t \in full :
    /\ full' = full \ {t}
    /\ Balanced'

Next == Fill \/ Pump

Spec == Init /\ [][Next]_vars

NeverLists == Balanced
====
