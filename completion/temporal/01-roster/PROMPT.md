# Roster

One baton, held by one of `Site` sites. A site that wants the baton puts its
name down on a list. A grant hands the baton to a site whose name is on the
list, and takes that name off. Weak fairness on the grant is what keeps the
list moving.

`work/Claims.tla` is the file you edit. It declares the state, gives you
`TypeOK` and the `vars` tuple, and leaves two claims missing.

**Claim 1.** A site that has put its name down does not wait for the baton
forever.

**Claim 2.** Whenever the baton moves, it moves to a site whose name was on
the list.

Write both, then run all three machines.

## The three machines

They all read your two claims out of `Claims.tla`, so you write each claim
once.

| machine | what it is | must report |
|---|---|---|
| `Roster` | the real roster | exit code 0 |
| `Stall` | takes every step the real roster takes, and nothing obliges a grant to happen | exit code 13 |
| `Askew` | hands the baton on whenever anybody is waiting, and not necessarily to them | exit code 13 |

```bash
bash completion/verify-item.sh completion/temporal/01-roster
```

Both claims are temporal, so a violation comes back as 13 and not as 12.
Exit code 150 on all three means a `FILL_IN` marker is still there, or what
you wrote does not parse.

## Reading the three codes

`Stall` answers to claim 1 and `Askew` answers to claim 2, so the codes say
which claim is weak rather than only that one is.

| signature | what it means |
|---|---|
| 0, 13, 13 | both claims hold and both bite |
| 0, 0, 0 | neither claim says anything |
| 0, 13, 0 | claim 1 is good, claim 2 is too weak |
| 0, 0, 13 | claim 2 is good, claim 1 is too weak |

`Answered == TRUE` and `OnRequest == TRUE` score the second row. They pass
the real roster, which is why two of the three machines are built to fail.

A claim that only says somebody was waiting lands on the third row. `Askew`
is the machine that cares who.
