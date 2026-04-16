---- MODULE BrokenDoor ----
EXTENDS FiniteSets, Integers, TLC

(*--algorithm BrokenDoor {
  variables door = "unlocked", through = {};

  define {
    TypeOK ==
      /\ door \in {"locked", "unlocked"}
      /\ through \subseteq {"Alice", "Bob"}
    MutualExclusion == Cardinality(through) <= 1
  }

  fair process (person \in {"Alice", "Bob"}) {
    check:
      if (door = "unlocked") {
        walk:
          door := "locked";
          through := through \union {self};
      };
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "c4f9564c" /\ chksum(tla) = "336beb8d")
VARIABLES door, through, pc

(* define statement *)
TypeOK ==
  /\ door \in {"locked", "unlocked"}
  /\ through \subseteq {"Alice", "Bob"}
MutualExclusion == Cardinality(through) <= 1


vars == << door, through, pc >>

ProcSet == ({"Alice", "Bob"})

Init == (* Global variables *)
        /\ door = "unlocked"
        /\ through = {}
        /\ pc = [self \in ProcSet |-> "check"]

check(self) == /\ pc[self] = "check"
               /\ IF door = "unlocked"
                     THEN /\ pc' = [pc EXCEPT ![self] = "walk"]
                     ELSE /\ pc' = [pc EXCEPT ![self] = "Done"]
               /\ UNCHANGED << door, through >>

walk(self) == /\ pc[self] = "walk"
              /\ door' = "locked"
              /\ through' = (through \union {self})
              /\ pc' = [pc EXCEPT ![self] = "Done"]

person(self) == check(self) \/ walk(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in {"Alice", "Bob"}: person(self))
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in {"Alice", "Bob"} : WF_vars(person(self))

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 

================================
