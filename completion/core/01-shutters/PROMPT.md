# Shopfront shutters

A shopfront has five shutters in a row, numbered 1 to 5, and they all start
shut. A catch sits between each neighbouring pair, so there are four catches.
Working one flips both shutters of its own pair: a shut shutter opens, and an
open one shuts. A tally counts how many times a catch has been worked, and it
stops the shop at `Limit`.

`work/Claims.tla` is the file you edit. It declares the state, gives you
`TypeOK`, and names the five shutters. Two claims under that are missing.

**Claim 1.** The count of open shutters is never odd.

**Claim 2.** Once the shopfront is back to all shut, with a catch worked at
least once, the tally stands at an even number.

Write both, then run all three machines.

## The three machines

They all read your two claims out of `Claims.tla`, so you write each claim
once.

| machine | what it is | must report |
|---|---|---|
| `Shutters` | the real shopfront | exit code 0 |
| `Single` | every catch has come loose and flips one shutter, not two | exit code 12 |
| `Looped` | the row runs round a corner, so a fifth catch joins shutter 5 to shutter 1 | exit code 12 |

```bash
bash completion/verify-item.sh completion/core/01-shutters
```

Exit code 150 on all three means a `FILL_IN` marker is still there, or what
you wrote does not parse.

## Reading the three codes

`Single` answers to claim 1 and `Looped` answers to claim 2, so the codes say
which claim is weak rather than only that one is.

| 0, 12, 12 | both claims hold and both bite |
|---|---|
| 0, 0, 0 | neither claim says anything |
| 0, 12, 0 | claim 1 is good, claim 2 is too weak |
| 0, 0, 12 | claim 2 is good, claim 1 is too weak |

`EvenOpen == TRUE` and `ShutEvenly == TRUE` score the second row. They pass
the real shopfront, which is why two of the three machines are built to fail.
