# Rung 5 step 0, domain screens

Bead `tla-h2cg.11`, the fifth rung of batch 2 (V2-PLAN.md §7.0, table at line
1622). Both screens run over three candidate domains before anything is
written. §6 step 0 puts this ahead of the reference author.

## The rung, and what it can carry

Rung 5 is shape A in situation S4, time, expiry and leases. The learner models
from prose, so the state is theirs. Reading gate ch11.

The vector, in §2.5's order:

| dimension | level | reads as |
|---|---|---|
| representation | 2 | state is the learner's, reference variables are the `Observe` fields |
| property kind | 3 | at least one `<>` or `~>`, plus a fairness conjunct |
| property count | 2 | five to nine cfg lines, type invariant included |
| step sources | 1 | several actors of one kind, no clock |
| state space | 0 | under a second, under 1,000 distinct states |
| form left open | 0 | keyword, kind and subscript all given |

Property count 2 is the single new high. Everything else sits at or under the
running maximum from rungs 1 to 4.

The two constraints that decide this rung pull against each other. Five to nine
properties want a system with enough distinct rules to carry them honestly. A
thousand states want the instance tiny. So the domain has to have many rules
over few entities, which is a narrower target than either number looks on its
own.

## Why the domain changed

The §7.0 table drafted blood bank inventory for this rung. Central withdrew it
before this screen ran, because it screened BURNED on allocation and matching
in August (bead `tla-03d2`), and Frank took the strict reading. So the rung
keeps its vector and takes a fresh domain.

## The finding that belongs to the rung, not to any candidate

`harness/screen.sh:112` carries the map row
`blood bank|inventory|expiry|type compatibility~allocation,matching`. The bare
word **expiry** fires it. That word is a third of this rung's own situation
name, so any honest S4 phrasing walks into it.

The probe, offline, one word swapped and nothing else changed:

```
=== CANDIDATE: a maturation window with expiry of the piece if it is left on the floor too long
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    mechanism terms: allocation,matching
      allocation           2 README row(s) -> BURNED
                             Resource Allocator (specifications/allocator)
                             losa_ap (specifications/losa_ap)
      matching             no README row
--- §5.7 VERDICT: BURNED   (name: SKIPPED | mechanism: BURNED)
```

```
=== CANDIDATE: a maturation window with spoiling of the piece if it is left on the floor too long
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
--- §5.7 VERDICT: CLEAR   (name: SKIPPED | mechanism: CLEAR)
```

This is the same class of fault rung 1 found in the `warehouse|robot` row. It
matters more here, because rungs 2, 5 and 7 are all S4. My read is that the row
was authored to burn the blood bank, and it burns the situation instead.

I phrased all six candidate strings below without the word, which is a
workaround and not a clearance. I say the mechanism by hand for each one
underneath, and that is where the real screening happens.

Every pasted block below is the tool's own output with one thing cut: the
standing trailer saying §5.7b is a separate screen and wasn't run. The two
offline probe blocks also drop their step 1 line, which reads "skipped
(offline)". Nothing else is edited.

## What the tool returned, and what it did not

All three candidates came back CLEAR on both phrasings, and all six phrasings
returned "no mechanism derived". The tool says itself that is not a clean bill.
Six no-derivations in a row is a fact about the map's coverage of time and
expiry vocabulary, not a fact about the three domains. So the hand-named
mechanism carries the weight in every section below.

---

# Candidate 1: laytime and demurrage, `Laytime`

Several charterers, each with a vessel to load. Each has a fixed allowance of
working shifts, the laydays. A shift spent working cargo and a shift spent idle
both draw the allowance down. Once the allowance is gone every further shift is
on demurrage and is paid for, and a vessel on demurrage stays on demurrage
until the cargo is done. A charterer who finishes with allowance left earns
despatch.

It sits in S4 because the allowance is a lease on the ship's time and it runs
out. It isn't S2, because nothing is contended. Each charterer has their own
vessel and their own allowance.

## §5.7, the mechanism screen

