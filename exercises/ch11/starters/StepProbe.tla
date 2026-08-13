---- MODULE StepProbe ----
\* Exercise 2 starter. This file is complete and runs as it stands.
\*
\* A climber goes up a ladder. Look at the four labels and count how many of
\* them change `rung`. Then predict the verdict, write the prediction down, and
\* only then run it.
\*
\* This file ships translated, so the `define` block sits in it twice: once
\* inside the PlusCal comment, and once more below the translation marker near
\* the foot of the file. TLC reads only that second copy. Edit both, or edit
\* the PlusCal copy and run `pcal starters/StepProbe.tla` again, from the
\* directory above this one.
EXTENDS Integers

Rungs == 3

(*--algorithm stepprobe {
  variables
    rung = 0,
    hand = "free";
  define {
    RungGoesUpByOne == [][rung' = rung + 1]_rung
  }
  {
    Climb:
      while (rung < Rungs) {
        Grip:
          hand := "held";
        Pull:
          rung := rung + 1;
        Release:
          hand := "free";
      };
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "77f17f31" /\ chksum(tla) = "ac105341")
VARIABLES pc, rung, hand

(* define statement *)
RungGoesUpByOne == [][rung' = rung + 1]_rung


vars == << pc, rung, hand >>

Init == (* Global variables *)
        /\ rung = 0
        /\ hand = "free"
        /\ pc = "Climb"

Climb == /\ pc = "Climb"
         /\ IF rung < Rungs
               THEN /\ pc' = "Grip"
               ELSE /\ pc' = "Done"
         /\ UNCHANGED << rung, hand >>

Grip == /\ pc = "Grip"
        /\ hand' = "held"
        /\ pc' = "Pull"
        /\ rung' = rung

Pull == /\ pc = "Pull"
        /\ rung' = rung + 1
        /\ pc' = "Release"
        /\ hand' = hand

Release == /\ pc = "Release"
           /\ hand' = "free"
           /\ pc' = "Climb"
           /\ rung' = rung

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Climb \/ Grip \/ Pull \/ Release
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 
====
