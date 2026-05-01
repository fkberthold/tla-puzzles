---- MODULE Room ----
EXTENDS Integers, FiniteSets, TLC

(*--algorithm Room {
  variables
    occupied = {},
    count = 0,
    phase = 0;

  define {
    Chairs == 1..6
    NumOccupied == Cardinality(occupied)
    IsFull == NumOccupied = 6

    TypeOK ==
      /\ occupied \subseteq Chairs
      /\ count \in 0..6
      /\ phase \in 0..2
    CountAccurate == phase = 2 => count = NumOccupied
    Bound == NumOccupied <= 6
  }

  fair process (monitor = "Mon") {
    fill:
      with (s \in SUBSET Chairs) {
        occupied := s;
      };
      phase := phase + 1;
    read:
      count := NumOccupied;
      phase := phase + 1;
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "5355fea9" /\ chksum(tla) = "9b22222")
VARIABLES occupied, count, phase, pc

(* define statement *)
Chairs == 1..6
NumOccupied == Cardinality(occupied)
IsFull == NumOccupied = 6

TypeOK ==
  /\ occupied \subseteq Chairs
  /\ count \in 0..6
  /\ phase \in 0..2
CountAccurate == phase = 2 => count = NumOccupied
Bound == NumOccupied <= 6


vars == << occupied, count, phase, pc >>

ProcSet == {"Mon"}

Init == (* Global variables *)
        /\ occupied = {}
        /\ count = 0
        /\ phase = 0
        /\ pc = [self \in ProcSet |-> "fill"]

fill == /\ pc["Mon"] = "fill"
        /\ \E s \in SUBSET Chairs:
             occupied' = s
        /\ phase' = phase + 1
        /\ pc' = [pc EXCEPT !["Mon"] = "read"]
        /\ count' = count

read == /\ pc["Mon"] = "read"
        /\ count' = NumOccupied
        /\ phase' = phase + 1
        /\ pc' = [pc EXCEPT !["Mon"] = "Done"]
        /\ UNCHANGED occupied

monitor == fill \/ read

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == monitor
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(monitor)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
