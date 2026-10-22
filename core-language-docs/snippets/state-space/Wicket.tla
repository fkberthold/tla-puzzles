---- MODULE Wicket ----
EXTENDS Integers
CONSTANT Lim
VARIABLE pos

Init == pos = 0
Step == pos' \in {pos + 1, pos + 2}
Next == Step
Spec == Init /\ [][Next]_<<pos>>

\* A state predicate: it reads one state.
Inside == pos <= Lim

\* A step predicate: it reads the pair, which no state predicate can do.
EvenStride == pos' - pos = 2
=======================
