---- MODULE Clicks ----
EXTENDS Integers, TLC

(*--algorithm Clicks {
  variables
    clicks = [u \in {"u1", "u2", "u3"} |-> 0],
    step = 0;

  define {
    Users == DOMAIN clicks
    Total == clicks["u1"] + clicks["u2"] + clicks["u3"]

    TypeOK ==
      /\ Users = {"u1", "u2", "u3"}
      /\ \A u \in Users : clicks[u] \in 0..2
      /\ step \in 0..4
    TotalEqualsStep == Total = step
    EndsCorrect == step = 4 =>
      (clicks["u1"] = 2 /\ clicks["u2"] = 1 /\ clicks["u3"] = 1)
  }

  fair process (dashboard = "Dash") {
    clickU1:
      clicks := [clicks EXCEPT !["u1"] = @ + 1];
      step := step + 1;
    clickU2:
      clicks := [clicks EXCEPT !["u2"] = @ + 1];
      step := step + 1;
    clickU1again:
      clicks := [clicks EXCEPT !["u1"] = @ + 1];
      step := step + 1;
    clickU3:
      clicks := [clicks EXCEPT !["u3"] = @ + 1];
      step := step + 1;
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "b3910244" /\ chksum(tla) = "d17e70df")
VARIABLES clicks, step, pc

(* define statement *)
Users == DOMAIN clicks
Total == clicks["u1"] + clicks["u2"] + clicks["u3"]

TypeOK ==
  /\ Users = {"u1", "u2", "u3"}
  /\ \A u \in Users : clicks[u] \in 0..2
  /\ step \in 0..4
TotalEqualsStep == Total = step
EndsCorrect == step = 4 =>
  (clicks["u1"] = 2 /\ clicks["u2"] = 1 /\ clicks["u3"] = 1)


vars == << clicks, step, pc >>

ProcSet == {"Dash"}

Init == (* Global variables *)
        /\ clicks = [u \in {"u1", "u2", "u3"} |-> 0]
        /\ step = 0
        /\ pc = [self \in ProcSet |-> "clickU1"]

clickU1 == /\ pc["Dash"] = "clickU1"
           /\ clicks' = [clicks EXCEPT !["u1"] = @ + 1]
           /\ step' = step + 1
           /\ pc' = [pc EXCEPT !["Dash"] = "clickU2"]

clickU2 == /\ pc["Dash"] = "clickU2"
           /\ clicks' = [clicks EXCEPT !["u2"] = @ + 1]
           /\ step' = step + 1
           /\ pc' = [pc EXCEPT !["Dash"] = "clickU1again"]

clickU1again == /\ pc["Dash"] = "clickU1again"
                /\ clicks' = [clicks EXCEPT !["u1"] = @ + 1]
                /\ step' = step + 1
                /\ pc' = [pc EXCEPT !["Dash"] = "clickU3"]

clickU3 == /\ pc["Dash"] = "clickU3"
           /\ clicks' = [clicks EXCEPT !["u3"] = @ + 1]
           /\ step' = step + 1
           /\ pc' = [pc EXCEPT !["Dash"] = "Done"]

dashboard == clickU1 \/ clickU2 \/ clickU1again \/ clickU3

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == dashboard
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(dashboard)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
