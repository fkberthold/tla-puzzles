# Rung 2 step 0, domain screens

Bead `tla-h2cg.8`, the second rung of batch 2 (V2-PLAN.md §7.0, table at line
1622). Both screens run over three candidate domains before anything is
written. §6 step 0 puts this ahead of the reference author, because the pilot
ran §5.7 after freezing a spec and got BURNED back in two seconds.

## The rung, and what it can carry

Rung 2 is shape A in situation S4, time, expiry and leases. The learner writes
the whole spec and its `Observe` from prose. Reading gate ch11, so PlusCal-era
TLA+.

The vector, in §2.5's order:

| dimension | level | reads as |
|---|---|---|
| representation | 2 | state is the learner's, `Observe` fields are the reference's variables |
| property kind | 2 | at least one `[][A]_v`, no liveness, no fairness |
| property count | 1 | two to four cfg lines, type invariant included |
| step sources | 0 | one actor, no clock, no unassigned step |
| state space | 0 | under a second, under 1,000 distinct states |
| form left open | 0 | keyword, kind and subscript all given |

Representation 2 is the single new high over rung 1. Everything else sits level
with it or below. So the whole weight of this rung is that the learner picks the
state, and the reference's variables are exactly what `Observe` exposes.

The hard part is not the vector. It's that S4 and step sources 0 pull against
each other. S4 is about time running out, and the cheapest way to write that is
a calendar that ticks on its own. A calendar is a step the statement assigns to
no party, which is step sources 3, and that isn't available until rung 8. So
expiry here has to be something the one actor does, or a fact that falls out of
his own steps.

## Why the domain changed

The §7.0 table drafted escape room booking with reset time for this rung.
Central withdrew it before this screen ran. It screened BURNED on allocation
and scheduling in August (bead `tla-03d2`), and Frank took the strict reading
on 2026-09-05. Burned means burned. Under §7.0 the domain changes and the rung
keeps its vector, so the three candidates below are all S4 and all written to
the same six levels.

## Three findings that belong to the rung, not to any candidate

Worth stating once, because otherwise they read three times as a fault in
whichever candidate is under the microscope.

**The tool burns the word "expiry", and S4 is the expiry situation.**
`harness/screen.sh:112` carries the map row
`blood bank|inventory|expiry|type compatibility~allocation,matching`. The row
fires on the bare word. Any phrasing that uses S4's own headline noun comes back
BURNED on allocation and matching, whatever the domain is. I hit it on
candidate 3 and probed it with one word swapped, and the probe is pasted below.
Batch 2 has three S4 rungs (2, 5 and 7). My read is that all three will hit this
row, and rungs 5 and 7 should be told before they screen rather than after.

**The Examples README carries no time row at all.** I grepped the cached table
for lease, expiry, timeout, token bucket, rate limit, quarantine and window.
One line matched, and it's the mailing-list footer at line 169. The same file
returns 16 lines for allocation, knapsack and Paxos, so the fixture is real and
the absence is the corpus. That's §2.1's claim about S4 (gap #6, unserved
anywhere) holding up under a check rather than on assertion.

**Step sources 0 forces a puzzle answer on Q6.** The rubric's Q6 asks how many
agents act and whether any can fail or interleave. The rung pins that at one
actor, so every candidate answers "one, infallible", which is the puzzle column.
No domain can rescue it. Rung 1's record found the same thing and the reasoning
carries over. The threshold is three puzzle rows of eight, so one mandated row
still leaves room.

---

# Candidate 1: laytime and demurrage, `Laytime`

A ship berths to discharge a cargo. The charter gives the charterer a fixed
allowance of working time, called laytime, to get the cargo off. One actor, the
ship's agent, keeps the laytime statement. He tenders the notice of readiness,
which starts the reckoning. He then logs each period of the discharge as either
working, which draws laytime down, or excepted, which the charter says doesn't
count. When the allowance runs out the ship goes on demurrage and the charterer
pays by the period from then on. Once on demurrage, always on demurrage. The
exceptions stop applying, and rain that was free an hour ago is now billed.

