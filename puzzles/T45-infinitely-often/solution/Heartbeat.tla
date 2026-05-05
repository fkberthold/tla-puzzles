---- MODULE Heartbeat ----
EXTENDS TLC

(*--algorithm Heartbeat {
  variables pulse = FALSE;

  define {
    TypeOK == pulse \in BOOLEAN
    BeatsForever == []<>(pulse = TRUE)
  }

  fair process (heart = "Heart") {
    beat:
      while (TRUE) {
        pulse := TRUE;
        rest:
          pulse := FALSE;
      }
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
