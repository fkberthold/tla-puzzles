---- MODULE Tollgate ----
EXTENDS Integers
CONSTANT Cap
VARIABLE paid

Init == paid = 0
Pay == paid' = paid + 1
Next == Pay
Spec == Init /\ [][Next]_<<paid>>

\* The same bound, written in the two places it can go.
Inside == paid <= Cap
Bounded == Next /\ paid' <= Cap
BoundedSpec == Init /\ [][Bounded]_<<paid>>

NotSeven == paid # 7
=========================
