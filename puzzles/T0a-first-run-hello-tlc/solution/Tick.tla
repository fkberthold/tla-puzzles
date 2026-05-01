---- MODULE Tick ----
EXTENDS Integers

(*--algorithm Tick {
  variables count = 0;

  define {
    TypeOK == count \in 0..3
  }

  fair process (clock = "Clock") {
    tick:
      while (count < 3) {
        count := count + 1;
      }
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "1a39b6d" /\ chksum(tla) = "38868998")
VARIABLES count, pc

(* define statement *)
TypeOK == count \in 0..3


vars == << count, pc >>

ProcSet == {"Clock"}

Init == (* Global variables *)
        /\ count = 0
        /\ pc = [self \in ProcSet |-> "tick"]

tick == /\ pc["Clock"] = "tick"
        /\ IF count < 3
              THEN /\ count' = count + 1
                   /\ pc' = [pc EXCEPT !["Clock"] = "tick"]
              ELSE /\ pc' = [pc EXCEPT !["Clock"] = "Done"]
                   /\ count' = count

clock == tick

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == clock
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(clock)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
====
