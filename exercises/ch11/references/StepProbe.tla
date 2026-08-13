---- MODULE StepProbe ----
\* Exercise 2 reference answer, which is also the shipped starter.
\*
\* A climber goes up a ladder. `rung` moves by exactly one when it moves, and
\* three of the four steps in the loop do not touch it at all. That is what the
\* `[...]_rung` brackets are for.
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
