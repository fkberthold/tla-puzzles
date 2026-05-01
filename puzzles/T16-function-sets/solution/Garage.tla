---- MODULE Garage ----
EXTENDS Integers, TLC

(*--algorithm Garage {
  variables
    parked = [c \in {"X", "Y", "Z"} |-> 1],
    assigned = FALSE;

  define {
    Cars == {"X", "Y", "Z"}
    Spots == 1..2
    AllAssignments == [Cars -> Spots]

    TypeOK == parked \in AllAssignments /\ assigned \in BOOLEAN
    EveryoneInSpot1 == \A c \in Cars : parked[c] = 1
    NotAlwaysSpot1 == ~EveryoneInSpot1   \* This WILL be violated at the initial state
  }

  fair process (operator = "Op") {
    assign:
      with (a \in AllAssignments) {
        parked := a;
      };
      assigned := TRUE;
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "700fd395" /\ chksum(tla) = "671ed68f")
VARIABLES parked, assigned, pc

(* define statement *)
Cars == {"X", "Y", "Z"}
Spots == 1..2
AllAssignments == [Cars -> Spots]

TypeOK == parked \in AllAssignments /\ assigned \in BOOLEAN
EveryoneInSpot1 == \A c \in Cars : parked[c] = 1
NotAlwaysSpot1 == ~EveryoneInSpot1


vars == << parked, assigned, pc >>

ProcSet == {"Op"}

Init == (* Global variables *)
        /\ parked = [c \in {"X", "Y", "Z"} |-> 1]
        /\ assigned = FALSE
        /\ pc = [self \in ProcSet |-> "assign"]

assign == /\ pc["Op"] = "assign"
          /\ \E a \in AllAssignments:
               parked' = a
          /\ assigned' = TRUE
          /\ pc' = [pc EXCEPT !["Op"] = "Done"]

operator == assign

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == operator
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(operator)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
