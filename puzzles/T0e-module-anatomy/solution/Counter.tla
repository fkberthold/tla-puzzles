---- MODULE Counter ----
EXTENDS Integers

(*--algorithm Counter {
  variables n = 0;

  define {
    TypeOK == n \in 0..3
  }

  fair process (counter = "Counter") {
    bump:
      while (n < 3) {
        n := n + 1;
      }
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "2f0377de" /\ chksum(tla) = "de1f2187")
VARIABLES n, pc

(* define statement *)
TypeOK == n \in 0..3


vars == << n, pc >>

ProcSet == {"Counter"}

Init == (* Global variables *)
        /\ n = 0
        /\ pc = [self \in ProcSet |-> "bump"]

bump == /\ pc["Counter"] = "bump"
        /\ IF n < 3
              THEN /\ n' = n + 1
                   /\ pc' = [pc EXCEPT !["Counter"] = "bump"]
              ELSE /\ pc' = [pc EXCEPT !["Counter"] = "Done"]
                   /\ n' = n

counter == bump

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == counter
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(counter)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
====
