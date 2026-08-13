---- MODULE Incubator ----
\* Exercise 4 reference answer.
\*
\* Two culture plates grow independently. The property has to say something
\* about every plate, and the quantifier has to go inside the box for TLC to
\* check it.
EXTENDS Integers

Plates == {"left", "right"}
Limit == 4

(*--algorithm incubator {
  variables
    colony = [p \in Plates |-> 1];
  define {
    \* The quantifier sits INSIDE the box, and the subscript is the whole
    \* variable `colony`. Written the other way round, with the `\A` outside
    \* and `]_colony[p]` as the subscript, SANY rejects the module.
    \*
    \* The `colony[p]` branch of the set carries its weight. One plate
    \* doubling is a step that leaves the other plate alone, and the body
    \* still has to hold for that other plate, so holding still has to be a
    \* legal move for every plate on every step.
    ColoniesDoubleOrHold ==
      [][\A p \in Plates: colony[p]' \in {colony[p], 2 * colony[p]}]_colony
  }
  process (plate \in Plates) {
    Divide:
      while (colony[self] < Limit) {
        colony[self] := colony[self] * 2;
      };
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "883339a7" /\ chksum(tla) = "88df9d77")
VARIABLES pc, colony

(* define statement *)
ColoniesDoubleOrHold ==
  [][\A p \in Plates: colony[p]' \in {colony[p], 2 * colony[p]}]_colony


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
