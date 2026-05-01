---- MODULE Delivery ----
EXTENDS Integers, TLC

(*--algorithm Delivery {
  variables
    last = [address |-> 0, kind |-> "depot"],
    stops = 0,
    holding = FALSE;

  define {
    IsPickup == last.kind = "pickup"
    IsDropoff == last.kind = "dropoff"
    AtDepot == last.address = 0
    ValidAddress(s) == s.address \in 0..5
    ValidKind(s) == s.kind \in {"depot", "pickup", "dropoff"}

    TypeOK ==
      /\ ValidAddress(last)
      /\ ValidKind(last)
      /\ stops \in 0..4
      /\ holding \in BOOLEAN
    PickupImpliesHolding == IsPickup => holding
    NeverDropoffEmpty == IsDropoff => holding  \* This WILL be violated!
  }

  fair process (van = "Van") {
    drive:
      while (stops < 4) {
        with (a \in 1..5) {
          with (k \in {"pickup", "dropoff"}) {
            last := [address |-> a, kind |-> k];
            holding := (k = "pickup");
          };
        };
        stops := stops + 1;
      }
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "37144149" /\ chksum(tla) = "cb5a62c5")
VARIABLES last, stops, holding, pc

(* define statement *)
IsPickup == last.kind = "pickup"
IsDropoff == last.kind = "dropoff"
AtDepot == last.address = 0
ValidAddress(s) == s.address \in 0..5
ValidKind(s) == s.kind \in {"depot", "pickup", "dropoff"}

TypeOK ==
  /\ ValidAddress(last)
  /\ ValidKind(last)
  /\ stops \in 0..4
  /\ holding \in BOOLEAN
PickupImpliesHolding == IsPickup => holding
NeverDropoffEmpty == IsDropoff => holding


vars == << last, stops, holding, pc >>

ProcSet == {"Van"}

Init == (* Global variables *)
        /\ last = [address |-> 0, kind |-> "depot"]
        /\ stops = 0
        /\ holding = FALSE
        /\ pc = [self \in ProcSet |-> "drive"]

drive == /\ pc["Van"] = "drive"
         /\ IF stops < 4
               THEN /\ \E a \in 1..5:
                         \E k \in {"pickup", "dropoff"}:
                           /\ last' = [address |-> a, kind |-> k]
                           /\ holding' = (k = "pickup")
                    /\ stops' = stops + 1
                    /\ pc' = [pc EXCEPT !["Van"] = "drive"]
               ELSE /\ pc' = [pc EXCEPT !["Van"] = "Done"]
                    /\ UNCHANGED << last, stops, holding >>

van == drive

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == van
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(van)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
