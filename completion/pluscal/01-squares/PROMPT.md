# Squares

A number `n` is picked when the run starts, anywhere from 0 to 15. The algorithm
walks `r` up one at a time and carries `s` along beside it, and it stops as soon
as `s` has gone past `n`.

`work/Claims.tla` is the file you edit. It declares the four names the algorithm
ends up using and gives you `TypeOK`. Two claims under that are missing.

**Claim 1.** In every state, `s` is the square of one more than `r`.

**Claim 2.** Once the algorithm has finished, `r * r` is at most `n`, and `n` is
below `s`.

Claim 1 is what turns claim 2's two comparisons into "`r` is the whole-number
square root of `n`". Neither claim says that on its own.

Write both, then run all three machines.

## The three machines

They all read your two claims out of `Claims.tla`, so you write each claim once.

| machine | what it is | must report |
|---|---|---|
| `Squares` | the real algorithm | exit code 0 |
| `Stall` | carries `s` correctly and never moves `r` | exit code 12 |
| `Over` | takes one turn of the loop too many | exit code 12 |

```bash
bash completion/verify-item.sh completion/pluscal/01-squares
```

Exit code 150 on all three means a `FILL_IN` marker is still there, or what you
wrote does not parse.

## Reading the three codes

`Stall` answers to claim 1 and `Over` answers to claim 2, so the codes say which
claim is weak rather than only that one is.

| 0, 12, 12 | both claims hold and both bite |
|---|---|
| 0, 0, 0 | neither claim says anything |
| 0, 12, 0 | claim 1 is good, claim 2 is too weak |
| 0, 0, 12 | claim 2 is good, claim 1 is too weak |

`Tied == TRUE` and `Landed == TRUE` score the second row. They pass the real
algorithm, which is why two of the three machines are built to fail.

## One thing about the files

The algorithm and its translation sit inside each machine, because that is where
`pcal` needs them. So `Claims.tla` cannot declare the variables and be extended
the way it is in the other families. It declares the same four names and is
instantiated instead. The `C == INSTANCE Claims` line at the bottom of each
machine, with no `WITH` clause, is what binds those names to that machine's own
variables and brings your claims in. You do not have to touch those lines.
