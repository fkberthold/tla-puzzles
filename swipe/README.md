# The swipe rung

A phone recognition channel graded by TLC. The reader sees a stream of single
lines and answers each one with a swipe: right for true, left for false, down
for not a true-or-false claim at all, up to review the last wrong answer.
Verdicts are baked when the corpus is built, so the phone runs no model
checker.

Epic `tla-7xql` carries the contract and the seven locked decisions. This file
covers what the level 0 rung looks like once there are real items in it, which
is bead `tla-7xql.2`, grown to a size the stem-blind gate can decide in bead
`tla-7xql.7`.

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
swipe/level0/ITEMS.tsv       240 items, 48 per template
swipe/level0/bake.sh         the verdict channel: --check, --write, --stats
harness/test-swipe-level0.sh the gate
harness/swipe/stemblind.sh   the stem-blind instrument
harness/test-swipe-stemblind.sh  the gate over that instrument
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

## 48 items per template, and why that number

Bead `tla-7xql.7` grew the corpus from 80 items to 240 for one reason: at 16
items per template the stem-blind gate could not decide anything. Run
`harness/swipe/stemblind.sh power --n 16` and the exact binomial says a judge
needs 10 of 16, which is 25 points over the 0.3750 floor, and an artifact has
to make the label 69.0 percent predictable before the gate fires at 80 percent
power.

Gururangan's published result was 67 percent against a 34.3 percent baseline.
So the finding the gate was copied from would have sat right at the edge of
what 16 items can see.

| items | crit | critacc | tolerance | detectable at 0.80 power |
|---|---|---|---|---|
| 16 | 10 | 0.6250 | 0.2500 | 0.6900 |
| 32 | 18 | 0.5625 | 0.1875 | 0.6190 |
| 48 | 25 | 0.5208 | 0.1458 | 0.5705 |
| 64 | 31 | 0.4844 | 0.1094 | 0.5295 |

At 48 the tolerance is 14.6 points and detection sits at 0.5705, which clears
Gururangan's 0.67 with room. 32 would have met the bar as well, at 0.6190, and
the bead allowed it. I took 48 because each of the five families had that many
distinct generating ideas in it without repeating one in new clothes, and
because the margin is where the next author's habit gets caught rather than
tied.

**The size is a property of the sample, not of the corpus.** That is the whole
argument for growing rather than for loosening a tolerance. A skew that sits
under the floor today becomes a real finding the moment somebody adds items,
and by then it has shipped.

**Pooling the five templates is not the alternative.** It reaches a 10.0 point
tolerance at once, and it throws away the thing the gate measures, since the
artifact is template-local and a pooled number hides one bad family behind
four good ones.

### What the gain buys, measured rather than argued

Plant one token on the first N false items of a template, the way part 4 of
`harness/test-swipe-stemblind.sh` does, and raise N until the probe fires.

| corpus | fires at | share of the template | best stump | null95 |
|---|---|---|---|---|
| 16 per template | 5 of 16 | 31% | 0.6875 | 0.6250 |
| 48 per template | 8 of 48 | 17% | 0.5417 | 0.5208 |

So a token has to be about half as widespread now before the probe can call
it. The permutation null fell from 0.6250 to 0.5208 at the same time, which is
the same gain read off the threshold instead of off the plant.

### Two gate assertions move with the size, and neither is in this bead

`harness/test-swipe-level0.sh` asserts the corpus holds 60 to 100 items, and
`harness/test-swipe-stemblind.sh` compares the live scorer's critical count
against `power --n 16`. Both were written when 16 per template was the size,
and both go red at 48 for that reason alone. They belong to beads
`tla-7xql.2` and `tla-7xql.1`, so this bead reports them rather than editing
the instruments that measure it.

## How an item gets authored, now that the gate can see

Bead `tla-7xql.8` found three authoring signatures in the first 80 items, and
all three were the writer's habit rather than the item's content. That is
Gururangan's finding reproduced in miniature in our own corpus.

The fix is structural rather than a list of tokens to avoid. **Items are
authored in matched groups that share their surface and differ in their
label.** The unit is either a four, one item of each kind built from one idea,
or a pair, a true and a false item built from one idea. Six fours and twelve
pairs is 48, and it landed the mix at 18 true, 18 false, 6 vacuous and
6 ill-formed without anybody counting.

