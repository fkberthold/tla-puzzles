# Statement against models

This reads the learner-facing part of
`.claude/overnight-2026-09-06/statements/fencing.md`, lines 1 to 51, against the
spike's models in `sources/spikes/fencing/`. Two lists: what the models do that
the rules never licensed, and what the rules claim that the models don't do.

Measurements come from this command, run from the repository root on 2026-09-06:

```
bash harness/spike-measure.sh --dir sources/spikes/fencing --module <M> --budget 120 --label verify-<M>
```

## The property the statement must not promise

**The statement doesn't assert or imply it.** I read every sentence of lines 1
to 51 looking for a claim that the storage service only accepts writes from a
live lease, and there isn't one.

That property is false in the fenced system as well as the broken one. A client
whose lease lapsed while nobody else wanted it still holds the highest number
issued, so the fence lets its write through. The spike measured that. The model
carrying the literal wording fails on the fenced system at 34 states with exit
13 (`MCFencedAction`, run above). That's the same result it gives on the broken
one. Fencing rules out a superseded write, not an expired one, and the two
coincide only while somebody else is waiting.

The nearest the statement comes is lines 13 and 14:

> Holding the lease is what entitles a client to write. Nothing in the system
> enforces that.

Read it as one thought and it's a statement of intent that withdraws itself as a
guarantee in the same breath. The first sentence says what the lease is for,
which the problem needs or it has no stakes. The second says the system doesn't
deliver it. Neither says the storage service refuses an expired writer, and
neither says the numbers will fix that.

Line 51 is what protects the statement most, and it's easy to walk past:

> Check each property you wrote against both versions and say where it holds.

That sentence pre-authorizes the discovery. A learner whose property fails on
the fixed system has been asked in advance to report exactly that. So the
statement never leaves them thinking the fence is broken.

**The other near miss** is line 47, "the properties you think establish that it
behaves", asked about the first version, which is the one that misbehaves. It
requests the learner's own properties rather than promising any, and I don't
think it names the false property even loosely. I'd call it a minor wording risk
and leave it. It's worth knowing about only because it's the second place a
reader could look for a promise.

**Verdict: no defect, no change.** Hold the line where it is.

## What the models do that the statement doesn't license

### The fence is stricter than rule 10

Rule 10, lines 38 and 39:

> The storage service rejects a write whose number is lower than the number on a
> write it has already accepted. It accepts any other write.

An equal number is "any other write", so rule 10 accepts it. `Fenced.tla:61`
accepts only on a strictly higher number, and `:69` rejects on anything at or
below. So the model rejects a write the rule accepts.

The spike already built the rule as written. `FencedGE.tla` accepts on "at or
above" and rejects on "below", which is rule 10 word for word, and it comes back
clean at 74 states, rc 0. `Fenced.tla` comes back clean at 74 states, rc 0. The
two are indistinguishable here, because the lock service never issues a number
twice, so the guards can never disagree.

They disagree only once numbers repeat. `FencedRestart.tla` supplies the ordinary
way that happens, a lock service that restarts with its counter back at 1. Strict
holds at 284 states, rc 0. Non-strict fails at 126 states, rc 12
(`measurements.tsv`, rows `restart-strict-gt-2c` and `restart-offbyone-ge-2c`).

**Verdict: not a defect, worth disclosing.** A learner who follows rule 10
exactly builds the licensed model and gets the same verdict, which is measured
rather than assumed. Two things follow. The answer key shouldn't treat the
strict guard as the only correct reading. And rule 10 becomes the wrong rule the
day the restart extension joins the problem, because that's the environment where
the difference bites.

### Version one already carries the number

Rule 7 introduces numbers as the second version's addition, at line 34.
`Broken.tla` has `nextTok` and `tok` from the start (`:34`, `:36`, `:68-69`),
before anything reads them.

It's there so the requirement can be stated at all. Staleness is "this write
landed behind one from a later grant", and version one has nothing else that
orders the grants. So the models' two versions differ by one variable and one
guard in the storage service, not by the numbers. The account of "what the
numbers change" then lands on the check rather than on the numbering.

**Verdict: scope limit worth disclosing.** The statement's split between the
versions is honest about the system. The models' split is forced by what can be
observed. A learner whose version one has no numbers in it needed another
observable, and a history variable is the usual answer.
`FencedRestart.tla:20-27` reaches for one when the number itself stops being
usable, which is the same move at a harder moment.

### Four commitments that add without contradicting

The models settle four things the rules leave open, and none of them cuts across
a rule.

**One clock, shared.** The clients and the lock service read the same counter
(`Broken.tla:31`). No skew, and no rule says there could be any.

**One duration for every grant.** A deadline is always the clock plus a constant
(`Broken.tla:67`). The rules never mention duration.

**A write is one step.** The client's state and the log change together
(`Broken.tla:74-78`). No message, no delivery, no loss between the components.

