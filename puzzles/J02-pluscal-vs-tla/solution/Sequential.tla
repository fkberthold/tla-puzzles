---- MODULE Sequential ----
\* Side A: PlusCal — natural for sequential, control-flow-heavy logic.
\* A vending machine: insert coin, choose item, dispense.
EXTENDS Integers, TLC

(*--algorithm Sequential {
  variables
    coins = 0,
    chosen = "none",
    dispensed = FALSE;

  define {
    TypeOK ==
      /\ coins \in 0..2
      /\ chosen \in {"none", "snack", "drink"}
      /\ dispensed \in BOOLEAN
  }

  fair process (machine = "Vending") {
    insert:
      coins := 1;
    choose:
      either { chosen := "snack"; }
      or     { chosen := "drink"; };
    dispense:
      dispensed := TRUE;
      coins := 0;
  }
}
*)
\* BEGIN TRANSLATION
VARIABLES pc, coins, chosen, dispensed

(* define statement *)
TypeOK ==
  /\ coins \in 0..2
  /\ chosen \in {"none", "snack", "drink"}
  /\ dispensed \in BOOLEAN


vars == << pc, coins, chosen, dispensed >>

ProcSet == {"Vending"}

Init == (* Global variables *)
        /\ coins = 0
        /\ chosen = "none"
        /\ dispensed = FALSE
        /\ pc = [self \in ProcSet |-> "insert"]

insert == /\ pc["Vending"] = "insert"
          /\ coins' = 1
          /\ pc' = [pc EXCEPT !["Vending"] = "choose"]
          /\ UNCHANGED << chosen, dispensed >>

choose == /\ pc["Vending"] = "choose"
          /\ \/ /\ chosen' = "snack"
             \/ /\ chosen' = "drink"
          /\ pc' = [pc EXCEPT !["Vending"] = "dispense"]
          /\ UNCHANGED << coins, dispensed >>

dispense == /\ pc["Vending"] = "dispense"
            /\ dispensed' = TRUE
            /\ coins' = 0
            /\ pc' = [pc EXCEPT !["Vending"] = "Done"]
            /\ UNCHANGED chosen

machine == insert \/ choose \/ dispense

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == machine
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(machine)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION
================================
