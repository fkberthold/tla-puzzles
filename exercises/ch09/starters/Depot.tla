---- MODULE Depot ----
\* Exercise 5 starter. Nothing to fill in yet. Read it, predict, then run.
\*
\* A repair depot books a part in, mends it, then hands it back. `Chain` is two
\* leads-to obligations stacked: booked leads to mended, and mended leads to
\* collected. `MaxOpen` caps how many parts the depot will take in.
\*
\* `BookDeskIdle` is not a property of the depot. It is a probe, and it is
\* meant to fail. Read its verdict backwards.
\*
\* This file is already translated. You do not need to run `pcal` unless you
\* change something in the PlusCal comment.
EXTENDS Integers, FiniteSets

CONSTANT Parts

MaxOpen == 0

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
\* BEGIN TRANSLATION (chksum(pcal) = "258a6818" /\ chksum(tla) = "d5c29542")
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
