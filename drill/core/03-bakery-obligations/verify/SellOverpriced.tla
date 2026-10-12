---- MODULE SellOverpriced ----
\* Mutant 3: Sell rings up one more than the price. Safe is defined
\* here so the same module can be run under Bundled.cfg.
EXTENDS Naturals

CONSTANTS Batch, Shelf, Price, Day

VARIABLES oven, tray, loaves, sold, till

vars == <<oven, tray, loaves, sold, till>>

TypeOK ==
  /\ oven \in {"cold", "hot"}
  /\ tray \in {"empty", "baking", "done"}
  /\ loaves \in Nat
  /\ sold \in 0..Day
  /\ till \in Nat

Init ==
  /\ oven = "cold"
  /\ tray = "empty"
  /\ loaves = 0
  /\ sold = 0
  /\ till = 0

Light ==
  /\ oven = "cold"
  /\ oven' = "hot"
  /\ UNCHANGED <<tray, loaves, sold, till>>

Douse ==
  /\ oven = "hot"
  /\ tray = "empty"
  /\ oven' = "cold"
  /\ UNCHANGED <<tray, loaves, sold, till>>

Load ==
  /\ oven = "hot"
  /\ tray = "empty"
  /\ tray' = "baking"
  /\ UNCHANGED <<oven, loaves, sold, till>>

Bake ==
  /\ tray = "baking"
  /\ tray' = "done"
  /\ UNCHANGED <<oven, loaves, sold, till>>

Unload ==
  /\ tray = "done"
  /\ loaves + Batch <= Shelf
  /\ tray' = "empty"
  /\ loaves' = loaves + Batch
  /\ UNCHANGED <<oven, sold, till>>

Sell ==
  /\ loaves > 0
  /\ sold < Day
  /\ loaves' = loaves - 1
  /\ sold' = sold + 1
  /\ till' = till + Price + 1
  /\ UNCHANGED <<oven, tray>>

Bank ==
  /\ sold = Day
  /\ sold' = 0
  /\ till' = 0
  /\ UNCHANGED <<oven, tray, loaves>>

Next == Light \/ Douse \/ Load \/ Bake \/ Unload \/ Sell \/ Bank

Spec == Init /\ [][Next]_vars

NothingInAColdOven == tray /= "empty" => oven = "hot"

ShelfNeverOverfull == loaves <= Shelf

TillMatchesSales == till = sold * Price

Safe == NothingInAColdOven /\ ShelfNeverOverfull /\ TillMatchesSales
====
