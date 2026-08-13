---- MODULE Ex1Dispenser ----
EXTENDS Integers, TLC

\* The `target` variable and the Record label exist so the Check label can add
\* the payout up. Without them the assert set says nothing about `nickels`, and
\* a dispenser that counted a nickel while paying out a penny would pass. That
\* was a live mutant escape, not a hypothetical: see reports/authoring.md.

(*--algorithm dispenser {
  variables
    owed \in 0..12,
    target = 0,
    nickels = 0,
    pennies = 0;

  macro Give(count, value) {
    owed := owed - value;
    count := count + 1;
  }

  {
    Record:
      target := owed;
    Dispense:
      while (owed > 0) {
        if (owed >= 5) {
          Give(nickels, 5);
        } else {
          Give(pennies, 1);
        };
      };
    Check:
      assert owed = 0;
      assert pennies < 5;
      assert nickels * 5 + pennies = target;
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "d1e8c926" /\ chksum(tla) = "a7793b1e")
VARIABLES pc, owed, target, nickels, pennies

vars == << pc, owed, target, nickels, pennies >>

Init == (* Global variables *)
        /\ owed \in 0..12
        /\ target = 0
        /\ nickels = 0
        /\ pennies = 0
        /\ pc = "Record"

Record == /\ pc = "Record"
          /\ target' = owed
          /\ pc' = "Dispense"
          /\ UNCHANGED << owed, nickels, pennies >>

Dispense == /\ pc = "Dispense"
            /\ IF owed > 0
                  THEN /\ IF owed >= 5
                             THEN /\ owed' = owed - 5
                                  /\ nickels' = nickels + 1
                                  /\ UNCHANGED pennies
                             ELSE /\ owed' = owed - 1
                                  /\ pennies' = pennies + 1
                                  /\ UNCHANGED nickels
                       /\ pc' = "Dispense"
                  ELSE /\ pc' = "Check"
                       /\ UNCHANGED << owed, nickels, pennies >>
            /\ UNCHANGED target

Check == /\ pc = "Check"
         /\ Assert(owed = 0, "Failure of assertion at line 33, column 7.")
         /\ Assert(pennies < 5, "Failure of assertion at line 34, column 7.")
         /\ Assert(nickels * 5 + pennies = target,
                   "Failure of assertion at line 35, column 7.")
         /\ pc' = "Done"
         /\ UNCHANGED << owed, target, nickels, pennies >>

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Record \/ Dispense \/ Check
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION
====
