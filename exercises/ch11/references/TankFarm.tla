---- MODULE TankFarm ----
\* Exercise 4 reference answer.
\*
\* Two tanks fill independently. The property has to say something about every
\* tank, and the quantifier has to go inside the box for TLC to check it.
EXTENDS Integers

Tanks == {"east", "west"}
Cap == 2

(*--algorithm tankfarm {
  variables
    level = [t \in Tanks |-> 0];
  define {
    \* The quantifier sits INSIDE the box, and the subscript is the whole
    \* variable `level`. Written the other way round, with the `\A` outside and
    \* `]_level[t]` as the subscript, SANY rejects the module.
    LevelsNeverFall ==
      [][\A t \in Tanks: level[t]' >= level[t]]_level
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
\* BEGIN TRANSLATION (chksum(pcal) = "d52ee1f9" /\ chksum(tla) = "afc24e78")
VARIABLES pc, level

(* define statement *)
LevelsNeverFall ==
  [][\A t \in Tanks: level[t]' >= level[t]]_level


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
