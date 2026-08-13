---- MODULE KnobPanel ----
\* Exercise 3 reference, learntla core ch.6 "Structured Data".
\*
\* `dial` is a function from knobs to notch positions, so its type is a
\* function set. The upper notch is not a constant. `ceiling` is an ordinary
\* variable chosen at startup, and the function set is written against it, so
\* one run covers every ceiling from 1 to MaxNotch.
EXTENDS Integers

CONSTANT NumKnobs
ASSUME NumKnobs > 0

MaxNotch == 3

Knobs == 1..NumKnobs

(*--algorithm knobpanel {
variables
  ceiling \in 1..MaxNotch;
  dial = [k \in Knobs |-> 0];
  next = 1;

define {
  DialType == [Knobs -> 0..ceiling]

  TypeOK == dial \in DialType
}

{
  Turn:
    while (next <= NumKnobs) {
      dial[next] := ceiling;
      next := next + 1;
    };
}
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "7199e90d" /\ chksum(tla) = "2bdd8cbb")
VARIABLES pc, ceiling, dial, next

(* define statement *)
DialType == [Knobs -> 0..ceiling]

TypeOK == dial \in DialType


vars == << pc, ceiling, dial, next >>

Init == (* Global variables *)
        /\ ceiling \in 1..MaxNotch
        /\ dial = [k \in Knobs |-> 0]
        /\ next = 1
        /\ pc = "Turn"

Turn == /\ pc = "Turn"
        /\ IF next <= NumKnobs
              THEN /\ dial' = [dial EXCEPT ![next] = ceiling]
                   /\ next' = next + 1
                   /\ pc' = "Turn"
              ELSE /\ pc' = "Done"
                   /\ UNCHANGED << dial, next >>
        /\ UNCHANGED ceiling

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Turn
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 
====
