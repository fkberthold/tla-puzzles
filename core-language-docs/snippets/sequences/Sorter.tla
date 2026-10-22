---- MODULE Sorter ----
EXTENDS Integers, Sequences
VARIABLE line

Big(x) == x > 20

Init == line = <<10, 30, 20, 40>>
Next == UNCHANGED line
Spec == Init /\ [][Next]_<<line>>

Kept == SelectSeq(line, Big) = <<30, 40>>
KeptByLambda == SelectSeq(line, LAMBDA x : x > 20) = <<30, 40>>
Reindexed == DOMAIN SelectSeq(line, Big) = 1..2
NoneKept == SelectSeq(line, LAMBDA x : FALSE) = <<>>
OrderHeld == \A i \in 1..1 : SelectSeq(line, Big)[i] < SelectSeq(line, Big)[i + 1]
=======================
