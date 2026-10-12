------------------------------ MODULE Roster ------------------------------
EXTENDS Naturals, TLC

CONSTANTS Nurses, Nobody, MaxStreak

ASSUME Nobody \notin Nurses
ASSUME MaxStreak \in Nat /\ MaxStreak >= 1

\* One ward, one shift at a time. A nurse may start a shift when the ward
\* is unstaffed and she has not already worked MaxStreak shifts in a row.
\* Starting a shift resets everybody else's streak.

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

\* Whenever the ward is unstaffed, somebody is allowed to take the shift.
\* True with two or more nurses. False with one, who works her MaxStreak
\* and then nobody can start: the size of the model is part of the claim.
SomeoneAvailable == onShift = Nobody => \E n \in Nurses : streak[n] < MaxStreak

Perms == Permutations(Nurses)

==========================================================================
