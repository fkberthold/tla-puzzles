---- MODULE Scattered ----
\* Side A: each piece of state is its own variable.
\* The same Order modeled as four independent variables.
EXTENDS Integers, TLC

(*--algorithm Scattered {
  variables
    orderId = 0,
    orderQty = 0,
    orderPaid = FALSE,
    orderShipped = FALSE;

  define {
    TypeOK ==
      /\ orderId \in 0..2
      /\ orderQty \in 0..3
      /\ orderPaid \in BOOLEAN
      /\ orderShipped \in BOOLEAN

    \* Business rule: never ship an unpaid order.
    NoUnpaidShip == orderShipped => orderPaid
  }

  fair process (clerk = "Clerk") {
    place:
      orderId := 1;
      orderQty := 2;
    pay:
      orderPaid := TRUE;
    ship:
      orderShipped := TRUE;
  }
}
*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
