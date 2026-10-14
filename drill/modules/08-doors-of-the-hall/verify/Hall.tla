------------------------------- MODULE Hall -------------------------------
\* A hall with several doorways and one pallet being stacked wider. The
\* doorway module is instantiated once per width, and the width is not
\* known until the quantifier binds it, so the instance takes it as an
\* argument.
EXTENDS Naturals

CONSTANT Widths

VARIABLE pallet

D(w) == INSTANCE Doorway WITH Width <- w

Fits(p) == \A w \in Widths : D(w)!Admits(p)

Init == pallet = 1

Widen == Fits(pallet + 1) /\ pallet' = pallet + 1

Unload == pallet' = 1

Next == Widen \/ Unload

Spec == Init /\ [][Next]_pallet

FitsAll == Fits(pallet)

=============================================================================
