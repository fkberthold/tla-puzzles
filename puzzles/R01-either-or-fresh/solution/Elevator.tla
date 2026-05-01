---- MODULE Elevator ----
EXTENDS Integers, TLC

(*--algorithm Elevator {
  variables floor = 0, doors = "closed";

  define {
    TypeOK == floor \in {0, 1, 5} /\ doors \in {"closed", "open"}
    AlwaysOffice == floor /= 1  \* This WILL be violated!
    EventuallyOpen == <>(doors = "open")
  }

  fair process (elevator = "Car") {
    travel:
      either {
        floor := 1;
      } or {
        floor := 5;
      };
    arrive:
      doors := "open";
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "9b6c8622" /\ chksum(tla) = "c8d01418")
VARIABLES floor, doors, pc

(* define statement *)
TypeOK == floor \in {0, 1, 5} /\ doors \in {"closed", "open"}
AlwaysOffice == floor /= 1
EventuallyOpen == <>(doors = "open")


vars == << floor, doors, pc >>

ProcSet == {"Car"}

Init == (* Global variables *)
        /\ floor = 0
        /\ doors = "closed"
        /\ pc = [self \in ProcSet |-> "travel"]

travel == /\ pc["Car"] = "travel"
          /\ \/ /\ floor' = 1
             \/ /\ floor' = 5
          /\ pc' = [pc EXCEPT !["Car"] = "arrive"]
          /\ doors' = doors

arrive == /\ pc["Car"] = "arrive"
          /\ doors' = "open"
          /\ pc' = [pc EXCEPT !["Car"] = "Done"]
          /\ floor' = floor

elevator == travel \/ arrive

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == elevator
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(elevator)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
