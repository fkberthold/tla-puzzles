---- MODULE Girder ----
EXTENDS Integers, Sequences
VARIABLE cell

Rows == {1, 2}
Cols == {3}
Levels == {4}

Triples == Rows \X Cols \X Levels
Nested == (Rows \X Cols) \X Levels

Init == cell \in Triples
Next == UNCHANGED cell
Spec == Init /\ [][Next]_<<cell>>

SameSet == Triples = Nested
InNested == cell \in Nested
Arity == /\ \A c \in Triples : Len(c) = 3
         /\ \A c \in Nested : Len(c) = 2
=======================
