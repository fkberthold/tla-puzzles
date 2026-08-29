---- MODULE Beacon ----
\* Exercise 2, the top of the chain. Ships complete and is not edited.

EXTENDS Signal

VARIABLE lamp

Init == lamp = "green"

Next == \/ /\ lamp = "green"
           /\ lamp' = "amber"
        \/ /\ lamp = "amber"
           /\ lamp' = "red"
        \/ /\ lamp = "red"
           /\ lamp' = "green"

Spec == Init /\ [][Next]_lamp

\* Needs an operator that lives two files down.
LampWarmOrCool == IsWarm(lamp) \/ lamp = "green"

\* Needs an operator that lives one file down.
EscalationIsRed == Escalated(lamp) => lamp = "red"
====
