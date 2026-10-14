# Answer

```tla
[][count' = count + 1]_count
```

Every step that changes the count raises it by one. S2 is allowed because
it leaves `count` unchanged, and a step that leaves the subscript unchanged
is a stuttering step of the formula, whatever it does to the clock.

`[][count' = count + 1]_<<count>>` is the same formula with a one-tuple
subscript. Measured identical on every row.

## The subscript is the answer

The published default is to subscript over the tuple of every variable, and
it holds at 96.2% of resolvable sites (`.claude/rules/tla-practice.md`,
section 2). This item is the other 3.8%, on purpose. Lamport's own example
is `MinTime == [][HCnxt => (t >= 3600 - Rho)]_hr`, with the comment "we
don't care about steps that leave hr unchanged". The narrow subscript is
sound when the action mentions only the subscripted variables, which is
`count` alone here. It's also the only way to let the clock tick.

A reader who writes `_vars` with `vars == <<count, clock>>` has written the
most common shape in the corpus and the wrong formula for this table. S2
changes the tuple, so the action has to hold, and 3 isn't 4.

## Measured

| run | rows | rc |
|---|---|---|
| `AnswerAllowedRun` | S1, S2, S5, S6 | rc 0 |
| `AnswerS3Run` | S3 | rc 13 |
| `AnswerS4Run` | S4 | rc 13 |
| the `V1` runs | the same | rc 0, rc 13, rc 13 |

A single step refutes each forbidden row, and TLC still exits 13, because a
boxed action goes through the implied-action channel
(`harness/verdict.sh:81-91`).

## Elimination table

| wrong neighbor | row | rc | why |
|---|---|---|---|
| `[][count' = count + 1]_<<count, clock>>` | S2 | 13 | the tick changes the tuple, so the action must hold, and the count didn't move |
| `[][count' >= count]_count` | S3 | 0 | monotone is weaker than by-one |
| `[][count' \in {count - 1, count + 1}]_count` | S4 | 0 | a turnstile only counts in |
| `[][(count' = count + 1 /\ UNCHANGED clock) \/ (count' = count /\ clock' # clock)]_<<count, clock>>` | S5 | 13 | spelling out the clock's moves forbids a tick and an entry in one step, which the rules never did |
| `[](count' = count + 1)` | none | 150 | SANY: "[] followed by action not of form [A]_v." |
| `[][count' = count + 1]_clock` | S2, S3 | 13, 0 | the wrong variable. Rejects an allowed tick and admits a jump |

The fourth row is the one I'd point a reader at. It's what you write after
S2 kills `_vars` if you still think the subscript is the whole tuple: list
the clock's moves as a disjunct. S5 kills that, because the rules allow a
tick and an entry in the same step and the enumeration doesn't. The narrow
subscript says the same thing in six characters and gets S5 right.

## Runs

Every module below is a three-line wrapper that extends the step table and
runs the cfg beside it, which is the pairing `harness/drill-gate.sh` checks.
`bash drill/temporal/verify-item.sh drill/temporal/08-turnstile-clock`
reproduces the rc column.

| module | spec | rows | checks | rc |
|---|---|---|---|---|
| `AnswerAllowedRun` | `Spec` | 1, 2, 5, 6 | `PROPERTY Answer` | rc 0 |
| `AnswerS3Run` | `Spec` | 3 | `PROPERTY Answer` | rc 13 |
| `AnswerS4Run` | `Spec` | 4 | `PROPERTY Answer` | rc 13 |
| `N1S2Run` | `Spec` | 2 | `PROPERTY N1` | rc 13 |
| `N2S3Run` | `Spec` | 3 | `PROPERTY N2` | rc 0 |
| `N3S4Run` | `Spec` | 4 | `PROPERTY N3` | rc 0 |
| `N4S5Run` | `Spec` | 5 | `PROPERTY N4` | rc 13 |
| `N5S1Run` | `Spec` | 1 | `PROPERTY N5` | rc 150 |
| `N6S2Run` | `Spec` | 2 | `PROPERTY N6` | rc 13 |
| `N6S3Run` | `Spec` | 3 | `PROPERTY N6` | rc 0 |
| `V1AllowedRun` | `Spec` | 1, 2, 5, 6 | `PROPERTY V1` | rc 0 |
| `V1S3Run` | `Spec` | 3 | `PROPERTY V1` | rc 13 |
| `V1S4Run` | `Spec` | 4 | `PROPERTY V1` | rc 13 |

## Why not in prompt

Six step rows, no formula. The reader has to retrieve the box, the prime,
and that there's a subscript at all, then choose it.

The caveat: "the clock isn't the turnstile's business" is doing real work.
Without it S2 is unmotivated, and with it a reader who knows the subscript
rule is most of the way there. I don't see how to drop it without making S2
look like a typo. The other caveat is the one in the section above. This is
the minority idiom, and the item has to say so or it drills the exception
as the rule.
