---- MODULE Capper ----
\* Exercise 5. This module is complete and runs as it stands.
\*
\* A bottling line. A bottle arrives at the capping station, and the press
\* then either caps it or waves it through bare. Those two are branches of one
\* press stroke, so the machine takes them under the same label.
EXTENDS Integers

Limit == 2

VARIABLES station, capped

vars == << station, capped >>

Init == /\ station = "empty"
        /\ capped = 0

Arrive == /\ station = "empty"
          /\ station' = "bottle"
          /\ UNCHANGED capped

Cap == /\ station = "bottle"
       /\ capped < Limit
       /\ station' = "empty"
       /\ capped' = capped + 1

Wave == /\ station = "bottle"
        /\ station' = "empty"
        /\ UNCHANGED capped

Press == Cap \/ Wave

Next == Arrive \/ Press

Fairness == /\ WF_vars(Arrive)
            /\ SF_vars(Cap)

Spec == Init /\ [][Next]_vars /\ Fairness

SomethingGetsCapped == <>(capped > 0)
====
