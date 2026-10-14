---- MODULE PrintJob ----
\* Trace spec for drill item 01-print-job. Each row of Table is one behavior
\* from the prompt: a finite list of states and the index the tail loops back
\* to. loop = Len(s) is "then forever": the last state repeats.
EXTENDS Naturals, Sequences

CONSTANT Rows

VARIABLES row, i, job

Table == <<
  [s |-> <<"empty", "queued", "queued", "printed">>, loop |-> 4],   \* R1 allowed
  [s |-> <<"empty">>,                                loop |-> 1],   \* R2 allowed
  [s |-> <<"empty", "queued">>,                      loop |-> 2],   \* R3 forbidden
  [s |-> <<"queued", "printed", "queued">>,         loop |-> 3],   \* R4 forbidden
  [s |-> <<"empty", "queued", "printed", "empty">>,   loop |-> 4],   \* R5 allowed
  [s |-> <<"queued", "empty">>,                      loop |-> 1]    \* R6 forbidden
>>

Init == /\ row \in Rows
        /\ i = 1
        /\ job = Table[row].s[1]

NextIdx == IF i < Len(Table[row].s) THEN i + 1 ELSE Table[row].loop

\* When the tail is a self-loop this is a stuttering step, so <<Advance>>_vars
\* is disabled there and WF_vars(Advance) asks nothing more. That is how
\* "then forever" becomes a stuttering tail rather than a deadlock.
Advance == /\ i' = NextIdx
           /\ job' = Table[row].s[i']
           /\ UNCHANGED row

vars == <<row, i, job>>

Spec == Init /\ [][Advance]_vars /\ WF_vars(Advance)

Queued  == job = "queued"
Printed == job = "printed"

\* The answer and its spelled-out form.
Answer    == Queued ~> Printed
AnswerBox == [](Queued => <>Printed)

\* The neighbors the elimination table kills.
N1 == <>Printed
N2 == []<>Printed
N3 == <>[]Printed
N4 == Queued => <>Printed
N5 == [](Queued => Printed)
N6 == [][Queued => Printed']_job
N7 == Printed ~> Queued
N8 == []<>(Queued => Printed)
====
