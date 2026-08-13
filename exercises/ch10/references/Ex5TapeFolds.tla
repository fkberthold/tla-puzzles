---------------------------- MODULE Ex5TapeFolds ----------------------------
\* Reference answer for exercise 5, "Folding the tape".
\*
\* The repair is one line, and it goes ABOVE the definition rather than
\* inside it. An operator cannot mention its own name until it has been
\* declared, and `RECURSIVE` is that declaration. The `(_)` says how many
\* arguments to expect; a two-argument operator would be declared `(_, _)`.

EXTENDS Integers

\* ---------------- the repaired definition ----------------

RECURSIVE Folds(_)
Folds(len) == IF len < 3 THEN 0 ELSE 1 + Folds(len \div 2)

\* ---------------- scaffolding below this line ----------------

VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

FoldsAreRight ==
    /\ probe = 0
    /\ Folds(1) = 0
    /\ Folds(2) = 0
    /\ Folds(3) = 1
    /\ Folds(100) = 6

===========================================================================
