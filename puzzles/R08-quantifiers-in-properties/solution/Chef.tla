---- MODULE Chef ----
EXTENDS TLC

(*--algorithm Chef {
  variables plated = [c \in {"Alice", "Bob", "Carol"} |-> FALSE];

  define {
    Chefs == {"Alice", "Bob", "Carol"}
    TypeOK == plated \in [Chefs -> BOOLEAN]
    EveryoneEventuallyPlates == \A c \in Chefs : <>(plated[c] = TRUE)
  }

  fair process (chef \in {"Alice", "Bob", "Carol"}) {
    plate:
      plated[self] := TRUE;
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
