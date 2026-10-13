---- MODULE ClockFace ----
EXTENDS Naturals, FiniteSets

CONSTANT Face
ASSUME Face \in 2..24

Hour == 0..(Face - 1)

Orbit(s) == {(k * s) % Face : k \in Hour}

Period(s) ==
  CHOOSE k \in 1..Face :
    /\ (k * s) % Face = 0
    /\ \A j \in 1..(k - 1) : (j * s) % Face # 0

VARIABLES step, pos, seen
vars == <<step, pos, seen>>

TypeOK ==
  /\ step \in 1..(Face - 1)
  /\ pos \in Hour
  /\ seen \subseteq Hour

Init ==
  /\ step \in 1..(Face - 1)
  /\ pos = 0
  /\ seen = {0}

Tick ==
  /\ pos' = (pos + step) % Face
  /\ seen' = seen \cup {pos'}
  /\ UNCHANGED step

Next == Tick

Spec == Init /\ [][Next]_vars

Walked == seen \subseteq Orbit(step)

OrderIsSize == Period(step) = Cardinality(Orbit(step))

Divides == Face % Cardinality(Orbit(step)) = 0

Closes == (pos = 0 /\ seen # {0}) => seen = Orbit(step)
====
