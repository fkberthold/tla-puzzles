---- MODULE NoFairness ----
\* Side A: no fairness. Spec admits behaviors that stutter forever.
\* A coffee machine that should eventually brew, but with no fairness it can stall.
EXTENDS Integers, TLC

(*--algorithm NoFairness {
  variables brewed = FALSE;

  define {
    TypeOK == brewed \in BOOLEAN
    EventuallyBrewed == <>(brewed = TRUE)
  }

  process (machine = "Machine") {
    brew:
      brewed := TRUE;
  }
}
*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
