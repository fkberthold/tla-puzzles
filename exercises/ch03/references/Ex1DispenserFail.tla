---- MODULE Ex1DispenserFail ----
EXTENDS Integers, TLC

\* The seeded-wrong dispenser. One character differs from Ex1Dispenser: the
\* branch guard reads `owed > 5` instead of `owed >= 5`, so an owed of exactly
\* 5 is paid out in pennies. `assert pennies < 5` catches it.

(*--algorithm dispenser
  variables
    owed \in 0..12,
    target = 0,
    nickels = 0,
    pennies = 0;

  macro Give(count, value) begin
    owed := owed - value;
    count := count + 1;
  end macro;

begin
  Record:
    target := owed;
  Dispense:
    while owed > 0 do
      if owed > 5 then
        Give(nickels, 5);
      else
        Give(pennies, 1);
      end if;
    end while;
  Check:
    assert owed = 0;
    assert pennies < 5;
    assert nickels * 5 + pennies = target;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "6d3c1264" /\ chksum(tla) = "f0fd3c1f")
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
                  THEN /\ IF owed > 5
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
         /\ Assert(owed = 0, "Failure of assertion at line 32, column 5.")
         /\ Assert(pennies < 5, "Failure of assertion at line 33, column 5.")
         /\ Assert(nickels * 5 + pennies = target, 
                   "Failure of assertion at line 34, column 5.")
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
