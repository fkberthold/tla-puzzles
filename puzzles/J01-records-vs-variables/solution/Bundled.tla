---- MODULE Bundled ----
\* Side B: a single record variable holds all four fields.
\* Same Order, modeled as one record.
EXTENDS Integers, TLC

(*--algorithm Bundled {
  variables
    order = [id |-> 0, qty |-> 0, paid |-> FALSE, shipped |-> FALSE];

  define {
    TypeOK ==
      /\ order.id \in 0..2
      /\ order.qty \in 0..3
      /\ order.paid \in BOOLEAN
      /\ order.shipped \in BOOLEAN

    NoUnpaidShip == order.shipped => order.paid
  }

  fair process (clerk = "Clerk") {
    place:
      order := [order EXCEPT !.id = 1, !.qty = 2];
    pay:
      order := [order EXCEPT !.paid = TRUE];
    ship:
      order := [order EXCEPT !.shipped = TRUE];
  }
}
*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
