---- MODULE Weather ----
EXTENDS Integers, TLC

(*--algorithm Weather {
  variables
    readings = [s \in {"north", "south", "east"} |-> 50],
    calibrated = FALSE;

  define {
    Stations == DOMAIN readings

    TypeOK ==
      /\ \A s \in Stations : readings[s] \in 0..100
      /\ calibrated \in BOOLEAN
    AllSame == \A s \in Stations : readings[s] = readings["north"]
    DomainStable == Stations = {"north", "south", "east"}
  }

  fair process (station = "Weather") {
    measure:
      readings := [s \in {"north", "south", "east"} |-> 65];
      calibrated := TRUE;
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
