# ANSWER: completion/pluscal/01-squares

## The two claims

```tla
Tied == s = (r + 1) * (r + 1)

Landed == (pc = "Done") => (r * r <= n /\ n < s)
```

## Why claim 1 holds on the real algorithm

`Init` sets `r = 0` and `s = 1`, and 1 is `(0 + 1) * (0 + 1)`. The body raises
`s` by `2 * r + 3` and `r` by 1, and `(r + 1) * (r + 1) + 2 * r + 3` works out to
`(r + 2) * (r + 2)`. So the body carries the identity from `r` across to
`r + 1`.

Both assignments read the pre-step state, and that was read off the translation
rather than assumed. `pcal` emits `s' = s + 2 * r + 3` and `r' = r + 1` side by
side under the same `IF`, both over unprimed `r`. Writing the `s` assignment
first makes the module say the same thing whichever way `pcal` sequences a label.

## Why claim 2 holds on the real algorithm

The loop runs while `s <= n`, so at `Done` the current `s` has passed `n`, which
is the second conjunct. `r` last moved on a turn whose guard was true, and `s`
held `r * r` at the start of that turn, so `r * r <= n`. At `n = 0` the loop
never runs, `r` stays 0, and `0 <= 0` holds.

The guard is not optional. `r * r <= n` unguarded is false in mid-run, where `r`
has already moved past the root.

## Accepted variants

Both of these were run and both score the reference signature:

```tla
Tied == s = (r + 1) ^ 2

Landed == (s > n) => (r * r <= n)
```

`^` comes from `Naturals`, which every machine already extends.

That second variant is worth knowing about, because it drops `pc` and the second
conjunct and still catches `Over`. `n < s` is true at `Done` on all three
machines, so that conjunct restates the loop's own exit test rather than anything
a machine here can break. It earns its place by making the claim read as "`r` is
the root" instead of as half of it.

## What each machine measures

`n \in 0..15`, so one run covers 16 inputs. Codes from `harness/verdict.sh`.

| machine | reference answer | both `TRUE` | claim 1 only | claim 2 only |
|---|---|---|---|---|
| `Squares` | 0, 66 distinct | 0 | 0 | 0 |
| `Stall` | 12, 18 distinct | 0 | 12 | 0 |
| `Over` | 12, 33 distinct | 0 | 0 | 12 |

Unfilled is 150 on all three machines.

Four distinct signatures, so the three codes separate every half-right answer
from the full one. That is the whole verification contract for this item, and it
is why there are two broken machines rather than one.

Each broken machine is caught by one claim and survives the other. `Stall` keeps
`r` at 0 forever, so both of claim 2's comparisons hold at `Done` and only the
loop invariant can see it. `Over` runs the real body, so claim 1 holds on it and
only the terminal claim bites. `Over` breaks first at `n = 0`, where `s <= n + 1`
lets one turn through and `r` lands on 1.

`PROPERTY Termination` is in all three configs and holds on all three, so it does
not discriminate. It is there because `--fair algorithm` put a `WF_vars(Next)` on
`Spec`, and an unchecked fairness conjunct is a conjunct nothing exercises.
