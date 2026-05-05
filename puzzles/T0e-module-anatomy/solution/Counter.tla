---- MODULE Counter ----
EXTENDS Integers

(*--algorithm Counter {
  variables n = 0;

  define {
    TypeOK == n \in 0..3
  }

  fair process (counter = "Counter") {
    bump:
      while (n < 3) {
        n := n + 1;
      }
  }
}
*)
\* BEGIN TRANSLATION
\* END TRANSLATION
====
