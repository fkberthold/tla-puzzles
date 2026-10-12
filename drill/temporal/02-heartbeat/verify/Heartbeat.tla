---- MODULE Heartbeat ----
\* Trace spec for drill item 02-heartbeat. Each row of Table is one behaviour
\* from the prompt: a finite list of values of last and the index the tail
\* loops back to. loop = Len(s) is "then forever"; loop = 1 cycles the whole
\* list; a loop into the middle cycles a suffix.
EXTENDS Naturals, Sequences

CONSTANT Rows

VARIABLES row, i, last

Table == <<
  [s |-> <<0, 1, 2>>, loop |-> 1],   \* R1 allowed:   0 1 2 0 1 2 ... cycling
  [s |-> <<0, 1>>,    loop |-> 2],   \* R2 forbidden: 0, then 1 forever
  [s |-> <<0>>,       loop |-> 1],   \* R3 forbidden: 0 forever
  [s |-> <<0, 1>>,    loop |-> 1],   \* R4 allowed:   0 1 0 1 ... cycling
  [s |-> <<0, 1, 2>>, loop |-> 2]    \* R5 allowed:   0, then 1 2 1 2 ... cycling
>>

Init == /\ row \in Rows
        /\ i = 1
        /\ last = Table[row].s[1]

NextIdx == IF i < Len(Table[row].s) THEN i + 1 ELSE Table[row].loop

Advance == /\ i' = NextIdx
           /\ last' = Table[row].s[i']
           /\ UNCHANGED row

vars == <<row, i, last>>

Spec == Init /\ [][Advance]_vars /\ WF_vars(Advance)

\* A heartbeat is any step that changes the stored number.
Beat == last' # last

\* The answer.
Answer == []<><<Beat>>_last

\* Variants that survive this table, each with a caveat in ANSWER.md.
BeatNext == last' = (last + 1) % 3
V1 == []<><<BeatNext>>_last
BeatE == last' \in (0..2) \ {last}
V2 == WF_last(BeatE)

\* Neighbours the elimination table kills by a row. N1 is the natural spelling
\* of "eventually one beat"; TLC refuses it as a property, so N1b is its
\* state-level stand-in on this table, where every row starts at 0.
N1  == <><<Beat>>_last
N1b == <>(last # 0)
N2 == []<>(last = 0)
N3 == []<>(last = 0) /\ []<>(last = 1) /\ []<>(last = 2)
N4 == [][Beat]_last
====
