# Spike: lease expiry and fencing tokens

Built 2026-09-06 against TLC 2026.07.31.184830. Every row below came from
`harness/spike-measure.sh` run from the repository root. Raw rows are in
`measurements.tsv`.

The headline is that this problem is much smaller than it looks, and that the
property the brief states is not the property fencing establishes. The second
one matters more than the first.

## How big it is

The broken system is 7 variables and 62 distinct states, checked in under a
second. Adding the fence costs one variable and 12 states. Neither model needs
a state constraint, a symmetry set, or a view.

| label | rc | verdict | secs | distinct | depth | vars |
|---|---|---|---|---|---|---|
| broken-clock-2c-t3 | 12 | invariant violated | 0.4 | 62 | 7 | 7 |
| fenced-clock-2c-t3 | 0 | checked, no violation | 0.4 | 74 | 8 | 8 |
| broken-minimal-2c-t1 | 12 | invariant violated | 0.5 | 22 | 6 | 7 |
| broken-notick-2c-t0 | 0 | checked, no violation | 0.5 | 5 | 3 | 7 |
| fenced-vacuity-witness | 12 | invariant violated | 0.5 | 60 | 7 | 8 |
| broken-action-property | 13 | property violated | 0.5 | 34 | 5 | 7 |
| fenced-action-property | 13 | property violated | 0.4 | 34 | 5 | 8 |
| fenced-liveness-fairspec | 13 | property violated | 0.5 | 74 | 8 | 8 |
| broken-abstract-2c | 12 | invariant violated | 0.4 | 21 | 6 | 5 |
| fenced-abstract-2c | 0 | checked, no violation | 0.5 | 29 | 7 | 6 |
| broken-clock-3c-t5 | 12 | invariant violated | 0.5 | 171 | 7 | 7 |
| fenced-clock-3c-t5 | 0 | checked, no violation | 0.5 | 684 | 12 | 8 |
| broken-abstract-3c | 12 | invariant violated | 0.5 | 44 | 6 | 5 |
| fenced-abstract-3c | 0 | checked, no violation | 0.5 | 241 | 10 | 6 |
| fenced-abstract-4c | 0 | checked, no violation | 0.5 | 2,777 | 13 | 6 |
| fenced-abstract-5c | 0 | checked, no violation | 0.9 | 41,021 | 16 | 6 |
| fenced-ge-offbyone-2c-t3 | 0 | checked, no violation | 0.4 | 74 | 8 | 8 |
| restart-strict-gt-2c | 0 | checked, no violation | 0.5 | 284 | 9 | 10 |
| restart-offbyone-ge-2c | 12 | invariant violated | 0.4 | 126 | 6 | 10 |
| restart-strict-lockout | 12 | invariant violated | 0.4 | 123 | 6 | 10 |
| fenced-clock-2c-t6 | 0 | checked, no violation | 0.5 | 269 | 11 | 8 |
| fenced-clock-2c-t12 | 0 | checked, no violation | 0.5 | 1,037 | 17 | 8 |
| fenced-clock-2c-t24 | 0 | checked, no violation | 0.5 | 4,085 | 29 | 8 |
| fenced-clock-2c-t48 | 0 | checked, no violation | 0.7 | 16,229 | 53 | 8 |
| broken-clock-unbounded-2c | 12 | invariant violated | 0.5 | 100 | 7 | 7 |
| fenced-clock-unbounded-2c | 124 | hit the 120s budget | 120.1 | 24,676,165 | - | 8 |

The `vars` column is the tool's, and it reads one high on two of these modules.
See the discrepancy section. Declared counts are 7 for `Broken.tla`, 8 for
`Fenced.tla`, 5 and 6 for the two abstract modules, and 10 for
`FencedRestart.tla`.

Every run except the last finished in under a second. The whole sweep of 26
models is about 15 seconds of wall clock. Nothing here needs a budget.

## How time is modelled, and what that cost

This is the decision the problem turns on, so I built it both ways and measured
the difference rather than arguing about it.

