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
\* BEGIN TRANSLATION (chksum(pcal) = "1456d87f" /\ chksum(tla) = "77edd16c"  )
VARIABLES orderId, orderQty, orderPaid, orderShipped, pc

(* define statement *)
TypeOK ==
  /\ orderId \in 0..2
  /\ orderQty \in 0..3
  /\ orderPaid \in BOOLEAN
  /\ orderShipped \in BOOLEAN


NoUnpaidShip == orderShipped => orderPaid


vars == << orderId, orderQty, orderPaid, orderShipped, pc >>

ProcSet == {"Clerk"}

Init == (* Global variables *)
        /\ orderId = 0
        /\ orderQty = 0
        /\ orderPaid = FALSE
        /\ orderShipped = FALSE
        /\ pc = [self \in ProcSet |-> "place"]

place == /\ pc["Clerk"] = "place"
         /\ orderId' = 1
         /\ orderQty' = 2
         /\ pc' = [pc EXCEPT !["Clerk"] = "pay"]
         /\ UNCHANGED << orderPaid, orderShipped >>

pay == /\ pc["Clerk"] = "pay"
       /\ orderPaid' = TRUE
       /\ pc' = [pc EXCEPT !["Clerk"] = "ship"]
       /\ UNCHANGED << orderId, orderQty, orderShipped >>

ship == /\ pc["Clerk"] = "ship"
        /\ orderShipped' = TRUE
        /\ pc' = [pc EXCEPT !["Clerk"] = "Done"]
        /\ UNCHANGED << orderId, orderQty, orderPaid >>

clerk == place \/ pay \/ ship

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == clerk
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(clerk)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION
================================
