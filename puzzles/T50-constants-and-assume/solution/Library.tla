---- MODULE Library ----
EXTENDS Integers, TLC

CONSTANT Capacity

ASSUME Capacity \in Nat
ASSUME Capacity >= 1

(*--algorithm Library {
  variables books = Capacity, ops = 0;

  define {
    TypeOK == books \in 0..Capacity /\ ops \in 0..5
    Bounded == books >= 0 /\ books <= Capacity
  }

  fair process (clerk = "Clerk") {
    work:
      while (ops < 5) {
        either {
          await books > 0;
          books := books - 1;
        } or {
          await books < Capacity;
          books := books + 1;
        };
        ops := ops + 1;
      }
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "2387b07e" /\ chksum(tla) = "b6f8965b")
VARIABLES books, ops, pc

(* define statement *)
TypeOK == books \in 0..Capacity /\ ops \in 0..5
Bounded == books >= 0 /\ books <= Capacity


vars == << books, ops, pc >>

ProcSet == {"Clerk"}

Init == (* Global variables *)
        /\ books = Capacity
        /\ ops = 0
        /\ pc = [self \in ProcSet |-> "work"]

work == /\ pc["Clerk"] = "work"
        /\ IF ops < 5
              THEN /\ \/ /\ books > 0
                         /\ books' = books - 1
                      \/ /\ books < Capacity
                         /\ books' = books + 1
                   /\ ops' = ops + 1
                   /\ pc' = [pc EXCEPT !["Clerk"] = "work"]
              ELSE /\ pc' = [pc EXCEPT !["Clerk"] = "Done"]
                   /\ UNCHANGED << books, ops >>

clerk == work

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == clerk
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(clerk)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
====
