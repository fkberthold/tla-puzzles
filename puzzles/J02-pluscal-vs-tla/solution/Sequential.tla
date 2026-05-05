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
\* END TRANSLATION
================================
