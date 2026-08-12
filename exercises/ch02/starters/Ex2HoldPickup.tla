--------------------------- MODULE Ex2HoldPickup ---------------------------
\* Starter for exercise 2, "The hold shelf rule".
\* Fill in the answer block. Leave the scaffolding alone.
\*
\* Run it before you change anything. It should go red. That is the point.

\* ---------------- answer block, this is what you fill in ----------------

\* Replace `FALSE` with the collection rule from EXERCISES.md.
\* Write it in bullet-point notation, one `/\` per line.
CanCollect(card_ok, hold_ready, owes_fines, staff_override) ==
    FALSE

\* Replace `FALSE` with the turned-away rule from EXERCISES.md.
\* This one wants `~` and `\/`, not bullets.
TurnedAwayAtTheDesk(card_ok, hold_ready) ==
    FALSE

\* ---------------- scaffolding below this line ----------------

\* The spec needs one variable so TLC has a state to check the invariant in.
\* It never changes.
VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

\* Ten rows of the truth table, chosen so that each one rules out a different
\* wrong answer. A wrong body makes TLC report `RuleIsRight` as violated.
RuleIsRight ==
    /\ probe = 0
    /\ CanCollect(TRUE,  TRUE,  FALSE, FALSE) = TRUE
    /\ CanCollect(TRUE,  TRUE,  FALSE, TRUE)  = TRUE
    /\ CanCollect(TRUE,  TRUE,  TRUE,  TRUE)  = TRUE
    /\ CanCollect(TRUE,  TRUE,  TRUE,  FALSE) = FALSE
    /\ CanCollect(FALSE, TRUE,  FALSE, TRUE)  = FALSE
    /\ CanCollect(TRUE,  FALSE, FALSE, TRUE)  = FALSE
    /\ TurnedAwayAtTheDesk(TRUE,  TRUE)  = FALSE
    /\ TurnedAwayAtTheDesk(FALSE, TRUE)  = TRUE
    /\ TurnedAwayAtTheDesk(TRUE,  FALSE) = TRUE
    /\ TurnedAwayAtTheDesk(FALSE, FALSE) = TRUE

===========================================================================
