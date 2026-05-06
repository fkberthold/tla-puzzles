---- MODULE GroupPhoto ----
EXTENDS TLC

(*--algorithm GroupPhoto {
  variables smiled = {};

  define {
    TypeOK == smiled \subseteq {"Ann", "Ben"}
    AllSmiled == <>(smiled = {"Ann", "Ben"})
  }

  fair process (person \in {"Ann", "Ben"}) {
    smile:
      smiled := smiled \union {self};
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION

================================