It sits in S4 and not S5 because the whole system is one allowance running out.
Nothing here is a lifecycle over an entity, and the states the ship passes
through are consequences of the clock rather than the subject of the problem.

## §5.7, the mechanism screen

Two phrasings, verdicts pasted:

```
=== CANDIDATE: consumable time allowance drawn down by logged periods with a one way switch to a penalty rate
--- step 1: NAME collision
    query: 'Laytime language:tla'
    hits: 2 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: laytime and demurrage on a discharging ship where excepted periods stop counting once the allowance is exhausted
--- step 1: NAME collision
    query: 'Laytime language:tla'
    hits: 2 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

**The two name hits are a GitHub tokenizer artifact.** Both are in one repo,
`morphicsnet/software`, under `docs/formal/tla`. I pulled the raw file and
grepped it. The word "laytime" doesn't appear. What matched is the substring
inside `ReplayTimeClose`, at `Types.tla:91`. So the name is unoccupied, and the
count of 2 is a fact about GitHub's index rather than about the corpus.

The tool derived no mechanism from either phrasing, and it says itself that
isn't a clean bill. So, by hand:

**The mechanism is a non-refilling allowance drawn down at a rate the actor
declares, with a one-way latch that changes which future steps count.** Three
parts, and the third is the one with content. The allowance only falls. The
latch only fires once. After it fires, the classification that used to exempt a
period stops exempting it.

Why the nearest burned mechanisms don't fit.

The closest named neighbour is a token bucket, and it's occupied.
`gh api -X GET search/code -f q='token bucket language:tla'` returns 41. A token
bucket refills at a rate, and running dry denies the request. Laytime never
refills, and running dry denies nothing. It reprices. I think those are
different enough to be different mechanisms, and the reprice is where the
modeling lives, but I'd rather record the 41 than leave it out.

Scheduling is the other one to clear, since it's half of what burned the
withdrawn domain. Scheduling assigns work to slots to satisfy a constraint. The
agent assigns nothing. He classifies periods that have already happened. There's
no slot, no ordering choice and no constraint to satisfy.

Resource allocation needs contention over something finite with somebody
waiting. One charterer, one ship, nobody waiting. Atomic commitment needs a vote
and an abort path, and a logged period has neither.

`gh api -X GET search/code -f q='demurrage language:tla'` returns 2. Both are
conservation-invariant specs in blockchain repos
(`ss1738/EvaporChain :: research/tla/ConservationInvariant.tla` and
`navigatorbuilds/elara-mesh :: spec/tla/Conservation.tla`), which is the
monetary sense of the word, a holding fee on tokens. Different sense, different
mechanism. The domain reads unoccupied to me.

## §5.7b, the puzzle screen, action-centric form

Shape A, so Q1 and Q2 in their first form.

| # | Question | My answer |
|---|---|---|
| 1 | Hand over the legal moves. Anything left to model? | **Yes, the actions.** "A period" is one step or two, and whether excepted is an action or an attribute is the learner's call. |
| 2 | Actions given, or decided? | **Decided.** The prose names the events. Nobody hands over the decomposition, and the latch can be state or a derivation. |
| 3 | What is asked? | **Is this design correct.** No goal state, no reachability. |
| 4 | Who works once it compiles? | **The learner models, TLC checks.** |
| 5 | Where does the difficulty live? | **Abstraction choice.** How the allowance is carried, and whether the latch is a variable. |
| 6 | Agents, fallibility, interleaving? | **One, infallible.** Mandated by the vector. Puzzle row. |
| 7 | Delete TLC, decision left? | **Yes.** Whether "once on demurrage, always on demurrage" is a state predicate or an action property is arguable on paper. |
| 8 | Names an optimum? | **No.** |

One puzzle row of eight, against a threshold of three.

**KIND: ACCEPT, system.**

## R, the route

**Intended route.** Decide how time is carried, whether as an allowance
remaining or as a count used. Decide whether the latch is a variable or falls
out of the allowance being zero. Write the state, write `Observe`, write the
four properties under the keywords the statement gives, run TLC on both trace
sets.

**Probes I can run at step 0.** Tiling is the cheap one and it fires on every
batch-2 rung: at count 1 and form 0 the rules and the cfg lines match one to one
by construction, so the cross-table is free and finds nothing. Recall has
nothing to hand over here, because §5.7 came back clear and I couldn't find a
published spec of the mechanism. Vocabulary absence, elimination, answer form
and pre-clearing all need a statement, and there isn't one yet.

**Shortest route I can see.** Carry `used` and `onDemurrage` as two independent
variables, and all four properties can be written without noticing that the
latch couples them. That's the failure I'd want the reference to catch, and at
representation 2 it does, since `Observe` has to match the reference's variables
and a learner who invents a spare variable is out of interface.

**ROUTE: provisional, leaning accept.** The route defence lives in the frozen
reference's variable choice, and the reference doesn't exist yet. Step 4 decides
it. I can't answer this honestly at step 0 and I'd rather say so than guess.

## Vector fit

**Parties.** One, the ship's agent. His steps are `TenderNotice`, `LogWorking`,
`LogExcepted` and `Complete`. Nothing arrives unprompted, so step sources 0
holds.

Two boundaries the statement has to draw, and I'd hand both to the statement
author rather than leave them implied.

The weather is the dangerous one. If the statement says "rain stops work", that
is a step assigned to no party and sources jumps straight from 0 to 3. It has to
be the agent classifying a period in his own log. The rain is his reason, not
his prompt.

The charterer and the shipowner are outside the system. The money is settled
later and none of it is modeled. §3.2 obliges the statement to fix the system
completely, so it has to say that in a sentence.

**Rules, and their kind.**

1. The type invariant. One-state claim.
2. Laytime remaining never rises. Step rule.
3. Demurrage accrued never falls. Step rule.
4. Demurrage is accrued only when laytime remaining is zero. One-state claim.

Four cfg lines, two of them action properties, none needing "eventually". That's
kind 2 and count 1 exactly. The agent is under no obligation to finish the
discharge, so nothing has to happen and kind stays at 2.

**State estimate.** Laytime remaining 0 to 3, demurrage accrued 0 to 3, notice
tendered and discharge complete as flags. That's 4 x 4 x 2 x 2 = 64 in the type
space, and reachable is smaller since both counters are monotone. Well under
1,000 and sub-second. INFERRED, not measured.

**What the domain wants that the vector won't give.** Despatch is the obvious
extra, the reverse payment when the charterer finishes early. It adds a third
counter and a fifth rule, which pushes count past 1. The statement leaves it
out. Real laytime is reckoned in hours against a calendar, and the statement has
to reckon in periods the agent logs instead. That substitution is what keeps
sources at 0, so it isn't a trim, it's the design.

## Frank's schema

Charterparty law, and the laytime statement a port agent keeps. He works in
industrial IoT and facility management. My read is he'd recognize "demurrage"
from container shipping and hold no working model of how the allowance is
reckoned. Nothing in refrigeration, alarms or control has a consumable
allowance that latches a billing regime and cancels its own exceptions.

**The vocabulary load, since it's the obvious objection.** Four terms: laytime,
notice of readiness, excepted period, demurrage. Each is one clause to define.
That's more than rung 1 carried, and shape A statements run longer than shape B
ones, so I think it's inside what this rung can hold. It's the thing I'd watch
at step 4.

**The threshold-ledger rhyme, since it's the other obvious objection.** Central
ruled out anything that rhymes with the holdout's apprenticeship hours, meaning
per-category minimums met and then a status flips. Laytime has one category, it
counts down rather than up, the flip is a failure rather than an achievement,
and the rules change after the flip. Hours has no analogue of that last part. I
read it as a near miss rather than a hit, and the reason I'm comfortable is that
the interesting half of laytime is the half hours doesn't have.

---

# Candidate 2: the pawnbroker's pledge book, `PledgeBook`

One pawnbroker. He takes in a pledge against a loan, and the customer has a term
in which to redeem it. The broker rules a line in his book at the close of each
trading period, which ages every live pledge by one. Before the term runs out a
pledge can be redeemed, or renewed on payment of interest, which restarts its
term. When the term runs out with neither, the broker declares the pledge
forfeit and the item is his to sell.

## §5.7, the mechanism screen

Two phrasings, verdicts pasted:

```
=== CANDIDATE: renewable term on a pledged item where the holder restarts the clock and forfeiture follows a lapse
--- step 1: NAME collision
    query: 'PledgeBook language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: pawnbroker redemption period with renewal and one way forfeiture when the term runs out
