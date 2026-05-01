---- MODULE Counter ----
EXTENDS Integers, Apalache

\* @type: Int;
VARIABLE n

vars == << n >>

Init == n := 0

Tick ==
  /\ n < 5
  /\ n' := n + 1

\* Terminal stutter: when work is finished, repeat the state forever.
\* Without this disjunct, Apalache (and TLC) report DEADLOCK at n = 5.
Done ==
  /\ n = 5
  /\ UNCHANGED n

Next == Tick \/ Done

Spec == Init /\ [][Next]_vars

TypeOK == n \in 0..5
====
