---- MODULE Garage ----
EXTENDS Integers

CONSTANTS Base, MaxHours, Budget

\* Leaves PerHour open, so the rate arrives at the call site.
Metered(PerHour) == INSTANCE Tariff WITH Base <- 0

\* Names no Base at all. This module has one, and it goes across by itself.
Flat == INSTANCE Tariff WITH PerHour <- 0

VARIABLE hours

Init == hours = 0

Next == /\ hours < MaxHours
        /\ hours' = hours + 1

Spec == Init /\ [][Next]_hours

MeteredWithinBudget == Metered(3)!Charge(hours) <= Budget

FlatIgnoresTheClock == Flat!Charge(hours) = Base
====
