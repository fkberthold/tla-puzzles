------------------------------- MODULE Chute -------------------------------
\* One chute. Which parcels it takes is a parameter: an operator, not a
\* set, so the rule can be anything the user of the chute can write.
CONSTANTS Parcels, Admit(_)

VARIABLE passed

Init == passed = {}

Pass(p) ==
    /\ p \in Parcels \ passed
    /\ Admit(p)
    /\ passed' = passed \cup {p}

Next == \E p \in Parcels : Pass(p)

Spec == Init /\ [][Next]_passed

OnlyAdmitted == \A p \in passed : Admit(p)

=============================================================================
