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
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
