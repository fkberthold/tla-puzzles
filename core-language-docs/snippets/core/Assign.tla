---- MODULE Assign ----
EXTENDS Integers
VARIABLE n

Init == n = 0

\* A claim about one state. It is false of every integer.
Unprimed == n = n + 1

\* A claim about a pair of states. This is the one that moves.
Primed == n' = n + 1

Cap == n <= 2
========================
