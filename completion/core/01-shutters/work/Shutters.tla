---- MODULE Shutters ----
\* The real shopfront. Five shutters in a row, all shut to start with. One
\* catch sits between each neighbouring pair, and working it flips both of
\* that pair.
EXTENDS Claims

vars == <<open, pulls>>

Init ==
  /\ open = {}
  /\ pulls = 0

\* The catch between shutter i and shutter i + 1.
Pull(i) ==
  LET pair == {i, i + 1}
  IN  /\ pulls < Limit
      /\ open' = (open \ pair) \cup (pair \ open)
      /\ pulls' = pulls + 1

Next == \E i \in 1..4 : Pull(i)

Spec == Init /\ [][Next]_vars
====
