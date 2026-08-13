---------------------------- MODULE Ex3SettlingTank ----------------------------
\* Starter for exercise 3, "The settling tank".
\* Write your answer in the answer block. Leave the scaffolding alone.
\*
\* Run it before you write anything. It will not parse, and the error names
\* the first thing you have not defined yet. That is your first checkpoint.

EXTENDS Integers

\* ---------------- answer block, this is what you write ----------------

\* Define three things here. The prompt is in EXERCISES.md.
\*
\*   1. the binary operator `\ominus`
\*   2. `Level`, a recursive function over `0..6`
\*   3. `Drop`, a plain function over `1..6`
\*
\* All three are written with the bracket form or the infix form. No operator
\* in this module needs a RECURSIVE declaration, including the recursive one.



\* ---------------- scaffolding below this line ----------------

\* The spec needs one variable so TLC has a state to check the invariant in.
\* It never changes.
VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

\* The `probe = 0` line is load bearing. Without it every conjunct is a
\* constant, TLC folds the whole invariant away before the run starts, and a
\* wrong answer comes back as a config error instead of a violation.
TankIsRight ==
    /\ probe = 0
    /\ (7 \ominus 3) = 4
    /\ (3 \ominus 7) = 0
    /\ (5 \ominus 5) = 0
    /\ Level[0] = 480
    /\ Level[1] = 344
    /\ Level[2] = 236
    /\ Level[3] = 149
    /\ Level[4] = 80
    /\ Level[5] = 24
    /\ Level[6] = 0
    /\ Drop[1] = 136
    /\ Drop[6] = 24
    /\ DOMAIN Drop = 1..6

===========================================================================
