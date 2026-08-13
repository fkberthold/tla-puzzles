---- MODULE TankFarm ----
\* Exercise 4 starter. One hole, marked TODO_1.
\*
\* Two tanks fill independently. `LevelsNeverFall` has to say that no tank's
\* level ever drops, for every tank, and it has to be a shape TLC will accept.
\*
\* THE STUB SITS IN THIS FILE TWICE. The file ships translated, so the `define`
\* block appears once inside the PlusCal comment, and once more below the
\* translation marker near the foot of the file. TLC reads only that second
\* copy. Fill both, or fill the PlusCal copy and run `pcal TankFarm.tla` again.
\* Filling only the PlusCal copy and running the model checks the stub.
EXTENDS Integers

Tanks == {"east", "west"}
Cap == 2

(*--algorithm tankfarm {
  variables
    level = [t \in Tanks |-> 0];
  define {
    \* TODO 1. No tank's level ever drops. One action property covering every
    \* tank in `Tanks`.
    \*
    \* The obvious first attempt puts the `\A` outside the `[]` and subscripts
    \* one entry, `]_level[t]`. That module does not compile. Write the shape
    \* that does.
    LevelsNeverFall == TODO_1
  }
  process (pump \in Tanks) {
    Fill:
      while (level[self] < Cap) {
        level[self] := level[self] + 1;
      };
    Top:
      level[self] := Cap;
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "4ea49037" /\ chksum(tla) = "22b7fe35")
VARIABLES pc, level

(* define statement *)
LevelsNeverFall == TODO_1


vars == << pc, level >>

ProcSet == (Tanks)

Init == (* Global variables *)
        /\ level = [t \in Tanks |-> 0]
        /\ pc = [self \in ProcSet |-> "Fill"]

Fill(self) == /\ pc[self] = "Fill"
              /\ IF level[self] < Cap
                    THEN /\ level' = [level EXCEPT ![self] = level[self] + 1]
                         /\ pc' = [pc EXCEPT ![self] = "Fill"]
                    ELSE /\ pc' = [pc EXCEPT ![self] = "Top"]
                         /\ level' = level

Top(self) == /\ pc[self] = "Top"
             /\ level' = [level EXCEPT ![self] = Cap]
             /\ pc' = [pc EXCEPT ![self] = "Done"]

pump(self) == Fill(self) \/ Top(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Tanks: pump(self))
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
====
