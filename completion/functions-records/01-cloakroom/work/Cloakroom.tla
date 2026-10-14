---- MODULE Cloakroom ----
\* The real cloakroom. Four coats on four pegs, each on the peg it came in
\* on. The attendant's one move takes two coats and swaps them over.
EXTENDS Claims

vars == <<hangs, swaps>>

Init ==
  /\ hangs = Own
  /\ swaps = 0

Swap(a, b) ==
  /\ a # b
  /\ swaps < Limit
  /\ hangs' = [hangs EXCEPT ![a] = hangs[b], ![b] = hangs[a]]
  /\ swaps' = swaps + 1

Next == \E a, b \in Coat : Swap(a, b)

Spec == Init /\ [][Next]_vars
====