**What I chose for the primary pair**: a bounded integer `clock`, a `Tick`
action guarded by `clock < MaxTime`, and a lock service holding `expiry` as an
absolute clock value. A lease is live when `clock < expiry`. At `MaxTime = 3`
and `Lease = 2` that gives 62 and 74 states.

**What I rejected**: modelling the pause. There's no `Pause` action anywhere in
these specs and there doesn't need to be. A client sitting in `pc = "held"`
while `Tick` fires is a paused client, and TLA+ hands you that interleaving for
nothing. I think this is the single most useful thing a learner takes away from
the problem, and it's easy to miss on the way in.

**What the clock cost**: `BrokenAbstract.tla` deletes it. No `clock`, no
`expiry`, no `MaxTime`, no `Lease`. The lock service just has an `Expire`
action that clears the owner at any moment.

```
Expire == owner # NoClient /\ owner' = NoClient
```

That's 3 fewer variables and 2 fewer constants, and it finds the same bug.

| model | broken states | fenced states |
|---|---|---|
| bounded clock, `MaxTime = 3` | 62 | 74 |
| no clock | 21 | 29 |

So the clock costs about 2.9x on the broken side and 2.6x on the fenced side,
at this size. That understates it, since the multiplier grows with the bound.
The clock bound drives the space quadratically, which the scaling rows show:
`clock` and `expiry` are each bounded by `MaxTime`, so they multiply.

| `MaxTime` | fenced distinct states | ratio to previous |
|---|---|---|
| 3 | 74 | |
| 6 | 269 | 3.6 |
| 12 | 1,037 | 3.9 |
| 24 | 4,085 | 3.9 |
| 48 | 16,229 | 4.0 |

Doubling the bound roughly quadruples the space. The clockless model doesn't
have that axis at all.

**My call**: the clockless model is the better one for this property, and I'd
teach it second rather than first. The safety requirement asks about the
_order_ of expiry against the client's progress and never about how long either
took, so the numbers buy nothing. What brings the clock back is a requirement
with a number in it. "A lease is never granted twice inside one lease duration"
needs arithmetic. Nothing in the fencing story does.

The reason I'd still start a learner on the clock is that deleting it is the
insight, and you can't have the insight before you've paid for the thing. The
pair of modules is worth more than either one.

## Is the broken version reachable at small size

Yes, and smaller than the brief guessed. Two clients, `Lease = 1`,
`MaxTime = 1`. One tick is the whole of the pause. That model is 22 distinct
states at depth 6, and TLC exits 12 in 0.5 seconds.

The counterexample at the primary size is DDIA figure 8-4 with nothing added:

```
State 2: Acquire(c1)   owner=c1  expiry=2  tok=(c1:>1)  clock=0
State 3: Tick          clock=1
State 4: Tick          clock=2                     \* c1's lease is now dead
State 5: Acquire(c2)   owner=c2  expiry=4  tok=(c1:>1 @@ c2:>2)
State 6: Write(c2)     log = <<2>>
State 7: Write(c1)     log = <<2, 1>>              \* the stale write lands
```

I built a control for this, and it earns its place. `MCBrokenNoTick.cfg` sets
`MaxTime = 0`, so the clock can't move and no lease can lapse. It exits 0 in 5
states. A learner who picks a clock bound too small gets a green run that means
nothing, and there's no signal in the output separating it from a correct one.
That failure is one config line away at all times.

The vacuity probe on the fenced side is the same hazard from the other
direction. `Fenced.tla` exits 0, and so would a storage service that accepted
nothing. `MCFencedWitness.cfg` checks `Len(log) < 2` and TLC exits 12, which is
the evidence that two writes really do land.

## Where the real modelling difficulty is

Not the clock. The learner will get stuck on **how to say the property**, and I
didn't expect that going in.

The brief words the requirement as "the storage service never accepts a write
from a client whose lease has expired". Written down literally, that's a claim
about the instant of the write. No later state carries it, so it isn't a state
invariant without a history variable. It's an action property:

```
NoExpiredWrite ==
    [][ \A c \in Clients : (pc[c] = "held" /\ pc'[c] = "done") => LeaseLive(c) ]_vars
```

