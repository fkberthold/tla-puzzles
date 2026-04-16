---- MODULE OffByOne ----
EXTENDS Integers, TLC

(*--algorithm OffByOne {
  variables count = 3, done = FALSE;

  define {
    TypeOK == count \in 0..3 /\ done \in {TRUE, FALSE}
    DoneImpliesZero == done = TRUE => count = 0
  }

  fair process (counter = "Counter") {
    loop:
      \* BUG: loop exits when count > 0 is false, i.e., count = 0
      \* But we decrement FIRST, so we go 3->2->1->0 then exit
      \* and set done. Actually that's correct...
      \* The real bug: use count > 1 as condition — exits at count=1
      while (count > 1) {
        count := count - 1;
      };
    finish:
      done := TRUE;
      \* BUG: count is 1 here, not 0!
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "e6e155ad" /\ chksum(tla) = "b5377eaa")
VARIABLES pc, count, done

(* define statement *)
TypeOK == count \in 0..3 /\ done \in {TRUE, FALSE}
DoneImpliesZero == done = TRUE => count = 0


vars == << pc, count, done >>

ProcSet == {"Counter"}

Init == (* Global variables *)
        /\ count = 3
        /\ done = FALSE
        /\ pc = [self \in ProcSet |-> "loop"]

loop == /\ pc["Counter"] = "loop"
        /\ IF count > 1
              THEN /\ count' = count - 1
                   /\ pc' = [pc EXCEPT !["Counter"] = "loop"]
              ELSE /\ pc' = [pc EXCEPT !["Counter"] = "finish"]
                   /\ count' = count
        /\ done' = done

finish == /\ pc["Counter"] = "finish"
          /\ done' = TRUE
          /\ pc' = [pc EXCEPT !["Counter"] = "Done"]
          /\ count' = count

counter == loop \/ finish

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == counter
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(counter)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 

================================
