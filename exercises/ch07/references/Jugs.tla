---- MODULE Jugs ----
\* Exercise 3 reference. Nothing is missing from this file. It is the same
\* module the learner is handed.
\*
\* Two unmarked jugs and a tap. Six things you can do, and no rule about
\* which to do next, so `either` covers all six and TLC walks the lot.
\*
\* The invariant is written the wrong way round on purpose. `NotYet` claims
\* the big jug never holds `Target`. A run that comes back `OK` is TLC saying
\* the claim held, which means the measurement is impossible. A run that comes
\* back `SAFETY_VIOLATION` is TLC handing back the pouring sequence.
EXTENDS Integers

CONSTANTS BigCap, SmallCap, Target

Min(a, b) == IF a < b THEN a ELSE b

(*--algorithm jugs {
  variables
    big = 0,
    small = 0;

  define {
    NotYet == big # Target
  }

  {
    Pour:
      while (TRUE) {
        either {
          \* Fill the big jug from the tap.
          big := BigCap;
        } or {
          \* Fill the small jug from the tap.
          small := SmallCap;
        } or {
          \* Tip the big jug out.
          big := 0;
        } or {
          \* Tip the small jug out.
          small := 0;
        } or {
          \* Pour big into small until one of them runs out.
          with (moved = Min(big, SmallCap - small)) {
            big := big - moved || small := small + moved;
          };
        } or {
          \* Pour small into big until one of them runs out.
          with (moved = Min(small, BigCap - big)) {
            big := big + moved || small := small - moved;
          };
        };
      };
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "401672f8" /\ chksum(tla) = "9c7bed4")
VARIABLES big, small

(* define statement *)
NotYet == big # Target


vars == << big, small >>

Init == (* Global variables *)
        /\ big = 0
        /\ small = 0

Next == \/ /\ big' = BigCap
           /\ small' = small
        \/ /\ small' = SmallCap
           /\ big' = big
        \/ /\ big' = 0
           /\ small' = small
        \/ /\ small' = 0
           /\ big' = big
        \/ /\ LET moved == Min(big, SmallCap - small) IN
                /\ big' = big - moved
                /\ small' = small + moved
        \/ /\ LET moved == Min(small, BigCap - big) IN
                /\ big' = big + moved
                /\ small' = small - moved

Spec == Init /\ [][Next]_vars

\* END TRANSLATION 
====