```
=== CANDIDATE: laytime allowance consumed by cargo work before demurrage begins to run
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
=== CANDIDATE: depleting allowance spent by the actors own work with an irreversible switch to a penalty regime
--- step 1: NAME collision
    query: 'Laytime language:tla'
    hits: 2 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

Named by hand: **the mechanism is an allowance drawn down by the actor's own
work, with a one-way switch into a penalty regime that never switches back.**
The allowance is monotone down, the penalty is monotone up, and the switch
latches.

Why the nearest burned mechanisms don't fit. Scheduling needs an order over
tasks to be decided, and nobody here chooses what to work on next. The
`Resource Allocator` needs contention over something finite and somebody
waiting, and each charterer holds their own vessel. Atomic commitment needs a
vote and an abort path.

**Two hand searches worth recording.** `gh api -X GET search/code -f
q='Laytime language:tla'` returns 2, both in `morphicsnet/software` under
`docs/formal/tla`, in `Types.tla` and `ReplayEquivalence.tla`. One distinct
work, and I read both as loose word matches from the paths.

`q='demurrage language:tla'` also returns 2, in `ss1738/EvaporChain ::
research/tla/ConservationInvariant.tla` and `navigatorbuilds/elara-mesh ::
spec/tla/Conservation.tla`. Both are token demurrage, which is a holding fee on
a balance under a conservation law. That's a different sense of the word and a
different mechanism from laydays. I don't read either as BURNED. I do read them
as the word being taken, and a learner searching it will land on crypto.

## §5.7b, the puzzle screen

Shape A, so Q1 and Q2 in their action-centric form.

| # | Question | My answer |
|---|---|---|
| 1 | Hand over the legal moves. Anything left to model? | **Yes.** What a unit of time is, and whether demurrage is a latched flag or a comparison read off the allowance. |
| 2 | Actions given, or decided? | **Decided, with a push.** Nobody hands over `Work`, `Idle` and `Finish`, but the trade's own vocabulary leans hard on them. |
| 3 | What is asked? | **Is this design correct.** No goal state. |
| 4 | Who works once it compiles? | **The learner models, TLC checks.** |
| 5 | Where does the difficulty live? | **Abstraction choice.** What one shift is, and where demurrage lives. |
| 6 | Agents, fallibility, interleaving? | **Several, of one kind, and they can stall.** An idle shift is a charterer wasting their own allowance. |
| 7 | Delete TLC, decision left? | **Yes.** Latch or derivation is defensible either way, and the two give different step rules. |
| 8 | Names an optimum? | **No, as drafted.** The danger is real though. "Minimise demurrage" is the natural trade framing and it would write a puzzle. |

No clear puzzle rows of eight.

**KIND: ACCEPT, system.**

## R, the route

**Intended route.** Decide what a shift is and who takes it. Decide whether
demurrage is state or derivation. Write the actions. Write the seven
properties, whose forms the statement gives.

**Probes I can run at step 0.** Tiling is free and finds nothing, because at
form 0 the rules and the cfg lines match one to one by construction. Recall
fires weakly on the two crypto hits above, and I think it points a learner away
from laydays rather than toward them. The rest need a statement.

**Shortest route I can see.** At form 0 the properties are mechanical once the
state exists, so the whole route is the state design. That's true of every
representation 2 candidate here and it isn't a fault of this one.

**ROUTE: provisional, leaning accept.** The route turns on the statement, and
step 4 decides it.

## Vector fit

**Parties.** Several charterers, one kind. `Work`, `Idle` and `Finish` are all
theirs.

**The problem with this candidate, and it's here.** Demurrage in the real trade
accrues with the calendar, not with anybody's act. To hold step sources at 1,
the statement has to make the passing of a shift a charterer's own step. That
is workable, since standing idle is a choice a charterer makes and pays for.
But it's a fudge, and a statement that says "a shift passes" instead of "the
charterer stands the vessel idle" assigns a step to no party and takes the rung
to sources 3. I'd hand that to the statement author as a hard constraint rather
than a note.

**Rules, and their kind.**

1. Type invariant. One-state claim.
2. Laytime left is never negative and never above the allowance. One-state claim.
3. Only a vessel with laytime spent owes demurrage. One-state claim.
4. Laytime left never rises. Step rule.
5. A vessel on demurrage stays on demurrage. Step rule.
6. Despatch is earned only on a finish with laytime left. Step rule.
7. Every vessel eventually finishes. `~>` with `WF` on each charterer.

Seven lines, one of them temporal with fairness. That's kind 3 and count 2.

**State estimate.** Two charterers, allowance 2, demurrage 0 to 2, a finished
flag. Per vessel that's 3 × 3 × 2 = 18 in the type space, and rule 3 cuts the
reachable set well below it. Two vessels gives 324 at the outside. Under 1,000
and sub-second. INFERRED, not measured.

**What the domain wants that the vector won't give.** Nothing beyond the shift
constraint above. Real charterparties have weather working days, exceptions and
notices of readiness, and the statement can leave all of them out.

## Frank's schema

Charterparty laytime is specialist maritime commercial law. It isn't industrial
IoT, facility management, refrigeration or software. My read is he knows
"demurrage" as a line on a container bill and holds no model of laydays,
despatch, or the once-on-demurrage rule.

---

# Candidate 2: banns of marriage, `Banns`

Several parish clerks. Each holds a register of couples whose banns must be
called at three services before the marriage may be solemnised. Anyone present
may enter an objection, which stops the calling until it's withdrawn. If the
marriage isn't solemnised within a set number of further services, the banns
lapse and must be called afresh from nothing.

It sits in S4 because the permission ripens and then expires. It isn't S5,
because there's no lifecycle the couple moves along under anybody's approval.

## §5.7, the mechanism screen

```
=== CANDIDATE: banns of marriage called three times before a wedding may be solemnised
--- step 1: NAME collision
    query: 'Banns language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: permission accrued by repeated public announcement defeasible by objection and lapsing unused