That form works. It's the `braf` shape from `.claude/rules/tla-practice.md` §7,
and it catches the bug at 34 states. It's checked with `PROPERTY`, so a failure
exits 13 rather than 12.

Here's the part that matters. **That property is false in the fenced system
too.** `MCFencedAction` exits 13, at the same 34 states. The trace:

```
State 2: Acquire(c1)   owner=c1  expiry=2  maxTok=0
State 3: Tick          clock=1
State 4: Tick          clock=2        \* c1's lease has expired
State 5: Write(c1)     maxTok=1       \* and the fence accepts it anyway
```

C1's lease lapsed while nobody else wanted it. C1 still holds the highest token
issued, so the fence lets the write through, and nothing is corrupted by that.
Fencing rules out a **superseded** write, not an **expired** one. Those two
coincide only while somebody else is waiting for the lease.

So a learner who writes the brief's sentence faithfully gets a red fenced spec
and concludes the fix doesn't work. That's the hard step, and it's a good one.
The exercise is to notice that the requirement as stated is stronger than what
the mechanism buys, then write down the weaker thing that's actually true. The
weaker thing is the log-monotonicity invariant these specs check.

```
NoStaleWrite ==
    \A i \in 1..Len(log) : \A j \in 1..Len(log) : i < j => log[i] < log[j]
```

I'd set the problem so a learner meets this rather than around it.

## The three edges

**Three clients.** The property holds. The fenced clock model goes from 74
states to 684, and the clockless one from 29 to 241. No new defect appears, and
I didn't expect one. The clockless model at 4 and 5 clients runs 2,777 and
41,021 states, both under a second, so headroom isn't a problem here.

**The `>=` off-by-one.** `FencedGE.tla` swaps `tok[c] > maxTok` for
`tok[c] >= maxTok` and TLC exits 0. That surprised me, and the reason is worth
the whole variant. The lock service issues a strictly increasing token on every
grant, so no two live tokens are ever equal, and the two guards can never
disagree. The bug is real and unreachable. It survives review, it survives the
model check, and it waits.

What it waits for is a repeated token. `FencedRestart.tla` supplies the ordinary
way that happens: the lock service restarts and its counter goes back to 1,
while the storage service keeps its high-water mark. That asymmetry is the
problem. One module covers both halves through a `Strict` constant.

| guard | rc | distinct | what happens |
|---|---|---|---|
| `tok > maxTok` | 0 | 284 | safe |
| `tok >= maxTok` | 12 | 126 | stale write lands |

The `>=` counterexample has both clients holding token 1 after the reset. C2
writes, C1 wakes and writes, and `1 >= 1` lets it through. I had to add an
auxiliary grant-sequence variable to state the property there, since once tokens
repeat the token log can't tell a stale write from an ordered pair.

**Bounded or unbounded clock.** The bound is load-bearing, and the answer splits
by which verdict you're after.

| model | rc | secs | distinct |
|---|---|---|---|
| broken, unbounded | 12 | 0.5 | 100 |
| fenced, unbounded | 124 | 120.1 | 24,676,165 and climbing |

`Tick` is enabled in every state once you remove the guard, so `clock` alone
makes the space infinite whatever the clients do. Breadth-first search reaches
the broken system's counterexample at depth 7 and stops, so an unbounded clock
costs nothing when the answer is a counterexample. It costs everything when the
answer is a proof. I think that asymmetry is worth showing a learner directly,
since it's a general fact about model checking that this problem happens to
demonstrate in two runs.

## Does it need liveness

The safety story needs no fairness. Both main configs check `INVARIANT` only,
and neither module needs `WF_` to say what it says.

Two things are worth checking with fairness, and both fail on purpose.

`MCFencedLiveness` checks the price of the fence against `FairSpec`:

```
HeldEventuallyWrites == \A c \in Clients : (pc[c] = "held") ~> (pc[c] = "done")
```

TLC exits 13. A client that got the lease can be superseded while it works and
then refused. That's the trade the mechanism makes, and stating it is more
honest than leaving it implicit. Without the fairness conjunct the property is
violated by a behaviour that simply stops, which is a true counterexample and a
useless one.

