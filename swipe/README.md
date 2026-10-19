# The swipe rung

A phone recognition channel graded by TLC. The reader sees a stream of single
lines and answers each one with a swipe: right for true, left for false, down
for not a true-or-false claim at all. Up walks into the premise one step at a
time and tap comes back out. Verdicts are baked when the corpus is built, so
the phone runs no model checker.

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
swipe/reader/               the published page. See "The reader" below
harness/test-swipe-reader.sh     the gate over it. --static skips the JVMs
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

# Level 1: the ENABLED rung

Bead `tla-7xql.4`, and everything above this line is about level 0. A level 1
item **pins a state** and asks a question about it, so for the first time in
this rung there is a model on screen. That is what settles the epic's open
thread T2, which level 0 could not touch at all: a level 0 item has no model
screen, no pin and nothing to strip, so D2, D7 and the pin were consistent on
paper only until an item was rendered.

```
swipe/level1/TEMPLATES.tsv   one template, the pilot
swipe/level1/ITEMS.tsv       48 items
swipe/level1/bake.sh         the verdict channel: --check, --write, --stats
swipe/level1/render.sh       the model screen, and the transitive strip
harness/test-swipe-enabled.sh  the gate
```

```bash
swipe/level1/bake.sh --stats
swipe/level1/bake.sh --check
swipe/level1/render.sh --item L1-E1-10
swipe/level1/render.sh --model reading/sequences/01-brackets/Brackets.tla --list-stripped
harness/swipe/stemblind.sh probe --items swipe/level1/ITEMS.tsv --surface 9,13
harness/test-swipe-enabled.sh
```

## The reader

The page is at `https://fkberthold.github.io/tla-puzzles/swipe/`. Frank ruled
on 2026-10-18 that this channel is **published rather than delivered**, so it
is the one rung that does not put files in `~/tla-practice`.

**It's two pages since `tla-7xql.16`.** The reader owns the viewport on
`/swipe/`, so the prose that used to sit under it lives at `/swipe/contract/`
and the reader's menu links to it. One URL is the reader and one is the
contract, so there's no mode to be in.

`scripts/build-docs.sh` emits it beside the reading section. The reader is
five files under `swipe/reader/`:

```
emit-items.sh      turns every corpus into items.json
render-screens.sh  bakes the model screens into SCREENS.tsv
SCREENS.tsv        373 screen lines over 24 models. Generated, committed
swipe.js           the page
swipe.css          phone-first, because the phone is the only target
```

**All three rungs reach the page**, since bead `tla-7xql.14`. It served level
0 alone for a day, which was right when it was written and stopped being right
the moment 144 level 1 items and 48 level 2 items landed behind it. 432 items,
138,987 bytes of payload.

### What ships per level, and what does not

| | ships | withheld |
|---|---|---|
| every level | `id`, `level`, `template`, `ask`, `swipe`, `claim`, `flash` | `kind`, `vacuity` |
| level 0 | | `rc_claim`, `rc_wf` |
| level 1 | `model`, `pin` | `rc`, `pin_states` |
| level 2 | `model`, `pre`, `post`, `binds` | `rc`, `pin_states` |

The vacuity witness is the one that matters most: it states in TLA+ exactly
when an item is vacuous, so shipping it hands over the down swipe in prose.

**The pin ships and the kind does not**, which looks inconsistent and is not.
The reader cannot be asked whether `ENABLED Pop` holds without being told
where. `harness/swipe/stemblind.sh` already draws the line in the same place:
level 1 drives the probe with `--surface 9,13` and level 2 with
`--surface 9,13,14,15`, so the pin is part of the surface a judge may see
while the model stays the premise it withholds.

**Two of the 46 vacuity witnesses are a conjunct of their own pin, verbatim.**
`L1-E1-44` carries the witness `a = 0` and the pin `a = 0 /\ b = 0 /\ c = 2`,
because a vacuous level 1 item is vacuous *because of* its pin. So the leak
scan reads a copy of the payload with the pin blocks stripped by position.
Exempting a witness for being a substring of its own pin would exempt a
planted one too, and the scan's negative control plants exactly those.

The baked verdict ships, and it is the answer. A page with no server cannot
grade without it, so the rule is narrow rather than absent: ship the verdict
and nothing else that bears on it. `harness/test-swipe-reader.sh` is what
holds the line, and it scans for every witness in both raw and escaped form.

**The card never prints an item id.** The ids ran in kind order inside each
template, so `L0-T1-09` carries its own answer, which is why
`stemblind.sh emit` hashes it. The log needs the id and the screen must not
have it.

**The stream draws at random from what the browser has no answer for.** The
file order puts a matched true and false pair next to each other for review,
which is right for an author and wrong for a reader. Drawing at random also
makes resume fall out with nothing to store: the pool is the corpus minus the
log.

**The draw is inside a bucket**, one per level and model, and that narrows the
random draw rather than replacing it. The epic's mechanic is "a model, then a
stream of single lines", ten to twenty lines per model, and without the bucket
a 29-line screen is redrawn every item and the reader crosses 17 models in 17
items. Level 0 has no model, so the whole rung is one bucket.

A bucket run can put two halves of a matched pair closer together than a
whole-corpus draw would. At the pinned rungs I read that as the lesson rather
than a leak: six pairs per template carry the same claim text at two pins with
opposite answers, and meeting both is what says the claim does not decide and
the state does.

### The model screen is baked, and the reason is not the phone

A level 1 item pins a state and a level 2 item pins a step, so both show the
model. `swipe/level1/render.sh` builds that screen and it calls
`harness/levels/levels.sh`, which reads SANY's semantic tree. One screen is
one JVM, measured at 0.49 s per model over 24 models.

The cost is the smaller half of the argument. The deciding half is that
`.github/workflows/pages.yml` installs Python and mkdocs-material and nothing
else. **There is no Java on the deploy runner**, so a `build-docs.sh` that
rendered a screen would fail on the deploy, and `scripts/cibuild` would never
see it because cibuild does install the toolchain.

So `swipe/reader/render-screens.sh` runs on a dev box and its output is
committed. `harness/test-swipe-reader.sh` re-renders every screen and compares
byte for byte, which is what keeps the committed copy from drifting, and it
drives the build again with `java`, `tlc`, `sany` and `javac` shimmed to write
a sentinel and asserts the sentinel is absent.

Field 5 of a `SCREEN` row opens with a pipe that is not part of the line. A
screen carries blank lines between definitions and they are part of its
layout, so without the pipe a blank line is a trailing tab, and an editor that
strips trailing whitespace on save would delete it in silence: the file would
still parse and every definition would run into the next one.

### One model of the 33 renders an empty screen, and it is reported

`Ring` renders nothing at either rung. Its actions live in the PlusCal
translation block under names the shown-roots rule does not reach, so the
module declares no action as far as the rule is concerned. That follows from
the rule rather than breaking it, and PlusCal screens are separate work.

No shipped item is about `Ring`, so nothing is dropped today. The rule is
there anyway, because an item about such a model would arrive as a pin and a
claim with no premise under them:

- an `EMPTY` row in `SCREENS.tsv` means the items are **dropped**, stderr
  names them, and the payload carries a `withheld` block
- **no** row at all means a stale `SCREENS.tsv`, and the emitter **dies**

Those two must not behave the same. Withholding items because the generator
was not re-run would be a silent corpus shrink. The gate drives both paths
against a scratch corpus carrying one `Ring` item.

### The layout, which is where the work went

Frank ruled on 2026-10-18 that the phone is the only target. Measured over the
two pinned corpora:

