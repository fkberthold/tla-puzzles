------------------------------ MODULE BuyClub ------------------------------
EXTENDS Naturals, FiniteSets

CONSTANTS Members, Products, Min, Cap

ASSUME /\ IsFiniteSet(Members)
       /\ IsFiniteSet(Products)
       /\ Min \in Nat /\ Min >= 1
       /\ Cap \in Nat

VARIABLES phase, book, share

vars == <<phase, book, share>>

Phases == {"open", "placed", "arrived"}

PledgeAmounts == 0..Cap

Total(p) ==
    LET Sum[T \in SUBSET Members] ==
            IF T = {} THEN 0
            ELSE LET m == CHOOSE x \in T : TRUE
                 IN  book[m][p] + Sum[T \ {m}]
    IN  Sum[Members]

Init ==
    /\ phase = [p \in Products |-> "open"]
    /\ book  = [m \in Members |-> [p \in Products |-> 0]]
    /\ share = [m \in Members |-> [p \in Products |-> 0]]

Pledge(m, p, n) ==
    /\ phase[p] = "open"
    /\ n \in PledgeAmounts \ {book[m][p]}
    /\ book' = [book EXCEPT ![m][p] = n]
    /\ UNCHANGED <<phase, share>>

Place(p) ==
    /\ phase[p] = "open"
    /\ Total(p) >= Min
    /\ phase' = [phase EXCEPT ![p] = "placed"]
    /\ share' = [m \in Members |-> [share[m] EXCEPT ![p] = book[m][p]]]
    /\ UNCHANGED book

Deliver(p) ==
    /\ phase[p] = "placed"
    /\ phase' = [phase EXCEPT ![p] = "arrived"]
    /\ UNCHANGED <<book, share>>

Collect(m, p) ==
    /\ phase[p] = "arrived"
    /\ share[m][p] > 0
    /\ share' = [share EXCEPT ![m][p] = 0]
    /\ UNCHANGED <<phase, book>>

Next ==
    \/ \E m \in Members, p \in Products, n \in PledgeAmounts : Pledge(m, p, n)
    \/ \E p \in Products : Place(p)
    \/ \E p \in Products : Deliver(p)
    \/ \E m \in Members, p \in Products : Collect(m, p)

Spec == Init /\ [][Next]_vars /\ \A p \in Products : WF_vars(Deliver(p))

Observe == [phase |-> phase, book |-> book, share |-> share]

TypeOK ==
    /\ phase \in [Products -> Phases]
    /\ book  \in [Members -> [Products -> PledgeAmounts]]
    /\ share \in [Members -> [Products -> PledgeAmounts]]

SharesTellTheBook ==
    \A m \in Members, p \in Products :
        IF phase[p] = "open"
        THEN share[m][p] = 0
        ELSE share[m][p] \in {book[m][p], 0}

Opening ==
    /\ \A p \in Products : phase[p] = "open"
    /\ \A m \in Members, p \in Products : book[m][p] = 0 /\ share[m][p] = 0

OneHandOnTheBook ==
    book' # book =>
        /\ \E m \in Members, p \in Products :
                /\ phase[p] = "open"
                /\ book'[m][p] # book[m][p]
                /\ \A mm \in Members, pp \in Products :
                        (mm # m \/ pp # p) => book'[mm][pp] = book[mm][pp]
        /\ UNCHANGED <<phase, share>>

ThresholdAtPlacement ==
    \A p \in Products :
        (phase[p] = "open" /\ phase'[p] = "placed") => Total(p) >= Min

SnapshotAtPlacement ==
    \A p \in Products :
        (phase[p] = "open" /\ phase'[p] = "placed") =>
            /\ \A m \in Members : share'[m][p] = book[m][p]
            /\ \A m \in Members, pp \in Products :
                    pp # p => share'[m][pp] = share[m][pp]

SharesMoveTwoWays ==
    \A m \in Members, p \in Products :
        share'[m][p] # share[m][p] =>
            \/ /\ phase[p] = "open" /\ phase'[p] = "placed"
               /\ share[m][p] = 0
               /\ share'[m][p] = book[m][p]
            \/ /\ phase[p] = "arrived"
               /\ share[m][p] > 0
               /\ share'[m][p] = 0
               /\ UNCHANGED <<phase, book>>
               /\ \A mm \in Members, pp \in Products :
                        (mm # m \/ pp # p) => share'[mm][pp] = share[mm][pp]

PhasesRunForward ==
    /\ \A p \in Products :
            phase'[p] # phase[p] =>
                /\ \/ phase[p] = "open" /\ phase'[p] = "placed"
                   \/ phase[p] = "placed" /\ phase'[p] = "arrived"
                /\ \A pp \in Products : pp # p => phase'[pp] = phase[pp]
                /\ UNCHANGED book
    /\ \A p \in Products :
            (phase[p] = "placed" /\ phase'[p] = "arrived") => UNCHANGED share

OneHandAtATime == [][OneHandOnTheBook]_vars

Threshold == [][ThresholdAtPlacement]_vars

Snapshot == [][SnapshotAtPlacement]_vars

TwoWaysOnly == [][SharesMoveTwoWays]_vars

ForwardPhases == [][PhasesRunForward]_vars

DeliveryComes ==
    \A p \in Products : (phase[p] = "placed") ~> (phase[p] = "arrived")

=============================================================================
