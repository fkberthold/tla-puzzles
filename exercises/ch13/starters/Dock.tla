---- MODULE Dock ----
EXTENDS Integers

CONSTANTS Bays, Cap

\* TODO_1. Bind DockRules to the name Rules. Nothing from that file should
\* land in this file's namespace; it should all sit behind the name.
TODO_1

VARIABLE crates

Init == crates = [b \in Bays |-> 0]

Take(b) == /\ crates[b] < Cap
           /\ crates' = [crates EXCEPT ![b] = @ + 1]

Send(b) == /\ crates[b] > 0
           /\ crates' = [crates EXCEPT ![b] = @ - 1]

Next == \E b \in Bays : Take(b) \/ Send(b)

Spec == Init /\ [][Next]_crates

\* TODO_2. No bay ever holds more crates than Cap. One call into the rules
\* file, handing it the state it has to judge.
WithinCap == TODO_2

\* TODO_3. No bay ever holds a negative number of crates.
NeverBelowZero == TODO_3
====
