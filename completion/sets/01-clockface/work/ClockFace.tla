---- MODULE ClockFace ----
\* The real clock. One hand. Its step size is picked once and never changes.
EXTENDS Claims

vars == <<step, pos, seen>>

Init ==
  /\ step \in 1..(Face - 1)
  /\ pos = 0
  /\ seen = {0}

Tick ==
  /\ pos' = (pos + step) % Face
  /\ seen' = seen \cup {pos'}
  /\ UNCHANGED step

Next == Tick

Spec == Init /\ [][Next]_vars
====
