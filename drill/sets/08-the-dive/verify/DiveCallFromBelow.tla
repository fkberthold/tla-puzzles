---- MODULE DiveCallFromBelow ----
\* Mutant. CallOff draws from every diver not already calling, including
\* the ones underwater, so rule 2 reports it.

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
  /\ checkedIn = Divers
  /\ calledOff = {}
  /\ \E d \in Divers \ descended : descended' = descended \cup {d}
  /\ UNCHANGED <<checkedIn, calledOff>>

CallOff ==
  /\ \E d \in Divers \ calledOff :
       calledOff' = calledOff \cup {d}
  /\ UNCHANGED <<checkedIn, descended>>

Next == CheckIn \/ Descend \/ CallOff

Spec == Init /\ [][Next]_vars

AllInBeforeAnyDown == descended /= {} => checkedIn = Divers

NoCallerDown == descended \cap calledOff = {}
====