**A rejected client learns of it.** `Fenced.tla:31` and `:67-71` give the client
a fourth state. Rule 10 says the storage service rejects and says nothing about
the client being told.

**Verdict on all four: fine.** They're modelling decisions, and they're covered
in `CHOICES.md`.

## What the statement says that the models don't do

### Rule 1 allows repeated asks, the models allow one

Rule 1, lines 18 and 19, says any client can ask for the lease at any time. In
every one of the five specification modules, the string `"idle"` appears only in
the type invariant, the initial state, and the guard on acquiring
(`grep -n '"idle"' Broken.tla Fenced.tla BrokenAbstract.tla FencedAbstract.tla
FencedRestart.tla`, 15 lines, none of them an assignment). So no action sends a
client back, and each one asks at most once.

**Verdict: scope limit worth disclosing.** The failure needs only one grant per
client, so nothing about the safety question is lost. But it's what bounds the
token space without a separate constant (`Broken.tla:27-28`), and a learner who
modelled looping clients needs that bound somewhere else. Their model is bigger
and it isn't wrong.

### Rule 3 is true of one model literally and of both in spirit

Rule 3, line 22: "A granted lease expires without anything else having to happen
first." It carries three readings and the models answer them differently.

**Nothing causes the expiry.** In particular, not a second client asking. True of
both. In the clockless model the expiry action is guarded only by somebody
holding the lease (`BrokenAbstract.tla:58-61`). In the clocked one the tick
action reads no client state at all (`Broken.tla:80-83`). I think this is the
reading the rule was written for, and it holds.

**Nothing at all happens first.** A tick is something. The clocked model needs
ticks and needs clock headroom to have them, so under this reading it fails.
`MCBrokenNoTick.cfg:5` sets the bound to zero and no lease can ever lapse: rc 0
at 5 states.

**A granted lease does expire.** Neither model honours this. Nothing forces a
tick or an expire step, since neither main specification carries a fairness
conjunct (`Broken.tla:89`, `BrokenAbstract.tla:73`). And at `MaxTime = 3` with
`Lease = 2`, a lease granted at clock 2 gets a deadline of 4, past the bound, so
it never expires inside that model (`Broken.tla:67`, `Broken.cfg:5-6`).

**Verdict: scope limit, and the one line I'd re-examine.** The rule's job is to
keep a clock out of the statement, and it does that job. The risk is the second
reading. A literal reader can conclude a ticking clock is disallowed, and that
would delete half the exercise. Building the clock and then deleting it is where
the insight is. My call is to leave the wording and watch for the
misreading in what a learner hands back. Tightening it to say no other event
causes the expiry starts naming events, which is the leak the rule exists to
prevent.

### The clockless model is admitted, and rule 2 is what admits it

Nothing in rules 1 to 6 mentions a duration, a clock, a tick, or order in time.
Rule 2's second sentence does the work, at line 21: "An expired lease isn't
held." That lets expiry be nothing more than the holder going away, which is
exactly what the clockless model writes (`BrokenAbstract.tla:58-61`).

It isn't a hypothetical. The clockless broken model finds the same bug at 21
states, rc 12, against 62 for the clocked one.

**Verdict: fine.** This is the statement working as intended, and I'd leave it
alone.

### The rest, checked and clean

**The client count.** Rule 1 says more than one and doesn't fix a number. Neither
do the models, which run at two through five clients from the same modules
(`Broken.cfg:3`, `measurements.tsv` rows `broken-clock-3c-t5` through
`fenced-abstract-5c`). Fine.

**Rules 4 and 5.** Writing is guarded only by the client's own state
(`Broken.tla:74-75`), so a write can land at any point after the grant, including
after expiry. No client action reads the clock, the holder or the deadline. The
one that looks like it does is acquiring (`Broken.tla:65`), and that guard is the
lock service's grant decision folded into the same step. Fine.

**Rule 6.** Version one's write has no guard beyond the client's own state and
there's no rejection anywhere in the module (`Broken.tla:74-78`). Fine.

**Rule 11.** The accept and reject guards read only the number and the high-water
mark (`Fenced.tla:61`, `:69`). The actions carry a client parameter, which is the
model naming who acts rather than the storage service knowing who it is. Worth a
sentence in the answer key so nobody misreads the parameter as knowledge.
Otherwise fine.

## Where that leaves it

I found no defect in the statement, across lines 1 to 51 and the spike's
modules. Four things are worth disclosing:

- Rule 10 licenses a weaker guard than the models use.
- Version one in the models carries a number the statement adds later.
- The models let each client ask once where rule 1 lets it ask always.
- Rule 3 admits a literal reading that would rule out the clocked model.

The strongest case for a change is rule 3, and my call is still to leave it. I'd
rather catch that misreading in one learner's write-up than trade the rule for
one that names the events it's trying to keep out.
