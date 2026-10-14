---- MODULE Askew ----
\* A broken roster. It keeps the list of names, but a hand-over only checks
\* that the list is not empty, so the baton goes wherever it likes.
EXTENDS Claims

Init ==
  /\ holder \in Site
  /\ asked = {}

Ask(s) ==
  /\ s # holder
  /\ s \notin asked
  /\ asked' = asked \cup {s}
  /\ UNCHANGED holder

Hand(s) ==
  /\ asked # {}
  /\ holder' = s
  /\ asked' = asked \ {s}

Next == \E s \in Site : Ask(s) \/ Hand(s)

Spec ==
  /\ Init /\ [][Next]_vars
  /\ \A s \in Site : WF_vars(Hand(s))
====
