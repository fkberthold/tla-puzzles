---- MODULE Tick ----
EXTENDS Integers

(*--algorithm Tick {
  variables count = 0;

  define {
    TypeOK == count \in 0..3
  }

  fair process (clock = "Clock") {
    tick:
      while (count < 3) {
        count := count + 1;
      }
  }
}
*)
\* BEGIN TRANSLATION
\* END TRANSLATION
====
