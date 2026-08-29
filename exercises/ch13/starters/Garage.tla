---- MODULE Garage ----
EXTENDS Integers

CONSTANTS Base, MaxHours, Budget

\* TODO_1. An instance named Metered. It fixes the fixed part at 0 and
\* leaves the hourly rate open, so a caller supplies the rate at the point
\* of use rather than here.
TODO_1

\* TODO_2. An instance named Flat whose hourly rate is 0. Do not name Base
\* anywhere in this one.
TODO_2

VARIABLE hours

Init == hours = 0

Next == /\ hours < MaxHours
        /\ hours' = hours + 1

Spec == Init /\ [][Next]_hours

\* TODO_3. The charge at a metered rate of 3 an hour never runs over Budget.
MeteredWithinBudget == TODO_3

FlatIgnoresTheClock == Flat!Charge(hours) = Base
====
