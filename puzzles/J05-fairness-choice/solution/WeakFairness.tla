---- MODULE WeakFairness ----
\* Side B: weak fairness. The process eventually takes a step
\* if it remains continuously enabled.
\* Same coffee machine — now brewing is guaranteed.
EXTENDS Integers, TLC

(*--algorithm WeakFairness {
  variables brewed = FALSE;

  define {
    TypeOK == brewed \in BOOLEAN
    EventuallyBrewed == <>(brewed = TRUE)
  }

  fair process (machine = "Machine") {
    brew:
      brewed := TRUE;
  }
}
*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
