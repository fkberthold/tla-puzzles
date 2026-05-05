---- MODULE Pantry ----
EXTENDS Integers, TLC

CONSTANT MaxJars

(*--algorithm Pantry {
  variables jars = 0;

  define {
    TypeOK == jars \in 0..MaxJars
    NeverNegative == jars >= 0
  }

  fair process (cook = "Cook") {
    work:
      while (jars < MaxJars) {
        either {
          jars := jars + 1;
        } or {
          if (jars > 0) { jars := jars - 1; };
        };
      }
  }
}
*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
