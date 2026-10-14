---- MODULE Steps ----
\* Trace spec for drill item 04-revision-freeze. Rows 1 to 3 are one-state
\* behaviors that pin the initial state. Rows 4 to 10 are two-state
\* behaviors, one step each, then the second state forever. Each value is
\* <<rev, published>>.
EXTENDS Naturals, Sequences

CONSTANT Rows

VARIABLES row, i, rev, published

D == INSTANCE Document

Table == <<
  [s |-> << <<0, FALSE>> >>,                loop |-> 1],  \* 1  I1 allowed start
  [s |-> << <<0, TRUE>> >>,                 loop |-> 1],  \* 2  I2 forbidden start
  [s |-> << <<1, FALSE>> >>,                loop |-> 1],  \* 3  I3 forbidden start
  [s |-> << <<3, FALSE>>, <<4, FALSE>> >>,  loop |-> 2],  \* 4  S1 allowed
  [s |-> << <<3, FALSE>>, <<3, TRUE>> >>,   loop |-> 2],  \* 5  S2 allowed
  [s |-> << <<3, FALSE>>, <<4, TRUE>> >>,   loop |-> 2],  \* 6  S3 forbidden
  [s |-> << <<3, TRUE>>,  <<3, FALSE>> >>,  loop |-> 2],  \* 7  S4 forbidden
  [s |-> << <<3, TRUE>>,  <<4, TRUE>> >>,   loop |-> 2],  \* 8  S5 forbidden
  [s |-> << <<3, FALSE>>, <<5, FALSE>> >>,  loop |-> 2],  \* 9  S6 forbidden
  [s |-> << <<3, TRUE>>,  <<3, TRUE>> >>,   loop |-> 2]   \* 10 S7 allowed
>>

At(k) == Table[row].s[k]

Init == /\ row \in Rows
        /\ i = 1
        /\ rev = At(1)[1]
        /\ published = At(1)[2]

NextIdx == IF i < Len(Table[row].s) THEN i + 1 ELSE Table[row].loop

Advance == /\ i' = NextIdx
           /\ rev' = At(i')[1]
           /\ published' = At(i')[2]
           /\ UNCHANGED row

vars == <<row, i, rev, published>>

Spec == Init /\ [][Advance]_vars /\ WF_vars(Advance)

\* The candidate's two halves, and the neighbors, as names the cfg can use.
AnswerInit  == D!Init
AnswerNext  == D!NextBox
NoGuard     == D!NoGuardBox
NoUnchanged == D!NoUnchangedBox
Gt          == D!GtBox
Toggle      == D!ToggleBox
Conj        == D!ConjBox
SubRev      == D!SubRevBox
SubPub      == D!SubPubBox
InitNoRev   == D!InitNoRev
InitNoPub   == D!InitNoPub
====
