---- MODULE Interleave ----
EXTENDS Naturals, FiniteSets

CONSTANT Worker

(* --algorithm interleave {
     variables counter = 0;
     fair process (w \in Worker)
       variable seen = 0;
     { read:  seen := counter;
       write: counter := seen + 1 }
   } *)
\* BEGIN TRANSLATION (chksum(pcal) = "61fd2955" /\ chksum(tla) = "c988837e")
VARIABLES pc, counter, seen

vars == << pc, counter, seen >>

ProcSet == (Worker)

Init == (* Global variables *)
        /\ counter = 0
        (* Process w *)
        /\ seen = [self \in Worker |-> 0]
        /\ pc = [self \in ProcSet |-> "read"]

read(self) == /\ pc[self] = "read"
              /\ seen' = [seen EXCEPT ![self] = counter]
              /\ pc' = [pc EXCEPT ![self] = "write"]
              /\ UNCHANGED counter

write(self) == /\ pc[self] = "write"
               /\ counter' = seen[self] + 1
               /\ pc' = [pc EXCEPT ![self] = "Done"]
               /\ seen' = seen

w(self) == read(self) \/ write(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Worker: w(self))
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in Worker : WF_vars(w(self))

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 

TypeOK ==
  /\ counter \in 0..Cardinality(Worker)
  /\ seen \in [Worker -> 0..Cardinality(Worker)]
  /\ pc \in [Worker -> {"read", "write", "Done"}]

AtLeastOne == (\A p \in ProcSet : pc[p] = "Done") => counter >= 1
====
