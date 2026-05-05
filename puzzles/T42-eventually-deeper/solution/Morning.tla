---- MODULE Morning ----
EXTENDS TLC

(*--algorithm Morning {
  variables alarmRang = FALSE, coffeeBrewed = FALSE, doorLocked = FALSE;

  define {
    TypeOK ==
      /\ alarmRang \in BOOLEAN
      /\ coffeeBrewed \in BOOLEAN
      /\ doorLocked \in BOOLEAN
    MorningComplete ==
      /\ <>(alarmRang = TRUE)
      /\ <>(coffeeBrewed = TRUE)
      /\ <>(doorLocked = TRUE)
  }

  fair process (routine = "Routine") {
    work:
      while (~alarmRang \/ ~coffeeBrewed \/ ~doorLocked) {
        either {
          alarmRang := TRUE;
        } or {
          coffeeBrewed := TRUE;
        } or {
          doorLocked := TRUE;
        };
      }
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
