---------------------------- MODULE Ex1TruckLoad ----------------------------
\* Reference answer for exercise 1, "Loading the truck".
\* Everything below the answer block is scaffolding. Leave it alone.

EXTENDS Integers

\* ---------------- answer block, this is what you write ----------------

\* Both operators peel the set one crate at a time, and both peel the
\* HEAVIEST crate first. That is what the selection predicate says. A bare
\* `CHOOSE c \in crates : TRUE` would also compile and also run, and it would
\* hand back the lightest crate every time, because TLC resolves an
\* under-determined CHOOSE to the lowest value. The answer would then be a
\* different loading order and a different number.

RECURSIVE Loaded(_, _)
Loaded(crates, room) ==
    IF crates = {}
    THEN 0
    ELSE LET w == CHOOSE c \in crates : \A d \in crates : c >= d
         IN  IF w > room
             THEN 0
             ELSE 1 + Loaded(crates \ {w}, room - w)

RECURSIVE Dockside(_, _)
Dockside(crates, room) ==
    IF crates = {}
    THEN {}
    ELSE LET w == CHOOSE c \in crates : \A d \in crates : c >= d
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
