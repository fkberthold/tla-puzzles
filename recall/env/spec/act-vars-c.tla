\* a yard gate that swings open once and then stays open, beside a bell that goes on ringing for ever. the tuple the step relation is subscripted by is left out.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES gate, bell
vars ==
__ANSWER__
Init == gate = 0 /\ bell = 0
Swing == gate = 0 /\ gate' = 1 /\ bell' = bell
Ring == bell' = 1 - bell /\ gate' = gate
Next == Swing \/ Ring
Spec == Init /\ [][Next]_vars /\ WF_<<gate, bell>>(Ring)
Busy == []<><<Next>>_vars
====
