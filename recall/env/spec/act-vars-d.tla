\* a yard gate that swings open and shut for ever, beside a bell that rings once and is then taken out of service. the subscript tuple is left out.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES gate, bell
vars ==
__ANSWER__
Init == gate = 0 /\ bell = 0
Swing == gate' = 1 - gate /\ bell' = bell
Ring == bell = 0 /\ bell' = 1 /\ gate' = gate
Next == Swing \/ Ring
Spec == Init /\ [][Next]_vars /\ WF_<<gate, bell>>(Swing)
Busy == []<><<Next>>_vars
====
