---- MODULE Chef ----
EXTENDS TLC

(*--algorithm Chef {
  variables plated = [c \in {"Alice", "Bob", "Carol"} |-> FALSE];

  define {
    Chefs == {"Alice", "Bob", "Carol"}
    TypeOK == plated \in [Chefs -> BOOLEAN]
    EveryoneEventuallyPlates == \A c \in Chefs : <>(plated[c] = TRUE)
  }

  fair process (chef \in {"Alice", "Bob", "Carol"}) {
    plate:
      plated[self] := TRUE;
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "6be3d2ad" /\ chksum(tla) = "b19a29d3")
VARIABLES pc, plated

(* define statement *)
Chefs == {"Alice", "Bob", "Carol"}
TypeOK == plated \in [Chefs -> BOOLEAN]
EveryoneEventuallyPlates == \A c \in Chefs : <>(plated[c] = TRUE)


vars == << pc, plated >>

ProcSet == ({"Alice", "Bob", "Carol"})

Init == (* Global variables *)
        /\ plated = [c \in {"Alice", "Bob", "Carol"} |-> FALSE]
        /\ pc = [self \in ProcSet |-> "plate"]

plate(self) == /\ pc[self] = "plate"
               /\ plated' = [plated EXCEPT ![self] = TRUE]
               /\ pc' = [pc EXCEPT ![self] = "Done"]

chef(self) == plate(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in {"Alice", "Bob", "Carol"}: chef(self))
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in {"Alice", "Bob", "Carol"} : WF_vars(chef(self))

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
