---- MODULE Stall ----
\* A broken roster. Every step is the one the real roster takes, and nothing
\* anywhere obliges a grant to happen.
EXTENDS Claims

Init ==
  /\ holder \in Site
  /\ asked = {}

Ask(s) ==
  /\ s # holder
  /\ s \notin asked
  /\ asked' = asked \cup {s}
  /\ UNCHANGED holder

Grant(s) ==
  /\ s \in asked
  /\ holder' = s
  /\ asked' = asked \ {s}

Next == \E s \in Site : Ask(s) \/ Grant(s)

Spec == Init /\ [][Next]_vars
====
