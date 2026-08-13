---- MODULE Beacon ----
\* Exercise 4 starter. Nothing to fill in. Read it, predict, then run.
\*
\* A harbour beacon that the keeper flips between lit and dark for ever.
\*
\* Three properties are defined over the one variable, and each has its own
\* .cfg. One property per run is not fussiness. TLC reports that a temporal
\* property was violated without naming which one, so a run carrying all three
\* would tell you something broke and leave you guessing what.
\*
\* This file is already translated. You do not need to run `pcal` unless you
\* change something in the PlusCal comment.

(*--algorithm beacon {
  variables lamp = "dark";

  define {
    LampOK == lamp \in {"lit", "dark"}

    EverLit == <>(lamp = "lit")

    LitAgainAndAgain == []<>(lamp = "lit")

    SettlesLit == <>[](lamp = "lit")
  }

  fair process (Keeper = "keeper") {
    Turn:
      while (TRUE) {
        if (lamp = "dark") {
          lamp := "lit";
        } else {
          lamp := "dark";
        };
      }
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "316e30d4" /\ chksum(tla) = "eeb00653")
VARIABLE lamp

(* define statement *)
LampOK == lamp \in {"lit", "dark"}

EverLit == <>(lamp = "lit")

LitAgainAndAgain == []<>(lamp = "lit")

SettlesLit == <>[](lamp = "lit")


vars == << lamp >>

ProcSet == {"keeper"}

Init == (* Global variables *)
        /\ lamp = "dark"

Keeper == IF lamp = "dark"
             THEN /\ lamp' = "lit"
             ELSE /\ lamp' = "dark"

Next == Keeper

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(Keeper)

\* END TRANSLATION 
====
