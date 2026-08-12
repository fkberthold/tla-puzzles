---- MODULE DomainProbe ----
\* Exercise 2 reference, learntla core ch.6 "Structured Data".
\*
\* A scratch-file module: no VARIABLE, no behavior spec, six ASSUME claims.
\* TLC checks every assumption before it looks for a behavior spec, so the
\* whole module is decided by the six lines at the bottom.
EXTENDS Integers, Sequences, FiniteSets, TLC

Claim1 == DOMAIN <<"red", "green", "blue">> = {1, 2, 3}

Claim2 == DOMAIN [hue |-> 3, sat |-> 7] = {"hue", "sat"}

Claim3 == [i \in 1..3 |-> i * i] = <<1, 4, 9>>

Claim4 == Len([i \in 1..3 |-> i * i]) = 3

Claim5 == ("hue" :> 3 @@ "hue" :> 9)["hue"] = 3

Claim6 == Cardinality(DOMAIN [i \in 1..3, j \in 1..2 |-> i]) = 6

ASSUME Claim1
ASSUME Claim2
ASSUME Claim3
ASSUME Claim4
ASSUME Claim5
ASSUME Claim6
====