| | |
|---|---|
| tallest model screen | 29 lines, `Shelves` |
| widest screen line | 73 characters |
| level 1 pin | 1 to 3 conjuncts |
| level 2 pin | 4 to 7 rows over two or three labels |
| longest claim | 80 characters |

The theme sets 1rem to 20 pixels, so 29 lines at 0.76rem and a 1.45 line
height is 638 pixels and a 7-row level 2 pin is about 278. 73 characters does
not fit 390 CSS pixels at any readable monospace size. None of it shares one
844-pixel viewport.

**The page above the reader was not ours to measure, and now there isn't one.**
mkdocs-material used to put a 2.4rem sticky header, an h1 and a lead-in above
`#swipe-app`. Bead `tla-7xql.12` measured the level 0 answer row landing at 812
of 844, which works back to roughly 400 pixels of page, and that number was the
theme's rather than ours. A layout that budgets against it is wrong after the
next theme bump, with nothing in the repo to say so.

`tla-7xql.16` removed the budget instead of fixing it. The reader is fixed at
`100dvh` and the document doesn't scroll, so the three rules below hold inside
a box whose height we set. Rule 3 keeps a tighter form there, where flexbox
divides the room and the viewport fractions are off.

So the budget is three rules rather than a sum.

1. **The question is docked.** `.swipe-card` holds the tag, the ask, the claim
   and the three buttons and sticks to the bottom of the viewport. The reader
   can read the question and answer it without scrolling, whatever is above it.
2. **The premise is not in the resting view at all.** It is a stack the reader
   walks up, one step at a time. See the section below.
3. **A step that cannot fit scrolls inside itself.** The screen box is capped
   at 26vh and a step body at 40vh, so one long model cannot push another
   layout around.

Rule 2 is what `tla-7xql.15` added, and rule 3 is the old rule 2 widened to
cover a step. The pin stays out of the dock either way, because 278 pixels of
it in there is a dock that has eaten the room it exists to leave. The screen
also folds away on a tap, remembered per bucket for the visit, which is the
reader's own lever rather than a rule.

A sideways scroll of the model and a left swipe are two gestures on one pixel,
so the gesture handler declines a touch that starts inside the screen body.
Without that, reading along a long line answers the item.

**The pixels were read in a real browser on 2026-10-19**, at a true 390x844
viewport against the published site. The bead that built this could not take
the reading, because Chrome 154 would not complete a headless load in its
sandbox: `Page.navigate` over the DevTools protocol times out and wedges the
renderer, `--dump-dom` and `--screenshot` both hang with no output, and a URL
on the command line leaves `location.href` at `about:blank` whenever remote
debugging is on. So it shipped a table computed from the CSS and marked it
INFERRED, and the reading is what settles it.

**The dock held.** It is fully visible at scroll 0 and at every position where
the premise is in view, 298px at level 1 and 269px at level 2 against a worst
case of 384px, which is 45% of the viewport. That is the one thing the design
was betting on, since a sticky dock puts the question somewhere that does not
depend on the roughly 250px of theme above it.

**Two of the inferred numbers were wrong.** The claim font renders 34 chars
to a line rather than the 24 the table assumed, and claims still wrap longer
than it predicted, because `pre-wrap` breaks at spaces and a TLA+ formula is
mostly unbreakable tokens. Measured over all 432: 156 claims wrap to 2 lines,
206 to 3, 58 to 4, 11 to 5, and `L1-E3-37` to 6. So 70 of 432 run to four
lines or more, where the table said one did.

**And level 2 did not fit above the dock.** The screen is 296px and the pin
327px against 575px of room, so 198px of pin sat behind the dock when the
item was drawn. The reader landed on a `steps to` label with its content
covered, and nothing said to scroll. Hiding the model cleared it, and that is
a lever rather than an answer. Filed as `tla-7xql.15` and fixed by the stack
below.

### The premise is a stack, and it costs the reader a swipe

Frank ruled on 2026-10-19 against fitting the premise and the question into
one room. The premise leaves the resting view instead. At rest the card is the
level tag, the ask, the claim and the three answers, and that is all. Swipe up
for one step deeper, tap for one step back.

| gesture | meaning |
|---|---|
| right, left, down | true, false, not a claim |
| up | one step deeper |
| tap | one step back |

**Every gesture keeps one meaning in every state**, and that is the property
the design turns on rather than a nicety. An earlier draft had down mean back
while the stack was open. It went because a reader wrong about the mode would
file a vacuity verdict on a real claim. The log cannot tell that from a reader
who meant it.

| rung | up 1 | up 2 | up 3 |
|---|---|---|---|
| constant | the last one you got wrong | | |
| state | the pinned state | the model | the last one you got wrong |
| action | from, steps to, where | the model | the last one you got wrong |

**The list is built from what the item carries, not from its level**, so an
item with no model skips that step rather than drawing an empty one. Nothing
in the corpus takes the short list today. All 192 shipped level 1 and 2 items
name a model and carry a pin, and `SCREENS.tsv` holds no `EMPTY` row. So the
branch is defensive, and the gate drives it against two items the corpus does
not have.

**The dock used to stay while the stack was open, and `tla-7xql.18` took it
away.** The argument for keeping it was that reading the premise with the claim
hidden is the working-memory test the dock exists to prevent. That argument was
right and the arithmetic under it wasn't. The dock, the menu and the counts
left the step 276 pixels of 844 and the model screen inside it 66. One line of
the claim comes up with the step now, and nothing else of the dock does. See
"A step is the whole page" below.

**The answers go dead at the last step and nowhere else.** Steps 1 and 2 are
the item in the dock. The last step is the last item you answered wrong, which
is a different item, so the three buttons grey out there. That is the one
visible mode change in the reader.

**Every step draws its own back button.** `touchstart` declines a touch that
starts inside a model screen scrolling sideways, and that screen is most of
the page since `tla-7xql.18`. So tap anywhere is the convenience and the button
is the guarantee. A tap surface with a hole in it where the reader's thumb has
just been is not a way out on its own. Escape does the same job from a
keyboard.

**The tags are `constant`, `state` and `action`.** Frank asked for an English
name on each item, and that is TLA+'s own level calculus, so the tag teaches
the vocabulary the project exists to make automatic. "level 1" teaches
nothing. Level 3 is temporal and this corpus has no rung for it.

#### What the stack costs

192 of 432 items stop being answerable without at least one swipe, which is
the 144 level 1 items and the 48 level 2 items. That is a change to the task
and not only to the layout. A level 1 item used to put the state on screen
beside the claim, and now it asks the reader to go and get it.

I think that is the right trade at these rungs, and it is worth saying what
the argument rests on. The occlusion is gone by construction rather than by
arithmetic, since nothing can sit behind the dock when nothing but the
question is drawn. Tuning heights would have left the next corpus free to
break it again.

The cost I would watch is the run rate at level 2. The epic measures
recognition at flow speed and two swipes per item is not flow. The bucket
should take most of that back, since a run of ten to twenty items shares one
model and the model is step 2. The reader reads it once and then walks one
step for the pin. Whether that holds up is a reading somebody has to take on
a phone.

**The stack was read in a browser on 2026-10-19**, under `tla-7xql.16`, at a
true 390x844 with touch emulation on. Every step fits. The lowest thing the
reader draws is the menu, and it lands 10 pixels inside the bottom edge at
every rung, at every step of the stack, and with the stats panel open. The step
heights stopped being arithmetic because the room is divided by flexbox now,
and a flex line knows what else is on screen where a viewport fraction can't.

### The reader owns the viewport, and a scroll used to file a verdict

Frank hit this on his own phone on 2026-10-19, minutes after the stack shipped.
"I'm not sure whether a swipe is going to scroll through the page or send a
message. I've now accidentally sent multiple responses." His record held
verdicts he never gave.

