---- MODULE Lottery ----
EXTENDS Integers, TLC

(*--algorithm Lottery {
  variables
    tickets = {1, 2, 3, 4},
    winner = 0,
    minValid = 0,
    phase = 0;

  define {
    Tickets == tickets
    AnyTicket == CHOOSE t \in Tickets : TRUE
    SmallestAtLeast2 ==
      CHOOSE t \in Tickets : t >= 2 /\ \A u \in Tickets : (u >= 2 => t <= u)

    TypeOK ==
      /\ winner \in Tickets \cup {0}
      /\ minValid \in Tickets \cup {0}
      /\ phase \in 0..2
    MinIs2 == phase = 2 => minValid = 2
    WinnerStable == phase >= 1 => winner = AnyTicket
  }

  fair process (operator = "Op") {
    announceWinner:
      winner := AnyTicket;
      phase := phase + 1;
    announceMinValid:
      minValid := SmallestAtLeast2;
      phase := phase + 1;
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
