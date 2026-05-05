---- MODULE Battery ----
EXTENDS Integers

(*--algorithm Battery {
  variables charge = 3;

  define {
    TypeOK == charge \in 0..3
    StaysCharged == charge > 0
  }

  fair process (drain = "Drain") {
    deplete:
      while (charge > 0) {
        charge := charge - 1;
      }
  }
}
*)
\* BEGIN TRANSLATION
\* END TRANSLATION
====
