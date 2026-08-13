---------------------------- MODULE Ex1TruckLoadBroken ----------------------------
\* Seeded-wrong copy of the exercise 1 reference, "Loading the truck".
\*
\* THE SEEDED ERROR: both selection predicates read `TRUE` where the working
\* answer reads `\A d \in crates : c >= d`. Nothing else differs.
\*
\* `TRUE` is satisfied by every crate in the set, so it names no single one.
\* TLC still has to return something, and it returns the lowest value, so the
\* truck gets loaded lightest first instead of heaviest first. Both operators
\* then answer a different question from the one the invariant asks.

EXTENDS Integers

RECURSIVE Loaded(_, _)
Loaded(crates, room) ==
    IF crates = {}
    THEN 0
    ELSE LET w == CHOOSE c \in crates : TRUE
         IN  IF w > room
             THEN 0
             ELSE 1 + Loaded(crates \ {w}, room - w)

RECURSIVE Dockside(_, _)
Dockside(crates, room) ==
    IF crates = {}
    THEN {}
    ELSE LET w == CHOOSE c \in crates : TRUE
         IN  IF w > room
             THEN crates
             ELSE Dockside(crates \ {w}, room - w)

\* ---------------- scaffolding below this line ----------------

\* The spec needs one variable so TLC has a state to check the invariant in.
\* It never changes.
VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

\* The `probe = 0` line is load bearing. Without it every conjunct is a
\* constant, TLC folds the whole invariant away before the run starts, and a
\* wrong answer comes back as a config error instead of a violation.
LoadIsRight ==
    /\ probe = 0
    /\ Loaded({}, 10) = 0
    /\ Loaded({4}, 4) = 1
    /\ Loaded({4}, 3) = 0
    /\ Loaded({2, 3, 4}, 9) = 3
    /\ Loaded({3, 5, 9}, 10) = 1
    /\ Loaded({1, 2, 10}, 11) = 1
    /\ Dockside({2, 3, 4}, 9) = {}
    /\ Dockside({3, 5, 9}, 10) = {3, 5}
    /\ Dockside({6, 7, 8}, 20) = {6}
    /\ Dockside({1, 2, 10}, 11) = {1, 2}

===========================================================================
