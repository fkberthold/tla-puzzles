---- MODULE Lockers ----
EXTENDS TLC

Members == {"Anna", "Ben", "Cleo"}

(*--algorithm Lockers {
  variables locker = [m \in Members |-> "closed"];

  define {
    TypeOK == \A m \in Members : locker[m] \in {"open", "closed"}
    DoneImpliesClosed ==
      \A m \in Members : pc[m] = "Done" => locker[m] = "closed"
  }

  fair process (member \in Members) {
    open:
      locker[self] := "open";
    use:
      skip;
    close:
      locker[self] := "closed";
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "f799b74d" /\ chksum(tla) = "ef3ac52")
VARIABLES pc, locker

(* define statement *)
TypeOK == \A m \in Members : locker[m] \in {"open", "closed"}
DoneImpliesClosed ==
  \A m \in Members : pc[m] = "Done" => locker[m] = "closed"


vars == << pc, locker >>

ProcSet == (Members)

Init == (* Global variables *)
        /\ locker = [m \in Members |-> "closed"]
        /\ pc = [self \in ProcSet |-> "open"]

open(self) == /\ pc[self] = "open"
              /\ locker' = [locker EXCEPT ![self] = "open"]
              /\ pc' = [pc EXCEPT ![self] = "use"]

use(self) == /\ pc[self] = "use"
             /\ TRUE
             /\ pc' = [pc EXCEPT ![self] = "close"]
             /\ UNCHANGED locker

close(self) == /\ pc[self] = "close"
               /\ locker' = [locker EXCEPT ![self] = "closed"]
               /\ pc' = [pc EXCEPT ![self] = "Done"]

member(self) == open(self) \/ use(self) \/ close(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Members: member(self))
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in Members : WF_vars(member(self))

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