--- step 1: NAME collision
    query: 'PledgeBook language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

Named by hand: **the mechanism is a renewable term per item, held by one party,
with a one-way forfeiture when the term lapses.** That is a lease. It is the
lease, in the sense the distributed systems literature means, wearing a
different hat.

**This one is BURNED, and the tool cleared it.**
`gh api -X GET search/code -f q='lease renewal language:tla'` returns 29,
against §5.7's threshold of 3. The first five are
`josehu07/summerset :: tla+/multipaxos_refine_lease/LeaseProtocol.tla`,
`.../bodega_refine_lease/RosterLeases.tla`,
`.../bodega_refine_lease/BodegaRefine.tla`,
`.../multipaxos_refine_lease/MultiPaxosRefine.tla` and
`zepdb/zeppelin :: formal-verifications/tla/MultiWriterLease.tla`. Those are
lease protocols with renewal and expiry, specified in TLA+, by name.

I can't probe that clear the way rung 1 probed its BURNED. A probe is for a
phrasing artifact, where one word swapped changes the verdict and nothing else
moves. This is the opposite fault. The tool's map has no row for leases at all,
so no phrasing of this domain will ever reach the mechanism step. The hit is
real and the clean bill is the artifact.

## §5.7b, the puzzle screen, action-centric form

