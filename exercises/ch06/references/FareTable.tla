---- MODULE FareTable ----
\* Exercise 5 reference, learntla core ch.6 "Structured Data".
\*
\* A two-argument function literal. `Fare` maps a pair of zones to the number
\* of zone boundaries a rider crosses between them.
EXTENDS Integers

Zones == 1..3

MaxFare == 2

Fare == [a, b \in Zones |-> IF a > b THEN a - b ELSE b - a]

Symmetric == \A a, b \in Zones: Fare[a, b] = Fare[b, a]

FreeWithinZone == \A z \in Zones: Fare[z, z] = 0

DomainIsPairs == DOMAIN Fare = Zones \X Zones

FareIsTyped == Fare \in [Zones \X Zones -> 0..MaxFare]

ASSUME Symmetric
ASSUME FreeWithinZone
ASSUME DomainIsPairs
ASSUME FareIsTyped
====
