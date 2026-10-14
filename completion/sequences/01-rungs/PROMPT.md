# Rungs

A text is built one character at a time out of `(` and `)`, up to `Limit`
characters. A `(` opens a bracket and a `)` closes one, and a `)` only goes on
when there is something open to close. `open` is how many brackets the text
leaves open right now.

The text also writes `rungs` down: the set of depths it has stood at. It
starts at depth 0 with nothing open, and depth 0 is already in `rungs`.

`work/Claims.tla` is the file you edit. It declares the state, gives you
`TypeOK`, and defines `Depth(t)` as the number of brackets a text `t` leaves
open. Two claims under that are missing.

**Claim 1.** The depths written down climb from 0 upwards with no depth
missing in between.

**Claim 2.** Every prefix of the text leaves the string at a depth that is
written down.

Write both, then run all three machines.

## The three machines

They all read your two claims out of `Claims.tla`, so you write each claim
once.

| machine | what it is | must report |
|---|---|---|
| `Rungs` | the real text | exit code 0 |
| `Topped` | also writes down the deepest depth the text could ever reach | exit code 12 |
| `Shed` | strikes a depth off again when a bracket closes | exit code 12 |

```bash
bash completion/verify-item.sh completion/sequences/01-rungs
```

Exit code 150 on all three means a `FILL_IN` marker is still there, or what
you wrote does not parse.

## Reading the three codes

`Topped` answers to claim 1 and `Shed` answers to claim 2, so the codes say
which claim is weak rather than only that one is.

| signature | what it means |
|---|---|
| 0, 12, 12 | both claims hold and both bite |
| 0, 0, 0 | neither claim says anything |
| 0, 12, 0 | claim 1 is good, claim 2 is too weak |
| 0, 0, 12 | claim 2 is good, claim 1 is too weak |

`Ladder == TRUE` and `Standing == TRUE` score the second row. They pass the
real text, which is why two of the three machines are built to fail.

Claim 2 is about every prefix and not only about the current depth. `Shed`
keeps `open` in `rungs` at every state it reaches, so a claim that only talks
about `open` scores the third row.