--- step 1: NAME collision
    query: 'Banns language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

`gh api -X GET search/code -f q='banns language:tla'` returns 0.

Named by hand: **the mechanism is a permission that accrues by repeated public
announcement, can be defeated by any single objector while it accrues, and
expires if it isn't used.** Three counters in one, and the interesting part is
that the permission is defeasible right up to the moment it's spent.

Why the nearest burned mechanisms don't fit. The objection looks like an abort,
so atomic commitment is the honest neighbour. It doesn't fit: there's no
coordinator, no request that a vote replies to, and no set of participants who
all have to agree. One objector stops one couple's banns and nothing rolls
back. Consensus needs agreement on a value and nobody here proposes one.

## §5.7b, the puzzle screen

| # | Question | My answer |
|---|---|---|
| 1 | Hand over the legal moves. Anything left to model? | **Some.** Whether a calling count is a number or a list of callings, and whether an objection is a flag or a set of objectors. |
| 2 | Actions given, or decided? | **Given, near enough.** `Call`, `Object`, `Withdraw`, `Solemnise` and `Lapse` are the domain's own words, in the domain's own order. Puzzle row. |
| 3 | What is asked? | **Is this design correct.** |
| 4 | Who works once it compiles? | **The learner models, TLC checks.** |
| 5 | Where does the difficulty live? | **Abstraction choice, thinly.** Mostly whether lapse is an action or a predicate. |
| 6 | Agents, fallibility, interleaving? | **Several clerks of one kind, and an objection interferes.** |
| 7 | Delete TLC, decision left? | **Yes, weakly.** Lapse as action or as predicate, and I can't name a second one. |
| 8 | Names an optimum? | **No.** |

One clear puzzle row of eight, under the threshold of three.

**KIND: ACCEPT, system.** It passes, and it passes by less than the other two.

## R, the route

**Intended route.** As candidate 1. Design the state, write the actions, write
the properties.

**Shortest route I can see, and it's the objection to this candidate.** The
domain hands over five verbs in five words, and at form 0 the properties come
with their keywords. A learner can transcribe the five verbs into five actions
and write seven cfg lines without making a decision they'd have to defend. That
is shorter than the intended route.

**ROUTE: leaning reject.** I can't prove it at step 0, because the route
depends on the statement. But the gap between intended and shortest is
narrower here than for either of the others, and I think that's a property of
the domain rather than of any wording.

## Vector fit

**Parties.** Several parish clerks, one kind.

**The lapse counter is where this breaks.** Banns lapse after a period, and a
period has to be measured in something. Measured in services, a service is one
clerk's act that ages every couple in the register at once. That's a broadcast
step, and I think it's the forbidden calendar wearing a cassock. Measured in
the clerk's discretionary striking of stale entries, the lapse rule stops being
a rule and becomes a choice. Neither reading is clean, and the rung block warns
against exactly this shape.

**Rules, and their kind.**

1. Type invariant. One-state claim.
2. No marriage is solemnised on fewer than three callings. One-state claim.
3. Banns under objection are never advanced. Step rule.
4. A calling count only rises, except on a lapse, which zeroes it. Step rule.
5. A couple is never married twice. One-state claim.
6. Banns called and unobjected eventually solemnise or lapse. `~>` with `WF`.

Six lines, kind 3, count 2. It fits the numbers.

**State estimate.** Two couples, callings 0 to 3, an objection flag, a married
flag. Per couple 4 × 2 × 2 = 16, so 256 for two. Under 1,000. INFERRED.

**What the domain wants that the vector won't give.** A calendar, which is the
whole problem above.

