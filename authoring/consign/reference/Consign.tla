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

(***************************************************************************)
(* Every obligation below reads the shop through Observe, never through    *)
(* the variable. The hand-off states all five over the observable of its   *)
(* section 3, and the grading engine builds a learner's score on the same  *)
(* operator, so an obligation that reads `standing` directly grades a      *)
(* different system from the one the interface publishes.                  *)
(*                                                                         *)
(* On this reference the two readings agree, because Observe.standing is   *)
(* standing. That agreement is what makes the raw form tempting and what   *)
(* makes it unsafe: a model whose Observe lies keeps every raw obligation  *)
(* green, and nothing downstream looks again.                              *)
(*                                                                         *)
(* The model half above still reads the variable. Only the obligations     *)
(* route through the operator. Routing the actions too would change the    *)
(* shop instead of what we check about it.                                 *)
(*                                                                         *)
(* Both action properties keep `_standing` as the subscript, and it has to *)
(* stay the raw variable. Under `[][...]_Observe` a model whose Observe    *)
(* never moves turns every step into a stutter, and the property passes    *)
(* without checking anything. The subscript picks which steps we grade.    *)
(* The body says what we grade about them.                                 *)
(***************************************************************************)

OneStandingEach == Observe.standing \in [Items -> Standings]

FloorCap == Cardinality({i \in Items : Observe.standing[i] = "listed"}) <= Floor

OpeningAllUnlisted == \A i \in Items : Observe.standing[i] = "unlisted"

LawfulMove(a, b) ==
    \/ a = b
    \/ a = "unlisted" /\ b = "listed"
    \/ a = "listed" /\ b \in {"returned", "sold"}
    \/ a = "sold" /\ b = "settled"

LawfulPath ==
    [][\A i \in Items :
          LawfulMove(Observe.standing[i], Observe'.standing[i])]_standing

Changed == {i \in Items : Observe'.standing[i] # Observe.standing[i]}

Owed(o) == {i \in Items : OwnerOf[i] = o /\ Observe.standing[i] = "sold"}

SingleStep ==
    \E i \in Items :
        /\ Changed = {i}
        /\ ~(Observe.standing[i] = "sold" /\ Observe'.standing[i] = "settled")

SettlementStep ==
    \E o \in Owners :
        /\ Owed(o) # {}
        /\ Changed = Owed(o)
        /\ \A i \in Owed(o) : Observe'.standing[i] = "settled"

SingleStepOrSettlement == [][SingleStep \/ SettlementStep]_standing

=========================================================================
