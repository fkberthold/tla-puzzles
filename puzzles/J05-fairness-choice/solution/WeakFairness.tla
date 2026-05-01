---- MODULE WeakFairness ----
\* Side B: weak fairness. The process eventually takes a step
\* if it remains continuously enabled.
\* Same coffee machine — now brewing is guaranteed.
EXTENDS Integers, TLC

(*--algorithm WeakFairness {
  variables brewed = FALSE;

  define {
    TypeOK == brewed \in BOOLEAN
    EventuallyBrewed == <>(brewed = TRUE)
  }

  fair process (machine = "Machine") {
    brew:
      brewed := TRUE;
  }
}
*)
\* BEGIN TRANSLATION
VARIABLES brewed, pc

(* define statement *)
TypeOK == brewed \in BOOLEAN
EventuallyBrewed == <>(brewed = TRUE)


vars == << brewed, pc >>

ProcSet == {"Machine"}

Init == (* Global variables *)
        /\ brewed = FALSE
        /\ pc = [self \in ProcSet |-> "brew"]

brew == /\ pc["Machine"] = "brew"
        /\ brewed' = TRUE
        /\ pc' = [pc EXCEPT !["Machine"] = "Done"]

machine == brew

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == machine
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(machine)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION
================================
