---- MODULE Capper ----
\* Exercise 5 reference answer, which is also what the starter ships. The
\* exercise is a prediction about this file and about one edit to it.
\*
\* A bottling line. A bottle arrives at the capping station, and the press
\* then either caps it or waves it through bare. Both of those are the same
\* label on the machine, and only one of them is the one we care about.
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

\* The whole press stroke, as the machine sees it: one label, two branches.
Press == Cap \/ Wave

Next == Arrive \/ Press

\* Fairness is a constraint on Spec, not a property checked against it. It
\* rules out behaviours that stall, and it is the ONLY reason a liveness
\* property can hold here at all.
\*
\* `SF_vars(Cap)` names a branch and marks just that branch. Marking the whole
\* label with `SF_vars(Press)` would be satisfied by waving every bottle
\* through forever, which is exactly the behaviour we are trying to rule out.
\*
\* Strong, not weak. `Cap` is disabled at every empty-station state, so it is
\* never EVENTUALLY ALWAYS enabled, and weak fairness would be vacuous.
Fairness == /\ WF_vars(Arrive)
            /\ SF_vars(Cap)

Spec == Init /\ [][Next]_vars /\ Fairness

SomethingGetsCapped == <>(capped > 0)
====