A few groups came apart when the bake contradicted a label or when the probe
named a token, so the file is not six clean fours and twelve clean pairs
today. The arithmetic is the reason the mix holds, and the discipline is what
keeps a token from carrying the answer.

**The mix reads 18 true, 18 false, 6 vacuous, 5 ill-formed and 1 unparsed
now**, and the five rows that changed came out of groups that had already come
apart rather than out of clean fours. `illformed` and `unparsed` share the
down swipe, so the swipe mix and the base rate are untouched by that. The
section on the fourth outcome below carries the ruling and the five claims.

A token that enters the corpus inside a matched group carries the label
distribution of that group, so a decision stump learns nothing from it. A
token unique to one member of a group sits on one item, and leave-one-out
scoring already makes a one-item rule worthless. The length and token-count
features the probe also fits come out balanced for free, since the members of
a group are about the same length.

Run the probe while authoring, not once at the end:

```bash
harness/swipe/stemblind.sh probe
harness/swipe/stemblind.sh probe --template T5
```

If a template flags, re-author it. Do not raise the threshold, do not reseed
for a different permutation draw, and do not drop the item that happens to
carry the signature. Dropping it picks the features the corpus is clean on,
which is the failure the gate exists to catch.

### The vacuity sentinel is gone, and reaching for one rebuilds the signature

