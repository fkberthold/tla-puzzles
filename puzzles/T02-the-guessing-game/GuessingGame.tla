---- MODULE GuessingGame ----
EXTENDS TLC, Integers

(*--algorithm GuessinGame {
variables 
  secret \in 1..5,
  guess = 1;
  result = "playing";


define {
  TypeOk ==
    /\ secret \in 1..5
    /\ guess \in 1..5
  NeverWin == result # "Win"
}

fair process (guessinggame = "GuessingGame") {
  guess:
  with (g \in 1..5) {
    guess := g;
  };
  if (guess = secret) {
    result := "Win";
  } else {
    result := "Loss";
  };
}
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "4439218d" /\ chksum(tla) = "6ccd6444")
\* Label guess of process guessinggame at line 20 col 8 changed to guess_
VARIABLES pc, secret, guess, result

(* define statement *)
TypeOk ==
  /\ secret \in 1..5
  /\ guess \in 1..5
NeverWin == result # "Win"


vars == << pc, secret, guess, result >>

ProcSet == {"GuessingGame"}

Init == (* Global variables *)
        /\ secret \in 1..5
        /\ guess = 1
        /\ result = "playing"
        /\ pc = [self \in ProcSet |-> "guess_"]

guess_ == /\ pc["GuessingGame"] = "guess_"
          /\ \E g \in 1..5:
               guess' = g
          /\ IF guess' = secret
                THEN /\ result' = "Win"
                ELSE /\ result' = "Loss"
          /\ pc' = [pc EXCEPT !["GuessingGame"] = "Done"]
          /\ UNCHANGED secret

guessinggame == guess_

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == guessinggame
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(guessinggame)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 

====
