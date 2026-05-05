---- MODULE Kitchen ----
EXTENDS Integers, TLC

(*--algorithm Kitchen {
  variables cooked = 0, served = 0;

  define {
    TypeOK == cooked \in 0..3 /\ served \in 0..3
    NeverOverServe == served <= cooked
  }

  fair process (chef = "Chef") {
    cookLoop:
      while (cooked < 3) {
        bake:
          cooked := cooked + 1;
      }
  }

  fair process (server = "Server") {
    serveLoop:
      while (served < 3) {
        deliver:
          served := served + 1;
      }
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
