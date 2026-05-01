---- MODULE Split ----
\* Side B: read-and-increment SPLIT into two labels, with a temp.
\* Two clients each "read counter into local; write back local+1."
\* Because the two labels can interleave, the classic LOST UPDATE bug appears.
\* TLC will find a 5-state counterexample where final counter = 1, not 2.
EXTENDS Integers, TLC

(*--algorithm Split {
  variables counter = 0;

  define {
    TypeOK == counter \in 0..2
    Correct == (\A self \in {"A", "B"} : pc[self] = "Done") => counter = 2
  }

  fair process (client \in {"A", "B"})
    variables local = 0;
  {
    read:
      local := counter;
    write:
      counter := local + 1;
  }
}
*)
\* BEGIN TRANSLATION
VARIABLES counter, pc

(* define statement *)
TypeOK == counter \in 0..2
Correct == (\A self \in {"A", "B"} : pc[self] = "Done") => counter = 2

VARIABLE local

vars == << counter, pc, local >>

ProcSet == ({"A", "B"})

Init == (* Global variables *)
        /\ counter = 0
        (* Process client *)
        /\ local = [self \in {"A", "B"} |-> 0]
        /\ pc = [self \in ProcSet |-> "read"]

read(self) == /\ pc[self] = "read"
              /\ local' = [local EXCEPT ![self] = counter]
              /\ pc' = [pc EXCEPT ![self] = "write"]
              /\ UNCHANGED counter

write(self) == /\ pc[self] = "write"
               /\ counter' = local[self] + 1
               /\ pc' = [pc EXCEPT ![self] = "Done"]
               /\ local' = local

client(self) == read(self) \/ write(self)

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
