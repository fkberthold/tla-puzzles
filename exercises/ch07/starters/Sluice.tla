---- MODULE Sluice ----
\* Exercise 2 starter. Three holes, marked TODO.
\*
\* A canal sluice gate. Each step the world does one of four things to it,
\* and the spec does not get to say which. `either` is already written. What
\* is missing is the invariant, and the guard on each branch that could put
\* the gate into a state the invariant forbids.
\*
\* Read all four branches before you write anything. Under `either` every
\* branch is tried from every state, so a branch with no guard runs whenever
\* it feels like it.
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

    \* TODO 1. A frozen gate is never open. Write that as a boolean over the
    \* two variables. Implication is the natural shape.
    FrozenIsShut == TODO_1
  }

  {
    Step:
      while (steps < MaxSteps) {
        either {
          \* Somebody winds the gate open.
          \* TODO 2. Ice holds the gate fast. When does this branch get to
          \* do anything?
          if (TODO_2) {
            open := TRUE;
          };
        } or {
          \* Somebody winds the gate shut. This always works.
          open := FALSE;
        } or {
          \* The canal freezes over.
          \* TODO 3. Ice only takes hold on a gate that is already shut.
          if (TODO_3) {
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
\* BEGIN TRANSLATION (chksum(pcal) = "ee1b6966" /\ chksum(tla) = "2b75a7c7")
VARIABLES pc, open, frozen, steps

(* define statement *)
TypeOK == /\ open \in BOOLEAN
          /\ frozen \in BOOLEAN
          /\ steps \in 0..MaxSteps



FrozenIsShut == TODO_1


vars == << pc, open, frozen, steps >>

Init == (* Global variables *)
        /\ open = FALSE
        /\ frozen = FALSE
        /\ steps = 0
        /\ pc = "Step"

Step == /\ pc = "Step"
        /\ IF steps < MaxSteps
              THEN /\ \/ /\ IF TODO_2
                               THEN /\ open' = TRUE
                               ELSE /\ TRUE
                                    /\ open' = open
                         /\ UNCHANGED frozen
                      \/ /\ open' = FALSE
                         /\ UNCHANGED frozen
                      \/ /\ IF TODO_3
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
