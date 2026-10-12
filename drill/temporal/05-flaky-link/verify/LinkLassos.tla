---- MODULE LinkLassos ----
\* The three lassos from the prompt of drill item 05-flaky-link, as a trace
\* spec. Each candidate fairness conjunct is then checked as a PROPERTY of a
\* single lasso: rc 0 means the conjunct admits that lasso, rc 13 means it
\* rules it out. Each value is <<link, msg>>.
EXTENDS Naturals, Sequences

CONSTANT Rows

VARIABLES row, i, link, msg

Table == <<
  [s |-> << <<"up", "pending">> >>,                         loop |-> 1],  \* L1 forbidden
  [s |-> << <<"up", "pending">>, <<"down", "pending">> >>,  loop |-> 1],  \* L2 forbidden
  [s |-> << <<"down", "pending">> >>,                       loop |-> 1]   \* L3 allowed
>>

At(k) == Table[row].s[k]

Init == /\ row \in Rows
        /\ i = 1
        /\ link = At(1)[1]
        /\ msg = At(1)[2]

NextIdx == IF i < Len(Table[row].s) THEN i + 1 ELSE Table[row].loop

Advance == /\ i' = NextIdx
           /\ link' = At(i')[1]
           /\ msg' = At(i')[2]
           /\ UNCHANGED row

vars == <<row, i, link, msg>>

Spec == Init /\ [][Advance]_vars /\ WF_vars(Advance)

\* The system's actions restated over the lasso's own link and msg, so a
\* fairness formula about them can be evaluated on each lasso.
sv == <<link, msg>>

LinkDown == link = "up" /\ link' = "down" /\ UNCHANGED msg
LinkUp   == link = "down" /\ link' = "up" /\ UNCHANGED msg
Deliver  == link = "up" /\ msg = "pending" /\ msg' = "delivered" /\ UNCHANGED link
SysNext  == LinkDown \/ LinkUp \/ Deliver

SFDeliver         == SF_sv(Deliver)
WFDeliver         == WF_sv(Deliver)
WFNext            == WF_sv(SysNext)
SFNext            == SF_sv(SysNext)
SFDeliverLinkFair == SF_sv(Deliver) /\ WF_sv(LinkUp)
WFBoth            == WF_sv(LinkUp) /\ WF_sv(Deliver)
====
