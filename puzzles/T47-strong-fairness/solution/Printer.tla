---- MODULE Printer ----
EXTENDS Integers, TLC

(*--algorithm Printer {
  variables hasJob = FALSE, printed = 0;

  define {
    TypeOK == hasJob \in BOOLEAN /\ printed \in 0..3
    JobsServed == []<>(printed = 3)
  }

  fair process (user = "User") {
    submit:
      while (TRUE) {
        either {
          await ~hasJob;
          hasJob := TRUE;     \* submit a new job
        } or {
          await hasJob;
          hasJob := FALSE;    \* cancel the pending job
        };
      }
  }

  fair+ process (printer = "Printer") {
    work:
      while (TRUE) {
        await hasJob;
        if (printed < 3) {
          printed := printed + 1;
        } else {
          printed := 0;       \* wrap: start counting again
        };
        hasJob := FALSE;
      }
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
