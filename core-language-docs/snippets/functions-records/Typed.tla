---- MODULE Typed ----
EXTENDS Integers
VARIABLE f

Keys == {"a", "b"}
Vals == 0..2

\* [Keys -> Vals] is the SET of every function from Keys to Vals. Its size
\* is 3 to the power of 2, and each member is one initial state.
Init == f \in [Keys -> Vals]
Next == UNCHANGED f
Spec == Init /\ [][Next]_<<f>>

\* The colon form. This is a set, so it is what \in wants.
ByColon == f \in [a : Vals, b : Vals]

\* The arrow form. This is one record whose fields hold sets, not a set of
\* records, so \in has nothing to search.
ByArrow == f \in [a |-> Vals, b |-> Vals]

\* The two set-building forms agree when the keys are the same.
SameSet == [Keys -> Vals] = [a : Vals, b : Vals]

Holds == ByColon /\ SameSet
=====================
