# Two hands

A clock has `Face` hours, numbered from 0. Two hands start together at hour 0.
Each hand gets its own step size when the clock starts, and that size never
changes. Every tick moves both hands on by their own step.

The clock writes two things down. `gaps` is every gap it has seen between the
hands, counted forwards from hand a round to hand b. `met` is every hour the
two hands have stood on together.

`work/Claims.tla` is the file you edit. It declares the state, gives you
`TypeOK`, and gives you two helpers. `Orbit(s)` is the set of hours that whole
steps of size `s` can reach from hour 0, and `Ahead(x, y)` is how far hour `y`
sits ahead of hour `x`. Two claims under that are missing.

**Claim 1.** Every gap the two hands have stood at could have been reached by
whole steps of one fixed size away from hour 0. Working out what that size is
is part of the claim.

**Claim 2.** Every hour the two hands have shared could have been reached by
whole steps of either hand.

Write both, then run all three machines.

## The three machines

They all read your two claims out of `Claims.tla`, so you write each claim
once.

| machine | what it is | must report |
|---|---|---|
| `TwoHands` | the real clock | exit code 0 |
| `Fudge` | writes the gap down one hour too far ahead | exit code 12 |
| `Alone` | writes hand a's hour down whether or not hand b is there | exit code 12 |

```bash
bash completion/verify-item.sh completion/sets/02-twohands
```

Exit code 150 on all three means a `FILL_IN` marker is still there, or what
you wrote does not parse.

## Reading the three codes

`Fudge` answers to claim 1 and `Alone` answers to claim 2, so the codes say
which claim is weak rather than only that one is.

| signature | what it means |
|---|---|
| 0, 12, 12 | both claims hold and both bite |
| 0, 0, 0 | neither claim says anything |
| 0, 12, 0 | claim 1 is good, claim 2 is too weak |
| 0, 0, 12 | claim 2 is good, claim 1 is too weak |

`Tracks == TRUE` and `Shared == TRUE` score the second row. They pass the real
clock, which is why two of the three machines are built to fail.

A claim about where the hands are standing now, rather than about the whole
set the clock has written down, scores the third or the fourth row. Both
broken machines move their hands correctly, so the current state is no help
in telling them apart.
