------------------------ MODULE Ex4LiftBandsReordered ------------------------
\* Exercise 4, the second half. This is the repaired reference with the first
\* two arms swapped and nothing else changed.
\*
\* Both arms are still there, every load still matches something, and the
\* module still runs. It just answers differently. A load of 1200 satisfies
\* `load >= 600` and `load >= 900` both, and now the 600 arm is written
\* first, so an overloaded lift comes back "warn" instead of "refuse".
\*
\* This is what "the first match wins" costs you when the arms overlap. The
\* arms of a CASE are not a set of independent rules. They are a list, and
\* reordering the list is editing the behaviour.

EXTENDS Integers

\* ---------------- the reordered CASE ----------------

Band(load) ==
    CASE load >= 600 -> "warn"
      [] load >= 900 -> "refuse"
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
