---- MODULE Weather ----
EXTENDS Integers

VARIABLES mode, temp, humidity, snowing

vars == << mode, temp, humidity, snowing >>

Init ==
  \/ /\ mode = "summer"
     /\ temp \in 60..90
     /\ humidity \in 0..40
     /\ snowing = FALSE
  \/ /\ mode = "winter"
     /\ temp \in 0..30
     /\ humidity \in 30..70
     /\ snowing \in {TRUE, FALSE}

Next == UNCHANGED vars

Spec == Init /\ [][Next]_vars

TypeOK ==
  /\ mode \in {"summer", "winter"}
  /\ temp \in 0..90
  /\ humidity \in 0..70
  /\ snowing \in {TRUE, FALSE}

WinterImpliesCold == mode = "winter" => temp <= 30
SummerImpliesNoSnow == mode = "summer" => snowing = FALSE

====
