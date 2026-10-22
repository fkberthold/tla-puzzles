---- MODULE Seesaw ----
EXTENDS Integers
VARIABLES left, right
vars == <<left, right>>

\* Two state functions over the same two variables. The set forgets which
\* value sat on which side, and the record does not.
seen == {left, right}
pans == [l |-> left, r |-> right]

Init == left = 0 /\ right = 1
Swap == left' = right /\ right' = left
Next == Swap
Spec == Init /\ [][Next]_vars

\* One claim, which is false: the left pan never moves.
Tuple == [][left' = left]_vars
Set == [][left' = left]_seen
Record == [][left' = left]_pans

\* A fourth subscript, reached by indexing the tuple. vars[1] is left.
Index == [][left' = left]_(vars[1])
=======================
