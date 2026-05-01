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
\* BEGIN TRANSLATION (chksum(pcal) = "de13f218" /\ chksum(tla) = "7c111f90")
VARIABLES readings, calibrated, pc

(* define statement *)
Stations == DOMAIN readings

TypeOK ==
  /\ \A s \in Stations : readings[s] \in 0..100
  /\ calibrated \in BOOLEAN
AllSame == \A s \in Stations : readings[s] = readings["north"]
DomainStable == Stations = {"north", "south", "east"}


vars == << readings, calibrated, pc >>

ProcSet == {"Weather"}

Init == (* Global variables *)
        /\ readings = [s \in {"north", "south", "east"} |-> 50]
        /\ calibrated = FALSE
        /\ pc = [self \in ProcSet |-> "measure"]

measure == /\ pc["Weather"] = "measure"
           /\ readings' = [s \in {"north", "south", "east"} |-> 65]
           /\ calibrated' = TRUE
           /\ pc' = [pc EXCEPT !["Weather"] = "Done"]

station == measure

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == station
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(station)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
