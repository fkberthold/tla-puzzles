---- MODULE Single ----
\* A broken shopfront. Every catch has come loose and moves the shutter on
\* its own side only, so one pull flips one shutter.
EXTENDS Claims

vars == <<open, pulls>>

Init ==
  /\ open = {}
  /\ pulls = 0

Pull(i) ==
  LET pair == {i}
  IN  /\ pulls < Limit
      /\ open' = (open \ pair) \cup (pair \ open)
      /\ pulls' = pulls + 1

Next == \E i \in 1..5 : Pull(i)

Spec == Init /\ [][Next]_vars
====
