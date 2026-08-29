---- MODULE Dock ----
EXTENDS Integers

CONSTANTS Bays, Cap

Rules == INSTANCE DockRules

VARIABLE crates

Init == crates = [b \in Bays |-> 0]

Take(b) == /\ crates[b] < Cap
           /\ crates' = [crates EXCEPT ![b] = @ + 1]

Send(b) == /\ crates[b] > 0
           /\ crates' = [crates EXCEPT ![b] = @ - 1]

Next == \E b \in Bays : Take(b) \/ Send(b)

Spec == Init /\ [][Next]_crates

WithinCap == Rules!NoBayOver(crates, Cap)

NeverBelowZero == Rules!NoBayNegative(crates)
====
