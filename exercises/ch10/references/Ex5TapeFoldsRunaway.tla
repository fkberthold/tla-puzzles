------------------------ MODULE Ex5TapeFoldsRunaway ------------------------
\* Exercise 5, the second half. This is the repaired reference with one
\* character changed: the base case tests `len < 0` where the working answer
\* tests `len < 3`.
\*
\* The declaration is still there and the module still parses. Nothing checks
\* that a recursion ends, so the error arrives at run time instead.
\*
\* Halving 100 walks down 50, 25, 12, 6, 3, 1, 0 and then stops moving,
\* because 0 \div 2 is 0 and 0 < 0 is false. The base case is never reached
\* and the operator calls itself until the Java stack underneath TLC runs
\* out.

EXTENDS Integers

\* ---------------- the runaway definition ----------------

RECURSIVE Folds(_)
Folds(len) == IF len < 0 THEN 0 ELSE 1 + Folds(len \div 2)

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
