---- MODULE Kitchen ----
EXTENDS Integers

Oven == INSTANCE Timer WITH MaxMinutes <- 60
Microwave == INSTANCE Timer WITH MaxMinutes <- 5

VARIABLES oven, micro

vars == << oven, micro >>

Init == oven = 0 /\ micro = 0

TickOven ==
  /\ ~Oven!Ringing(oven)
  /\ oven' = oven + 1
  /\ UNCHANGED micro

TickMicro ==
  /\ ~Microwave!Ringing(micro)
  /\ micro' = micro + 1
  /\ UNCHANGED oven

Next == TickOven \/ TickMicro

Spec == Init /\ [][Next]_vars

OvenTypeOK == oven \in Oven!Range
MicroTypeOK == micro \in Microwave!Range
BoundsCorrect == oven <= 60 /\ micro <= 5

====
