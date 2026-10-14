---- MODULE CommitTrace ----
\* Trace spec for drill item 03-commit-sticks. Each row of Table is one
\* behavior from the prompt: a finite list of status values and the index
\* the tail loops back to. loop = Len(s) is "then forever".
EXTENDS Naturals, Sequences

CONSTANT Rows

VARIABLES row, i, status

Table == <<
  [s |-> <<"pending", "pending", "committed">>, loop |-> 3],  \* R1 allowed
  [s |-> <<"pending">>,                         loop |-> 1],  \* R2 allowed
  [s |-> <<"pending", "aborted">>,              loop |-> 2],  \* R3 allowed
  [s |-> <<"pending", "committed", "pending">>, loop |-> 3],  \* R4 forbidden
  [s |-> <<"pending", "committed", "aborted">>, loop |-> 3]   \* R5 forbidden
>>

Init == /\ row \in Rows
        /\ i = 1
        /\ status = Table[row].s[1]

NextIdx == IF i < Len(Table[row].s) THEN i + 1 ELSE Table[row].loop

Advance == /\ i' = NextIdx
           /\ status' = Table[row].s[i']
           /\ UNCHANGED row

vars == <<row, i, status>>

Spec == Init /\ [][Advance]_vars /\ WF_vars(Advance)

\* The same trace spec with no fairness conjunct. A safety property is
\* refuted by a finite prefix, so the fairness is not needed for the verdict,
\* and its presence turns out to change which channel TLC reports through.
SpecNoFair == Init /\ [][Advance]_vars

Committed == status = "committed"
Pending   == status = "pending"

\* The answer, and three action-formula spellings of the same property.
Answer == [](Committed => []Committed)
V1 == [][(Committed => Committed')]_status
V2 == [][(Committed => UNCHANGED status)]_status
V3 == [][(status = "committed") => (status' = "committed")]_status

\* Neighbors the elimination table kills.
N1 == <>Committed
N2 == Pending ~> Committed
N3 == [](status # "aborted")
N4 == Committed => []Committed
N5 == [](Committed => []~Pending)
N6 == <>[]Committed
N7 == []<>Committed
N8 == []Committed
====
