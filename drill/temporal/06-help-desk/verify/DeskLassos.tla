---- MODULE DeskLassos ----
\* The three lassos from the prompt of drill item 06-help-desk, as a trace
\* spec. Each candidate fairness conjunct is checked as a PROPERTY of a single
\* lasso: rc 0 means the conjunct admits that lasso, rc 13 means it rules it
\* out. Each value is <<customer, clerk>>.
EXTENDS Naturals, Sequences

CONSTANT Rows

VARIABLES row, i, customer, clerk

Table == <<
  [s |-> << <<"waiting", "present">> >>,                           loop |-> 1],  \* L1 forbidden
  [s |-> << <<"waiting", "present">>, <<"waiting", "absent">> >>,  loop |-> 1],  \* L2 allowed
  [s |-> << <<"none", "present">> >>,                              loop |-> 1]   \* L3 allowed
>>

At(k) == Table[row].s[k]

Init == /\ row \in Rows
        /\ i = 1
        /\ customer = At(1)[1]
        /\ clerk = At(1)[2]

NextIdx == IF i < Len(Table[row].s) THEN i + 1 ELSE Table[row].loop

Advance == /\ i' = NextIdx
           /\ customer' = At(i')[1]
           /\ clerk' = At(i')[2]
           /\ UNCHANGED row

vars == <<row, i, customer, clerk>>

Spec == Init /\ [][Advance]_vars /\ WF_vars(Advance)

\* The system's actions restated over the lasso's own variables.
sv == <<customer, clerk>>

Arrive   == customer = "none" /\ customer' = "waiting" /\ UNCHANGED clerk
StepAway == clerk = "present" /\ clerk' = "absent" /\ UNCHANGED customer
Return   == clerk = "absent" /\ clerk' = "present" /\ UNCHANGED customer
Serve    == customer = "waiting" /\ clerk = "present" /\ customer' = "none" /\ UNCHANGED clerk
SysNext  == Arrive \/ StepAway \/ Return \/ Serve

WFServe  == WF_sv(Serve)
SFServe  == SF_sv(Serve)
WFNext   == WF_sv(SysNext)
WFArrive == WF_sv(Arrive)
====
