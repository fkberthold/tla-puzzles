---- MODULE Scoreboard ----
EXTENDS Integers, TLC

(*--algorithm Scoreboard {
  variables home = 0, away = 0, round = 0;

  define {
    TotalPoints == home + away
    HomeLeads == home > away
    Tied == home = away
    GameOver == round = 5
    ValidScore(s) == s \in 0..5

    TypeOK ==
      /\ ValidScore(home)
      /\ ValidScore(away)
      /\ round \in 0..5
    PointsConserved == TotalPoints = round
    HomeAlwaysLeads == HomeLeads
  }

  fair process (game = "Game") {
    play:
      while (~GameOver) {
        either {
          home := home + 1;
        } or {
          away := away + 1;
        };
        round := round + 1;
      }
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "29907057" /\ chksum(tla) = "f80e0779")
VARIABLES home, away, round, pc

(* define statement *)
TotalPoints == home + away
HomeLeads == home > away
Tied == home = away
GameOver == round = 5
ValidScore(s) == s \in 0..5

TypeOK ==
  /\ ValidScore(home)
  /\ ValidScore(away)
  /\ round \in 0..5
PointsConserved == TotalPoints = round
HomeAlwaysLeads == HomeLeads


vars == << home, away, round, pc >>

ProcSet == {"Game"}

Init == (* Global variables *)
        /\ home = 0
        /\ away = 0
        /\ round = 0
        /\ pc = [self \in ProcSet |-> "play"]

play == /\ pc["Game"] = "play"
        /\ IF ~GameOver
              THEN /\ \/ /\ home' = home + 1
                         /\ away' = away
                      \/ /\ away' = away + 1
                         /\ home' = home
                   /\ round' = round + 1
                   /\ pc' = [pc EXCEPT !["Game"] = "play"]
              ELSE /\ pc' = [pc EXCEPT !["Game"] = "Done"]
                   /\ UNCHANGED << home, away, round >>

game == play

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == game
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(game)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 

================================
