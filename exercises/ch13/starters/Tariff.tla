---- MODULE Tariff ----
\* Exercise 4, the library. Ships complete and is not edited.
\*
\* A charge is a fixed part plus a part that runs with the clock. Which of
\* the two a caller pins down, and which it leaves open, is the exercise.
EXTENDS Integers

CONSTANTS Base, PerHour

Charge(hours) == Base + PerHour * hours
====
