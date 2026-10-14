---- MODULE Doubled ----
\* A broken cloakroom. The attendant moves one coat onto the peg another is
\* already using, and leaves that other coat where it is.
EXTENDS Claims

vars == <<hangs, swaps>>

Init ==
  /\ hangs = Own
  /\ swaps = 0

Move(a, b) ==
  /\ a # b
  /\ swaps < Limit
  /\ hangs' = [hangs EXCEPT ![a] = hangs[b]]
  /\ swaps' = swaps + 1

Next == \E a, b \in Coat : Move(a, b)

Spec == Init /\ [][Next]_vars
====
