---- MODULE Elevator ----
EXTENDS Integers, TLC

(*--algorithm Elevator {
  variables floor = 0, doors = "closed";

  define {
    TypeOK == floor \in {0, 1, 5} /\ doors \in {"closed", "open"}
    AlwaysOffice == floor /= 1  \* This WILL be violated!
    EventuallyOpen == <>(doors = "open")
  }

  fair process (elevator = "Car") {
    travel:
      either {
        floor := 1;
      } or {
        floor := 5;
      };
    arrive:
      doors := "open";
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
