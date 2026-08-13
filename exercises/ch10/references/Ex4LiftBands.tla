---------------------------- MODULE Ex4LiftBands ----------------------------
\* Reference answer for exercise 4, "The freight lift".
\*
\* The repair is one arm. `OTHER` is the arm that matches when nothing else
\* does, and a CASE without one is a partial function that TLC will walk off
\* the end of the moment you hand it a value no condition covers.

EXTENDS Integers

\* ---------------- the repaired CASE ----------------

\* The arms are tested top to bottom and the first true one wins, so the
\* order is part of the meaning rather than a matter of taste. A load of
\* 1200 satisfies all three numeric arms. It comes back "refuse" because
\* "refuse" is written first.

Band(load) ==
    CASE load >= 900 -> "refuse"
      [] load >= 600 -> "warn"
      [] load >= 250 -> "carry"
      [] OTHER       -> "idle"

\* ---------------- scaffolding below this line ----------------

VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

BandIsRight ==
    /\ probe = 0
    /\ Band(1200) = "refuse"
    /\ Band(900)  = "refuse"
    /\ Band(880)  = "warn"
    /\ Band(640)  = "warn"
    /\ Band(600)  = "warn"
    /\ Band(250)  = "carry"
    /\ Band(80)   = "idle"

===========================================================================
