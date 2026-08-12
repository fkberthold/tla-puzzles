---------------------------- MODULE Ex1Postage ----------------------------
\* Reference answer for exercise 1, "Parcel postage bands".
\* Everything below the answer block is scaffolding. Leave it alone.

EXTENDS Integers

\* ---------------- answer block, this is what you write ----------------

Postage(grams) ==
    LET handling == 120
    IN  IF grams <= 100
        THEN handling
        ELSE IF grams <= 500
             THEN handling + 90
             ELSE handling + 250

\* ---------------- scaffolding below this line ----------------

\* The spec needs one variable so TLC has a state to check the invariant in.
\* It never changes.
VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

\* The invariant pins the answer. A wrong `Postage` body makes TLC report
\* `PostageIsRight` as violated.
\*
\* The `probe = 0` line is load bearing. Without it every conjunct is a
\* constant, TLC folds the whole invariant before the run starts, and a wrong
\* answer comes back as a config error instead of a violation.
PostageIsRight ==
    /\ probe = 0
    /\ Postage(0)   = 120
    /\ Postage(100) = 120
    /\ Postage(101) = 210
    /\ Postage(500) = 210
    /\ Postage(501) = 370
    /\ Postage(2000) = 370

===========================================================================
