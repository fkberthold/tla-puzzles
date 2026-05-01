---- MODULE Printer ----
EXTENDS FiniteSets, Integers, TLC

(*--algorithm Printer {
  variables printerInUse = FALSE, printing = {};

  define {
    TypeOK ==
      /\ printerInUse \in BOOLEAN
      /\ printing \subseteq {"Alice", "Bob"}
    MutualExclusion == Cardinality(printing) <= 1
    FlagMatchesSet == printerInUse <=> (printing /= {})
  }

  fair process (user \in {"Alice", "Bob"}) {
    acquire:
      await ~printerInUse;
      printerInUse := TRUE;
      printing := printing \union {self};
    release:
      printing := printing \ {self};
      printerInUse := FALSE;
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "a1419c50" /\ chksum(tla) = "e7c8c6a9")
VARIABLES pc, printerInUse, printing

(* define statement *)
TypeOK ==
  /\ printerInUse \in BOOLEAN
  /\ printing \subseteq {"Alice", "Bob"}
MutualExclusion == Cardinality(printing) <= 1
FlagMatchesSet == printerInUse <=> (printing /= {})


vars == << pc, printerInUse, printing >>

ProcSet == ({"Alice", "Bob"})

Init == (* Global variables *)
        /\ printerInUse = FALSE
        /\ printing = {}
        /\ pc = [self \in ProcSet |-> "acquire"]

acquire(self) == /\ pc[self] = "acquire"
                 /\ ~printerInUse
                 /\ printerInUse' = TRUE
                 /\ printing' = (printing \union {self})
                 /\ pc' = [pc EXCEPT ![self] = "release"]

release(self) == /\ pc[self] = "release"
                 /\ printing' = printing \ {self}
                 /\ printerInUse' = FALSE
                 /\ pc' = [pc EXCEPT ![self] = "Done"]

user(self) == acquire(self) \/ release(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in {"Alice", "Bob"}: user(self))
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in {"Alice", "Bob"} : WF_vars(user(self))

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
