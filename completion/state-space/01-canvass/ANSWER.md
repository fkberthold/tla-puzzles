# ANSWER: completion/state-space/01-canvass

## The two claims

```tla
Known == \A d \in Door : noted[d] # Nil => noted[d] \in heard

Counted == Cardinality(heard) <= calls
```

## Why claim 1 holds on the real canvass

`Knock(d, a)` writes `a` against `d` and adds `a` to `heard` in the same
step, and nothing ever removes an answer from `heard`. At `Init` every door
holds `Nil`, so the antecedent is false everywhere and the claim starts out
true.

## Why claim 2 holds on the real canvass

`heard` gains at most one element per knock and `calls` gains exactly one, so
the difference never falls. Both start at zero.

## Accepted variants

For claim 1, `{noted[d] : d \in Door} \ {Nil} \subseteq heard` is the same
statement as a set containment. `\A d \in Door : noted[d] \in heard \cup
{Nil}` is the same again, with the case split folded into the right-hand
side.

For claim 2, `Cardinality(heard) =< calls` is the same operator spelled the
other way, and `calls >= Cardinality(heard)` is the same comparison.

What does not count is a claim about the shape of the state. `heard \subseteq
Answer` is already in `TypeOK`, and it passes all three machines.

## What each machine measures

`Door = {d1, d2}`, `Answer = {yes, no, maybe}`, `Limit = 4` throughout. Taken
from each machine's `.cfg`.

| machine | reference answer | both `TRUE` | claim 1 only | claim 2 only | unfilled |
|---|---|---|---|---|---|
| `Canvass` | 0, 127 distinct | 0 | 0 | 0 | 150 |
| `Mute` | 12 | 0 | 12 | 0 | 150 |
| `Chatty` | 12 | 0 | 0 | 12 | 150 |

Five distinct signatures, so the three codes separate every half-right answer
from the full one.

`Mute` is the machine that makes claim 1 necessary. It still counts the call,
so `Cardinality(heard) <= calls` holds on it with room to spare, and only
claim 1 can fire.

`Chatty` is the machine that makes claim 2 necessary, and it takes the other
route. It adds every answer to `heard` on the first knock, which keeps claim
1 true: the answer it wrote against the door is in `heard` along with the two
it never heard. So claim 2 is the only thing left that can catch it.

Both broken machines report at 2 distinct states, which is one knock. The
real canvass takes 127, which is every reachable combination under the bound.

## The CONSTRAINT, and what it buys

`Bounded == calls \in 0..Limit` is given, not asked for. It is the only
reason the run finishes. Measured: a copy of `Canvass.cfg` with the
`CONSTRAINT Bounded` line deleted returns 124 under
`harness/verdict.sh -t 20`.

So rc 0 means no violation among the behaviours that stay under the bound,
and the bound is a decision rather than a description. `reading/state-space/02-tickets`
makes the same point and is worth reading next to this item.

One thing this item cannot do, and the reason is worth knowing.
`completion/verify-item.sh` goes through `harness/verdict.sh`, which passes
TLC `-deadlock` unless the caller asks otherwise, and it refuses the run at
99 when a `.cfg` says `CHECK_DEADLOCK TRUE`. Measured: a copy of
`Canvass.cfg` with that line appended returns 99 `CHECK_DID_NOT_RUN`. Both
state-space reading models carry the keyword, so the thing to carry over from
them here is the `CONSTRAINT` and not the deadlock check.

## Where the module comes from

`reading/state-space/02-tickets` is the sibling. It has the climbing counter,
the `Nil` model value, the set of model values and the `CONSTRAINT` that buys
termination. None of its five invariants is either claim here, so the page
shows how the configuration surface fits together and says nothing about what
to write.
