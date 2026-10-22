---- MODULE Grow ----
EXTENDS Integers, Sequences
VARIABLE q

Init == q = <<>>

\* The operator that appends.
Push == q' = Append(q, 1)

\* The EXCEPT that reads as though it appends. Len(q) + 1 is one past the
\* end of the domain, so the clause is dropped and q never moves.
Reach == q' = [q EXCEPT ![Len(q) + 1] = 1]

SpecPush  == Init /\ [][Push]_<<q>>
SpecReach == Init /\ [][Reach]_<<q>>

Cap == Len(q) <= 3
=====================
