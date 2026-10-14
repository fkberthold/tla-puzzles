----------------------------- MODULE BeltNamed -----------------------------
\* The other fix, made on the conveyor's side: the helper as first written,
\* brought in under a name so nothing of its lands in this namespace.
EXTENDS Naturals

VARIABLES gear, belt

G == INSTANCE Gearing

Teeth == 24

Wrap(n) == n % Teeth

Init == gear = 0 /\ belt = 0

Advance ==
    /\ gear' = G!Turn(gear)
    /\ belt' = Wrap(belt + 4)

Spec == Init /\ [][Advance]_<<gear, belt>>

InStep == belt % 12 = gear

Stations == belt \in 0..23

=============================================================================
