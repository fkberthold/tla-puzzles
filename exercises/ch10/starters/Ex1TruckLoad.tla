---------------------------- MODULE Ex1TruckLoad ----------------------------
\* Starter for exercise 1, "Loading the truck".
\* Write your answer in the answer block. Leave the scaffolding alone.
\*
\* Run it before you write anything. It will not parse, and the error names
\* the operator you have not defined yet. That is your first checkpoint.

EXTENDS Integers

\* ---------------- answer block, this is what you write ----------------

\* Define `Loaded` and `Dockside` here. The prompt is in EXERCISES.md.
\*
\* Each one needs a RECURSIVE line of its own before it, and each one takes
\* two arguments.



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
