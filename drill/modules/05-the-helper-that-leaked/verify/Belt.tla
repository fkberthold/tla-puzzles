------------------------------- MODULE Belt -------------------------------
\* The conveyor. Twenty-four stations, so it has its own Wrap and its own
\* Teeth, and it expects to get only Turn from the helper.
EXTENDS Naturals, GearingLocal

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
