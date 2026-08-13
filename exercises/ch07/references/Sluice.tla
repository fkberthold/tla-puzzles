---- MODULE Sluice ----
\* Exercise 2 reference answer.
\*
\* A canal sluice gate. Each step the world does one of four things to it,
\* and the spec does not get to say which. Once the gate is frozen it must
\* never be found open again, so every branch that could open it carries its
\* own guard.
EXTENDS Integers

MaxSteps == 3

(*--algorithm sluice {
  variables
    open = FALSE,
    frozen = FALSE,
    steps = 0;

  define {
    TypeOK == /\ open \in BOOLEAN
              /\ frozen \in BOOLEAN
              /\ steps \in 0..MaxSteps

    FrozenIsShut == frozen => ~open
  }

  {
    Step:
      while (steps < MaxSteps) {
        either {
          \* Somebody winds the gate open. Ice holds it fast.
          if (~frozen) {
            open := TRUE;
          };
        } or {
          \* Somebody winds the gate shut. This always works.
          open := FALSE;
        } or {
          \* The canal freezes over. It only takes hold on a shut gate.
          if (~open) {
            frozen := TRUE;
          };
        } or {
          \* Nothing happens to the gate this step.
          skip;
        };
        steps := steps + 1;
      };
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "20760d0b" /\ chksum(tla) = "88f49c7")
VARIABLES pc, open, frozen, steps

(* define statement *)
TypeOK == /\ open \in BOOLEAN
          /\ frozen \in BOOLEAN
          /\ steps \in 0..MaxSteps

FrozenIsShut == frozen => ~open


vars == << pc, open, frozen, steps >>

Init == (* Global variables *)
        /\ open = FALSE
        /\ frozen = FALSE
        /\ steps = 0
        /\ pc = "Step"

Step == /\ pc = "Step"
        /\ IF steps < MaxSteps
              THEN /\ \/ /\ IF ~frozen
                               THEN /\ open' = TRUE
                               ELSE /\ TRUE
                                    /\ open' = open
                         /\ UNCHANGED frozen
                      \/ /\ open' = FALSE
                         /\ UNCHANGED frozen
                      \/ /\ IF ~open
                               THEN /\ frozen' = TRUE
                               ELSE /\ TRUE
                                    /\ UNCHANGED frozen
                         /\ open' = open
                      \/ /\ TRUE
                         /\ UNCHANGED <<open, frozen>>
                   /\ steps' = steps + 1
                   /\ pc' = "Step"
              ELSE /\ pc' = "Done"
                   /\ UNCHANGED << open, frozen, steps >>

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Step
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 
====
