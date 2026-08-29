---- MODULE Cellar ----
EXTENDS Integers

WineBand == INSTANCE Band WITH Lo <- 10, Hi <- 14
BeerBand == INSTANCE Band WITH Lo <- 2, Hi <- 6

VARIABLES wine, beer

vars == <<wine, beer>>

Init == /\ wine = 12
        /\ beer = 4

WineDrifts == /\ wine' \in {wine - 1, wine + 1}
              /\ WineBand!Holds(wine')
              /\ beer' = beer

BeerDrifts == /\ beer' \in {beer - 1, beer + 1}
              /\ BeerBand!Holds(beer')
              /\ wine' = wine

Next == WineDrifts \/ BeerDrifts

Spec == Init /\ [][Next]_vars

BothInBand == WineBand!Holds(wine) /\ BeerBand!Holds(beer)

NeitherRoomOverfull == /\ WineBand!Headroom(wine) >= 0
                       /\ BeerBand!Headroom(beer) >= 0
====