The second one is an availability failure I can state as an invariant, so it
needs no fairness at all. Under a lock-service restart the strict fence refuses
the client that currently holds a **live** lease, not a stale writer.
`MCFencedRestartLockout` exits 12 at 123 states, with C2 rejected while
`owner = c2` and `clock = 0 < expiry = 2`. This is why real systems persist the
counter.

So my answer is no for the core problem, and yes for one good optional
extension. I'd keep liveness out of the base exercise.

## Discrepancies

**`harness/spike-measure.sh` over-counts variables by one when `VARIABLES` sits
alone on its line.** `Broken.tla` declares 7 and the tool reports 8.
`FencedRestart.tla` declares 10 and the tool reports 11. Modules with
`VARIABLES a, b, c` on one line read correctly. Isolated with a 5-line probe:

```
$ printf 'VARIABLES\n    a,\n    b\n\nx == 1\n' > probe.txt
$ awk -f <the tool's variable-count block> probe.txt
counted: 3 (2 declared)
```

The cause is in the awk at `harness/spike-measure.sh`. The `VARIABLES?` match
strips the keyword into `line`, leaving it empty, and the next block's
`if (!line) line=$0` restores the whole line. The token `VARIABLES` then matches
the identifier pattern and gets counted. I didn't fix it, since the brief scoped
me to this directory. The gate at `harness/test-spike-measure.sh` doesn't catch
it, and its two fixtures both put `VARIABLES` on one line.

**The `fairness` and `temporal` columns read the module, not the config.** The
`fenced-clock-2c-t3` row says `yes` to both, and `Fenced.cfg` names neither
`FairSpec` nor `HeldEventuallyWrites`. Those definitions sit in the module for
the wrapper configs to use. That's normal by this project's own survey, where
47% of obligation-shaped definitions aren't named by any config, so I read the
columns as facts about the text rather than about the run.

**The brief predicted exit 12 for the broken system and got it**, but only for
the log-monotonicity invariant. The brief's own wording of the property gives
13. I've kept both and reported them separately rather than picking the one that
matched.

## Files

- `Broken.tla` / `Fenced.tla`, the primary pair, bounded clock
- `BrokenAbstract.tla` / `FencedAbstract.tla`, the same pair with no clock
- `FencedGE.tla`, the `>=` off-by-one that holds
- `FencedRestart.tla`, token reuse, where `>=` stops holding
- `BrokenUnbounded.tla` / `FencedUnbounded.tla`, the unbounded-clock question
- `MC*.tla`, 12 wrapper modules carrying one config each
- `measurements.tsv`, all 26 rows

## Verdict

**Good practice problem, and I'd build it.** It's the smallest thing I've seen
that puts a real distributed-systems failure inside a model a learner can hold
in their head. Two clients, one tick, 22 states.

**Difficulty: level 3, at its lower edge.** By this project's own criterion in
`corpus/manifest.tsv`, level 2 is one function-valued variable over scalars and
level 3 is several functions relating multiple entity kinds. `Fenced.tla` has
two functions over `Clients` plus a sequence, relating three components. The
clockless version at 6 variables sits closer to level 2. Nothing here is nested
and there are no records, so it doesn't reach level 4.

**Three things I'd change about how it's set.**

The property has to be the exercise, not a given. Handing a learner
`NoStaleWrite` removes the one hard step. I'd state the requirement in the
brief's own English, let them write the action property, watch it fail on the
fixed system, and make the finding be that the requirement was stronger than the
fix. That's the part that transfers.

The clock should be built and then deleted, in that order. Both models are under
a second, so there's no cost to doing both, and the clockless one only teaches
anything to somebody who already paid for the other.

The `>=` variant needs the restart to be worth setting. On its own it exits 0
and the lesson is "your off-by-one was fine", which is the wrong lesson from the
right question. With the counter reset it becomes the best sub-problem in the
set: an unreachable bug, and the one change to the environment that reaches it.

One caution on all of this. I built one problem and measured it well, and I
haven't checked whether the property-shape difficulty above generalises past this
system. I suspect it does, since anything with a deadline has the same gap
between "expired" and "superseded". That's a hunch, not a result.
