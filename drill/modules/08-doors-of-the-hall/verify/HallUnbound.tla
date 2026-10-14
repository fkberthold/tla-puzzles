---------------------------- MODULE HallUnbound ----------------------------
\* The wrong neighbor: the instance is written at module level, where the
\* width it wants to substitute is not in scope.
EXTENDS Naturals

CONSTANT Widths

VARIABLE pallet

D == INSTANCE Doorway WITH Width <- w

Fits(p) == \A w \in Widths : D!Admits(p)

Init == pallet = 1

Widen == Fits(pallet + 1) /\ pallet' = pallet + 1

Unload == pallet' = 1

Next == Widen \/ Unload

Spec == Init /\ [][Next]_pallet

FitsAll == Fits(pallet)

=============================================================================
