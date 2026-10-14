----------------------------- MODULE BeltLeak -----------------------------
\* The silent version. The conveyor never writes its own Wrap or Teeth and
\* so picks up the helper's, which belong to a twelve-position face.
EXTENDS Naturals, Gearing

VARIABLES gear, belt

Init == gear = 0 /\ belt = 0

Advance ==
    /\ gear' = Turn(gear)
    /\ belt' = Wrap(belt + Teeth)

Spec == Init /\ [][Advance]_<<gear, belt>>

InStep == belt % 12 = gear

Stations == belt \in 0..23

=============================================================================
