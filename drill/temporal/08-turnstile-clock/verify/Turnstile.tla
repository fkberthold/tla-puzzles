---- MODULE Turnstile ----
\* Trace spec for drill item 08-turnstile-clock. Every row is one step from
\* the prompt: the state before, the state after, then the after-state
\* forever. Each value is <<count, clock>>.
EXTENDS Naturals, Sequences

CONSTANT Rows

VARIABLES row, i, count, clock

Table == <<
  [s |-> << <<3, 0>>, <<4, 0>> >>, loop |-> 2],  \* S1 allowed
  [s |-> << <<3, 0>>, <<3, 1>> >>, loop |-> 2],  \* S2 allowed
  [s |-> << <<3, 0>>, <<5, 0>> >>, loop |-> 2],  \* S3 forbidden
  [s |-> << <<3, 0>>, <<2, 0>> >>, loop |-> 2],  \* S4 forbidden
  [s |-> << <<3, 0>>, <<4, 1>> >>, loop |-> 2],  \* S5 allowed
  [s |-> << <<3, 0>>, <<3, 0>> >>, loop |-> 2]   \* S6 allowed
>>

At(k) == Table[row].s[k]

Init == /\ row \in Rows
        /\ i = 1
        /\ count = At(1)[1]
        /\ clock = At(1)[2]

NextIdx == IF i < Len(Table[row].s) THEN i + 1 ELSE Table[row].loop

Advance == /\ i' = NextIdx
           /\ count' = At(i')[1]
           /\ clock' = At(i')[2]
           /\ UNCHANGED row

vars == <<row, i, count, clock>>

Spec == Init /\ [][Advance]_vars /\ WF_vars(Advance)

\* The answer: the subscript is the one variable the action mentions.
Answer == [][count' = count + 1]_count
V1 == [][count' = count + 1]_<<count>>

\* Neighbors.
N1 == [][count' = count + 1]_<<count, clock>>
N2 == [][count' >= count]_count
N3 == [][count' \in {count - 1, count + 1}]_count
N4 == [][\/ (count' = count + 1 /\ UNCHANGED clock)
         \/ (count' = count /\ clock' # clock)]_<<count, clock>>
N6 == [][count' = count + 1]_clock
====