`bindGestures` binds `touchstart` and `touchend` with `{ passive: true }`, so
the handler can't cancel a scroll. A vertical drag inside the reader scrolled
the page and fired `gesture()` on the same stroke. Down is "not a claim", so a
scroll filed a vacuity verdict on an item that is a claim. That's the failure
the single-meaning gesture table exists to prevent, arriving through the page's
own scroll rather than through a mode.

**The surface matters, and the bead didn't name it.** `.swipe-card` already
carried `touch-action: pinch-zoom`, so a drag starting on the dock never
panned. What panned was everything else: the counts, the menu, a step's head,
and the gaps between them. Driven as a real touch against the published page,
with the document parked at 200 pixels, one downward stroke over the counts
took it to 0 and wrote one row to the log. One finger, a scroll and a verdict.

Frank ruled against taking the reader to the step with a scroll call, which was
the one-line option and which he turned down. "The Design is deeply ambiguous."
The page stops scrolling instead, and then a vertical drag has nothing to
scroll.

1. **The reader fills the viewport on its own page.**
2. **The class that does it goes on at runtime, from `swipe.js`.**
3. **The contract prose moved to a page of its own.**
4. **`touch-action` is set per element, never on an ancestor of a scroller.**
5. **The menu got a forget button.**

`html` and `body` take `overflow: hidden` and `overscroll-behavior: none` under
the class, and `#swipe-app` is fixed at `100dvh` over the top of the theme. The
header, the footer, the h1 and the sidebars are hidden as well as covered, so
the header can't take a touch meant for the reader.

**`dvh` rather than `vh`, and `overscroll-behavior` rather than `overflow`
alone.** `vh` is the large viewport, so a `100vh` reader on a phone runs taller
than the screen by the height of the address bar and the menu goes under it.
And Chrome Android's pull-to-refresh is a browser gesture on a downward drag
near the top of the document, which beats ours. Stopping the scroll doesn't
stop it. Refusing the overscroll does. Neither of those two is measurable
headless, where there's no browser chrome and no pull-to-refresh, so I'm taking
both from the specifications rather than from a reading.

**The class has to come off again, and that's the half that breaks the site.**
`mkdocs.yml` runs `navigation.instant`, which replaces the document's content
without reloading, so the `html` element survives every navigation. A class
left on it follows the reader to every other page and takes the header with it.
`applyViewport()` is the whole rule and `boot()` is its only caller: the class
is on exactly when the document carries `#swipe-app`.

That was read both ways through a real instant navigation. Following the
contract link off the reader left `html` with `js-focus-visible js`, put
`.md-header` back to `display: block`, and a sentinel set on `window`
beforehand survived, which is what says the document was never replaced. A link
back to the reader put the class on again. `harness/test-swipe-reader.sh` drives
the same rule with no browser, over one stub whose root comes and goes.

**`touch-action` needed the care the previous bead gave it.** The property
intersects up the ancestor chain, so a value on `#swipe-app` reaches the model
screen's sideways scroll and kills it, and the widest screen line is 73
characters against 390 pixels. So the property is set on the surfaces that are
gestures and on nothing above a scroller: the counts, the dock, the done
screen, a step's head, the menu. Measured on the model step, the chain from
`.swipe-screen-body` up to `html` reads `auto` at all twelve elements, and a
real horizontal touch drag moved `scrollLeft` from 0 to 234 in a 593-pixel
screen. A vertical drag in the same place moved the screen body 234 pixels and
left both the document and the open step where they were.

#### The flash was the one thing this broke

The flash is a gesture surface, so a drag on it means advance. With the page no
longer scrolling, a correction taller than the flash had nowhere left to be
read. Measured over every item of each pinned rung: 39 of the 48 at level 2 run
past the flash, worst case 111 pixels, against 0 of 144 at level 1.

**The first reading of this sampled, and the sample moved.** It answered 40
items drawn from the 48, and the stream draws at random from what the browser
has no answer for, so three runs of one tree gave 35, 31 and 29. I had it in
four files at two values before anyone caught it. Answering until the done
screen covers each item once, and then both numbers repeat exactly. Don't
sample a rung you can exhaust in 48 answers.

The worst case moved for a real reason and it's worth knowing which. The
pre-fix reading was 93 pixels and the committed one is 111, a uniform 18 across
the five tallest corrections, and 18 pixels is the flash's own
`padding-bottom`. A box with `overflow: visible` leaves its bottom padding out
of the scrollable region and a scroll container puts it in, so adding
`overflow: auto` to the flash moved the number by exactly that. Measured both
ways by taking the one rule back off.

So the flash allows `pan-y` and `bindGestures` declines a touch that starts in
an overflowing one. That's R1 of the stack design applied to one more scroller,
and it changes where a gesture is read rather than what one means. A drag now
scrolls the correction and stays on the item. A tap still advances, because the
browser raises a click after a tap and suppresses it after a scroll, so the
discrimination is the browser's rather than ours.

I think this was already broken before the page stopped scrolling, and in a
worse way. A reader dragging outside the flash to reach the tail of a long
correction scrolled the page and advanced off the item in the same stroke.

#### Forget

There was no way to clear the record at all. Clearing site data was the only
route and it takes the theme preference with it. The menu carries a forget
button now, behind a confirm, and it drops both storage keys including the
level 0 one `loadState()` still migrates.

`forgetState()` returns the state it was given when the reader declines, and
`doForget()` drops the keys only when it gets a different object back. So the
decline path can't reach a write, and that's checkable without a browser. Both
ways were driven in one anyway: declining left 87 rows and the key in place,
accepting took it to 0 rows with the key removed.

### A step is the whole page

Frank, on his phone on 2026-10-19: "It isn't showing the model."

It was showing the model. It gave it 66 of the 438 pixels its content wanted,
which is about one line of a 29-line module. Read in Chrome at a true 390x844
against the published build, with a record in the browser and the model step
open:

| element | pixels |
|---|---|
| the counts | 29.6 |
| the step | 276.4 |
| the card | 304 |
| the menu | 172 |
| padding and gaps | 62 |
| | 844 exactly |

Every child of `#swipe-app` is `flex: 0 0 auto` except `.swipe-step`. So the
step is the only shrinkable thing on the page, and it absorbs whatever the
other four leave. Hiding the menu alone took the step to 462.4 and the screen
inside it to 252.3.

Dividing the room by flexbox was `tla-7xql.16`'s answer to a viewport fraction
that couldn't know what else was on screen. It works, and it only works when
everything asking for room has a claim on it. Three of those four had no claim
at the model step.

The payload was checked first and cleared: 24 screen keys against 24 non-zero
bucket keys, `2:Handover` among them at 222 characters. Nothing an item needs
was missing from the screens map.

**Frank's ruling: a step is the whole page.** Swiping up replaces the view with
the premise rather than stacking a panel above the card. At depth the counts,
the card and the menu aren't drawn at all, and the step gets 824 of the 844.

- **D1**: at depth the counts, the card and the menu aren't drawn.
- **D2**: one line of the claim stays, at the foot of the step.
- **D3**: the menu collapses behind one control at rest too.
- **D4**: the gesture table doesn't move.

`chromeAt()` is the whole of D1, and it's one pure function rather than three
conditions inside `render()`. D1 has to hold over every state the reader can be
in, and no pattern over `render()`'s source can read a table. So the gate drives
all 24 combinations of depth, panel and flash, and holds `render()` to obeying
every slot the answer carries.

D2 is the half I'd watch. One line of the claim comes along on the dock's own
`.swipe-claim` type, with no tag, no ask prompt and no buttons. It's drawn
where `answersLive()` is true, which is every step about the item in hand. The
explanation step is about a different item and already carries that item's
claim, so a second one there would put two claims from two items on one screen.

