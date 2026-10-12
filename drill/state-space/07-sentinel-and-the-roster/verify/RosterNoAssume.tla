--------------------------- MODULE RosterNoAssume ---------------------------
EXTENDS Naturals, TLC

\* Roster.tla with both assumptions deleted, so a config that puts the
\* sentinel inside the nurse set runs instead of stopping. The measurement
\* is what that run reports.

CONSTANTS Nurses, Nobody, MaxStreak

VARIABLES onShift, streak

vars == <<onShift, streak>>

TypeOK ==
    /\ onShift \in Nurses \cup {Nobody}
    /\ streak \in [Nurses -> 0..MaxStreak]

Init ==
    /\ onShift = Nobody
    /\ streak = [n \in Nurses |-> 0]

Start(n) ==
    /\ onShift = Nobody
    /\ streak[n] < MaxStreak
    /\ onShift' = n
    /\ streak' = [m \in Nurses |-> IF m = n THEN streak[m] + 1 ELSE 0]

End ==
    /\ onShift # Nobody
    /\ onShift' = Nobody
    /\ UNCHANGED streak

Next == End \/ \E n \in Nurses : Start(n)

Spec == Init /\ [][Next]_vars

SomeoneAvailable == onShift = Nobody => \E n \in Nurses : streak[n] < MaxStreak

Perms == Permutations(Nurses)

==========================================================================
