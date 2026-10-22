---- MODULE Bellows ----
EXTENDS Integers, FiniteSets
CONSTANT Hands

(*--algorithm bellows {
  variables chamber = 0;

  define {
    BothDone == \A h \in Hands : pc[h] = "Done"
    NoLoss == BothDone => chamber = Cardinality(Hands)
  }

  macro Lift(seen) {
    seen := chamber;
  }

  macro Press(seen) {
    chamber := seen + 1;
  }

  process (hand \in Hands)
  variables seen = 0;
  {
    Stroke:
      Lift(seen);
      Press(seen);
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "f7e2dd5e" /\ chksum(tla) = "5ac7af06")
VARIABLES pc, chamber

(* define statement *)
BothDone == \A h \in Hands : pc[h] = "Done"
NoLoss == BothDone => chamber = Cardinality(Hands)

VARIABLE seen

vars == << pc, chamber, seen >>

ProcSet == (Hands)

Init == (* Global variables *)
        /\ chamber = 0
        (* Process hand *)
        /\ seen = [self \in Hands |-> 0]
        /\ pc = [self \in ProcSet |-> "Stroke"]

Stroke(self) == /\ pc[self] = "Stroke"
                /\ seen' = [seen EXCEPT ![self] = chamber]
                /\ chamber' = seen'[self] + 1
                /\ pc' = [pc EXCEPT ![self] = "Done"]

hand(self) == Stroke(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Hands: hand(self))
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
========================
