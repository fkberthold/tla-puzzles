\* a sorting room: parcels go down the chute one at a time, a belt rolls, a fan turns. only the chute runs out of work; the other two can go on for ever.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES parcel, belt, fan
vars == <<parcel, belt, fan>>
Init == parcel = 0 /\ belt = 0 /\ fan = 0
Chute == parcel < 2 /\ parcel' = parcel + 1 /\ belt' = belt /\ fan' = fan
Roll == belt' = 1 - belt /\ parcel' = parcel /\ fan' = fan
Spin == fan' = 1 - fan /\ parcel' = parcel /\ belt' = belt
Next == Chute \/ Roll \/ Spin
Fair ==
__ANSWER__
Spec == Init /\ [][Next]_vars /\ Fair
Sorted == <>(parcel = 2)
====
