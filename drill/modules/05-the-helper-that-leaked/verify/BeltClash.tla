----------------------------- MODULE BeltClash -----------------------------
\* The same conveyor over the helper as first written. Two names arrive
\* twice.
EXTENDS Naturals, Gearing

VARIABLES gear, belt

Teeth == 24

Wrap(n) == n % Teeth

Init == gear = 0 /\ belt = 0

Advance ==
    /\ gear' = Turn(gear)
    /\ belt' = Wrap(belt + 4)

Spec == Init /\ [][Advance]_<<gear, belt>>

InStep == belt % 12 = gear

Stations == belt \in 0..23

=============================================================================
