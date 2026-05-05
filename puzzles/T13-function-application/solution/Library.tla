---- MODULE Library ----
EXTENDS Integers, TLC

(*--algorithm Library {
  variables
    inventory = [t \in {"alpha", "beta", "gamma"} |->
                  IF t = "alpha" THEN 4 ELSE IF t = "beta" THEN 2 ELSE 7],
    looked_up = 0,
    total = 0,
    phase = 0;

  define {
    Titles == DOMAIN inventory
    Count(t) == inventory[t]

    TypeOK ==
      /\ Titles = {"alpha", "beta", "gamma"}
      /\ \A t \in Titles : inventory[t] \in 0..10
      /\ phase \in 0..3
      /\ looked_up \in 0..10
      /\ total \in 0..30
    LookedUpCorrect == phase >= 1 => looked_up = 2
    TotalCorrect == phase >= 2 => total = 13
    TitlesStable == Titles = {"alpha", "beta", "gamma"}
  }

  fair process (librarian = "Librarian") {
    lookOne:
      looked_up := inventory["beta"];
      phase := phase + 1;
    sumAll:
      total := inventory["alpha"] + inventory["beta"] + inventory["gamma"];
      phase := phase + 1;
    finish:
      phase := phase + 1;
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
