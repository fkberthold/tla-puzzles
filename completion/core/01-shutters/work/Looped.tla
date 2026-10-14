---- MODULE Looped ----
\* A broken shopfront. The shop is on a corner and the row of shutters runs
\* right round it, so a fifth catch joins shutter 5 to shutter 1. Every
\* catch still flips its own pair.
EXTENDS Claims

vars == <<open, pulls>>

Init ==
  /\ open = {}
  /\ pulls = 0

Pull(i) ==
  LET pair == IF i = 5 THEN {5, 1} ELSE {i, i + 1}
  IN  /\ pulls < Limit
      /\ open' = (open \ pair) \cup (pair \ open)
      /\ pulls' = pulls + 1

Next == \E i \in 1..5 : Pull(i)

Spec == Init /\ [][Next]_vars
====
