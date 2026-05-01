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
\* BEGIN TRANSLATION (chksum(pcal) = "ced93fc7" /\ chksum(tla) = "342188f2")
VARIABLES pc, goals, step

(* define statement *)
Teams == DOMAIN goals

TypeOK ==
  /\ Teams = {"red", "blue", "green"}
  /\ \A t \in Teams : goals[t] \in 0..3
  /\ step \in 0..4
EndsCorrect == step = 4 =>
  goals = [t \in {"red", "blue", "green"} |->
            IF t = "red" THEN 2 ELSE IF t = "blue" THEN 2 ELSE 3]
TeamsStable == Teams = {"red", "blue", "green"}


vars == << pc, goals, step >>

ProcSet == {"Ref"}

Init == (* Global variables *)
        /\ goals = [t \in {"red", "blue", "green"} |-> 0]
        /\ step = 0
        /\ pc = [self \in ProcSet |-> "redOne"]

redOne == /\ pc["Ref"] = "redOne"
          /\ goals' = [goals EXCEPT !["red"] = 1]
          /\ step' = step + 1
          /\ pc' = [pc EXCEPT !["Ref"] = "blueTwo"]

blueTwo == /\ pc["Ref"] = "blueTwo"
           /\ goals' = [goals EXCEPT !["blue"] = 2]
           /\ step' = step + 1
           /\ pc' = [pc EXCEPT !["Ref"] = "redTwo"]

redTwo == /\ pc["Ref"] = "redTwo"
          /\ goals' = [goals EXCEPT !["red"] = 2]
          /\ step' = step + 1
          /\ pc' = [pc EXCEPT !["Ref"] = "greenThree"]

greenThree == /\ pc["Ref"] = "greenThree"
              /\ goals' = [goals EXCEPT !["green"] = 3]
              /\ step' = step + 1
              /\ pc' = [pc EXCEPT !["Ref"] = "Done"]

referee == redOne \/ blueTwo \/ redTwo \/ greenThree

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == referee
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(referee)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
