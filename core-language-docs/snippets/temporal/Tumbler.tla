---- MODULE Tumbler ----
CONSTANT Pins
VARIABLE lifted
vars == <<lifted>>

Init == lifted = {}
Drop(p) == p \notin lifted /\ lifted' = lifted \cup {p}
Settled == lifted = Pins /\ UNCHANGED vars
Next == (\E p \in Pins : Drop(p)) \/ Settled

\* Weak fairness on every pin.
All == Init /\ [][Next]_vars /\ \A p \in Pins : WF_vars(Drop(p))

\* Weak fairness on some pin, which leaves the rest of them free to hang.
Some == Init /\ [][Next]_vars /\ \E p \in Pins : WF_vars(Drop(p))

Full == <>(lifted = Pins)
========================
