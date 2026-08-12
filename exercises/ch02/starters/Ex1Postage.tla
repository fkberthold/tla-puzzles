---------------------------- MODULE Ex1Postage ----------------------------
\* Starter for exercise 1, "Parcel postage bands".
\* Write your answer in the answer block. Leave the scaffolding alone.
\*
\* Run it before you write anything. It will not parse, and the error names
\* the operator you have not defined yet. That is your first checkpoint.

EXTENDS Integers

\* ---------------- answer block, this is what you write ----------------

\* Define `Postage` here. The prompt is in EXERCISES.md.



\* ---------------- scaffolding below this line ----------------

\* The spec needs one variable so TLC has a state to check the invariant in.
\* It never changes.
VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

\* The invariant pins the answer. A wrong `Postage` body makes TLC report
\* `PostageIsRight` as violated.
PostageIsRight ==
    /\ probe = 0
    /\ Postage(0)   = 120
    /\ Postage(100) = 120
    /\ Postage(101) = 210
    /\ Postage(500) = 210
    /\ Postage(501) = 370
    /\ Postage(2000) = 370

===========================================================================
