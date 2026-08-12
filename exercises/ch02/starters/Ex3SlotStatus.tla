--------------------------- MODULE Ex3SlotStatus ---------------------------
\* Starter for exercise 3, "What type is that answer".
\*
\* This one arrives broken on purpose. Read it, predict the verdict, write the
\* prediction into your log, and only then run it.

EXTENDS Integers

\* A vending bank. Slots are named with strings, stock levels are integers.
Stock(slot) ==
    IF   slot = "a1" THEN 4
    ELSE IF slot = "a2" THEN 0
    ELSE 7

\* Arithmetic, so this module really does need `EXTENDS Integers`.
Restocked(slot) == Stock(slot) + 6

\* A string answer, not a number.
Status(slot) == IF Stock(slot) = 0 THEN "empty" ELSE "stocked"

\* ---------------- scaffolding below this line ----------------

VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

\* One line below compares a string answer against an integer. Find it before
\* you run anything.
\*
\* The `probe = 0` line is load bearing. Without it every conjunct is a
\* constant, TLC folds the whole invariant before the run starts, and a wrong
\* answer comes back as a config error instead of a violation.
StatusIsRight ==
    /\ probe = 0
    /\ Stock("a1") = 4
    /\ Stock("a2") = 0
    /\ Stock("zz") = 7
    /\ Restocked("a2") = 6
    /\ Status("a1") = "stocked"
    /\ Status("a2") = 0
    /\ Status("zz") = "stocked"
    /\ (Status("a1") # Status("a2")) = TRUE

===========================================================================
