--------------------------- MODULE Ex2HoldPickup ---------------------------
\* Reference answer for exercise 2, "The hold shelf rule".
\* Everything below the answer block is scaffolding. Leave it alone.

\* ---------------- answer block, this is what you fill in ----------------

CanCollect(card_ok, hold_ready, owes_fines, staff_override) ==
    /\ card_ok
    /\ hold_ready
    /\ owes_fines => staff_override

\* Why a patron was turned away, when it had nothing to do with fines.
TurnedAwayAtTheDesk(card_ok, hold_ready) == ~card_ok \/ ~hold_ready

\* ---------------- scaffolding below this line ----------------

\* The spec needs one variable so TLC has a state to check the invariant in.
\* It never changes.
VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

\* Ten rows of the truth table, chosen so that each one rules out a different
\* wrong answer. A wrong body makes TLC report `RuleIsRight` as violated.
\*
\* The `probe = 0` line is load bearing. Without it every conjunct is a
\* constant, TLC folds the whole invariant before the run starts, and a wrong
\* answer comes back as a config error instead of a violation.
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
