---- MODULE DiveWeakRule ----
\* The trap on the broken model. Descend is the early-descent mutant, and
\* rule 1 is the subset statement, that whoever is down had checked in.
\* That's true of the mutant too, so the config reports nothing.

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

AllInBeforeAnyDown == descended \subseteq checkedIn

NoCallerDown == descended \cap calledOff = {}
====
