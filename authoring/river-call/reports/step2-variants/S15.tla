----------------------------- MODULE S15 -----------------------------
EXTENDS Integers, FiniteSets

CONSTANTS Owners, Decree, Flow

ASSUME /\ IsFiniteSet(Owners)
       /\ Owners \subseteq Nat
       /\ Flow \in Nat
       /\ DOMAIN Decree = Owners
       /\ \A o \in Owners : Decree[o] \in Nat

VARIABLES diverted, calling, flow

vars == <<diverted, calling, flow>>

Observe == [diverted |-> diverted, calling |-> calling]

Senior(a, b) == a < b

Taken(d) ==
    LET Tally[T \in SUBSET Owners] ==
            IF T = {} THEN 0
            ELSE LET o == CHOOSE x \in T : TRUE
                 IN  d[o] + Tally[T \ {o}]
    IN  Tally[Owners]

Short(d, o) == d[o] + (Flow - Taken(d)) < Decree[o]

Init ==
    /\ diverted = [o \in Owners |-> 0]
    /\ calling = [o \in Owners |-> FALSE]
    /\ flow = Flow

Open(o) ==
    /\ \A s \in Owners : Senior(s, o) => ~ calling[s]
    /\ \E n \in (diverted[o] + 1) .. Decree[o] :
           /\ Taken([diverted EXCEPT ![o] = n]) =< flow
           /\ diverted' = [diverted EXCEPT ![o] = n]
    /\ UNCHANGED <<calling, flow>>

Close(o) ==
    /\ \E n \in 0 .. (diverted[o] - 1) :
           diverted' = [diverted EXCEPT ![o] = n]
    /\ UNCHANGED <<calling, flow>>

CallOut(o) ==
    /\ ~ calling[o]
    /\ Short(diverted, o)
    /\ calling' = [calling EXCEPT ![o] = TRUE]
    /\ UNCHANGED <<diverted, flow>>

CallBack(o) ==
    /\ calling[o]
    /\ calling' = [calling EXCEPT ![o] = FALSE]
    /\ UNCHANGED <<diverted, flow>>

Weather ==
    /\ flow' \in 0 .. Flow
    /\ UNCHANGED <<diverted, calling>>

Next ==
    \/ \E o \in Owners : Open(o)
    \/ \E o \in Owners : Close(o)
    \/ \E o \in Owners : CallOut(o)
    \/ \E o \in Owners : CallBack(o)
    \/ Weather

Spec == Init /\ [][Next]_vars

TypeOK ==
    /\ DOMAIN Observe.diverted = Owners
    /\ \A o \in Owners : Observe.diverted[o] \in 0 .. Decree[o]
    /\ Observe.calling \in [Owners -> BOOLEAN]

FlowHolds == Taken(Observe.diverted) =< Flow

NobodyOpensAgainstACall ==
    [][\A o \in Owners :
          Observe'.diverted[o] > Observe.diverted[o] =>
              \A s \in Owners :
                  Senior(s, o) => ~ Observe.calling[s]]_Observe

ACallIsHonest ==
    [][\A o \in Owners :
          (~ Observe.calling[o] /\ Observe'.calling[o]) =>
              Short(Observe.diverted, o)]_Observe

Decrees == [o \in Owners |-> 2]

=============================================================================
