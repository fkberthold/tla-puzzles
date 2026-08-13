---- MODULE Depot ----
\* Exercise 5 reference solution, with the capacity constant repaired.
\*
\* A repair depot books a part in, mends it, then hands it back. `Chain` is two
\* leads-to obligations stacked: booked leads to mended, and mended leads to
\* collected.
\*
\* The starter ships with `MaxOpen == 0`, so the Book branch is never enabled,
\* nothing is ever booked, and both leads-to obligations are true about
\* nothing. The repair is the `2` below. Note what the wrong constant did to
\* the verdict. It did not break `Chain`. It emptied `Chain`, and TLC reported
\* `OK` either way.
EXTENDS Integers, FiniteSets

CONSTANT Parts

MaxOpen == 2

(*--algorithm depot {
  variables booked = {}, mended = {}, collected = {};

  define {
    SetsOK ==
      /\ booked \subseteq Parts
      /\ mended \subseteq booked
      /\ collected \subseteq mended

    Chain ==
      /\ \A p \in Parts: (p \in booked ~> p \in mended)
      /\ \A p \in Parts: (p \in mended ~> p \in collected)

    \* Not a property of the depot. This is a non-vacuity probe, and it is
    \* meant to FAIL. Run it on its own and read the verdict backwards: if it
    \* passes, nothing was ever booked, so neither half of `Chain` was ever
    \* asked a question.
    BookDeskIdle == booked = {}
  }

  fair process (Clerk = "clerk") {
    Desk:
      while (TRUE) {
        either {
          await Cardinality(booked) < MaxOpen;
          with (p \in Parts \ booked) {
            booked := booked \union {p};
          }
        } or {
          with (p \in booked \ mended) {
            mended := mended \union {p};
          }
        } or {
          with (p \in mended \ collected) {
            collected := collected \union {p};
          }
        }
      }
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "8e228e30" /\ chksum(tla) = "d5c29542")
VARIABLES booked, mended, collected

(* define statement *)
SetsOK ==
  /\ booked \subseteq Parts
  /\ mended \subseteq booked
  /\ collected \subseteq mended

Chain ==
  /\ \A p \in Parts: (p \in booked ~> p \in mended)
  /\ \A p \in Parts: (p \in mended ~> p \in collected)





BookDeskIdle == booked = {}


vars == << booked, mended, collected >>

ProcSet == {"clerk"}

Init == (* Global variables *)
        /\ booked = {}
        /\ mended = {}
        /\ collected = {}

Clerk == \/ /\ Cardinality(booked) < MaxOpen
            /\ \E p \in Parts \ booked:
                 booked' = (booked \union {p})
            /\ UNCHANGED <<mended, collected>>
         \/ /\ \E p \in booked \ mended:
                 mended' = (mended \union {p})
            /\ UNCHANGED <<booked, collected>>
         \/ /\ \E p \in mended \ collected:
                 collected' = (collected \union {p})
            /\ UNCHANGED <<booked, mended>>

Next == Clerk

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(Clerk)

\* END TRANSLATION 
====
