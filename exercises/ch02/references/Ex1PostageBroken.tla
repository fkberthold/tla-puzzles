------------------------- MODULE Ex1PostageBroken -------------------------
\* Seeded-wrong variant of `Ex1Postage`. Run this to see the check go red.
\* One edit against the reference: the first band test is `<` instead of `<=`,
\* so a parcel of exactly 100 grams falls into the wrong band.

EXTENDS Integers

Postage(grams) ==
    LET handling == 120
    IN  IF grams < 100
        THEN handling
        ELSE IF grams <= 500
             THEN handling + 90
             ELSE handling + 250

VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

PostageIsRight ==
    /\ probe = 0
    /\ Postage(0)   = 120
    /\ Postage(100) = 120
    /\ Postage(101) = 210
    /\ Postage(500) = 210
    /\ Postage(501) = 370
    /\ Postage(2000) = 370

===========================================================================
