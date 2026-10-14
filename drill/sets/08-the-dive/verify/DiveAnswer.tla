---- MODULE DiveAnswer ----
\* Reference answer. Three sets of divers and nothing else. Rule 1 says the
\* first descent waits for the whole group. Rule 2 says a diver who called
\* it off is never down, and a diver who is down never calls it off.

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
  /\ \E d \in Divers \ (descended \cup calledOff) :
       calledOff' = calledOff \cup {d}
  /\ UNCHANGED <<checkedIn, descended>>

Next == CheckIn \/ Descend \/ CallOff

Spec == Init /\ [][Next]_vars

AllInBeforeAnyDown == descended /= {} => checkedIn = Divers

NoCallerDown == descended \cap calledOff = {}
====
