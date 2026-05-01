---- MODULE Vending ----
EXTENDS Integers, TLC

(*--algorithm Vending {
  variables coins = 0, items = 3;

  define {
    TypeOK == coins \in 0..2 /\ items \in 0..3
  }

  \* Three concurrent processes: insert a coin, buy an item, refund 5 coins.
  \* The Refund process can never fire because coins is bounded above by 2.

  fair process (inserter = "Inserter") {
    insertLoop:
      while (items > 0) {
        await coins < 2;
        coins := coins + 1;
      };
  }

  fair process (buyer = "Buyer") {
    buyLoop:
      while (items > 0) {
        await coins >= 1 /\ items > 0;
        coins := coins - 1;
        items := items - 1;
      };
  }

  fair process (refunder = "Refunder") {
    refundLoop:
      while (items > 0) {
        await coins >= 5;
        coins := coins - 5;
      };
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "5ef5a373" /\ chksum(tla) = "6a489ce0")
VARIABLES pc, coins, items

(* define statement *)
TypeOK == coins \in 0..2 /\ items \in 0..3


vars == << pc, coins, items >>

ProcSet == {"Inserter"} \cup {"Buyer"} \cup {"Refunder"}

Init == (* Global variables *)
        /\ coins = 0
        /\ items = 3
        /\ pc = [self \in ProcSet |-> CASE self = "Inserter" -> "insertLoop"
                                        [] self = "Buyer" -> "buyLoop"
                                        [] self = "Refunder" -> "refundLoop"]

insertLoop == /\ pc["Inserter"] = "insertLoop"
              /\ IF items > 0
                    THEN /\ coins < 2
                         /\ coins' = coins + 1
                         /\ pc' = [pc EXCEPT !["Inserter"] = "insertLoop"]
                    ELSE /\ pc' = [pc EXCEPT !["Inserter"] = "Done"]
                         /\ coins' = coins
              /\ items' = items

inserter == insertLoop

buyLoop == /\ pc["Buyer"] = "buyLoop"
           /\ IF items > 0
                 THEN /\ coins >= 1 /\ items > 0
                      /\ coins' = coins - 1
                      /\ items' = items - 1
                      /\ pc' = [pc EXCEPT !["Buyer"] = "buyLoop"]
                 ELSE /\ pc' = [pc EXCEPT !["Buyer"] = "Done"]
                      /\ UNCHANGED << coins, items >>

buyer == buyLoop

refundLoop == /\ pc["Refunder"] = "refundLoop"
              /\ IF items > 0
                    THEN /\ coins >= 5
                         /\ coins' = coins - 5
                         /\ pc' = [pc EXCEPT !["Refunder"] = "refundLoop"]
                    ELSE /\ pc' = [pc EXCEPT !["Refunder"] = "Done"]
                         /\ coins' = coins
              /\ items' = items

refunder == refundLoop

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == inserter \/ buyer \/ refunder
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(inserter)
        /\ WF_vars(buyer)
        /\ WF_vars(refunder)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION
================================
