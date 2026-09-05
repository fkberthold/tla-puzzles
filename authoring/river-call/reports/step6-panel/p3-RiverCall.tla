---- MODULE RiverCall ----
EXTENDS Naturals

CONSTANT Owners, Decree, Flow

Decrees == [o \in Owners |-> 2]

VARIABLE diverted, calling

Init == /\ diverted = [o \in Owners |-> 0]
        /\ calling = [o \in Owners |-> FALSE]

Total == (IF 1 \in Owners THEN diverted[1] ELSE 0) +
         (IF 2 \in Owners THEN diverted[2] ELSE 0) +
         (IF 3 \in Owners THEN diverted[3] ELSE 0)

Available(o) == Flow - (Total - diverted[o])

IsShort(o) == Available(o) + diverted[o] < Decree[o]

Next == \E o \in Owners :
  (\E a \in 0..Decree[o] :
    /\ a /= diverted[o]
    /\ IF a > diverted[o] THEN
         LET rest == Total - diverted[o]
         IN /\ rest + a <= Flow
            /\ \A s \in {x \in Owners : x < o} : calling[s] = FALSE
       ELSE TRUE
    /\ diverted' = [diverted EXCEPT ![o] = a]
    /\ calling' = calling)
  \/ (/\ calling[o] = FALSE
      /\ IsShort(o)
      /\ calling' = [calling EXCEPT ![o] = TRUE]
      /\ diverted' = diverted)
  \/ (/\ calling[o] = TRUE
      /\ calling' = [calling EXCEPT ![o] = FALSE]
      /\ diverted' = diverted)

Spec == Init /\ [][Next]_<<diverted, calling>>

Observe == [diverted |-> diverted, calling |-> calling]

GatesWellFormed == \A o \in Owners :
                     /\ diverted[o] \in 0..Decree[o]
                     /\ calling[o] \in BOOLEAN

TheFlowHolds == Total <= Flow

NobodyOpensAgainstACall == [][\A o \in Owners :
                               (diverted'[o] > diverted[o]) =>
                               \A s \in {x \in Owners : x < o} : calling'[s] = FALSE]_Observe

ACallIsHonest == [][\A o \in Owners :
                      (calling'[o] /\ ~calling[o]) =>
                      (Available(o) + diverted[o] < Decree[o])]_Observe

====
