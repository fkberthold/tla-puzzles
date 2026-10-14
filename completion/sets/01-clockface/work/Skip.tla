---- MODULE Skip ----
\* A broken clock. Same as ClockFace except the hand moves two steps at a
\* time while still calling one step its step size.
EXTENDS Claims

vars == <<step, pos, seen>>

Init ==
  /\ step \in 1..(Face - 1)
  /\ pos = 0
  /\ seen = {0}

Tick ==
  /\ pos' = (pos + 2 * step) % Face
  /\ seen' = seen \cup {pos'}
  /\ UNCHANGED step

Next == Tick

Spec == Init /\ [][Next]_vars
====
