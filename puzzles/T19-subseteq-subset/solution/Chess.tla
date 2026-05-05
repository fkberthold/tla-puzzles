---- MODULE Chess ----
EXTENDS Integers, TLC

(*--algorithm Chess {
  variables
    roster = {"a", "b", "c", "d"},
    team = {},
    captain = "none",
    phase = 0;

  define {
    TypeOK ==
      /\ team \subseteq roster
      /\ captain \in roster \cup {"none"}
      /\ phase \in 0..2
    CaptainConsistent == phase = 2 => (captain = "none" \/ captain \in team)
  }

  fair process (coach = "Coach") {
    pickTeam:
      with (t \in SUBSET roster) {
        team := t;
      };
      phase := phase + 1;
    pickCaptain:
      with (c \in team \cup {"none"}) {
        captain := c;
      };
      phase := phase + 1;
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
