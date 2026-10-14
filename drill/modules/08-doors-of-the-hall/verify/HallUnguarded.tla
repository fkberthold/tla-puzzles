--------------------------- MODULE HallUnguarded ---------------------------
\* The pallet widens without asking the doorways.
EXTENDS Naturals

CONSTANT Widths

VARIABLE pallet

D(w) == INSTANCE Doorway WITH Width <- w

Fits(p) == \A w \in Widths : D(w)!Admits(p)

Init == pallet = 1

Widen == pallet < 5 /\ pallet' = pallet + 1

Unload == pallet' = 1

Next == Widen \/ Unload

Spec == Init /\ [][Next]_pallet

FitsAll == Fits(pallet)

=============================================================================
