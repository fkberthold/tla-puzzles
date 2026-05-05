---- MODULE BrokenDoor ----
EXTENDS FiniteSets, Integers, TLC

(*--algorithm BrokenDoor {
  variables door = "unlocked", through = {};

  define {
    TypeOK ==
      /\ door \in {"locked", "unlocked"}
      /\ through \subseteq {"Alice", "Bob"}
    MutualExclusion == Cardinality(through) <= 1
  }

  fair process (person \in {"Alice", "Bob"}) {
    check:
      if (door = "unlocked") {
        walk:
          door := "locked";
          through := through \union {self};
      };
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION

================================