D3 is 120 pixels, and the arithmetic is worth writing down since no browser
read it. `.swipe-btn` is 2.6rem tall, `.swipe-menu`'s gap is 0.4rem, and the
theme sets a rem to 20px. Three rows are then 52 times 3 plus 8 times 2, which
is exactly the 172 that was measured. One row is 52.

Those 120 pixels are free space at the resting card. The dock has
`margin-top: auto`, so the room above it was already room nobody was using. The
120 go to every view that flexes with the menu still drawn, which is the flash
and the three panels. I think the flash is where it pays: it goes from 594.4
pixels to 714.4, and 39 of the 48 level 2 corrections used to run past it by up
to 111. That last figure is arithmetic on measured parts rather than a second
reading, so somebody should check it on a phone.

D4 is the one this bead could have broken without anybody noticing. A swipe
right at the model step still files "true" with no button on screen.
`answersLive()` is untouched, and the buttons going away removes the affordance
rather than the answer. The gate pins the two halves against each other in one
line, because a table saying "live" and a table saying "no card" sit on
different pages otherwise.

#### R1, which this change created

`bindGestures()` declined every touch starting inside `.swipe-screen-body`,
whatever the model looked like. At 66 of 844 pixels that cost almost nothing.
Full-page it's most of the phone, and the back button would be the only way out
of a view filling the screen.

Frank ruled the conditional form: decline only when the line actually overflows
sideways. The pattern already sat twelve lines below it, where the
`.swipe-step-body` decline reads `scrollHeight` against `clientHeight`. The
screen body takes the sideways form of the same test.

The room says most models now keep the whole page for tap and swipe.

This paragraph used to put a number on that and the number was wrong. It read
"824 less the step's own head, claim and hint leaves about 660 for the model
body". A browser read the body at 480.0 pixels with the claim drawn, under
`tla-7xql.19` the same afternoon, so the arithmetic was 180 pixels over before
the claim even came out. The chrome around the body is the theme's, so
subtracting a guess at it was never a reading.

`scrollerDeclining()` holds all three declines so the table can be driven with
no browser, in both directions. That matters more than it sounds. A decline
that always fires and a decline that never fires both pass a one-sided check,
and the first of those is what this bead removed. Both directions were driven:
making the screen decline unconditional reddened five cases, and taking it out
reddened two others.

A model taller than the room isn't declined, and that's the ruling rather than
an oversight. The sideways axis is the one Frank named.

**This paragraph also claimed the corpus never reaches vertical overflow at
844, and it does.** The claim rested on the same 660. Measured against the real
body height, five of the 24 screens overflowed with the claim drawn and one
still does without it. So a vertical drag inside `1:Shelves` scrolls the model
and moves the stack in one stroke, today, on a 390x844 phone. I don't think
that's urgent, since it's one screen of 24 and it's over by about 15 pixels, but
it's a live case rather than a hypothetical about shorter viewports.

#### The card hint closed itself

The hint on the card names the first step of the item's own stack, so at the
model step it read "up for the pinned state" with the pinned state one step
below. D1 takes the card away at depth, so the line can't be reached from a
step at all. `renderStep()` writes its own hint, and the gate drives the
unreachability rather than leaving it to inference.

### The claim left the step, the same day it arrived

D2 above put one line of the claim at the foot of the step. Frank took it back
out that afternoon, after reading a model on his phone: "I think we will be
better off having to flick back and forth for the problem." To re-read the
claim you tap back to the question and swipe up again.

**The reversal is the useful part, so it's written down rather than tidied
away.** D2's argument was that a reader checking a claim against a step in
front of them shouldn't be holding it in their head. Nothing refuted that. It
lost to a measurement nobody had taken yet.

Read in Chrome at a true 390x844 against the published build, model step open
on `1:Fences`, with the claim line set to `display: none` and the body
re-measured:

| the model body | pixels |
|---|---|
| with the claim | 480.0 |
| without it | 613.9 |
| returned | 133.9 |

At 21.28 pixels a line and 12 of bottom padding, that's five of the 24 screens
overflowing vertically with the claim against one without. The one left is
`1:Shelves` at 29 lines, which wants about 629 against 613.9. Frank ruled it
stays scrolling rather than the type shrinking for one screen, and accepted the
sideways scroll in the same breath: "the phone screen is going to be tight."

I'd watch this one the way the bead before it said to watch D2, and for the
opposite reason. The working-memory argument was real and it's now a thing the
reader pays for on every pinned item. If flicking back turns out to cost more
than the two lines bought, the measurement to take is how often a reader swipes
up and straight back down.

#### The collapse control was a leftover

The model head was a button. It toggled `v.collapsed[key]` and printed "hide"
or "show", and the state was remembered per bucket for the visit.

That earned its place while the model shared the resting view with the card. It
gave the viewport back to the stream, and the bucketed stream means the next
ten to twenty items are about the same model. D1 made the step the whole page,
so there's no stream to give the viewport back to. Collapsing a step now leaves
a head over nothing, which I suspect is what Frank was looking at when he
reported that the model wasn't showing.

The head is a `div` now and the model's **name** stays on it. That name is the
one label on screen saying which model is being read.
`harness/swipe/stemblind.sh` withholds the module name from a judge for exactly
the reason a reader has to be shown it.

Dropping the button took three CSS properties with it. `border: 0`,
`background: transparent` and `font-family: inherit` only ever existed to undo
a button's own styling, and `cursor: pointer` is worse than useless on a label.
A button that does nothing is announced as pressable to a screen reader, which
is a stronger reason to drop it than the pixels.

#### The gate learned to read what the reader is shown

Both changes are text checks over the source, which is what every other
assertion in `harness/test-swipe-reader.sh` already was. 214 of them, and not
one could say whether a model fits the screen it's drawn on.

So the gate now scans the emitted payload: line count per screen, times the
measured line height, plus the measured padding, against the measured body
height. Exactly one screen overflows and it's `1:Shelves`. It keeps **both**
body heights, 613.9 and 480.0, and that pair is the control rather than a
second reading. A broken line count reports the same overflow set at either
height, and the two differ by four screens.

The four measured constants sit in one block above Part 1, with a paragraph
saying what invalidates them. That list is longer than it looks: the font size,
the line height, the padding, the theme's rem, anything that changes what a
step draws around the body, and the viewport. None of them reddens an assertion
on its own.

The flipped assertion is flipped rather than deleted. A deleted one would leave
the second ruling looking like the only one there had ever been.

### The record is a file and the browser is a cache

The browser resumes where you left off. The record is `SWIPE.tsv`, which
belongs at `~/tla-practice/swipe/SWIPE.tsv` beside the other channels' tables.

The format carries a `SWIPEFMT` version row, and the import **refuses** a file
it cannot read rather than starting over. Comments, blank lines and any row
order are fine, the merge never destroys what the browser already holds, and
field 5 is recomputed from the swipe so correcting one by hand needs no second
edit.

### A local server cannot test the page, unless you take the port away

The theme runs `navigation.instant`, so `swipe.js` subscribes to
mkdocs-material's `document$` rather than running on load.

**That hazard does not reproduce on localhost, including under
`mkdocs serve`.** The theme matches a clicked link against its sitemap after
overwriting only the protocol and the hostname, never the port, so on
`127.0.0.1:8000` nothing matches and every link falls through to a full
document load. Three runs against a local server looked fine and said nothing.
The reading that counts came from headless Chromium serving the real
`site_url`, where a window sentinel survived the navigation and the reader
booted anyway.

