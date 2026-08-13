---- MODULE Beacon ----
\* Exercise 4 reference solution.
\*
\* A harbour beacon that the keeper flips between lit and dark for ever. Three
\* properties are defined over the one variable. They are close enough in
\* shape to look interchangeable and they are not, which is the exercise.
\*
\* Each property gets its own .cfg, because TLC reports "temporal properties
\* were violated" without naming the one that broke. One property per run is
\* how you find out which.

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
