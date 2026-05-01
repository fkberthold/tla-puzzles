---- MODULE GuessingGame ----
EXTENDS Integers, TLC

(*--algorithm GuessingGame {
  variables secret \in 1..5, guess = 0, result = "playing";

  define {
    TypeOK ==
      /\ secret \in 1..5
      /\ guess \in 0..5
      /\ result \in {"playing", "won", "lost"}
    NeverWins == result /= "won"
  }

  fair process (player = "Player") {
    play:
      with (g \in 1..5) {
        guess := g;
      };
      if (guess = secret) {
        result := "won";
      } else {
        result := "lost";
      };
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "d2a9bbd" /\ chksum(tla) = "3733a5b")
VARIABLES secret, guess, result, pc

(* define statement *)
TypeOK ==
  /\ secret \in 1..5
  /\ guess \in 0..5
  /\ result \in {"playing", "won", "lost"}
NeverWins == result /= "won"


vars == << secret, guess, result, pc >>

ProcSet == {"Player"}

Init == (* Global variables *)
        /\ secret \in 1..5
        /\ guess = 0
        /\ result = "playing"
        /\ pc = [self \in ProcSet |-> "play"]

play == /\ pc["Player"] = "play"
        /\ \E g \in 1..5:
             guess' = g
        /\ IF guess' = secret
              THEN /\ result' = "won"
              ELSE /\ result' = "lost"
        /\ pc' = [pc EXCEPT !["Player"] = "Done"]
        /\ UNCHANGED secret

player == play

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == player
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(player)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 

================================
