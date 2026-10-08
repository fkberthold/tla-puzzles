# Requirement 1: nothing stands half-made

At every moment, neither roll carries a part entry for any member.

## Satisfies it

`allowed.md`, both runs, every state. Every entry in both tables reads off or
on. The part condition is declared in the interface, and no state of a correct
model ever shows it.

## Violates it

A model that writes the receiving entry over two moments. The clerk begins the
entry, and finishes it in a later step.

| # | sending | receiving | answer | step |
|---|---|---|---|---|
| 1 | m1 on, m2 on | m1 off, m2 off | waiting | the instruction is in the clerk's hands |
| 2 | m1 on, m2 on | m1 part, m2 off | waiting | the clerk begins m1's entry on the receiving roll |

**Where it breaks:** state 2. The receiving roll carries a part entry for m1.
Rule 3 lets the clerk make that entry and doesn't let her leave it standing,
and here it stands as a moment of its own.

Requirements 2 and 3 both hold at state 2. m1 still holds her whole entry on
the sending roll, so she's off neither roll and on only one of them. Drop the
first requirement and nothing left in the set catches a half-written entry.

The sending column can carry a part entry too. A model that marks m1's sending
entry for striking as a moment of its own reads `m1 part, m2 on` there, and the
first requirement catches it. That state breaks the second requirement as well,
since a member holding nothing but a part entry holds no whole entry anywhere.
So the run above is the cleaner one to ship, and your formula still has to look
at both columns.
