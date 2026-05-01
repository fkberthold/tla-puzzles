---- MODULE Battery ----
EXTENDS Integers

(*--algorithm Battery {
  variables charge = 3;

  define {
    TypeOK == charge \in 0..3
    StaysCharged == charge > 0
  }

  fair process (drain = "Drain") {
    deplete:
      while (charge > 0) {
        charge := charge - 1;
      }
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "8b960d87" /\ chksum(tla) = "34624bed")
VARIABLES pc, charge

(* define statement *)
TypeOK == charge \in 0..3
StaysCharged == charge > 0


vars == << pc, charge >>

ProcSet == {"Drain"}

Init == (* Global variables *)
        /\ charge = 3
        /\ pc = [self \in ProcSet |-> "deplete"]

deplete == /\ pc["Drain"] = "deplete"
           /\ IF charge > 0
                 THEN /\ charge' = charge - 1
                      /\ pc' = [pc EXCEPT !["Drain"] = "deplete"]
                 ELSE /\ pc' = [pc EXCEPT !["Drain"] = "Done"]
                      /\ UNCHANGED charge

drain == deplete

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == drain
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(drain)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
====
