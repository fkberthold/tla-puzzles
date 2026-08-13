---------------------------- MODULE Ex5TapeFolds ----------------------------
\* Starter for exercise 5, "Folding the tape".
\*
\* This one ships broken on purpose, twice over, and the exercise is to
\* predict each break before you run into it. Write your prediction down
\* first. Then run.
\*
\* `Folds(len)` counts how many times a strip of tape of length `len` can be
\* folded in half before the result is under 3 units long. Folding halves the
\* length, and the halving rounds down.

EXTENDS Integers

\* ---------------- read this, then predict, then run ----------------

Folds(len) == IF len < 3 THEN 0 ELSE 1 + Folds(len \div 2)

\* ---------------- scaffolding below this line ----------------

\* The spec needs one variable so TLC has a state to check the invariant in.
\* It never changes.
VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

\* The `probe = 0` line is load bearing. Without it every conjunct is a
\* constant, TLC folds the whole invariant away before the run starts, and a
\* wrong answer comes back as a config error instead of a violation.
FoldsAreRight ==
    /\ probe = 0
    /\ Folds(1) = 0
    /\ Folds(2) = 0
    /\ Folds(3) = 1
    /\ Folds(100) = 6

===========================================================================