**There is a route that does reproduce it, found under `tla-7xql.16`.** The
port is the only thing the theme doesn't normalize, so take it out of the
picture. Serve a mirror of the published site locally, then start the browser
with `--host-resolver-rules=MAP fkberthold.github.io 127.0.0.1:<port>` and
navigate to `http://fkberthold.github.io/tla-puzzles/swipe/`. `location.host`
then carries no port, the sitemap entries match after the theme's own
normalization, and instant navigation is live. A link the sitemap doesn't carry
is still declined, so a page added since the mirror was taken needs a `loc`
entry adding by hand.

Two more things worth knowing before you drive it. `Input.synthesizeScrollGesture`
with `gestureSourceType: "touch"` pans nothing at all on Chrome 154 headless,
so it reports every `touch-action` as working and measures none of them.
Dispatching the touch points one at a time with `Input.dispatchTouchEvent` does
pan, and does respect `touch-action`. And `/json/version` hands back the
browser-level socket, which carries no `Page` domain. Take the page target's
own socket from `/json/list`.


## What a rendered item looks like

This is `L1-E1-10`, and the question is the two-conjunct guard trap: `open` is
above zero, which is Pop's first conjunct, and the text is already at `Limit`,
which fails its second one.

```
   CONSTANT Limit = 6
   VARIABLES text, open

   Push ==
     /\ Len(text) < Limit
     /\ text' = Append(text, "(")
     /\ open' = open + 1

   Pop ==
     /\ open > 0
     /\ Len(text) < Limit
     /\ text' = Append(text, ")")
     /\ open' = open - 1

   ------------------------------ pinned at
   text = <<"(", "(", "(", "(", "(", "(">>
   open = 6
   ------------------------------

   does this fire here

      ENABLED Pop
```

Hidden: `Init`, `Next` and `Spec` by D7, `TypeOK`, `Surplus` and `PrefixSound`
by D2, and `Opens`, `Closes` and `vars` by the transitive rule below.

**Model screens measured over the seven models the pilot uses**: 4 nonblank
lines at the shortest, which is Fences, and 21 at the longest, which is Break.
Brackets reads 11 and Contention 18. Over all 33 `reading/` models the range is
0 to 22. The phone bound is the epic's constraint and these are the first
numbers anybody has for it.

**The pilot uses no PlusCal model, and the reason is not length.** I assumed
it was and the measurement says otherwise: the three longest screens are
Shelves at 22, Collatz at 22 and Break at 21, and only Collatz is PlusCal. The
real reason is that `render.sh` gets two things wrong on a translated module.
Ring is the 0 in the range above, because every one of its actions lives in
the translation block under a name the shown-roots rule does not reach, so the
screen comes out empty. And Collatz's screen shows `vars` and the
`\* BEGIN TRANSLATION` comment line, because a translated action references
`vars` directly and a column-0 comment attaches to the construct below it.
Both are honest consequences of the rule rather than bugs in it, and both make
a PlusCal screen a separate piece of work rather than one more model.

## The strip is transitive, and that is a rule nobody had written down

D2 says to strip the model's INVARIANT and PROPERTY declarations. Obligations
have helpers. `Brackets` defines `Opens` and `Closes`, which are free
definitions rather than obligations, so `harness/levels/levels.sh` field 8
keeps them. `Surplus` and `PrefixSound` are the only things that use them, and
both are stripped, so leaving the helpers puts two definitions on a phone
screen that no question can ever be about. `Contention` is the same shape one
definition over: `Holder` is free and only `TypeOK` uses it.

`render.sh` computes the kept set forward rather than backward:

| set | what is in it |
|---|---|
| shown roots | every level 2 definition the module declares, except `Next` and the SPECIFICATION formula |
| kept | the shown roots plus every definition they transitively use |
| stripped | everything else |

Forward is better than backward for two reasons beyond the helpers. It strips
a definition nothing uses at all, which the backward reading leaves on the
screen. And it needs no special case for `Init` or `Spec`: `Init` is level 1
and `Spec` is level 3, so neither is a shown root to begin with. Only `Next` is
excluded by name, because it really is level 2 and D7 really does name it.

**Show every action, always, and not only the ones the claim names.** A shown
set that tracked the claim would itself carry the answer, because a terminal
item needs all of them and an `ENABLED Pop` item needs one. It would also be a
signature the stem-blind gate should catch.

**A claim may only name a definition the screen shows.** A terminal item asks
`~ENABLED (Push \/ Pop)` and never `~ENABLED Next`, because a reader cannot
evaluate a name they have not been given. Section 9 of the gate asserts it
over every row, with `render.sh --list-stripped` as the authority.

## The verdict channel at level 1

One INVARIANT run per item, and no pair. Level 0 runs two `ASSUME`s because
rc 10 covers both "false" and "did not evaluate", so one number cannot split
them. This channel is already five-valued.

<!-- KIND TABLE L1: harness/test-swipe-enabled.sh section 13 reads the rows below. Column 3 is a dash when the kind ships and a reason when it does not. -->

| kind | swipe | deliberately unshipped, and why |
|---|---|---|
| `true` | right | - |
| `false` | left | - |
| `vacuous` | down | - |
| `illformed` | down | - |
| `wronglevel` | down | - |
| `unparsed` | down | - |

| rc | kind | what TLC says |
|---|---|---|
| 0 | `true`, or `vacuous` with its witness | nothing, the invariant held |
| 12 | `false` | `Invariant Claim is violated` |
| 75 | `illformed` | the evaluation error, `While working on the initial state` |
| 76 | `wronglevel` | `The invariant Claim is not a state predicate (one with no primes or temporal operators)` |
| 150 | `unparsed` | `Precedence conflict between ops ENABLED ... and =` |

**Row 75 is not row 76, and the difference is the whole bead.** 75 is
`SPEC_EVAL_FAILURE`, because the invariant is evaluated while the initial
states are computed, so an evaluation error lands on the spec rather than on
the invariant. I expected 76 there and measured 75. 76 is the row that arrives
when the claim is an action or a temporal formula, and TLC names the mistake
exactly: a reader who writes `Pop` where they mean `ENABLED Pop` has asked
whether a step holds at a state. The bead's own words are that people conflate
"the guard is true" with "the action can fire", and this is that conflation one
layer further out.

**Row 150 is this template's own parse trap.** `ENABLED Pop = TRUE` and
`ENABLED Pop'` both come back with a precedence conflict naming `ENABLED`.
Level 0's rule is that a template's unparsed item is a trap in its own subject
matter, and `ENABLED` binds tighter than a reader expects.

**Row 151 does not appear here and that is the level 0 difference.** A level 0
expression declared as an INVARIANT and found false folds to
`CONFIG_ERROR 151`. A level 1 claim is state-dependent, so TLC cannot fold it
and the refuted class reads 12. That is why the `{12, 13}` row the epic's
contract talks about belongs to this rung and not to level 0.

## The pin, and the two things measured about it

**A pinned state must satisfy the model's own type invariant, and it need not
be reachable. This is central's rule and Frank has not ruled on it.** Nothing
in the mechanization constrains a pin: a pin of `open = 5` violates Brackets'
own `Surplus` invariant and `ENABLED Pop` still reads rc 0, because the
generated `.cfg` names `Claim` and nothing else. That is D2 satisfied
mechanically rather than visually. `TypeOK` is the model's own statement of
what a well-formed state is and it costs one TLC run. Reachability costs a
model check, would cut the item space hard, and asks a different question:
`ENABLED` is about a state rather than about a history.

Cost measured: 31 of the 33 `reading/` models name a type invariant, both
exceptions are PlusCal, and no model the pilot uses lacks one. The check rides
the same JVM as the state count below, so the rule costs **one extra run per
item** and the bake is 100 runs over 48 items rather than 52.

