------------------------ MODULE Ex2HoldPickupBroken ------------------------
\* Seeded-wrong variant of `Ex2HoldPickup`. Run this to see the check go red.
\* One edit against the reference: the implication points the wrong way, so
\* the rule now says "an override means fines were owed" instead of "fines
\* owed means an override is needed".

CanCollect(card_ok, hold_ready, owes_fines, staff_override) ==
    /\ card_ok
    /\ hold_ready
    /\ staff_override => owes_fines

TurnedAwayAtTheDesk(card_ok, hold_ready) == ~card_ok \/ ~hold_ready

VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

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
