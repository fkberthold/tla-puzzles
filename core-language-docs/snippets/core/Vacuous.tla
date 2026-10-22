---- MODULE Vacuous ----
EXTENDS Integers
CONSTANT CanOpen
VARIABLES level, gate
vars == <<level, gate>>

Init == level = 0 /\ gate = "shut"

Fill == /\ level < 3
        /\ level' = level + 1
        /\ gate' = gate

Open == /\ CanOpen
        /\ gate' = "open"
        /\ level' = level

Next == Fill \/ Open
Spec == Init /\ [][Next]_vars

\* The requirement as a reader would state it.
Safe == (gate = "open") => (level > 0)

\* The witness. It holds exactly when Safe has nothing to say.
NeverOpen == gate # "open"
=========================