**`Ini` is a predicate rather than an assignment, so a pin may admit several
states.** Then `INVARIANT Claim` asks whether the claim holds at *every* state
it admits. Measured: `text = <<>> /\ open \in 0..1` with `ENABLED Pop` reads
12, because the claim splits across the two states. The item is still well
posed, and four shipped items pin three states on purpose.

**A model value CAN be pinned to one state, and the first write-up of this
said it could not.** `Ini == holder = s1` does fail at rc 150 with a semantic
error, because `s1` is a `.cfg` model value and not an identifier the module
can name. The conclusion drawn from that was wrong. Declare a constant in the
pin module and bind it in the `.cfg`:

```
CONSTANT H
Ini == holder = H /\ want = TRUE
```

```
CONSTANT Site = {s1, s2, s3}
         H = s1
```

Measured by central on 2026-10-18, after the pilot shipped: rc 0, one state.
So a multi-state pin is a CHOICE here rather than a constraint, and the four
`Handover` items that pin three states could pin one. They are correct items
and were left alone, but an author sizing template E2 or E3 should know that
every model carrying model values can still be pinned to a single state. The
machinery below is what makes a multi-state pin safe when you want one.

So field 8 is the declared count and a `POSTCONDITION TLCGet("distinct") = n`
confirms it. The postcondition has to be a named operator in the module: an
inline `POSTCONDITION TLCGet("distinct") = 1` in the `.cfg` is refused at rc
255 with "The post condition TLCGet cannot be a constant", which central hit
while checking the paragraph above. The auxiliary run reads 0 when the pin is type-correct and admits
the declared count, 12 when it fails the type invariant, and 10 when the count
is wrong, and the bake's report names which.

## The mix, and what carries from level 0

The **swipe** mix is level 0's: 18 right, 18 left, 12 down, so the base rate is
0.3750 and the power table above transfers unchanged. That argument is about
the swipe mix, which is why it carries.

The **kind** mix under `down` does not carry, because the channel has six kinds
rather than five:

| kind | level 0 | level 1 |
|---|---|---|
| `vacuous` | 6 | 4 |
| `illformed` | 6, then 5 | 3 |
| `wronglevel` | not a kind | 3 |
| `unparsed` | 1 | 2 |

Six fours and twelve pairs is 48 and it lands 18/18/12 without anybody
counting, which is level 0's arithmetic. A four here is one true, one false
and **two** down items of different kinds, where level 0's four was one of each
of its four kinds.

## Where the down kinds come from at this rung

`vacuous` arrives two ways and both are about the pin. A false antecedent, as
in `Len(text) = 6 => ENABLED Pop` at a text of length 3, and an empty
quantifier range the pin creates, as in
`\A p \in {q \in Player : playing[q]} : ENABLED Stop(p)` where nobody is
playing. The witness is a level 1 state predicate evaluated at the same pin.

`illformed` is a guard that does not denote. `ENABLED Stop("q")` where `Player`
is `{p1, p2}`, so `playing["q"]` has no value, and `ENABLED` does not rescue
it. The lesson is that `ENABLED` evaluates the guard, so an undefined guard is
not a false one.

`wronglevel` is the bead's own lesson and it has no level 0 counterpart.

`unparsed` is the `ENABLED` precedence trap.

## What one template of 48 cost, so the next author can size the rest

The bake is 100 JVMs and runs in 37 s. The gate adds the strip sections, which
are one `levels.sh` parse per model, plus seven TLC controls scoped to one item
each and five one-line fixtures that re-measure the channel's five rows.

**A level 1 item cannot batch.** Every item carries its own pin, so it costs
one run for the claim and one for the auxiliary check, and a vacuous item
costs a third for its witness. Level 0 batches 210 of its 240 claims into three
modules. That is the one place this rung is dearer than level 0 and it is
linear in items, so a second template of 48 doubles it.

# Level 2: the subscript rung

Bead `tla-7xql.5`, and everything above this line is about level 0 and level
1. A level 2 item **pins a step** and asks whether a step formula holds across
it, so the screen carries two states where level 1 carried one.

```
swipe/level2/TEMPLATES.tsv   one template, the pilot
swipe/level2/ITEMS.tsv       48 items
swipe/level2/bake.sh         the verdict channel: --check, --write, --stats
swipe/level2/render.sh       the two-state screen, over level 1's strip
harness/test-swipe-subscript.sh  the gate
```

```bash
swipe/level2/bake.sh --stats
swipe/level2/bake.sh --check
swipe/level2/render.sh --item L2-S1-03
harness/swipe/stemblind.sh probe --items swipe/level2/ITEMS.tsv --surface 9,13,14,15
harness/test-swipe-subscript.sh
```

## Why this rung is worth more than the other two

`.claude/rules/tla-practice.md` section 2 counted 1,182 subscript sites across
334 published modules and found **906 of them, 77 percent, are the bare token
`vars`**. Only 16 box sites in the whole corpus use a proper subset. The rule
that makes a narrow one sound is *Specifying Systems* p.123: it is sound when
`v` covers every variable the action mentions.

So almost everybody writes the safe default, almost nobody writes the narrow
one, and the reason the narrow one is usually wrong is a rule most people have
never had to state. Nothing else in this project drills it.

## Four readings of rc 0 with three reasons behind them

One pinned `Take` step on `Tickets`, from the initial state, with the
subscript as the only thing that changes:

| claim | rc | why |
|---|---|---|
| `[][Take(P1)]_vars` | 0 | the whole tuple moved and `Take` holds |
| `[][Take(P1)]_<<next>>` | 0 | `next` moved and `Take` holds |
| `[][Take(P1)]_<<serving>>` | 0 | `serving` never moved, so it is a stutter |
| `[][Leave(P1)]_<<serving>>` | 0 | the same stutter, and `Leave` is false |
| `[][Leave(P1)]_<<ticket>>` | 13 | `ticket` moved and `Leave` is false |
| `[][Leave(P1)]_<<next>>` | 13 | `next` moved and `Leave` is false |

The reader cannot tell the first four apart from the verdict, and that is the
lesson rather than a defect in the measurement.

**The bead's own worked example cannot ship, and finding out why is worth more
than the example was.** `tla-7xql.5` works the lesson on `Nim` over a step
from `(7, 7, 7)` to `(9, 7, 7)`, where a heap GREW so `Take` is false. `Nim`
types its heaps as `0..Heap` and the `.cfg` sets `Heap = 7`, so the post state
is outside the model's own type invariant and the auxiliary run reads 12. The
TypeOK rule that rejects it is central's and Frank has not ruled on it, and
this is the first item it has actually cost anybody.

Four of that table's five rows reproduce exactly on that pin. The fifth,
`[][Take]_<<a, b, c>>` at rc 0, reads **13** there: it is the same subscript as
the first row, so it has to be a different step, and the table does not say
so. Measured on the one step, both read 13. Nothing was wrong with the
measurement and the layout implies a step the rows do not share.

## The stuttering reading is the `vacuous` kind, and that is a ruling Frank has not taken

**Central's read was that it is a `true` item whose flash explains the
stutter.** This ships the other way, and the argument is three things.

`[A]_v` is `A \/ UNCHANGED v`, so a claim whose subscript does not move is an
implication with a false antecedent. That is the same shape level 1 already
calls vacuous: `Len(text) = 6 => ENABLED Pop` at a text of length 3. Calling
the same structure `true` here and `vacuous` there would be two names for one
thing.

It has a witness, which decision D3's own successor demands. The epic's note
of 2026-10-18 says every item carries a per-item vacuity witness "so the
vacuous label has a TLC run behind it rather than an author's word". Here the
witness is `[][FALSE]_v`: replace the action with FALSE and see whether the
truth value survives, which is the textbook vacuity test. Measured on the
`Take` step above, `[][FALSE]_<<serving>>` reads 0 and `[][FALSE]_<<next>>`
reads 13.

