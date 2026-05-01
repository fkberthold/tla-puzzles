---- MODULE Library ----
EXTENDS Integers, TLC

(*--algorithm Library {
  variables
    inventory = [t \in {"alpha", "beta", "gamma"} |->
                  IF t = "alpha" THEN 4 ELSE IF t = "beta" THEN 2 ELSE 7],
    looked_up = 0,
    total = 0,
    phase = 0;

  define {
    Titles == DOMAIN inventory
    Count(t) == inventory[t]

    TypeOK ==
      /\ Titles = {"alpha", "beta", "gamma"}
      /\ \A t \in Titles : inventory[t] \in 0..10
      /\ phase \in 0..3
      /\ looked_up \in 0..10
      /\ total \in 0..30
    LookedUpCorrect == phase >= 1 => looked_up = 2
    TotalCorrect == phase >= 2 => total = 13
    TitlesStable == Titles = {"alpha", "beta", "gamma"}
  }

  fair process (librarian = "Librarian") {
    lookOne:
      looked_up := inventory["beta"];
      phase := phase + 1;
    sumAll:
      total := inventory["alpha"] + inventory["beta"] + inventory["gamma"];
      phase := phase + 1;
    finish:
      phase := phase + 1;
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "10a9fbc7" /\ chksum(tla) = "c0b4f0a9")
VARIABLES inventory, looked_up, total, phase, pc

(* define statement *)
Titles == DOMAIN inventory
Count(t) == inventory[t]

TypeOK ==
  /\ Titles = {"alpha", "beta", "gamma"}
  /\ \A t \in Titles : inventory[t] \in 0..10
  /\ phase \in 0..3
  /\ looked_up \in 0..10
  /\ total \in 0..30
LookedUpCorrect == phase >= 1 => looked_up = 2
TotalCorrect == phase >= 2 => total = 13
TitlesStable == Titles = {"alpha", "beta", "gamma"}


vars == << inventory, looked_up, total, phase, pc >>

ProcSet == {"Librarian"}

Init == (* Global variables *)
        /\ inventory = [t \in {"alpha", "beta", "gamma"} |->
                         IF t = "alpha" THEN 4 ELSE IF t = "beta" THEN 2 ELSE 7]
        /\ looked_up = 0
        /\ total = 0
        /\ phase = 0
        /\ pc = [self \in ProcSet |-> "lookOne"]

lookOne == /\ pc["Librarian"] = "lookOne"
           /\ looked_up' = inventory["beta"]
           /\ phase' = phase + 1
           /\ pc' = [pc EXCEPT !["Librarian"] = "sumAll"]
           /\ UNCHANGED << inventory, total >>

sumAll == /\ pc["Librarian"] = "sumAll"
          /\ total' = inventory["alpha"] + inventory["beta"] + inventory["gamma"]
          /\ phase' = phase + 1
          /\ pc' = [pc EXCEPT !["Librarian"] = "finish"]
          /\ UNCHANGED << inventory, looked_up >>

finish == /\ pc["Librarian"] = "finish"
          /\ phase' = phase + 1
          /\ pc' = [pc EXCEPT !["Librarian"] = "Done"]
          /\ UNCHANGED << inventory, looked_up, total >>

librarian == lookOne \/ sumAll \/ finish

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == librarian
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(librarian)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