| # | Question | My answer |
|---|---|---|
| 1 | Hand over the legal moves. Anything left to model? | **Some.** Is the term a deadline or a remaining count, and is forfeiture an action or a derivation? |
| 2 | Actions given, or decided? | **Split.** Take in, redeem, renew and forfeit are the domain's own four words. |
| 3 | What is asked? | **Is this design correct.** |
| 4 | Who works once it compiles? | **The learner models, TLC checks.** |
| 5 | Where does the difficulty live? | **Nowhere I can point at.** The lease shape is standard enough that the representation is nearly dictated. Puzzle row. |
| 6 | Agents, fallibility, interleaving? | **One, infallible.** Mandated by the vector. Puzzle row. |
| 7 | Delete TLC, decision left? | **Yes, weakly.** Whether renewal resets or extends is arguable, and the domain settles it. |
| 8 | Names an optimum? | **No.** |

Two puzzle rows of eight. Under the threshold, so the tally passes.

**KIND: ACCEPT, system.** The tally isn't what rejects this candidate.

## R, the route

**Shortest route.** A learner who has seen a lease writes the whole spec in one
pass, because the state is the one every lease spec uses: a term counter, a
holder, and a status. The recall probe is exactly this, and PUZZLE-SCREEN.md
scopes it to a BURNED §5.7. The hand-run §5.7 above is BURNED, so the probe
fires, and 29 published lease specs are what the mechanism's prior hands over
for free.

**ROUTE: REJECT.** The route is recall, and recall is not the judgment this
rung is for.

## Vector fit

It fits the numbers and fails on two other things, which is worth separating.

**Parties.** One broker. `TakeIn`, `Rule`, `Redeem`, `Renew` and `Forfeit` are
all his, and ruling the line is what advances time. Step sources 0 holds
cleanly, and this is the candidate that satisfies the rung's hard constraint
most naturally of the three.

**Rules, and their kind.** A type invariant, "a forfeited pledge is never
redeemed" as a step rule, "a live pledge's age never exceeds its term" as a
one-state claim, and "redemption is terminal" as a step rule. Four lines,
kind 2, count 1. It fits.

**State estimate.** Two pledges, age 0 to 2, status in four values. Well under
1,000. INFERRED.

## Frank's schema

This is where it fails a second time, independently of §5.7.

