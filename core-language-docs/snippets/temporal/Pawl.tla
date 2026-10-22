---- MODULE Pawl ----
EXTENDS Integers
VARIABLE pos
vars == <<pos>>

Init == pos = 0
Climb == pos < 2 /\ pos' = pos + 1
Hold == pos = 2 /\ UNCHANGED vars
Next == Climb \/ Hold

\* The spec with no fairness, which admits the behavior that never moves.
Spec == Init /\ [][Next]_vars

\* The same spec with weak fairness on the one action that goes anywhere.
Fair == Init /\ [][Next]_vars /\ WF_vars(Climb)

\* The same spec without the Hold disjunct, so the top of the ratchet has no
\* successor and TLC finds a deadlock there.
Blocked == Init /\ [][Climb]_vars

Top == <>(pos = 2)
Rise == (pos = 0) ~> (pos = 2)

\* ENABLED as a state predicate. It is false at the top of the ratchet.
CanClimb == ENABLED Climb
=====================