And the lesson argument runs the other way from central's. The bead's own
words are that two of the four are "true for a reason the reader has to find".
If a stutter and a genuine hold both swipe right, the reader never has to find
it: the item becomes a free right swipe on a formula that looks hard. The
discrimination goes into the one gesture that already carries it at the other
two rungs.

**What it costs.** Four items of 48 carry the stutter, because `down` holds 12
and three other kinds share it. The flash is what has to do the rest of the
work on the 30 narrow-subscript items that are plainly right or left.

## The verdict channel at level 2

One PROPERTY run per item. Level 1 declares INVARIANT because it asks a state
predicate, and a step formula is not one.

<!-- KIND TABLE L2: harness/test-swipe-subscript.sh section 12 reads the rows below. Column 3 is a dash when the kind ships and a reason when it does not. -->

| kind | swipe | deliberately unshipped, and why |
|---|---|---|
| `true` | right | - |
| `false` | left | - |
| `vacuous` | down | - |
| `illformed` | down | - |
| `wronglevel` | down | - |
| `unparsed` | down | - |

| rc | kind | what TLC says |
|---|---|---|
| 0 | `true`, or `vacuous` with its witness | nothing, the property held |
| 12 or 13 | `false` | the property is violated |
| 75 | `illformed` | the evaluation error, against the spec |
| 150 | `unparsed` | `[] followed by action not of form [A]_v` |
| 151 | `wronglevel` | `is an action-level formula ... Only temporal-level (or state-level) formulas are allowed under PROPERTY` |

**The refuted row is a PAIR and the bake treats it as one.** Hazard H1 on the
epic says to read `{12, 13}` as one answer and never to predict which, and
until now that has been a rule in prose. Here it is `rc_set_for()`, which
returns a set and is tested for membership. It is load-bearing rather than
precautionary: **the shipped corpus carries both codes.** 15 refuted items
read 13, because a step formula is checked in the temporal pass, and 3 read
12, because `[]P` over a state predicate is lifted to an invariant and the
invariant channel reports. Same kind, same swipe, two numbers.

**Row 151 is this rung's own lesson and level 1 says it does not exist.** The
level 1 section above reads "Row 151 does not appear here and that is the
level 0 difference", and it comes back at level 2 for a completely unrelated
reason. TLC's message is worth quoting because it does the teaching:

> The formula Claim ... is an action-level formula (i.e., it contains no
> temporal operators). Only temporal-level (or state-level) formulas are
> allowed under PROPERTY or PROPERTIES. To check that action Claim holds in
> \*every\* step of the behavior, define a temporal property: ... rewrite A as
> `[][A]_v`, where v is a state function (typically the tuple of variables)
> (compare page 90 of Specifying Systems ...)

`[Take(P1)]_vars` reads 151 and `[][Take(P1)]_vars` reads 0. The whole
difference is the dropped box, and TLC names the fix and cites the page. All
three `wronglevel` items here are shapes a careful reader actually writes: the
dropped box, bare angle brackets, and a bare `UNCHANGED`.

**Row 150 is the subscript's own parse trap, and it settles a corpus
question.** SANY says `[] followed by action not of form [A]_v` for `[]Take`
and for `[][Take(P1)]_ticket[P1]` alike. Section 2 of
`.claude/rules/tla-practice.md` reports that an indexed element as a subscript
"matches zero times" over 666 published modules and lists it under "not
attested". It is not merely unattested. **It does not parse.** A record
literal as a subscript is the other half of that list and it does parse:
`[][Take(P1)]_[t |-> ticket]` reads 0. So of the two shapes the survey found
zero of, one is illegal and the other is legal and unfashionable, and the
survey could not tell them apart because it never ran anything.

**Row 75 is one row here and it was two at level 1.** Every evaluation failure
measured lands on 75, whether it sits in the action, in the subscript or in an
argument: `[][Take("zz")]_vars`, `[][Take(P1)]_<<ticket["zz"]>>` and
`[][ticket["zz"] = 0]_vars` all read 75. Level 1 splits 75 from 76 by where
the failure happens, and at this rung 76 moves to the auxiliary run instead.

## The pin, and what one number measures about it

```
Ini == Pre
Nxt == IF Pre THEN Post ELSE UNCHANGED vars
```

One real step and then a stuttering tail. The tail is harmless for a safety
property, because every subscript is unchanged across a stuttering step, so
`[A]_v` holds there by construction whatever `A` says.

**`TLCGet("distinct") = 2` is hazard H3, and it is the whole of it.** H3 says
a pinned behavior needs exactly one V-changing successor per state, because a
real branch means a SET of behaviors was pinned and TLC finds the member that
refutes you. Two distinct states means one initial state and one successor and
nothing else does. Measured: a `Pre` of `next \in {0, 1}` reads 10 against 2,
and a `Post` of `next' \in {1, 2}` reads 10 against 2 and 0 against 3. Level 1
had to carry the count as an authored per-item field. Here it is a constant of
the rung and field 8 reads 2 on every row.

**The type check is free at this rung and it was not at level 1.** TLC checks
an invariant at every reachable state and both pinned states are reachable, so
one `INVARIANT TypeOK` line covers the before and the after.

The auxiliary run reads 0 when the pin is one type-correct step, 12 when a
state breaks the model's own type invariant, 10 when the pin is not one step,
and 75 or 76 when the type invariant cannot be *evaluated* at the pre or the
post state. Those last two are real: `Tickets` types `next \in Nat`, and TLC
cannot decide whether a string is in an infinite set, so a pin that puts a
string there fails to evaluate rather than failing. The bake's report names
which.

**The pin check is per STEP and not per item, which is where this rung is
cheaper than level 1.** Items are authored in groups that share one pinned
step and vary only the claim, so 48 items cost 13 pin checks. Level 1 runs it
per item, and its own corpus repeats pins too, so the saving was available
there and nobody took it.

## A model value needs a declared constant, and field 15 carries it

`Ini == holder = s1` fails at rc 150 with a semantic error, because `s1` is a
`.cfg` model value and not an identifier the module can name. So the pin
module declares `CONSTANT H1` and the `.cfg` assigns `H1 = s1`. Four of the
seven pilot models carry model values, so this is the common case rather than
a corner, and central's correction at commit 8148330 is what the field is
built on.

The binds are shown to the reader, under a `where` rule on the pin. A reader
shown `holder' = H2` and not shown `H2 = s2` has a name they cannot evaluate.

## `vars` has to be on the screen, and level 1's strip takes it off

The level 1 kept set is every level 2 definition except `Next` and the
SPECIFICATION formula, plus their transitive closure. `vars` is a state
function, so it is level 1 and never a shown root, and an action reaches it
only when the action happens to name the tuple. **Measured over all seven
pilot models: not one of them keeps `vars`**, because every action writes
`UNCHANGED <x>` rather than naming the tuple.

That is right at level 1, where no claim can name `vars`. At level 2 the
subscript is the subject matter and `vars` is the subscript 77 percent of the
published corpus writes, so either the screen shows it or the corpus cannot
drill the one habit it exists for. The kept set here is level 1's plus `vars`,
and `swipe/level2/render.sh` is twelve lines of splice over
`swipe/level1/render.sh --screen` rather than a second copy of the strip.

It breaks neither decision. D2 strips the obligations and `vars` is not one.
D7 withholds `Init`, `Next` and `Spec` and `vars` is not one of those either.
Level 1 strips it for a reason that stops being true one rung up.

## What a rendered item looks like

