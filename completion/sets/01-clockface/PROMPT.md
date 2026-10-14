# Clock face

A clock has `Face` hours, numbered from 0. One hand starts at hour 0. Its step
size is picked when the clock starts and never changes, and every tick moves
the hand on by that many hours. The hand marks every hour it lands on.

`work/Claims.tla` is the file you edit. It declares the state, gives you
`TypeOK`, and defines `Orbit(s)` as the set of hours that whole steps of size
`s` can reach from hour 0. Two claims under that are missing.

**Claim 1.** The hand has never landed anywhere that whole steps of its own
step size could not have reached.

**Claim 2.** Once the hand is back at hour 0, having moved at all, it has
landed on every hour its step size can reach and nothing else.

Write both, then run all three machines.

## The three machines

They all read your two claims out of `Claims.tla`, so you write each claim
once.

| machine | what it is | must report |
|---|---|---|
| `ClockFace` | the real clock | exit code 0 |
| `Stray` | marks one hour extra, and stops before it comes home | exit code 12 |
| `Skip` | moves two steps while still calling one its step size | exit code 12 |

```bash
bash completion/verify-item.sh completion/sets/01-clockface
```

Exit code 150 on all three means a `FILL_IN` marker is still there, or what
you wrote does not parse.

## Reading the three codes

`Stray` answers to claim 1 and `Skip` answers to claim 2, so the codes say
which claim is weak rather than only that one is.

| 0, 12, 12 | both claims hold and both bite |
|---|---|
| 0, 0, 0 | neither claim says anything |
| 0, 12, 0 | claim 1 is good, claim 2 is too weak |
| 0, 0, 12 | claim 2 is good, claim 1 is too weak |

`Walked == TRUE` and `Closes == TRUE` score the second row. They pass the real
clock, which is why two of the three machines are built to fail.
