---- MODULE Library ----
EXTENDS Integers, FiniteSets, TLC

(*--algorithm Library {
  variables available = 1, holders = {};

  define {
    TypeOK == available \in -1..1 /\ holders \subseteq {"Pat1", "Pat2"}
    NoOverborrow == available >= 0  \* This WILL be violated!
  }

  fair process (patron \in {"Pat1", "Pat2"}) {
    inspect:
      if (available > 0) {
        goto borrow;
      } else {
        goto done;
      };
    borrow:
      available := available - 1;
      holders := holders \cup {self};
      goto done;
    done:
      skip;
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
