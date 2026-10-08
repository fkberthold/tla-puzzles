# Requirement 3: nobody is on both rolls

At every moment, no member holds a whole entry on both rolls at once.

## Satisfies it

`allowed.md`, both runs. m1 leaves the sending roll in the same moment she
reaches the receiving one, so no state of either run shows her on both.

## Violates it

A model that copies the entry onto the receiving roll and takes the sending
entry off in a later step.

| # | sending | receiving | answer | step |
|---|---|---|---|---|
| 1 | m1 on, m2 on | m1 off, m2 off | waiting | the instruction is in the clerk's hands |
| 2 | m1 on, m2 on | m1 on, m2 off | waiting | the clerk copies m1 onto the receiving roll and hasn't taken her off the sending one |

**Where it breaks:** state 2. m1 holds a whole entry on both rolls. Two
branches carry her, she's counted twice and she can draw twice, which rule 4
calls a fault rather than a breach.

Requirements 1 and 2 both hold at state 2. Nothing is part-written, and m1
holds a whole entry on at least one roll by holding two.

This is the requirement the orders only ask for. It's still a check here, and
rule 4 says why: the clerk in this problem does as asked on both counts, so her
conduct is narrowed to what the orders prefer. A `.cfg` has one strength to
declare an obligation at, and the difference between a requirement and a
preference isn't something TLC can carry.
