----------------------------- MODULE S16 -----------------------------
EXTENDS Naturals

CONSTANTS Pieces, Maltsters, LowerMark, UpperMark, NoCount

ASSUME /\ LowerMark \in Nat
       /\ UpperMark \in Nat
       /\ LowerMark < UpperMark

VARIABLES stage, modification

vars == <<stage, modification>>

Stages == {"floor", "malt", "loss"}

Observe == [stage |-> stage, modification |-> modification]

Ready(p) == modification[p] >= LowerMark /\ modification[p] < UpperMark

Init ==
    /\ stage = [p \in Pieces |-> "floor"]
    /\ modification = [p \in Pieces |-> 0]

Turn(m, p) ==
    /\ stage[p] = "floor"
    /\ modification[p] < UpperMark
    /\ modification' = [modification EXCEPT ![p] = @ + 1]
    /\ UNCHANGED stage

Kiln(m, p) ==
    /\ stage[p] = "floor"
    /\ stage' = [stage EXCEPT ![p] = IF Ready(p) THEN "malt" ELSE "loss"]
    /\ modification' = [modification EXCEPT ![p] = NoCount]

ThrowOut(m, p) ==
    /\ stage[p] = "floor"
    /\ stage' = [stage EXCEPT ![p] = "loss"]
    /\ modification' = [modification EXCEPT ![p] = NoCount]

Remove(m, p) == Kiln(m, p) \/ ThrowOut(m, p)

Next ==
    \E m \in Maltsters, p \in Pieces :
        \/ Turn(m, p)
        \/ Remove(m, p)

Spec ==
    /\ Init
    /\ [][Next]_vars
    /\ \A p \in Pieces : WF_vars(\E m \in Maltsters : Kiln(m, p))

TypeOK ==
    /\ Observe.stage \in [Pieces -> Stages]
    /\ DOMAIN Observe.modification = Pieces
    /\ \A p \in Pieces :
           \/ Observe.modification[p] = NoCount
           \/ Observe.modification[p] \in Nat

CountBelongsToTheFloor ==
    \A p \in Pieces :
        IF Observe.stage[p] = "floor"
        THEN /\ Observe.modification[p] \in Nat
             /\ Observe.modification[p] <= UpperMark
        ELSE Observe.modification[p] = NoCount

Opening ==
    \A p \in Pieces :
        /\ Observe.stage[p] = "floor"
        /\ Observe.modification[p] = 0

OnePairOfHands ==
    [][\A p, q \in Pieces :
          (/\ p # q
           /\ \/ Observe'.stage[p] # Observe.stage[p]
              \/ Observe'.modification[p] # Observe.modification[p])
              => /\ Observe'.stage[q] = Observe.stage[q]
                 /\ Observe'.modification[q] = Observe.modification[q]]_Observe

TurningAddsOne ==
    [][\A p \in Pieces :
          (Observe.stage[p] = "floor" /\ Observe'.stage[p] = "floor")
              => Observe'.modification[p] \in
                     {Observe.modification[p], Observe.modification[p] + 1}]_Observe

GoodMaltComesFromReady ==
    [][\A p \in Pieces :
          (Observe.stage[p] # "malt" /\ Observe'.stage[p] = "malt")
              => /\ Observe.stage[p] = "floor"
                 /\ Observe.modification[p] >= LowerMark
                 /\ Observe.modification[p] < UpperMark]_Observe

OffTheFloorIsFinal ==
    [][\A p \in Pieces :
          Observe.stage[p] # "floor"
              => /\ Observe'.stage[p] = Observe.stage[p]
                 /\ Observe'.modification[p] = Observe.modification[p]]_Observe

TheFloorGetsCleared ==
    \A p \in Pieces :
        (Observe.stage[p] = "floor") ~> (Observe.stage[p] # "floor")

=============================================================================
