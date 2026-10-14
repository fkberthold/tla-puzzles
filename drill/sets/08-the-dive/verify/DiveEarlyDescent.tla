---- MODULE DiveEarlyDescent ----
\* The break-it step. Descend takes any diver who has checked in without
\* waiting for the rest, so rule 1 reports the first diver down.

CONSTANT Divers

VARIABLES checkedIn, descended, calledOff

vars == <<checkedIn, descended, calledOff>>

TypeOK ==
  /\ checkedIn \subseteq Divers
  /\ descended \subseteq Divers
  /\ calledOff \subseteq Divers

Init ==
  /\ checkedIn = {}
  /\ descended = {}
  /\ calledOff = {}

CheckIn ==
  /\ \E d \in Divers \ checkedIn : checkedIn' = checkedIn \cup {d}
  /\ UNCHANGED <<descended, calledOff>>

Descend ==
  /\ calledOff = {}
  /\ \E d \in checkedIn \ descended : descended' = descended \cup {d}
  /\ UNCHANGED <<checkedIn, calledOff>>

CallOff ==
  /\ \E d \in Divers \ (descended \cup calledOff) :
       calledOff' = calledOff \cup {d}
  /\ UNCHANGED <<checkedIn, descended>>

Next == CheckIn \/ Descend \/ CallOff

Spec == Init /\ [][Next]_vars

AllInBeforeAnyDown == descended /= {} => checkedIn = Divers

NoCallerDown == descended \cap calledOff = {}
====
