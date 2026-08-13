---- MODULE Incubator ----
\* Exercise 4 starter. One hole, marked TODO_1.
\*
\* Two culture plates grow independently. `ColoniesDoubleOrHold` has to say
\* that a plate's colony only ever holds still or exactly doubles, for every
\* plate, and it has to be a shape TLC will accept.
\*
\* THE STUB SITS IN THIS FILE TWICE. The file ships translated, so the `define`
\* block appears once inside the PlusCal comment, and once more below the
\* translation marker near the foot of the file. TLC reads only that second
\* copy. Fill both, or fill the PlusCal copy and run `pcal Incubator.tla` again.
\* Filling only the PlusCal copy and running the model checks the stub.
EXTENDS Integers

Plates == {"left", "right"}
Limit == 4

(*--algorithm incubator {
  variables
    colony = [p \in Plates |-> 1];
  define {
    \* TODO 1. A colony either stays exactly where it is or exactly doubles.
    \* Never anything else. One action property covering every plate in
    \* `Plates`.
    \*
    \* The obvious first attempt writes the property for one plate, wraps a
    \* quantifier round the outside, and subscripts that one plate's entry:
    \* `\A p \in Plates: [][ ... ]_colony[p]`. That module does not compile.
    \* Write the shape that does.
    ColoniesDoubleOrHold == TODO_1
  }
  process (plate \in Plates) {
    Divide:
      while (colony[self] < Limit) {
        colony[self] := colony[self] * 2;
      };
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "7fa01e8f" /\ chksum(tla) = "a06da033")
VARIABLES pc, colony

(* define statement *)
ColoniesDoubleOrHold == TODO_1


vars == << pc, colony >>

ProcSet == (Plates)

Init == (* Global variables *)
        /\ colony = [p \in Plates |-> 1]
        /\ pc = [self \in ProcSet |-> "Divide"]

Divide(self) == /\ pc[self] = "Divide"
                /\ IF colony[self] < Limit
                      THEN /\ colony' = [colony EXCEPT ![self] = colony[self] * 2]
                           /\ pc' = [pc EXCEPT ![self] = "Divide"]
                      ELSE /\ pc' = [pc EXCEPT ![self] = "Done"]
                           /\ UNCHANGED colony

plate(self) == Divide(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Plates: plate(self))
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
====
