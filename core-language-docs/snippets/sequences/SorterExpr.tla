---- MODULE SorterExpr ----
EXTENDS Integers, Sequences
VARIABLE line

Init == line = <<10, 30>>
Next == UNCHANGED line
Spec == Init /\ [][Next]_<<line>>

Kept == SelectSeq(line, line[1] > 20) = <<30>>
===========================