This is `L2-S1-03`, the stutter item on the `Tickets` `Take` step.

```
   CONSTANTS
     Player = {a, b, c}
     Nil = Nil
     Limit = 6
   VARIABLES ticket, next, serving
   vars == <<ticket, next, serving>>

   Take(p) ==
     /\ ticket[p] = Nil
     /\ ticket' = [ticket EXCEPT ![p] = next]
     /\ next' = next + 1
     /\ UNCHANGED serving

   Leave(p) ==
     /\ ticket[p] = serving
     /\ ticket' = [ticket EXCEPT ![p] = Nil]
     /\ serving' = serving + 1
     /\ UNCHANGED next

   ------------------------------ from
   ticket = [q \in Player |-> Nil]
   next = 0
   serving = 0
   ---------- steps to
   ticket' = [ticket EXCEPT ![P1] = 0]
   next' = 1
   UNCHANGED serving
   ---------- where
   P1 = a
   ------------------------------

   does this hold across the step

      [][Leave(P1)]_<<serving>>
```

**The post is shown as a formula over primes rather than as concrete values,
and that was a choice.** `UNCHANGED serving` says the thing every subscript
item turns on, and `serving' = 0` would make the reader derive it.

**Model screens, measured over all 33 `reading/` models**: 0 at the shortest,
which is Ring, and 23 at the longest, which is Collatz and Shelves. The seven
the pilot uses read Fences 5, Nim 7, Handover 11, Quorums 13, Tickets 16,
Alternation 17 and Contention 19. Each is exactly one line longer than level
1's reading of the same model, which is `vars` and nothing else.

**Count those lines with `grep -c '[^[:space:]]'` and not with `grep -c .`.**
The screen is indented and its block separators are three spaces and nothing
else, so `grep -c .` counts every separator as content. Measured the wrong way
it reads about four lines high per model, which is one line per block, and I
spent a round believing the level 1 numbers above were stale before finding
that they reproduce exactly under the right predicate.

## The mix, and what carries from level 0

The **swipe** mix is level 0's: 18 right, 18 left, 12 down, so the base rate is
0.3750 and the power table above transfers unchanged.

The **kind** mix under `down` is level 1's too, which it was not obliged to be:

| kind | level 0 | level 1 | level 2 |
|---|---|---|---|
| `vacuous` | 6 | 4 | 4 |
| `illformed` | 6, then 5 | 3 | 3 |
| `wronglevel` | not a kind | 3 | 3 |
| `unparsed` | 1 | 2 | 2 |

Six fours and twelve pairs is 48 and it lands 18/18/12 without anybody
counting, which is level 1's arithmetic. A four here is one pinned step with
four claims on it, which is the bead's own framing of the lesson rather than a
packaging convenience.

## The two asks, and neither of them predicts anything

`step` is a formula over the pinned step and `always` is a box over a state
predicate. The second one exists because the boundary between them is the
subscript: `[](a <= b)` is a formula and `[]Take` is not, and the only
difference is whether a subscript was needed.

The split is 40 `step` and 8 `always`, and the `always` eight are 3 right, 3
left and 2 down. That is a base rate of 0.3750 and a down rate of 25 percent,
which are the corpus figures exactly, so the tag the reader is shown carries
no information about the answer.

## No claim uses `<>`, `WF_` or `SF_`, and that is a correctness rule

A pinned behavior carries no fairness, so `Ini /\ [][Nxt]_vars` admits the
behavior that stutters at the pre-state forever, and **every liveness claim is
refuted whatever it says.** Measured: `[]<>(next = 1)` reads 13 on a step that
does set `next` to 1, and `WF_vars(Take(P1))` reads 13 on a step that takes
it.

An author who writes one of those gets a 13, writes `false` in field 5, and
ships an item that is false for a reason the pin never had an opinion about.
That is hazard H2's shape one rung along, and the gate bans the three
operators outright rather than noting them.

## What the stem-blind probe reads here, and the control it needed

The surface is **the claim, both halves of the step, and the binds**, which is
`--surface 9,13,14,15`. Level 1 uses the claim and the pin, and this rung's
pin is two states. Both halves belong: the question is whether the action
describes *that* step, and a judge handed only the pre-state has half a
question. The model stays withheld, because it is the premise.

```
PROBE  S1  n=48  features=74  base=0.3750  best=0.4167  feature=has:<<  null95=0.5417  p=1.0000  clear
```

**The probe alone would not have been enough here**, and that is the one
instrument question this rung raised. Four items share a pinned step and
differ only in the subscript, so if the subscript alone predicted the label
the four would be one item with four spellings. So the gate also cuts every
claim down to its subscript and runs the probe over that:

```
PROBE  S1  n=48  features=24  base=0.3750  best=0.3438  feature=has:<<  null95=0.5000  p=0.9970  clear
```

**The best single-feature rule over the subscript alone scores below the base
rate.** Not one bit, and a bit the wrong way. That is not luck: the corpus is
authored so that every variable that stutters in a vacuous item also carries a
true item and a false item on another step, and `<<serving>>`, `<<served>>`
and `<<outcomes>>` each appear once as vacuous, once as true and once as
false.

### The probe cannot see a four-item tell, and that is not a bug in it

The first version of the subscript control gave the four vacuous items a
subscript nothing else used. A perfectly pure rule for the down swipe, and
**the probe came back clear at p=0.9950.** The probe is scored by leave-one-out
accuracy over the whole template, so a rule covering 4 of 48 items moves that
number by almost nothing however pure it is.

`harness/swipe/stemblind.sh` says this in its own header, where it separates
"could a judge beat the base rate" from "does this template have a tell". The
two questions have different answers and the probe only answers the first.

So the gate's section 14 asks the second one directly, in text and at no cost:
**no subscript carried by three or more items may be pure in one swipe.** The
floor is three because at two a pure subscript is a matched pair built from one
idea, which is how this corpus is authored, and `<<ticket>>` really is two
refuted items and nothing else. Measured over the shipped corpus, every
subscript on three or more items carries two or three different swipes.

Four controls are watched failing. A token planted on every false item's
pre-state is called at the full surface and invisible at level 0's default
surface. A subscript given to all 18 refuted items is called by the
subscript-only run. The same plant on 4 vacuous items is called by the purity
check and **not** by the probe, which is the pairing written down as an
assertion. And the one pure pair the shipped corpus does carry is checked to
be still allowed, so the floor is tested from both sides.

## What one template of 48 cost, so the next author can size the rest

The bake is **65 JVMs and runs in 26 s**: 48 claims, 13 pinned steps and 4
witnesses. Level 1 is 100 JVMs and 37 s for the same 48 items.

**A level 2 claim does not batch, for level 1's reason.** The exit code is one
number per run and the claim is the thing being measured, so a `.cfg` naming
four PROPERTYs answers for all four at once and says nothing about any of
them. What does batch is the pin check, because the step is shared and the
claim is not.

**Proposed for the rest, and Frank sizes it.** Three templates at 48 and stop,
which is 144 items:

- **S1**, shipped. Which subscript tests the action, on named actions.
- **S2**, the subscript as a state function rather than a tuple. A bare
  variable, a tuple of tuples, a record literal and a derived expression all
  parse, an indexed element does not, and section 2 of the practice file has
  corpus counts for every one of those shapes to calibrate against.
- **S3**, the step formula's own shape. `[][A => B]_v`, implication under the
  box, which is the shape seven of `braf`'s nine published properties use and
  the one a refinement mapping is written in.

Against a fourth: the item space is large, 439 distinct action-and-subscript
pairs across the 33 models, and the gate is linear in items. At 26 s a
template the three would be about 80 s of bake, which is already a large row
in the registry.