The domain is unfamiliar and the mechanism isn't, which is the wrong way round.
He hasn't run a pawnshop. He has spent twenty years in software, and a lease
with renewal and expiry is a software primitive. Central's exclusion list rules
out software of any kind, and §5.7's own headline is that name novelty is not
mechanism novelty. Putting a lease in a pledge book doesn't change what the
learner is modeling. Rung 1 rejected its breed registry on the same argument,
and I think it applies harder here, because a lease is closer to Frank's daily
work than a foreign key is.

---

# Candidate 3: the ripening cave, `Affinage`

One affineur. Wheels of washed-rind cheese arrive green from the dairy and go on
the boards. The affineur works the cave a round at a time, turning and washing
every wheel, and a round is what ages them. A wheel can't go out under its
minimum number of rounds. A wheel that passes its maximum has gone over, and he
pulls it as waste. Sold and waste are both final.

## §5.7, the mechanism screen

The first phrasing came back BURNED:

```
=== CANDIDATE: cheese ripening cave where a wheel is too young to sell and at expiry is condemned
--- step 1: NAME collision
    query: 'Affinage language:tla'
    hits: 1 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    mechanism terms: allocation,matching
    tlaplus/Examples README (cache: harness/fixtures/screen/examples-README.md):
      allocation           2 README row(s) -> BURNED
                             Resource Allocator (specifications/allocator)
                             losa_ap (specifications/losa_ap)
      matching             no README row
    mechanism code-search (README did not settle these):
      Matching             1368 hits -> BURNED (>3)
--- §5.7 VERDICT: BURNED   (name: CLEAR | mechanism: BURNED)
```

**The BURNED is a substring artifact of one map row, and here's the probe.**
`harness/screen.sh:112` carries `blood bank|inventory|expiry|type
compatibility~allocation,matching`, which fires on the bare word "expiry". A
ripening cave has nothing allocated and nothing matched. I reran the same
phrasing with "expiry" swapped for "overripeness" and changed nothing else:

```
=== CANDIDATE: cheese ripening cave where a wheel is too young to sell and at overripeness is condemned
--- step 1: NAME collision
    query: 'Affinage language:tla'
    hits: 1 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

One word is the whole delta. The second phrasing, mechanism-centric:

```
=== CANDIDATE: two sided admissibility window on a monotone age counter advanced by one global round
--- step 1: NAME collision
    query: 'Affinage language:tla'
    hits: 1 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

Named by hand: **the mechanism is a two-sided admissibility window over a
monotone age, where one act of the actor ages every item at once.** Too young is
a fault and too old is a fault, and the actor's own round is what moves items
through the window.

Why the nearest burned mechanisms don't fit. A lease has a one-sided expiry, so
candidate 2's problem doesn't reach here. The honest neighbour is an X.509
validity window, which has both bounds.
`gh api -X GET search/code -f q='notBefore notAfter language:tla'` returns 2,
which is under the threshold. Perishable inventory is the other neighbour, and
it's one-sided too, since nothing is too fresh to sell. Allocation and matching
are the tool's answer to a word rather than to the domain.

## §5.7b, the puzzle screen, action-centric form

| # | Question | My answer |
|---|---|---|
| 1 | Hand over the legal moves. Anything left to model? | **Yes.** Age per wheel, or one round counter with an entry stamp per wheel? Those give different properties. |
| 2 | Actions given, or decided? | **Decided.** A round that ages every wheel is one step or many, and the learner picks. |
| 3 | What is asked? | **Is this design correct.** |
| 4 | Who works once it compiles? | **The learner models, TLC checks.** |
| 5 | Where does the difficulty live? | **Abstraction choice.** Per-item age against a shared clock with stamps is the S4 modeling question in one line. |
| 6 | Agents, fallibility, interleaving? | **One, infallible.** Mandated by the vector. Puzzle row. |
| 7 | Delete TLC, decision left? | **Yes.** The lower bound is a state predicate over what was sold, or an action property on the sale step. Those are different claims. |
| 8 | Names an optimum? | **No.** |

One puzzle row of eight. Under the threshold.

**KIND: ACCEPT, system.** This is the strongest §5.7b of the three, and Q5 is
the reason.

## R, the route

**Intended route.** Pick a carrier for age, write the state and `Observe`, write
the four properties under the given keywords, run TLC.

