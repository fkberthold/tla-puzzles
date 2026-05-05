---- MODULE Loans ----
EXTENDS Integers, TLC

(*--algorithm Loans {
  variables
    loaned = [b \in 1..4 |-> IF b = 1 THEN "alice" ELSE "none"],
    outOnLoan = {},
    available = {},
    phase = 0;

  define {
    Books == DOMAIN loaned

    TypeOK ==
      /\ Books = 1..4
      /\ outOnLoan \subseteq Books
      /\ available \subseteq Books
      /\ phase \in 0..3
    Disjoint == outOnLoan \cap available = {}
    EndsCorrect == phase = 3 => (outOnLoan = {1} /\ available = {2, 3, 4})
  }

  fair process (librarian = "Lib") {
    scanLoaned:
      outOnLoan := {b \in 1..4 : loaned[b] /= "none"};
      phase := phase + 1;
    scanAvailable:
      available := {b \in 1..4 : loaned[b] = "none"};
      phase := phase + 1;
    finish:
      phase := phase + 1;
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
