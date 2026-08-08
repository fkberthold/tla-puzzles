---------------------------- MODULE Consign ----------------------------
EXTENDS Naturals, FiniteSets

CONSTANTS Owners, Items, OwnerOf, Floor

ASSUME OwnerOf \in [Items -> Owners]
ASSUME Floor \in Nat

VARIABLE standing

Standings == {"unlisted", "listed", "returned", "sold", "settled"}

Listed == {i \in Items : standing[i] = "listed"}

SoldOf(o) == {i \in Items : OwnerOf[i] = o /\ standing[i] = "sold"}

Observe == [standing |-> standing]

Init == standing = [i \in Items |-> "unlisted"]

Intake(i) ==
    /\ standing[i] = "unlisted"
    /\ Cardinality(Listed) < Floor
    /\ standing' = [standing EXCEPT ![i] = "listed"]

Sell(i) ==
    /\ standing[i] = "listed"
    /\ standing' = [standing EXCEPT ![i] = "sold"]

GoHome(i) ==
    /\ standing[i] = "listed"
    /\ standing' = [standing EXCEPT ![i] = "returned"]

Settle(o) ==
    /\ SoldOf(o) # {}
    /\ standing' = [i \in Items |-> IF i \in SoldOf(o) THEN "settled" ELSE standing[i]]

Next ==
    \/ \E i \in Items : Intake(i) \/ Sell(i) \/ GoHome(i)
    \/ \E o \in Owners : Settle(o)

Spec == Init /\ [][Next]_standing

OneStandingEach == standing \in [Items -> Standings]

FloorCap == Cardinality(Listed) <= Floor

OpeningAllUnlisted == \A i \in Items : standing[i] = "unlisted"

LawfulMove(a, b) ==
    \/ a = b
    \/ a = "unlisted" /\ b = "listed"
    \/ a = "listed" /\ b \in {"returned", "sold"}
    \/ a = "sold" /\ b = "settled"

LawfulPath == [][\A i \in Items : LawfulMove(standing[i], standing'[i])]_standing

Changed == {i \in Items : standing'[i] # standing[i]}

SingleStep ==
    \E i \in Items :
        /\ Changed = {i}
        /\ ~(standing[i] = "sold" /\ standing'[i] = "settled")

SettlementStep ==
    \E o \in Owners :
        /\ SoldOf(o) # {}
        /\ Changed = SoldOf(o)
        /\ \A i \in SoldOf(o) : standing'[i] = "settled"

SingleStepOrSettlement == [][SingleStep \/ SettlementStep]_standing

=========================================================================
