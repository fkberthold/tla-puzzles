---- MODULE Canvass ----
\* The real canvass. A knock writes what the door said against that door,
\* adds the answer to what the canvasser remembers hearing, and counts the
\* call. A door may be knocked on again, and the new answer replaces the old
\* one against that door.
EXTENDS Claims

Init ==
  /\ noted = [d \in Door |-> Nil]
  /\ heard = {}
  /\ calls = 0

Knock(d, a) ==
  /\ noted' = [noted EXCEPT ![d] = a]
  /\ heard' = heard \cup {a}
  /\ calls' = calls + 1

Next == \E d \in Door, a \in Answer : Knock(d, a)

Spec == Init /\ [][Next]_vars
====
