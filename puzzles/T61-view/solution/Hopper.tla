---- MODULE Hopper ----
EXTENDS Naturals, Sequences

CONSTANT Cap

VARIABLES level, history

vars == << level, history >>

Init == level = 0 /\ history = << >>

Fill == level' = level + 1 /\ level < Cap /\ history' = Append(history, "fill")
Drain == level' = level - 1 /\ level > 0 /\ history' = Append(history, "drain")

Next == Fill \/ Drain

Spec == Init /\ [][Next]_vars

TypeOK == level \in 0..Cap /\ history \in Seq({"fill", "drain"})

\* The VIEW projects away `history`. Two states differing only in history
\* count as the same state for TLC's exploration purposes.
LevelView == level

================================
