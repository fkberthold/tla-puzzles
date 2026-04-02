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
    choose:
      with (g \in 1..5) {
        guess := g;
      };
    check:
      if (guess = secret) {
        result := "won";
      } else {
        result := "lost";
      };
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "8714658e" /\ chksum(tla) = "2aade441")
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
        /\ pc = [self \in ProcSet |-> "choose"]

choose == /\ pc["Player"] = "choose"
          /\ \E g \in 1..5:
               guess' = g
          /\ pc' = [pc EXCEPT !["Player"] = "check"]
          /\ UNCHANGED << secret, result >>

check == /\ pc["Player"] = "check"
         /\ IF guess = secret
               THEN /\ result' = "won"
               ELSE /\ result' = "lost"
         /\ pc' = [pc EXCEPT !["Player"] = "Done"]
         /\ UNCHANGED << secret, guess >>

player == choose \/ check

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
