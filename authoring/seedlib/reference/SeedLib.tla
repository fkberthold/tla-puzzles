------------------------------- MODULE SeedLib -------------------------------
EXTENDS Naturals, FiniteSets

CONSTANTS Members, Varieties, OpeningStock, NumSeasons

ASSUME
    /\ IsFiniteSet(Members)
    /\ Members # {}
    /\ IsFiniteSet(Varieties)
    /\ Varieties # {}
    /\ OpeningStock \in [Varieties -> Nat]
    /\ NumSeasons \in Nat
    /\ NumSeasons >= 1

VARIABLES season, shelf, owed, standing

vars == <<season, shelf, owed, standing>>

Ended == NumSeasons + 1
Good == "good"
Default == "default"

InProgress == season \in 1..NumSeasons

Init ==
    /\ season = 1
    /\ shelf = OpeningStock
    /\ owed = [m \in Members |-> [v \in Varieties |-> 0]]
    /\ standing = [m \in Members |-> Good]

Checkout(m, v) ==
    /\ InProgress
    /\ standing[m] = Good
    /\ shelf[v] > 0
    /\ owed[m][v] = 0
    /\ shelf' = [shelf EXCEPT ![v] = @ - 1]
    /\ owed' = [owed EXCEPT ![m][v] = @ + 1]
    /\ UNCHANGED <<season, standing>>

Return(m, v) ==
    /\ InProgress
    /\ owed[m][v] > 0
    /\ shelf' = [shelf EXCEPT ![v] = @ + 1]
    /\ owed' = [owed EXCEPT ![m][v] = @ - 1]
    /\ standing' = [standing EXCEPT ![m] =
                        IF \A w \in Varieties : owed'[m][w] = 0
                        THEN Good
                        ELSE @]
    /\ UNCHANGED season

Close ==
    /\ InProgress
    /\ season' = season + 1
    /\ standing' = [m \in Members |->
                        IF \E v \in Varieties : owed[m][v] > 0
                        THEN Default
                        ELSE Good]
    /\ UNCHANGED <<shelf, owed>>

Next ==
    \/ \E m \in Members, v \in Varieties : Checkout(m, v) \/ Return(m, v)
    \/ Close

Spec == Init /\ [][Next]_vars /\ WF_vars(Close)

Observe ==
    [season |-> season, shelf |-> shelf, owed |-> owed, standing |-> standing]

RECURSIVE SumOver(_, _)
SumOver(f, S) ==
    IF S = {}
    THEN 0
    ELSE LET x == CHOOSE y \in S : TRUE
         IN f[x] + SumOver(f, S \ {x})

OwedTotal(v) == SumOver([m \in Members |-> Observe.owed[m][v]], Members)

Owes(m) == \E v \in Varieties : Observe.owed[m][v] > 0

TypeOK ==
    /\ season \in 1..Ended
    /\ shelf \in [Varieties -> Nat]
    /\ owed \in [Members -> [Varieties -> Nat]]
    /\ standing \in [Members -> {Good, Default}]

ShelfFloor == \A v \in Varieties : Observe.shelf[v] >= 0

OneDebtPerKind ==
    \A m \in Members, v \in Varieties : Observe.owed[m][v] <= 1

ConservationInKind ==
    \A v \in Varieties : Observe.shelf[v] + OwedTotal(v) = OpeningStock[v]

DefaultIsNeverClean ==
    \A m \in Members : Observe.standing[m] = Default => Owes(m)

TheOpening ==
    /\ Observe.season = 1
    /\ Observe.shelf = OpeningStock
    /\ Observe.owed = [m \in Members |-> [v \in Varieties |-> 0]]
    /\ Observe.standing = [m \in Members |-> Good]

StandingGatesTheShelf ==
    [][LET o == Observe
           n == Observe'
       IN \A v \in Varieties :
              n.shelf[v] < o.shelf[v] =>
                  \E m \in Members :
                      /\ n.owed[m][v] = o.owed[m][v] + 1
                      /\ o.standing[m] = Good]_Observe

ShelfDiscipline ==
    [][LET o == Observe
           n == Observe'
       IN /\ \A v \in Varieties :
                 /\ n.shelf[v] \in {o.shelf[v] - 1, o.shelf[v], o.shelf[v] + 1}
                 /\ n.shelf[v] = o.shelf[v] - 1 =>
                        \E m \in Members : n.owed[m][v] = o.owed[m][v] + 1
                 /\ n.shelf[v] = o.shelf[v] + 1 =>
                        \E m \in Members : n.owed[m][v] = o.owed[m][v] - 1
          /\ Cardinality({v \in Varieties : n.shelf[v] # o.shelf[v]}) <= 1
          /\ Cardinality({mv \in Members \X Varieties :
                              n.owed[mv[1]][mv[2]] # o.owed[mv[1]][mv[2]]})
                 <= 1]_Observe

LedgerDiscipline ==
    [][LET o == Observe
           n == Observe'
       IN \A m \in Members, v \in Varieties :
              /\ n.owed[m][v] > o.owed[m][v] =>
                     /\ n.owed[m][v] = o.owed[m][v] + 1
                     /\ n.shelf[v] = o.shelf[v] - 1
              /\ n.owed[m][v] < o.owed[m][v] =>
                     /\ n.owed[m][v] = o.owed[m][v] - 1
                     /\ n.shelf[v] = o.shelf[v] + 1]_Observe

CloseSquaresTheBook ==
    [][LET o == Observe
           n == Observe'
       IN /\ n.season # o.season =>
                 \A m \in Members :
                     n.standing[m] = (IF \E v \in Varieties : n.owed[m][v] > 0
                                      THEN Default
                                      ELSE Good)
          /\ n.season = o.season =>
                 \A m \in Members :
                     o.standing[m] = Good => n.standing[m] = Good
          /\ \A m \in Members :
                 o.standing[m] = Default /\ n.standing[m] = Good =>
                     /\ \E v \in Varieties : n.owed[m][v] < o.owed[m][v]
                     /\ \A v \in Varieties : n.owed[m][v] = 0]_Observe

TheCalendarMarches ==
    [][LET o == Observe
           n == Observe'
       IN /\ n.season \in {o.season, o.season + 1}
          /\ n.season # o.season =>
                 /\ n.shelf = o.shelf
                 /\ n.owed = o.owed]_Observe

TheEndIsTheEnd ==
    [][Observe.season = Ended => Observe' = Observe]_Observe

TheReckoningComes ==
    /\ \A s \in 1..NumSeasons :
           Observe.season = s ~> Observe.season = s + 1
    /\ [](Observe.season = Ended =>
              \A m \in Members : Owes(m) => Observe.standing[m] = Default)

=============================================================================