The first 80 items marked a vacuous claim's body with `99`: `Cardinality(s) =
99`, `x > 99`, `f[1] = 99`. Five items carried it and every one of them was
vacuous. Leave-one-out neutralizes a one-per-template rule, except T1 carried
two of them, which made `has:99` a real two-item rule sitting at the top of
T1's feature list.

**A reader who learns that a 99 means swipe down never evaluates another
vacuous item.** That reader scores well and has learned nothing, which is the
whole hazard.

So the five sentinels were replaced with ordinary bodies: `Cardinality(s) = 2`,
`x > 0`, `f[1] = 1`, `i > 0`, `Cardinality({}) = 1`. The new vacuous items are
written the same way, and some of their bodies are false where a non-empty
range would have evaluated them.

That is a stronger fix than varying the sentinel per template, which is what
the bead asked for. A varied sentinel is still a sentinel, and five of them
across five families is five rules rather than one. **If a later author wants
a distinguished value in a vacuous body, the thing to know is that the body is
the part the reader must not need.** The lesson of a vacuous universal is the
empty range, so the body should look like a claim worth evaluating.

### The universal quantifier is not a down-swipe marker either

`\A` sat on five items in the first 80, every one of them vacuous. It now
appears on true and false items in every template, so the quantifier says
nothing about the label. `\A s \in SUBSET {1, 2} : s \subseteq {1, 2}` is true,
`\A s \in SUBSET {1, 2} : Cardinality(s) = 1` is false, and only the range
being empty makes one vacuous.

### T5 and the running example

T5 scored 0.6250 on the token `17` in the first 80 items, which was 25 points
over its floor, with four claims carrying `17` and all four true. The named
cause was that the family's declared trap is a negative operand, so a minus
sign got reached for when writing false items while 17 was the running example
the true ones shared. The hand survey found the same shape on `has:-`, `has:%`
and `has:Cardinality`.

`17` and the minus sign now appear on all four kinds in T5. So does `%`, and
so does `Cardinality`.

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
| 150 | 150 | it does not parse | down |

A well-formed boolean satisfies `e \/ ~e` whatever its value, so only a claim
that fails to evaluate can redden the second column. Read the pair as a pair.
Never predict one member from the other, which is hazard H1 on the epic
written one level down.

The last row sits outside that reading. A claim SANY refuses never reaches the
pair at all, so both members read 150 together or neither does. It has its own
section below.

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

### The fourth outcome is rc 150, and it is a parse failure

The first three rows cover claims SANY accepts. A claim SANY refuses comes
back **(150, 150)**, and six of the 160 items authored for `tla-7xql.7` landed
there. The cause was the same every time: two operators from one precedence
band that do not associate with each other.

```
12 \div 2 * 3            \div beside *
TRUE \/ FALSE /\ FALSE   \/ beside /\
12 % 5 + 12 \div 5       % beside +
```

Parentheses fix all three. `2 * 3 % 4` parses and comes out 2, so `*` binds
tighter than `%` and the two never meet as equals. I read those four refusals
and that one acceptance rather than the precedence table, so I'd check the
table before adding a fifth pair to the list. The gate re-measures the first
line on every run: `12 \div 2 * 3 = 18` comes back 150 and
`(12 \div 2) * 3 = 18` comes back 0.

**Frank ruled on 2026-10-18 that a parse failure is a down-swipe item carrying
its own kind, `unparsed`.** Bead `tla-7xql.10` holds the question and the
answer. The reasoning is the one D3 and D5 already use for `vacuous` against
`illformed`. The swipe stays a three-way partition, so a reader always has a
correct gesture, and field 5 keeps the distinction the gesture threw away.

The two kinds share a gesture and arrive through different machinery, and that
is worth keeping straight. `illformed` is a measured fact about a well-formed
boolean that fails to denote, and the (10, 10) pair is what measures it.
`unparsed` never reaches the pair. SANY refuses the module and TLC exits
before either probe runs, so (150, 150) is one fact reported twice rather than
two readings that agree.

**The cost of the ruling is that a typo now has a home, and the declared kind
is what keeps it out.** Before the ruling, a claim that failed to parse
reddened whatever batch it sat in. After it, 150 is a legitimate outcome, so
the protection has to be that a kind earns the pair it predicts. A claim
declared `true` that fails to parse still reddens the holds batch, and
`bake.sh` names the parse failure rather than blaming the kind. A claim
declared `unparsed` that parses fine reddens its own probe at 0 or 10. Section
10 of `harness/test-swipe-level0.sh` controls both directions over a fixture.

### Every kind in the channel ships an item, or says why it does not

Bead `tla-7xql.10` built the `unparsed` machinery and deliberately shipped no
item of the kind, which left a channel row nobody had ever read. Frank ruled
on 2026-10-18 that the corpus closes that by **conversion rather than
addition**: five `illformed` rows became `unparsed` rows, and no row was
added.

<!-- KIND TABLE: harness/test-swipe-level0.sh section 11 reads the rows below. Column 3 is a dash when the kind ships and a reason when it does not. -->

| kind | swipe | deliberately unshipped, and why |
|---|---|---|
| `true` | right | - |
| `false` | left | - |
| `vacuous` | down | - |
| `illformed` | down | - |
| `unparsed` | down | - |

The gate reads that third column in both directions. A kind with no item and
no reason is a channel row no reader has ever met, which is the defect this
table exists to catch. A kind that ships while the column still carries a
reason is a record that has gone stale, which is the same defect wearing the
uniform of its own fix. Section 11 of `harness/test-swipe-level0.sh` reads
this table against the real `ITEMS.tsv`, which section 10 deliberately does
not.

**Conversion is what keeps every number above still true.** `illformed` and
`unparsed` both bake to `down`, so the swipe mix is still 18 right, 18 left
and 12 down per template, the base rate is still 18 of 48 and so 0.3750, and
the power table is unmoved. What moved is the kind mix under the down swipe:
6 vacuous, 5 ill-formed and 1 unparsed, which is still 12. Addition would have
moved n, the base rate and the detection floor together, and every number in
the power table with them.

All five templates carry a parse trap in their own subject matter, so none of
them needed the escape the table offers. The five, each with the message SANY
gives it:

| item | claim | what SANY says |
|---|---|---|
| `L0-T1-21` | `Cardinality({1, 2} \cup {3} \cap {2}) = 2` | precedence conflict between `\union` and `\intersect` |
| `L0-T2-48` | `TRUE \/ FALSE /\ FALSE` | precedence conflict between `\lor` and `\land` |
| `L0-T3-45` | `DOMAIN (1 :> 2 :> 3) = {1}` | precedence conflict between `:>` and `:>` |
| `L0-T4-47` | `Head <<1, 2, 3>> = 1` | encountered `<<` at the token `Head` |
| `L0-T5-45` | `2 ^ 3 ^ 2 = 512` | precedence conflict between `^` and `^` |

**What each conversion cost the group it came out of.** `L0-T1-21` was the
ill-formed member of the intersection idea, so that idea is the pair
`L0-T1-39` and `L0-T1-40` now. `L0-T2-48` was the ill-formed member of the
interval-beside-union idea, leaving `L0-T2-04` and `L0-T2-11`. The other
three cost a duplicate rather than a group: `L0-T3-45` and `L0-T4-47` were
each the second out-of-domain item on a surface that still carries one, at
`L0-T3-15` and `L0-T4-15`, and `L0-T5-45` was the second divide-by-zero
behind `L0-T5-15`. I picked the duplicates first and took an ill-formed
member off a three-item remnant only where no duplicate was there to take.

Four of the five are the shape all six of the `tla-7xql.7` refusals had, two
operators from one precedence band that SANY will not associate, and each one
sits on an operator its own template is about. T4's is a different parse
failure and it is the one a reader arriving from another language writes:
TLA+ has no juxtaposition, so SANY reads `Head` as a finished expression and
then meets the tuple. Parentheses fix all five, and in four of them the two
readings the parentheses choose between give different answers, which is what
makes the trap worth an item.

I expected T2 to be the only family that could produce these, and measuring
the candidates said otherwise. A generator working T2 will still hit them far
more often than a human author does.

### TLC does not always return FALSE on a mismatched comparison

Three items authored as false came back ill-formed, and all three asked TLC to
compare values of different shapes:

```
SUBSET {1, 2} \subseteq Nat              a set, asked whether it sits in Nat
[a : {1, 2}] = {1, 2}                    a set of records against numbers
Append(<<1, 2>>, <<3>>) = <<1, 2, 3>>    a sequence against a number
```

All three kept their claims and changed kind, since the lesson is worth an
item. An author who expects a type mismatch to read FALSE should write the
claim and bake it rather than predict it.

### Batching is the whole reason level 0 is cheap

One module with N assumes costs one JVM. Worst of three back-to-back runs:
382 ms at N=1, 535 ms at N=100, 684 ms at N=1000. So `--check` runs three
batch modules over the whole corpus rather than one process per item.

The one class that cannot batch is the items that do not evaluate. The first
evaluation error aborts the whole batch at rc 10, and only the items before it
print, so each of those gets its own run. At 48 items per template that is 25
ill-formed items, so 25 JVMs.

An `unparsed` item cannot batch either, and for a harder reason. SANY refuses
the whole module, so one bad claim hides every other row sitting in it rather
than only the rows after it, and the probe is the plain claim rather than the
well-formedness form. The corpus carries 5 of those, one per template, so the
single-run class is 30 in all and three batches cover the other 210. The
total did not move when bead `tla-7xql.11` converted five rows, because a row
that cannot batch for one reason costs the same as a row that cannot batch
for the other.

## The two kind fields, and why they are two

Decision D5 says the item's kind is tagged in the question. Decision D3 says
the kind is kept in the data so accuracy can be split by it. **Those cannot be
the same column.** D3's kind is the answer, so showing it with the question
gives the item away. With real items in hand the two decisions are reading one
word two ways.

**Frank ruled on 2026-10-18 that the split stands.** D5 wants rewording rather
than reversing: the kind it names is the reader-visible tag, and D3's kind is
the data field. The corpus was already built that way, so the ruling changes
the contract's wording and no row.

So there are two fields:

- **`ask`**: the tag the reader sees. `holds` or `implies`, naming which of
  the epic's question kinds the line is. It does not determine the answer.
- **`kind`**: what the data keeps. `true`, `false`, `vacuous`, `illformed` or
  `unparsed`. The reader never sees it before answering.

The swipe falls out of `kind`: true goes right, false goes left, and
`vacuous`, `illformed` and `unparsed` all go down. The first merge is D3, and
it is forced rather than chosen, since without it a vacuous item has no
correct swipe at all. `unparsed` is Frank's ruling of 2026-10-18, taken on the
same reading. The cost is that a down swipe stops telling the three apart, and
`kind` is where that discrimination went.

`implies` is worth its own tag because the vacuous-antecedent trap lives
there. A reader who checks the consequent of `P => Q` and ignores a false `P`
gets it wrong, and 15 of the 30 vacuous items are that shape.
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

## Every item carries a flash

L2 on the epic, and it is not optional. Measured on this task shape: a
falsehood is reproduced later at .19 with no feedback, .15 with a bare
verdict, and .04 with the verdict plus the corrected claim. A bare verdict
sits on the measured floor, so field 11 is required and the gate rejects a
blank one and a five-character stub.

**The .04 covers 150 of the 240 items.** L2 tracked whether a falsehood comes
back, so it speaks to the 90 false, 30 vacuous, 25 ill-formed and 5 unparsed
items. Those have something to correct, and an unparsed item is corrected by a
pair of parentheses rather than by a new value. The 90 true items carry the
reason the claim holds
instead, because there is nothing to correct about a true statement, and no
measurement says .04 carries to them. Frank ruled on 2026-10-18 that the field
is required on every row and the number is not claimed over the true ones.

## The mix, and the chance floor

L7 says the mix must carry true and false substantively, because a true-heavy
corpus transfers back to recognition and nowhere else. Every template carries
eighteen right, eighteen left and twelve down, which is the 6/6/2/2 swipe
ratio of the first 80 items scaled by three.

**The ratio is what holds the floor still.** Right is 18 of 48, so the base
rate stays 0.3750 whatever the size, and the power table above can be read
against the item count alone. A size that is not a multiple of eight moves the
floor and every number under it.

**The swipe ratio and the kind mix are two different things, and only the
first one holds the floor.** The twelve down items read 6 vacuous, 5
ill-formed and 1 unparsed per template since bead `tla-7xql.11`, and the floor
did not move, because all three kinds bake to the same swipe. That is the
whole reason the bead converted rows instead of adding them.

The base rate the stem-blind gate needs is the share of the most common swipe
in that template's own output, not one third. Here it is 37.5% in all five
templates, which is close to the 34.3% majority baseline the SNLI result in
bead `tla-7xql.1` is measured against. `bake.sh --stats` prints it, and the
gate fails a template that goes over 60% or drops below three of either
polarity.

## The ids no longer run in kind order

In the first 80 items the ids ran 01 to 06 true, 07 to 12 false, 13 and 14
vacuous, 15 and 16 do not evaluate. **Ids are never renumbered**, so the 160
items added in `tla-7xql.7` took 17 to 48 and the kind order holds inside the
appended block rather than across the template.

That is a weakening of a leak rather than a loss. The id was the sharpest
giveaway in the table, which is why `stemblind.sh emit` hashes it rather than
emitting it, and why the hash runs a full Lehmer step per character instead of
an additive accumulator. A reader who learns the id order learns the answer.
Breaking the ordinal-to-kind map takes one route to that away.

**The delivery order must still not be the id order**, and the file order is
not it either: items sit in their authoring groups, so a true item and its
matched false item are next to each other for review. Nothing in this bead
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

**T5's declared trap is a negative operand, so growing it runs straight at
this.** Every dividend in the corpus is non-negative. The negative operands
live on `%`, which obeys the contract, on `+` and `-`, on intervals like
`-3..3`, on `\in Int`, and on one ill-formed `-17 % 0`. No item carries a note
in field 11 saying it depends on TLC's truncation, because none of them does.
Bead `tla-7n7e` is open on the divergence itself.

## Working on the corpus

```bash
swipe/level0/bake.sh --stats                 # counts, mix and base rates
swipe/level0/bake.sh --check                 # confirm every stored verdict
swipe/level0/bake.sh --check --template T2   # one template
swipe/level0/bake.sh --write                 # measure every item from scratch
harness/test-swipe-level0.sh                 # the corpus gate
harness/swipe/stemblind.sh probe             # the surface-artifact probe
harness/test-swipe-stemblind.sh              # the gate over the probe
```

Fields 6, 7 and 8 belong to `bake.sh`. Author an item with a `-` in all three
and a `kind` you believe, then run `--write`: it measures both probes, fills
the three fields, and **reports every item where TLC disagrees with the
authored kind** rather than writing over it. Field 5 is a prediction and the
bake is there to contradict it. It contradicted three of the first eighty and
nine of the next hundred and sixty.

One trap in the tooling rather than in the corpus. `awk` reads a `-v` value as
a string literal and processes escape sequences in it, so a claim passed that
way arrives with `\subseteq` turned into `subseteq`. Pass it through `ENVIRON`
instead. `harness/test-swipe-level0.sh` carries the same warning beside its
own controls, and it caught me anyway.
