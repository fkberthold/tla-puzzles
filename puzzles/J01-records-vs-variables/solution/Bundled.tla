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
\* BEGIN TRANSLATION (chksum(pcal) = "ce70e293" /\ chksum(tla) = "66bbbc0e"  )
VARIABLES order, pc

(* define statement *)
TypeOK ==
  /\ order.id \in 0..2
  /\ order.qty \in 0..3
  /\ order.paid \in BOOLEAN
  /\ order.shipped \in BOOLEAN

NoUnpaidShip == order.shipped => order.paid


vars == << order, pc >>

ProcSet == {"Clerk"}

Init == (* Global variables *)
        /\ order = [id |-> 0, qty |-> 0, paid |-> FALSE, shipped |-> FALSE]
        /\ pc = [self \in ProcSet |-> "place"]

place == /\ pc["Clerk"] = "place"
         /\ order' = [order EXCEPT !.id = 1, !.qty = 2]
         /\ pc' = [pc EXCEPT !["Clerk"] = "pay"]

pay == /\ pc["Clerk"] = "pay"
       /\ order' = [order EXCEPT !.paid = TRUE]
       /\ pc' = [pc EXCEPT !["Clerk"] = "ship"]

ship == /\ pc["Clerk"] = "ship"
        /\ order' = [order EXCEPT !.shipped = TRUE]
        /\ pc' = [pc EXCEPT !["Clerk"] = "Done"]

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
