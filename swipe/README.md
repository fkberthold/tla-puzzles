# The swipe rung

A phone recognition channel graded by TLC. The reader sees a stream of single
lines and answers each one with a swipe: right for true, left for false, down
for not a true-or-false claim at all, up to review the last wrong answer.
Verdicts are baked when the corpus is built, so the phone runs no model
checker.

Epic `tla-7xql` carries the contract and the seven locked decisions. This file
covers what the level 0 rung looks like once there are real items in it, which
is bead `tla-7xql.2`.

## Why level 0 came first

A level 0 expression has no variable, no prime and no temporal operator.
`Cardinality(SUBSET {1, 2, 3}) = 8` is one. It is the only one of TLA+'s four
levels that needs **no model screen at all**, because there is no state for a
claim to be about, and that is what lets it run at flow speed on a phone.

Decision D1 says the CONSTANTS stay visible, since they change every answer.
At level 0 there are none to show, and that is true by construction rather
than by promise: the modules `bake.sh` generates declare no CONSTANT and no
VARIABLE, so a claim naming one is a free identifier and SANY refuses the
module. `harness/test-swipe-level0.sh` asserts the absence of both
declarations.

The gate also scans each claim's text for a prime, a temporal operator and a
free identifier, which is the fast half of the same check. **That scan should
probably be replaced by `harness/levels/levels.sh`**, which landed with bead
`tla-7xql.3` after this corpus was built and reads the level off SANY's
semantic tree rather than guessing from text. One parse per module, no TLC.
The two routes agree on the corpus as it stands, and I'd rather have the
parser than my own tokenizer: mine already got TLA+'s backslash operators
wrong once, reading `\cup` as a name called `cup` on 20 of 80 claims.

## What is here

```
swipe/level0/TEMPLATES.tsv   five families, each with its generating idea
swipe/level0/ITEMS.tsv       80 items, 16 per template
swipe/level0/bake.sh         the verdict channel: --check, --write, --stats
harness/test-swipe-level0.sh the gate, 37 assertions
```

Both tables carry a literal marker in field 1, so prose in them can never be
read as data. Read rows with `awk -F'\t'` or `cut`, never with
`IFS=$'\t' read`: tab is IFS whitespace, so a run of tabs collapses and an
empty field disappears.

Per-template grouping is a column and not a comment, because bead
`tla-7xql.1`, the stem-blind gate, runs **per template**. The artifact it
hunts is template-local, and a pooled number hides a bad template behind good
ones.

```bash
awk -F'\t' '$1 == "ITEM" && $3 == "T2"' swipe/level0/ITEMS.tsv
grep '^ITEM' swipe/level0/ITEMS.tsv | cut -f3,6 | sort | uniq -c
swipe/level0/bake.sh --stats
```

## The verdict channel

Every verdict comes from a TLC exit code through `harness/verdict.sh`. Nothing
reads TLC's stdout, which is the rule `V2-PLAN.md` section 5.1 sets for the
rest of the harness.

One run is not enough, because `ASSUME e` exits 10 both when `e` is false and
when `e` fails to evaluate. The pair of runs splits them:

| `ASSUME (e)` | `ASSUME ((e) \/ ~(e))` | verdict | swipe |
|---|---|---|---|
| 0 | 0 | the claim holds | right |
| 10 | 0 | the claim is false | left |
| 10 | 10 | it does not evaluate | down |

A well-formed boolean satisfies `e \/ ~e` whatever its value, so only a claim
that fails to evaluate can redden the second column. Read the pair as a pair.
Never predict one member from the other, which is hazard H1 on the epic
written one level down.

### A constant INVARIANT is not the channel

This corrects the table the bead was briefed with, which said `{12, 13}` means
refuted. A level 0 expression declared as an `INVARIANT` and found false comes
back **rc 151 CONFIG_ERROR**, not rc 12:

```
Error: The invariant of Refuted is equal to FALSE
```

The mechanism is not new here. `V2-PLAN.md` already records it for the literal
`INVARIANT FALSE`, and its workaround is to assert something state-dependent
that TLC cannot fold. What is new is the reach: it is not about the literal
`FALSE` at all, it covers **every constant-level expression that evaluates to
FALSE**, which is the whole refuted class of this corpus. Measured on TLC
2026.07.31.184830 against `Cardinality(SUBSET {1, 2, 3}) = 6`, and the same
claim with one state-dependent disjunct added does come back 12.

So an invariant channel would have labeled every false item a config defect
and sent it down instead of left. rc 12 needs an invariant TLC cannot fold,
which means a state-dependent one, which means level 1 or above. The
`{12, 13}` row belongs to the other rungs, and this one reads `{0}` against
`{10}`.

### Batching is the whole reason level 0 is cheap

One module with N assumes costs one JVM. Worst of three back-to-back runs:
382 ms at N=1, 535 ms at N=100, 684 ms at N=1000. So `--check` runs three
batch modules over 80 items rather than 80 processes.

