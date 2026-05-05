---- MODULE Scoreboard ----
EXTENDS Integers, TLC

(*--algorithm Scoreboard {
  variables
    goals = [t \in {"red", "blue", "green"} |-> 0],
    step = 0;

  define {
    Teams == DOMAIN goals

    TypeOK ==
      /\ Teams = {"red", "blue", "green"}
      /\ \A t \in Teams : goals[t] \in 0..3
      /\ step \in 0..4
    EndsCorrect == step = 4 =>
      goals = [t \in {"red", "blue", "green"} |->
                IF t = "red" THEN 2 ELSE IF t = "blue" THEN 2 ELSE 3]
    TeamsStable == Teams = {"red", "blue", "green"}
  }

  fair process (referee = "Ref") {
    redOne:
      goals := [goals EXCEPT !["red"] = 1];
      step := step + 1;
    blueTwo:
      goals := [goals EXCEPT !["blue"] = 2];
      step := step + 1;
    redTwo:
      goals := [goals EXCEPT !["red"] = 2];
      step := step + 1;
    greenThree:
      goals := [goals EXCEPT !["green"] = 3];
      step := step + 1;
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
