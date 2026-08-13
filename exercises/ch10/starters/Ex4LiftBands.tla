---------------------------- MODULE Ex4LiftBands ----------------------------
\* Starter for exercise 4, "The freight lift".
\*
\* This one ships broken on purpose, and the exercise is to predict HOW it is
\* broken before you run it. Read the CASE, read the invariant, write your two
\* predictions down, and only then run TLC.
\*
\* Do not repair anything until you have run it once.

EXTENDS Integers

\* ---------------- read this, do not edit it yet ----------------

Band(load) ==
    CASE load >= 900 -> "refuse"
      [] load >= 600 -> "warn"
      [] load >= 250 -> "carry"

\* ---------------- scaffolding below this line ----------------

\* The spec needs one variable so TLC has a state to check the invariant in.
\* It never changes.
VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

\* Every row here is the answer the lift controller is supposed to give.
\*
\* The `probe = 0` line is load bearing. Without it every conjunct is a
\* constant, TLC folds the whole invariant away before the run starts, and a
\* wrong answer comes back as a config error instead of a violation.
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
