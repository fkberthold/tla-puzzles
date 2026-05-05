---- MODULE Printer ----
EXTENDS FiniteSets, Integers, TLC

(*--algorithm Printer {
  variables printerInUse = FALSE, printing = {};

  define {
    TypeOK ==
      /\ printerInUse \in BOOLEAN
      /\ printing \subseteq {"Alice", "Bob"}
    MutualExclusion == Cardinality(printing) <= 1
    FlagMatchesSet == printerInUse <=> (printing /= {})
  }

  fair process (user \in {"Alice", "Bob"}) {
    acquire:
      await ~printerInUse;
      printerInUse := TRUE;
      printing := printing \union {self};
    release:
      printing := printing \ {self};
      printerInUse := FALSE;
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
