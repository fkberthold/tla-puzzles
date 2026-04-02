---- MODULE TollBooth ----
EXTENDS Integers, TLC

(*--algorithm TollBooth {
  variables paid = 0, gate = "closed";

  define {
    TypeOK ==
      /\ paid \in 0..100
      /\ gate \in {"open", "closed"}
    GateEventuallyOpens == <>(gate = "open")
  }

  fair process (driver = "Driver") {
    insert:
      while (gate = "closed") {
        either {
          paid := paid + 25;
        } or {
          paid := paid + 10;
        };
        assert paid <= 100;
        if (paid >= 50) {
          gate := "open";
        };
      }
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "8486cdc5" /\ chksum(tla) = "eda422f8")
VARIABLES paid, gate, pc

(* define statement *)
TypeOK ==
  /\ paid \in 0..100
  /\ gate \in {"open", "closed"}
GateEventuallyOpens == <>(gate = "open")


vars == << paid, gate, pc >>

ProcSet == {"Driver"}

Init == (* Global variables *)
        /\ paid = 0
        /\ gate = "closed"
        /\ pc = [self \in ProcSet |-> "insert"]

insert == /\ pc["Driver"] = "insert"
          /\ IF gate = "closed"
                THEN /\ \/ /\ paid' = paid + 25
                        \/ /\ paid' = paid + 10
                     /\ Assert(paid' <= 100, 
                               "Failure of assertion at line 22, column 9.")
                     /\ IF paid' >= 50
                           THEN /\ gate' = "open"
                           ELSE /\ TRUE
                                /\ gate' = gate
                     /\ pc' = [pc EXCEPT !["Driver"] = "insert"]
                ELSE /\ pc' = [pc EXCEPT !["Driver"] = "Done"]
                     /\ UNCHANGED << paid, gate >>

driver == insert

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == driver
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(driver)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 

================================