The one class that cannot batch is the items that do not evaluate. The first
evaluation error aborts the whole batch at rc 10, and only the items before it
print, so each of those gets its own run. Ten items, ten JVMs, and the batch
covers the other seventy.

## The two kind fields, and why they are two

Decision D5 says the item's kind is tagged in the question. Decision D3 says
the kind is kept in the data so accuracy can be split by it. **Those cannot be
the same column.** D3's kind is the answer, so showing it with the question
gives the item away. With real items in hand the two decisions are reading one
word two ways.

So there are two fields:

- **`ask`**: the tag the reader sees. `holds` or `implies`, naming which of
  the epic's question kinds the line is. It does not determine the answer.
- **`kind`**: what the data keeps. `true`, `false`, `vacuous` or `illformed`.
  The reader never sees it before answering.

The swipe falls out of `kind`: true goes right, false goes left, and both
`vacuous` and `illformed` go down. That merge is D3, and it is forced rather
than chosen, since without it a vacuous item has no correct swipe at all. The
cost is that a down swipe stops telling the two apart, and `kind` is where
that discrimination went.

`implies` is worth its own tag because the vacuous-antecedent trap lives
there. A reader who checks the consequent of `P => Q` and ignores a false `P`
gets it wrong, and five of the ten vacuous items in the corpus are that shape.
Measured on this build, `=>` short-circuits: `Len(<<>>) = 1 => Head(<<>>) = 0`
exits 0, although the consequent does not denote. So an implication can be
true while half of it is meaningless, which is the lesson and also a thing the
channel has to get right.

## Vacuity is measured, not asserted

A vacuous item and a plainly true one both exit 0, so the exit-code pair
cannot tell them apart. Field 10 carries a **vacuity witness**: a second level
0 expression that holds exactly when the item is vacuous. For
`\A n \in 5..1 : n * n = 0` the witness is `5..1 = {}`, and for a false
antecedent it is the negation of the antecedent. The witnesses run in their
own batch, so the vacuous label has a TLC run behind it like every other
label.

## Every item carries a correction

L2 on the epic, and it is not optional. Measured on this task shape: a
falsehood is reproduced later at .19 with no feedback, .15 with a bare
verdict, and .04 with the verdict plus the corrected claim. A bare verdict
sits on the measured floor, so field 11 is required and the gate rejects a
blank one and a five-character stub.

## The mix, and the chance floor

L7 says the mix must carry true and false substantively, because a true-heavy
corpus transfers back to recognition and nowhere else. Every template carries
six right, six left and four down.

The base rate the stem-blind gate needs is the share of the most common swipe
in that template's own output, not one third. Here it is 37.5% in all five
templates, which is close to the 34.3% majority baseline the SNLI result in
bead `tla-7xql.1` is measured against. `bake.sh --stats` prints it, and the
gate fails a template that goes over 60% or drops below three of either
polarity.

## One constraint on delivery

The ids run in kind order inside each template, so 01 to 06 are true, 07 to 12
are false, 13 and 14 are vacuous, and 15 and 16 do not evaluate. That order is
for reviewing the table, and **the delivery order must not be the id order**:
served as they sit, a reader meets six rights in a row. Nothing in this bead
delivers items, so the constraint lives here for whoever builds that.

## No item depends on `\div` with a negative dividend

The jar's own `Naturals.tla` states the contract:

> `a % b` and `a \div b` are defined so that for any integers `a` and `b` with
> `b > 0`, the following formula is true: `a = b * (a \div b) + (a % b)`

TLC 2026.07.31.184830 breaks it. Measured with `PrintT`: `-17 \div 5 = -3` and
`-17 % 5 = 3`, so `5 * -3 + 3` is -12 rather than -17. The remainder follows
the contract and sits in `0..4`, so it is the quotient that is wrong. It
truncates toward zero where the contract forces it to round down, and
`-9 \div 4 = -2` and `-7 \div 3 = -2` go the same way.

TLC is the authority the bake reads, so an item on `-17 \div 5` would ship
TLC's answer as the truth and teach a falsehood. Three authored items hit this
and were replaced rather than relabeled. The gate carries a tripwire on the
broken identity, so a TLC that fixes `\div` turns the suite red on purpose and
whoever reads it can lift the constraint.

## Working on the corpus

```bash
swipe/level0/bake.sh --stats                 # counts, mix and base rates
swipe/level0/bake.sh --check                 # confirm every stored verdict
swipe/level0/bake.sh --check --template T2   # one template, 5 JVMs
swipe/level0/bake.sh --write                 # measure every item from scratch
harness/test-swipe-level0.sh                 # the gate
```

Fields 6, 7 and 8 belong to `bake.sh`. Author an item with a `-` in all three
and a `kind` you believe, then run `--write`: it measures both probes, fills
the three fields, and **reports every item where TLC disagrees with the
authored kind** rather than writing over it. Field 5 is a prediction and the
bake is there to contradict it. It contradicted three of the first eighty.
