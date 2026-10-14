---- MODULE Stray ----
\* A broken clock. The hand moves correctly, but it also marks the hour one
\* past wherever it lands, and it stops rather than return to hour 0.
EXTENDS Claims

vars == <<step, pos, seen>>

Init ==
  /\ step \in 1..(Face - 1)
  /\ pos = 0
  /\ seen = {0}

Tick ==
  /\ pos' = (pos + step) % Face
  /\ pos' # 0
  /\ seen' = seen \cup {pos'} \cup {(pos' + 1) % Face}
  /\ UNCHANGED step

Next == Tick

Spec == Init /\ [][Next]_vars
====
