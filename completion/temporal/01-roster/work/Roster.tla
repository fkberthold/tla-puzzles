---- MODULE Roster ----
\* The real roster. One baton, held by one site. A site puts its name down
\* for the baton, and a grant hands the baton to a site whose name is down
\* and takes that name off the list.
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

Spec ==
  /\ Init /\ [][Next]_vars
  /\ \A s \in Site : WF_vars(Grant(s))
====
