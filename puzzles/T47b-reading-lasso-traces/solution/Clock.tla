---- MODULE Clock ----
EXTENDS Integers

(*--algorithm Clock {
  variables hour = 11, reset = FALSE;

  define {
    TypeOK == hour \in 11..12 /\ reset \in BOOLEAN
    ReachesNoon == <>( hour = 12 )
  }

  process (resetter = "Resetter") {
    loop:
      while (TRUE) {
        reset := ~reset;
      }
  }

  fair process (ticker = "Ticker") {
    advance:
      while (hour < 12) {
        await ~reset;
        hour := 12;
      }
  }
}*)
\* BEGIN TRANSLATION
\* END TRANSLATION
====
