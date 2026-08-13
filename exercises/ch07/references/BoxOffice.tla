---- MODULE BoxOffice ----
\* Exercise 4 reference answer.
\*
\* Orders arrive from outside the system, so the spec does not pick one. It
\* pulls a whole order out of `OrderType` and has to cope with whatever comes.
\* Every seat count and every tier is covered by the one run.
EXTENDS Integers

CONSTANT Capacity

MaxSeats == 2
MaxOrders == 2

Tiers == {"stalls", "circle"}

OrderType == [seats: 1..MaxSeats, tier: Tiers]

(*--algorithm boxoffice {
  variables
    sold = [t \in Tiers |-> 0],
    served = 0;

  define {
    TypeOK == sold \in [Tiers -> 0..Capacity]

    NeverOversold == \A t \in Tiers : sold[t] <= Capacity
  }

  {
    Serve:
      while (served < MaxOrders) {
        with (order \in OrderType) {
          if (sold[order.tier] + order.seats <= Capacity) {
            sold[order.tier] := sold[order.tier] + order.seats;
          } else {
            \* No room in that tier. The order is turned away.
            skip;
          };
        };
        served := served + 1;
      };
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "a14bc288" /\ chksum(tla) = "fad51b8a")
VARIABLES pc, sold, served

(* define statement *)
TypeOK == sold \in [Tiers -> 0..Capacity]

NeverOversold == \A t \in Tiers : sold[t] <= Capacity


vars == << pc, sold, served >>

Init == (* Global variables *)
        /\ sold = [t \in Tiers |-> 0]
        /\ served = 0
        /\ pc = "Serve"

Serve == /\ pc = "Serve"
         /\ IF served < MaxOrders
               THEN /\ \E order \in OrderType:
                         IF sold[order.tier] + order.seats <= Capacity
                            THEN /\ sold' = [sold EXCEPT ![order.tier] = sold[order.tier] + order.seats]
                            ELSE /\ TRUE
                                 /\ sold' = sold
                    /\ served' = served + 1
                    /\ pc' = "Serve"
               ELSE /\ pc' = "Done"
                    /\ UNCHANGED << sold, served >>

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Serve
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 
====