**Probes.** Tiling is free and finds nothing, same as every batch-2 candidate at
count 1 and form 0. Recall finds nothing: the §5.7 above is clear once the map
row is discounted, and the validity-window neighbour returned 2. The rest need a
statement.

**Shortest route I can see.** Same as the intended one, since form 0 hands over
every keyword. The representation choice is the whole exercise and it can't be
skipped, which is a better position than candidate 2 is in.

**ROUTE: provisional, leaning accept.**

## Vector fit

**Parties.** One affineur. `Receive`, `Round`, `Sell` and `Discard` are all his.
The round is the thing to watch. It looks like a clock, and it isn't one,
because he chooses to make it and nothing forces him. Step sources 0 holds, but
I think the statement has to be careful about the word "round" so a reader
doesn't hear a tick.

**Rules, and their kind.** A type invariant, "no wheel was sold under its
minimum" as a one-state claim, "a wheel's age never falls" as a step rule, and
"a wheel that has left never returns" as a step rule. Four lines, kind 2,
count 1.

**State estimate.** This is the one I'd flag. Three wheels, age 0 to 3, place in
four values is 4096 in the type space. Reachable is much smaller, since age only
rises and place is nearly monotone, but I can't tell from here whether it lands
under 1,000. Two wheels is comfortable. The reference author should measure
rather than assume, and the shipped instance may need to be two.

## Frank's schema

This is the objection that decides candidate 3 for me, and it isn't the one I
expected going in.

A ripening cave is a temperature and humidity controlled room. Frank's day job
is refrigeration, HVAC and facility control. §3.10 disqualifies exactly those
domains, and central's exclusion list names refrigeration outright. He wouldn't
know the affinage rules, but he'd arrive holding a working model of the room,
its set points and what happens to product when it drifts. That's half a model
handed over for free, which is what §3.10 exists to prevent.

I'd rather lose the best §5.7b of the three than take a domain that hands the
learner a schema. My read is that this is a real hit rather than a stretch, but
it's the call in this report I'd most like a second opinion on.

---

# The recommendation

**Take candidate 1, laytime and demurrage, `Laytime`.**

It's the only one of the three that clears both screens and §3.10 together.
Its four rules land on two one-state claims and two action properties with
nothing needing "eventually", which is kind 2 and count 1 without trimming. Its
one actor logs periods, so time is his own doing and step sources stays at 0
without a calendar anywhere. And the latch is the piece I'd build the rung on: a
learner who carries the allowance and the mode as two loose variables can write
all four properties and never notice they're coupled, and at representation 2
that shows up as an `Observe` that doesn't match the reference.

**The live alternative is candidate 3, `Affinage`, and the world where it wins
is this one.** Central reads the cheese cave as far enough from refrigeration
control, on the grounds that the problem is the affineur's rounds and not the
room, and prefers a three-word vocabulary (green, round, over) to four terms of
shipping law. That's a real position, and candidate 3 scores better on Q5 than
candidate 1 does. If the §3.10 call goes the other way, take it, and tell the
reference author to measure the state count before fixing the instance size.

I'd leave candidate 2 out. It's BURNED on the lease mechanism at 29 hits, its
route is recall, and it puts a software primitive in front of a software
engineer. Three independent reasons, and any one of them is enough.

# Two follow-ups worth filing

**Add a lease row to `screen.sh`'s mechanism map.** S4 is the situation the map
is thinnest on, and candidate 2 is the proof: the one mechanism in this rung
that's genuinely occupied is the one the tool can't see. A row along the lines
of `lease|term renewal|redemption period~lease,timeout` would have caught it.
Rungs 5 and 7 are both S4 and will screen against the same blind spot.

**Narrow the `expiry` alternate in the blood bank row.** As written it fires on
S4's own headline noun and returns allocation and matching, neither of which has
anything to do with time running out. Rung 1 filed the same class of finding
against the `warehouse|robot` row, so this is now two false positives from the
same map, and §2.2 already records the table side of it (V2-PLAN.md:180, bead
`tla-stdl`). I haven't touched the file, since this bead grants me one report
and nothing else.