## Frank's schema

Ecclesiastical marriage law. He'd know the phrase "reading the banns" from
novels, and my read is he holds no model of the three-calling requirement or
the lapse. Good on §3.10, which isn't enough to save it.

---

# Candidate 3: floor malting, `Maltings`

Several maltsters share a malting floor. Steeped barley is spread on the floor
as a piece. A maltster turns a piece with a shovel, and each turning advances
its modification by one. A piece kilned before its modification reaches the
lower mark is under-modified and is a loss. A piece left on the floor past the
upper mark mats together and overheats, and is also a loss. Between the two
marks the piece is ready and may be kilned. A kilned piece never returns to the
floor.

It sits in S4 because a piece is only good inside a window and the window
closes. It isn't S9, because the rules aren't standing facts about entities.
They're about when a thing may be acted on.

## §5.7, the mechanism screen

```
=== CANDIDATE: floor malting where green malt is turned by hand and kilned within a modification window
--- step 1: NAME collision
    query: 'Maltings language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: two sided maturation window where a piece acted on too early or too late is spoiled
--- step 1: NAME collision
    query: 'Maltings language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

`gh api -X GET search/code -f q='malting language:tla'` returns 0.

Named by hand: **the mechanism is a two-sided maturation window advanced by the
actor's own work, where acting too early and acting too late both ruin the
thing, and the exit is one-way.** Most time mechanisms in the corpus are
one-sided. A lease has a deadline and a timeout has a deadline. This one has a
floor as well as a ceiling, and that's what makes it worth five to nine rules.

Why the nearest burned mechanisms don't fit. The closest thing in the Examples
table is the timing side of the hybrid logical clock work, and that's about
ordering events across machines rather than about a validity interval.
Scheduling needs an order to be chosen, and here the pieces are independent.
Allocation needs contention, and every piece has its own place on the floor.

## §5.7b, the puzzle screen

| # | Question | My answer |
|---|---|---|
| 1 | Hand over the legal moves. Anything left to model? | **Yes, and this is the candidate's case.** Over-modification is true of a piece the moment it's turned once too often, and nobody sees it until a maltster looks. So spoiling is either a step somebody takes or a predicate over the state, and the two carry different invariants. |
| 2 | Actions given, or decided? | **Decided.** The trade gives you turning and kilning. It gives you nothing at all about the loss, and the loss is half the rules. |
| 3 | What is asked? | **Is this design correct.** |
| 4 | Who works once it compiles? | **The learner models, TLC checks.** |
| 5 | Where does the difficulty live? | **Abstraction choice.** Where the window lives, and whether a loss is an event or a fact. |
| 6 | Agents, fallibility, interleaving? | **Several maltsters of one kind, and neglect is a real failure.** A piece nobody turns is as spoiled as one turned too often. |
| 7 | Delete TLC, decision left? | **Yes.** Loss as event or as fact is arguable on paper, and the argument is the exercise. |
| 8 | Names an optimum? | **No, as drafted.** "Kiln as many pieces as you can" would be an optimum and it has to stay out. |

No clear puzzle rows of eight.

**KIND: ACCEPT, system.**

## R, the route

**Intended route.** Decide how modification is carried and where the two marks
live. Decide whether a loss is an action or a predicate. Write the actions.
Write the seven properties under the keywords the statement names.

**Probes.** Tiling is free and finds nothing, for the form 0 reason above.
Recall finds nothing, since the malting search returns 0 and no published spec
of a maturation window turned up. The other four need a statement.

**Shortest route I can see.** Carry modification as a counter, kiln when it's
in range, and write the properties off the counter. That reaches an answer. It
also produces a spec where over-modification can't be stated, since a piece
that's already ruined and a piece that's still ready look the same. My read is
that TLC catches it on the violating trace rather than the learner catching it
on paper, which is a later failure than I'd like but it's still a failure the
problem detects.

**ROUTE: provisional, leaning accept**, and leaning harder than either of the
others. The loss decision is the one place across all three candidates where a
learner has to choose between two representations that aren't
interchangeable.

## Vector fit

**Parties.** Several maltsters, one kind. `Turn`, `Kiln` and, if the learner
chooses it, `WriteOff` are all theirs.

**This is the cleanest of the three on step sources, and it's the reason I'd
take it.** Modification advances when somebody turns the grain and at no other
time. There's no shift to pass, no service to hold, and no day to end. The
rung's constraint that time is the actors' own doing isn't a constraint the
statement has to work around here. It's what the domain already is.

**Rules, and their kind.**

1. Type invariant. One-state claim.
2. A piece still on the floor is never past the upper mark. One-state claim.
3. A kilned piece is good or lost, never both. One-state claim.
4. Modification only rises, and only on a turning. Step rule.
5. A piece that leaves the floor never returns. Step rule.
6. A piece kilned below the lower mark is recorded as a loss. Step rule.
7. Every piece on the floor is eventually kilned or written off. `~>` with `WF`
   on each maltster.

Seven lines, three one-state claims, three step rules, one temporal with
fairness. Kind 3, count 2, and no rule is padding.

**State estimate.** Three pieces, modification 0 to 3, stage in floor, kilned
or lost. Per piece that's 12 in the type space, and rule 2 cuts it to about 8
reachable. Three pieces gives roughly 512. Under 1,000 and sub-second, with
room to drop to two pieces if it isn't. INFERRED, not measured.

**What the domain wants that the vector won't give.** Real malting turns on
temperature and moisture, which are continuous and would take the state space
past 0. The statement has to fix the window as a count of turnings instead.
That's a §3.2 move and it's legitimate, since the statement fixes the system.
Kilning is also a separate vessel with its own capacity in the real thing, and
that has to stay out or it drags allocation back in.

## Frank's schema

Strongest of the three. Floor malting is a nineteenth-century craft that
survives in a handful of maltings. It isn't industrial IoT, facility
management, refrigeration, HVAC or software.

**The obvious objection, since a maltings is a food plant.** CrossnoKaye Atlas
does control and refrigeration for food and beverage processing, so "grain
building" is uncomfortably adjacent on the face of it. My read is that the
adjacency is the industry and not the schema. Nothing in the mechanism is
control, cooling, alarming or sensing. It's a craftsman deciding when a heap of
barley is ready, and the whole point of floor malting is that no instrument
tells him. I'd still flag it for Frank rather than decide it for him.

**The vocabulary load.** Three terms: piece, modification, kilning. Each can be
defined in the sentence that introduces it, and modification is defined as a
count of turnings by fiat. Four sentences do the whole domain.

---

# The recommendation

**Take candidate 3, floor malting, `Maltings`.**

It's the only one of the three where time is already the actors' own doing.
Candidates 1 and 2 both need the statement to assign the passing of time to a
party, and in both cases that assignment is a fudge the statement author has to
maintain against the domain's own pull. Rung 5 holds step sources at 1, and a
domain that fights that constraint at every sentence is the wrong domain for
the rung.

It also carries the count honestly. Seven rules, three of them one-state, three
step rules and one temporal, over three entities and about 512 states. The new
high on this rung is property count, so the rules have to be real rather than
restatements of each other, and the two-sided window is what buys that. A
one-sided deadline gives you the same rule twice.

And it's the best of the three on Q2 and on R. The trade hands over turning and
kilning and hands over nothing about the loss, so the learner decides whether
spoiling is an event or a fact. That decision is where representation 2 earns
its level.

**The live alternative is candidate 1, `Laytime`, and the world where it wins
is this one.** Central wants the domain's rules to come from the domain rather
than from us. §3.2 obliges the statement to fix the system completely, and a
charterparty's laytime clauses are the most legally precise rules of the three.
Malting's marks are fixed by fiat, which is honest but means we're inventing
the numbers a learner has to reason about. If that trade reads the wrong way,
take `Laytime` and hand the shift constraint to the statement author in
writing.

I'd leave candidate 2, `Banns`, out. It clears §5.7 with a hand search of 0,
and it fails on the two things the rung actually needs. Its lapse counter needs
a service that ages every entry at once, which is the calendar in a cassock.
And its five verbs arrive named, in order, from the domain, which is the
shortest route across all three.

# One follow-up worth filing

Narrow the `expiry` alternative out of `harness/screen.sh:112`, or split that
row so the blood bank burns on `blood bank|type compatibility` and the bare
word doesn't. As written the row burns S4 itself, and rungs 2, 5 and 7 are all
S4. Rung 5's screens routed around it by not using the word, which is a
workaround that will quietly fail at step 4 when the statement uses the word
the situation is named after.

That's the second map-row false positive found in two rungs, after rung 1's
`warehouse|robot`. I think that's a pattern in how the map was authored rather
than two accidents. The rows map a domain phrase to a mechanism, and several of
them alternate a specific phrase with a bare common noun. The bare noun is what
misfires. I haven't touched the file, since this bead grants me one report and
nothing else.
