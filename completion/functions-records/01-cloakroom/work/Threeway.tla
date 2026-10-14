---- MODULE Threeway ----
\* A broken cloakroom. The attendant takes three coats at a time and moves
\* each onto the next one's peg, then books it as one swap.
EXTENDS Claims

vars == <<hangs, swaps>>

Init ==
  /\ hangs = Own
  /\ swaps = 0

Rotate(a, b, c) ==
  /\ a # b
  /\ b # c
  /\ a # c
  /\ swaps < Limit
  /\ hangs' = [hangs EXCEPT ![a] = hangs[b], ![b] = hangs[c], ![c] = hangs[a]]
  /\ swaps' = swaps + 1

Next == \E a, b, c \in Coat : Rotate(a, b, c)

Spec == Init /\ [][Next]_vars
====
