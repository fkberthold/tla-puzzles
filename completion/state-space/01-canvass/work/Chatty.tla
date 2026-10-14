---- MODULE Chatty ----
\* A broken canvass. One knock, and the canvasser writes down every answer
\* there is as something heard.
EXTENDS Claims

Init ==
  /\ noted = [d \in Door |-> Nil]
  /\ heard = {}
  /\ calls = 0

Knock(d, a) ==
  /\ noted' = [noted EXCEPT ![d] = a]
  /\ heard' = heard \cup Answer
  /\ calls' = calls + 1

Next == \E d \in Door, a \in Answer : Knock(d, a)

Spec == Init /\ [][Next]_vars
====
