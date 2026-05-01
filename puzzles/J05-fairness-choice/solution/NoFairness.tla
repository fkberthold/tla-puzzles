---- MODULE NoFairness ----
\* Side A: no fairness. Spec admits behaviors that stutter forever.
\* A coffee machine that should eventually brew, but with no fairness it can stall.
EXTENDS Integers, TLC

(*--algorithm NoFairness {
  variables brewed = FALSE;

  define {
    TypeOK == brewed \in BOOLEAN
    EventuallyBrewed == <>(brewed = TRUE)
  }

  process (machine = "Machine") {
    brew:
      brewed := TRUE;
  }
}
*)
\* BEGIN TRANSLATION
VARIABLES pc, brewed

(* define statement *)
TypeOK == brewed \in BOOLEAN
EventuallyBrewed == <>(brewed = TRUE)


vars == << pc, brewed >>

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

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION
================================
