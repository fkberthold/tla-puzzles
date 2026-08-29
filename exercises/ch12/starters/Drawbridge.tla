---- MODULE Drawbridge ----
\* Exercise 4. This module is complete and runs as it stands.
\*
\* A drawbridge is raised by two winches, one at each end. Each winch needs
\* `Target` turns. The bridge is up when both of them have had all their
\* turns.
EXTENDS Integers

Winches == {"north", "south"}
Target == 2

VARIABLE turns

vars == << turns >>

Init == turns = [w \in Winches |-> 0]

Raise(w) == /\ turns[w] < Target
            /\ turns' = [turns EXCEPT ![w] = @ + 1]

Next == \E w \in Winches : Raise(w)

Spec == /\ Init
        /\ [][Next]_vars
        /\ \A w \in Winches : WF_vars(Raise(w))

BridgeRaised == <>(\A w \in Winches : turns[w] = Target)
====
