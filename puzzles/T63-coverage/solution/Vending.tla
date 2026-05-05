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
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
