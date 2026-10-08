# Requirement 5: a box moves only under issue

At a step where a box's amendment changes, that box was under issue before
the step, and its new amendment is the one being circulated.

## Satisfies it

`full-circulation.md`. `working` moves three times, at rows 5, 10 and 14.
Each time the box that moved was already in `underIssue` at the row before,
and each time it moves to 1, which is the amendment being circulated. No box
moves at any other row.

## Violates it

A model where the standing instruction is never held, so a signalman who
finds his book behind the current amendment brings it up on his own.

| # | amendment | working b1 b2 b3 | inHand | underIssue | signedOff | step |
|---|---|---|---|---|---|---|
| 1 | 0 | 0 0 0 | 0 | `{}` | `{}` | the opening |
| 2 | 1 | 0 0 0 | 0 | `{}` | `{}` | head office issues the amendment |
| 3 | 1 | 1 0 0 | 0 | `{}` | `{}` | b1 brings its own book up, unprompted |

**Where it breaks:** the step into state 3. b1's amendment changed and b1 was
not under issue, and the circulation hasn't even opened. Rule 3 says the hold
is on for the whole of a circulation and nothing in this system lifts it.

Two steps is all it takes, which makes this the cheapest of the seven to get
wrong and the cheapest to catch. It's worth getting right early for a reason
that isn't obvious: a model that lets a box move on its own will pass
requirement 1 for the wrong reason, because every box reaches the amendment
whatever she does.

The other half of the requirement is the one that goes quiet. "Its new
amendment is the one being circulated" rules out a box pasting some other
edition, and at one amendment there's no other edition to paste. Keep the
clause anyway. At two amendments it's the whole requirement.
