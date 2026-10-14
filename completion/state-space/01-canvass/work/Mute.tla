---- MODULE Mute ----
\* A broken canvass. The knock writes the answer against the door and counts
\* the call, and never adds the answer to what it remembers hearing.
EXTENDS Claims

Init ==
  /\ noted = [d \in Door |-> Nil]
  /\ heard = {}
  /\ calls = 0

Knock(d, a) ==
  /\ noted' = [noted EXCEPT ![d] = a]
  /\ calls' = calls + 1
  /\ UNCHANGED heard

Next == \E d \in Door, a \in Answer : Knock(d, a)

Spec == Init /\ [][Next]_vars
====
