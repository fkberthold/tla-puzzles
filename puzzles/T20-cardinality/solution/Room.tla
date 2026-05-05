---- MODULE Room ----
EXTENDS Integers, FiniteSets, TLC

(*--algorithm Room {
  variables
    occupied = {},
    count = 0,
    phase = 0;

  define {
    Chairs == 1..6
    NumOccupied == Cardinality(occupied)
    IsFull == NumOccupied = 6

    TypeOK ==
      /\ occupied \subseteq Chairs
      /\ count \in 0..6
      /\ phase \in 0..2
    CountAccurate == phase = 2 => count = NumOccupied
    Bound == NumOccupied <= 6
  }

  fair process (monitor = "Mon") {
    fill:
      with (s \in SUBSET Chairs) {
        occupied := s;
      };
      phase := phase + 1;
    read:
      count := NumOccupied;
      phase := phase + 1;
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
