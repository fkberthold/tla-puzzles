---- MODULE Scoreboard ----
EXTENDS Integers, Sequences, TLC

(*--algorithm Scoreboard {
  variables homeScore = 0, awayScore = 0;

  define {
    TypeOK == homeScore \in 0..10 /\ awayScore \in 0..10
    BoundedScores == homeScore <= 5 /\ awayScore <= 5
    FinalState ==
      (\A p \in {"RefA", "RefB"}: pc[p] = "Done")
        => (homeScore = 5 /\ awayScore = 5)
  }

  procedure award(team = "home", pts = 0) {
    awardStep:
      if (team = "home") {
        homeScore := homeScore + pts;
      } else {
        awayScore := awayScore + pts;
      };
      return;
  }

  fair process (refA = "RefA") {
    a1: call award("home", 3);
    a2: call award("away", 2);
  }

  fair process (refB = "RefB") {
    b1: call award("home", 2);
    b2: call award("away", 3);
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
