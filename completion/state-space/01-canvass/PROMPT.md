# Canvass

A canvasser knocks on doors. Every knock writes what the door said against
that door, adds the answer to the set of answers the canvasser remembers
hearing, and counts the call. A door can be knocked on again, and the new
answer replaces the old one against that door. Nothing ever lowers the call
count, so the state space is infinite and a `CONSTRAINT` is what makes the
run finish.

`work/Claims.tla` is the file you edit. It declares the state, gives you
`TypeOK`, the `vars` tuple and the `Bounded` search bound, and leaves two
claims missing.

**Claim 1.** Nothing is written against a door that the canvasser does not
also remember hearing.

**Claim 2.** The canvasser has never heard more distinct answers than the
number of knocks made.

Write both, then run all three machines.

## The three machines

They all read your two claims out of `Claims.tla`, so you write each claim
once.

| machine | what it is | must report |
|---|---|---|
| `Canvass` | the real canvass | exit code 0 |
| `Mute` | writes the answer against the door and never remembers hearing it | exit code 12 |
| `Chatty` | remembers hearing every answer there is, off one knock | exit code 12 |

```bash
bash completion/verify-item.sh completion/state-space/01-canvass
```

Exit code 150 on all three means a `FILL_IN` marker is still there, or what
you wrote does not parse.

## Reading the three codes

`Mute` answers to claim 1 and `Chatty` answers to claim 2, so the codes say
which claim is weak rather than only that one is.

| signature | what it means |
|---|---|
| 0, 12, 12 | both claims hold and both bite |
| 0, 0, 0 | neither claim says anything |
| 0, 12, 0 | claim 1 is good, claim 2 is too weak |
| 0, 0, 12 | claim 2 is good, claim 1 is too weak |

`Known == TRUE` and `Counted == TRUE` score the second row. They pass the
real canvass, which is why two of the three machines are built to fail.

`Bounded` is given rather than asked for, and it is worth reading before you
start. It is named on a `CONSTRAINT` line in all three `.cfg` files, so a
keyword in a `.cfg` is reaching an operator you can see in `Claims.tla`. Take
the line out and the run does not finish.
