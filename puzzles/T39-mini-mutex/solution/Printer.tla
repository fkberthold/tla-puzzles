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
\* BEGIN TRANSLATION (chksum(pcal) = "c38e5de2" /\ chksum(tla) = "8ca0d0ec")
VARIABLES printerInUse, printing, pc

(* define statement *)
TypeOK ==
  /\ printerInUse \in BOOLEAN
  /\ printing \subseteq {"Alice", "Bob"}
MutualExclusion == Cardinality(printing) <= 1
FlagMatchesSet == printerInUse <=> (printing /= {})


vars == << printerInUse, printing, pc >>

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
