---- MODULE Plumbline ----
EXTENDS Integers
CONSTANT Floor
VARIABLE depth

\* The value a config cannot write. A definition can hold it, and the config
\* can point the constant at the definition.
NegTwo == -2

Init == depth = 0
Sink == depth > Floor /\ depth' = depth - 1
Rest == depth = Floor /\ UNCHANGED depth
Next == Sink \/ Rest
Spec == Init /\ [][Next]_<<depth>>

AboveFloor == depth >= Floor
==========================
