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
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
