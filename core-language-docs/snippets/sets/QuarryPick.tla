---- MODULE QuarryPick ----
EXTENDS Integers
VARIABLE atChute

Chutes == 1..3

Init == atChute = CHOOSE c \in Chutes : TRUE
Next == atChute' = CHOOSE c \in Chutes : TRUE
Spec == Init /\ [][Next]_<<atChute>>

OneChuteOnly == atChute = 1
===========================
