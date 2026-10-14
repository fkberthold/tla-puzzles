# The cloakroom

A cloakroom has four pegs and four coats, numbered 1 to 4. Every coat starts
on the peg it came in on. The attendant has one move: take two coats and swap
them over, each onto the peg the other was using. A tally counts the swaps,
and it stops the attendant at `Limit`.

`work/Claims.tla` is the file you edit. It declares the state, gives you
`TypeOK`, and defines `Own` as the peg each coat came in on. Two claims under
that are missing.

**Claim 1.** No peg carries two coats.

**Claim 2.** For every swap the attendant has made, at most two coats hang
away from the peg they came in on.

Write both, then run all three machines.

## The three machines

They all read your two claims out of `Claims.tla`, so you write each claim
once.

| machine | what it is | must report |
|---|---|---|
| `Cloakroom` | the real cloakroom | exit code 0 |
| `Doubled` | hangs a coat on a peg another coat is using, and leaves that one there | exit code 12 |
| `Threeway` | moves three coats round in one go and books it as one swap | exit code 12 |

```bash
bash completion/verify-item.sh completion/functions-records/01-cloakroom
```

Exit code 150 on all three means a `FILL_IN` marker is still there, or what
you wrote does not parse.

## Reading the three codes

`Doubled` answers to claim 1 and `Threeway` answers to claim 2, so the codes
say which claim is weak rather than only that one is.

| 0, 12, 12 | both claims hold and both bite |
|---|---|
| 0, 0, 0 | neither claim says anything |
| 0, 12, 0 | claim 1 is good, claim 2 is too weak |
| 0, 0, 12 | claim 2 is good, claim 1 is too weak |

`OnePerPeg == TRUE` and `FewMoved == TRUE` score the second row. They pass the
real cloakroom, which is why two of the three machines are built to fail.
