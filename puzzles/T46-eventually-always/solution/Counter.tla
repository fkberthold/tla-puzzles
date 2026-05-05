---- MODULE Counter ----
EXTENDS Integers, TLC

(*--algorithm Counter {
  variables n = 0;

  define {
    TypeOK == n \in 0..3
    Settles == <>[](n = 3)
  }

  fair process (counter = "Counter") {
    tick:
      while (TRUE) {
        either {
          if (n < 3) {
            n := n + 1;
          };
        } or {
          skip;
        };
      }
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
