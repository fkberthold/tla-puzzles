---- MODULE Atomic ----
\* Side A: read-and-increment fused into ONE label.
\* Two clients each increment a shared counter once.
\* Because read+write happens in one atomic step, no lost updates: final = 2.
EXTENDS Integers, TLC

(*--algorithm Atomic {
  variables counter = 0;

  define {
    TypeOK == counter \in 0..2
    \* The expected final-state property: after both clients are done, counter = 2.
    Correct == (\A self \in {"A", "B"} : pc[self] = "Done") => counter = 2
  }

  fair process (client \in {"A", "B"}) {
    bump:
      counter := counter + 1;
  }
}
*)
\* BEGIN TRANSLATION
VARIABLES pc, counter

(* define statement *)
TypeOK == counter \in 0..2

Correct == (\A self \in {"A", "B"} : pc[self] = "Done") => counter = 2


vars == << pc, counter >>

ProcSet == ({"A", "B"})

Init == (* Global variables *)
        /\ counter = 0
        /\ pc = [self \in ProcSet |-> "bump"]

bump(self) == /\ pc[self] = "bump"
              /\ counter' = counter + 1
              /\ pc' = [pc EXCEPT ![self] = "Done"]

client(self) == bump(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in {"A", "B"}: client(self))
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in {"A", "B"} : WF_vars(client(self))

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION
================================
