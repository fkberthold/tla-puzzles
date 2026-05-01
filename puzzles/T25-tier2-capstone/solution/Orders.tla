---- MODULE Orders ----
EXTENDS Integers, Sequences, FiniteSets, TLC

(*--algorithm Orders {
  variables
    orders = [c \in {"alice", "bob"} |->
                [id |-> IF c = "alice" THEN 1 ELSE 2,
                 cart |-> [i \in {"apple", "bread", "coffee"} |-> 0],
                 history |-> <<"opened">>]],
    summary = [total |-> 0, paidCustomers |-> {}, nPaid |-> 0, allItems |-> {}],
    phase = 0;

  define {
    Customers == {"alice", "bob"}
    Items == {"apple", "bread", "coffee"}
    Statuses == {"opened", "paid", "shipped"}
    PossibleQty == 0..10

    HasPaid(c) == \E k \in 1..Len(orders[c].history) : orders[c].history[k] = "paid"
    PaidSet == {c \in Customers : HasPaid(c)}

    TypeOK ==
      /\ \A c \in Customers :
           /\ orders[c].id \in 0..10
           /\ orders[c].cart \in [Items -> PossibleQty]
           /\ \A k \in 1..Len(orders[c].history) : orders[c].history[k] \in Statuses
      /\ summary.total \in 0..30
      /\ summary.paidCustomers \subseteq Customers
      /\ summary.nPaid \in 0..2
      /\ summary.allItems \subseteq Items
      /\ phase \in 0..3

    EveryCartItemIsKnown == \A c \in Customers : DOMAIN orders[c].cart = Items
    SomeoneHasOpened ==
      \E c \in Customers : \E k \in 1..Len(orders[c].history) : orders[c].history[k] = "opened"
    EndsCorrect ==
      phase = 3 =>
        /\ summary.total = 2
        /\ summary.paidCustomers = {"alice"}
        /\ summary.nPaid = 1
        /\ summary.allItems = {"apple"}
  }

  fair process (system = "Sys") {
    stockApple:
      orders := [orders EXCEPT !["alice"].cart = [@ EXCEPT !["apple"] = @ + 2]];
      phase := phase + 1;
    payAlice:
      orders := [orders EXCEPT !["alice"].history = Append(@, "paid")];
      phase := phase + 1;
    summarize:
      summary := LET aliceCart    == orders["alice"].cart
                     totalQty     == aliceCart["apple"] + aliceCart["bread"] + aliceCart["coffee"]
                     paid         == PaidSet
                     stockedAlice == {i \in Items : aliceCart[i] > 0}
                 IN [total |-> totalQty,
                     paidCustomers |-> paid,
                     nPaid |-> Cardinality(paid),
                     allItems |-> stockedAlice];
      phase := phase + 1;
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "3841ed17" /\ chksum(tla) = "7420988a")
VARIABLES pc, orders, summary, phase

(* define statement *)
Customers == {"alice", "bob"}
Items == {"apple", "bread", "coffee"}
Statuses == {"opened", "paid", "shipped"}
PossibleQty == 0..10

HasPaid(c) == \E k \in 1..Len(orders[c].history) : orders[c].history[k] = "paid"
PaidSet == {c \in Customers : HasPaid(c)}

TypeOK ==
  /\ \A c \in Customers :
       /\ orders[c].id \in 0..10
       /\ orders[c].cart \in [Items -> PossibleQty]
       /\ \A k \in 1..Len(orders[c].history) : orders[c].history[k] \in Statuses
  /\ summary.total \in 0..30
  /\ summary.paidCustomers \subseteq Customers
  /\ summary.nPaid \in 0..2
  /\ summary.allItems \subseteq Items
  /\ phase \in 0..3

EveryCartItemIsKnown == \A c \in Customers : DOMAIN orders[c].cart = Items
SomeoneHasOpened ==
  \E c \in Customers : \E k \in 1..Len(orders[c].history) : orders[c].history[k] = "opened"
EndsCorrect ==
  phase = 3 =>
    /\ summary.total = 2
    /\ summary.paidCustomers = {"alice"}
    /\ summary.nPaid = 1
    /\ summary.allItems = {"apple"}


vars == << pc, orders, summary, phase >>

ProcSet == {"Sys"}

Init == (* Global variables *)
        /\ orders = [c \in {"alice", "bob"} |->
                       [id |-> IF c = "alice" THEN 1 ELSE 2,
                        cart |-> [i \in {"apple", "bread", "coffee"} |-> 0],
                        history |-> <<"opened">>]]
        /\ summary = [total |-> 0, paidCustomers |-> {}, nPaid |-> 0, allItems |-> {}]
        /\ phase = 0
        /\ pc = [self \in ProcSet |-> "stockApple"]

stockApple == /\ pc["Sys"] = "stockApple"
              /\ orders' = [orders EXCEPT !["alice"].cart = [@ EXCEPT !["apple"] = @ + 2]]
              /\ phase' = phase + 1
              /\ pc' = [pc EXCEPT !["Sys"] = "payAlice"]
              /\ UNCHANGED summary

payAlice == /\ pc["Sys"] = "payAlice"
            /\ orders' = [orders EXCEPT !["alice"].history = Append(@, "paid")]
            /\ phase' = phase + 1
            /\ pc' = [pc EXCEPT !["Sys"] = "summarize"]
            /\ UNCHANGED summary

summarize == /\ pc["Sys"] = "summarize"
             /\ summary' = (LET aliceCart    == orders["alice"].cart
                                totalQty     == aliceCart["apple"] + aliceCart["bread"] + aliceCart["coffee"]
                                paid         == PaidSet
                                stockedAlice == {i \in Items : aliceCart[i] > 0}
                            IN [total |-> totalQty,
                                paidCustomers |-> paid,
                                nPaid |-> Cardinality(paid),
                                allItems |-> stockedAlice])
             /\ phase' = phase + 1
             /\ pc' = [pc EXCEPT !["Sys"] = "Done"]
             /\ UNCHANGED orders

system == stockApple \/ payAlice \/ summarize

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == system
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(system)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
