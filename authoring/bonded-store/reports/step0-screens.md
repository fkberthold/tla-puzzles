# Rung 1 step 0, domain screens

Bead `tla-h2cg.7`, the first rung of batch 2 (V2-PLAN.md §7.0, table at line
1622). Both screens run over three candidate domains before anything is
written. §6 step 0 puts this ahead of the reference author. The pilot ran §5.7
after freezing a spec and got BURNED back in two seconds.

## The rung, and what it can carry

Rung 1 is shape B in situation S9. The learner gets a complete spec plus prose
requirements, and writes the TLA+ form of each requirement and a cfg. S9 is
business rules with no concurrency, so pure invariants over entities. Reading
gate ch11, so PlusCal-era TLA+.

The vector, in §2.5's order:

| dimension | level | reads as |
|---|---|---|
| representation | 1 | a spec ships, the learner writes no state |
| property kind | 2 | at least one `[][A]_v`, no liveness, no fairness |
| property count | 1 | two to four cfg lines |
| step sources | 0 | one actor, no clock, no unassigned step |
| state space | 0 | under a second, under 1,000 distinct states |
| form left open | 0 | keyword, kind and subscript all given |

Representation 1 is the single new high over the floor, which is the ch11
Airlock drill (`authoring/VECTOR-FLOOR.md`). Everything else sits level with
it. So rung 1 is the floor plus a real spec to read, and it's meant to be
thin. A domain that needs five rules to be honest, or a second party to make
sense, or a calendar, is the wrong weight and I should say so rather than trim
it.

## Why the domain changed

The §7.0 table drafted apprenticeship hour logging for this rung. Central
withdrew it before this screen ran, because it's one of the sealed holdout
domains (§7.2, bead `tla-kl5.17`). The holdout only measures transfer if Frank
meets its domains cold. Under §7.0 the domain changes and the rung keeps its
vector, so the three candidates below are all S9 and all written to the same
six levels.

The withdrawal has a second consequence that shapes the screen. The holdout
screens mechanism, not noun. So a domain that reproduces per-category
accumulation against a threshold is out even under a different name, and I've
weighed that against candidate 1 below.

## Two findings that belong to the rung, not to any candidate

Worth stating once before the tables, because otherwise they read three times
as a fault in whichever domain is under the microscope.

**Step sources 0 forces a puzzle answer on Q6.** The rubric's Q6 asks how many
agents act and whether any can fail, stall or interleave. The rung's vector
pins that at one actor. So every rung-1 candidate answers Q6 "one, infallible",
which is the puzzle column, and no domain can rescue it. The threshold is three
puzzle rows of eight, so one mandated row still leaves room. My read is that
this is the cost of having a floor at all, and it's why the threshold isn't one.

**Form left open 0 pushes Q2 toward "given".** `harness/PUZZLE-SCREEN.md` names
the real tell for the spec-in-hand form: if every stated rule maps to one
obvious formula in a vocabulary the artifact already supplies, Q2 reads "given"
and the learner is transcribing one level up. At form 0 the statement hands
over the keyword, the kind and the subscript. What's left is the formula and
the set it ranges over.

So rung 1's defence against Q2 has to come from representation 1 and nowhere
else. At representation 0 the prompt names the variables, so the rule and the
formula share a vocabulary. At representation 1 the learner has to read the
shipped spec to find out how the rule's nouns are carried. The answer can be a
used-count, a remaining-count, or a set of events. That discovery is the
modeling read, and §2.5 says as much when it calls rung 1 "the first thing you
do with a real system is read one" (V2-PLAN.md:395).

That defence only holds if the shipped spec isn't the transliteration of the
English. A variable called `fillsRemaining` next to a rule about fills
remaining is transcription. Step 0 can't settle that, because the spec doesn't
exist yet. So rung 1's §5.7b verdict is more provisional than a rung with open
form would be. Step 4 re-runs both screens on the statement and the frozen
spec, and that's where it's decided. I've flagged the same thing under R for
each candidate.

---

# Candidate 1: pharmacy dispensing register, `Dispensary`

One pharmacist. Drugs held in stock, prescriptions each allowing a fixed number
of fills. Dispense against a prescription, receive stock.

## §5.7, the mechanism screen

Two phrasings, verdicts pasted:

```
=== CANDIDATE: dispensing register with per-prescription fill limits and stock decrement
--- step 1: NAME collision
    query: 'Dispensary language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: bounded draw counter against a fixed authorization cap
--- step 1: NAME collision
    query: 'Dispensary language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

The tool derived no mechanism from either phrasing, and it says itself that
isn't a clean bill. So, by hand:

**The mechanism is a per-key draw counter against a per-key cap, paired with a
two-sided stock balance.** Each dispense raises one prescription's fill count
toward its allowance and lowers one drug's stock. Receiving raises stock. The
counter is monotone, the stock isn't.

Why the nearest burned mechanisms don't fit. The `Resource Allocator` needs
contention over something finite and somebody waiting. One pharmacist waits on
nobody. Atomic commitment needs an all-or-nothing vote and an abort path, and
a dispense has neither. `Knapsack` needs an optimum, and nothing here asks for
one.

**Two hits I'd rather record than leave out.** `gh api -X GET search/code -f
q='Pharmacy language:tla'` returns 5. Four of the five are two mirrors of one
repo, so it's three distinct works. One of them is real prior art:
`SyncFree/WP1 :: D1.2/TLA/fmk.tla` specifies patients, doctors, prescriptions,
pharmacies and a `giveDrug` action that consumes a prescription. Its mechanism
is CRDT replication across datacenters under logical clocks, which isn't ours.
So I don't read it as BURNED. I do read it as the domain being occupied, and
the R rubric's recall probe cares about that.

The second is the holdout rhyme, and it's the serious one. See below.

## §5.7b, the puzzle screen, spec-in-hand form

Shape B, so Q1 and Q2 in their second form, about requirements.

| # | Question | My answer |
|---|---|---|
| 1 | Spec and rules in hand, anything left to model? | **The requirements, thinly.** The rules talk about fills left on a prescription. The spec can carry that three ways, and each gives a different formula. |
| 2 | Requirements given as formal claims, or decided? | **Split.** The kind and keyword are given by form 0. Which counter the rule ranges over is decided. |
| 3 | What is asked? | **Is this design correct.** No goal state, no reachability. |
| 4 | Who works once it compiles? | **The learner writes the properties, TLC checks them.** |
| 5 | Where does the difficulty live? | **Reading the representation.** The state space is nothing. |
| 6 | Agents, fallibility, interleaving? | **One, infallible.** Mandated by the vector. Puzzle row. |
| 7 | Delete TLC, decision left? | **Yes, weakly.** Which counter, and what the step rule's subscript ranges over. |
| 8 | Names an optimum? | **No.** |

One clear puzzle row of eight, plus a split on Q2. Under the threshold of
three.

**KIND: ACCEPT, system.**

## R, the route

**Intended route.** Read the shipped spec. Find how each stated rule's nouns
live in the state. Write each formula under the keyword the statement names.
Run TLC against both trace sets.

**Probes I can run at step 0.** Tiling is the cheap one and it fires on every
rung-1 candidate: at count 1 and form 0 the rules and the cfg lines match
one-to-one by construction, so the cross-table is free and finds nothing. The
recall probe fires here specifically, because of `fmk.tla` above. Vocabulary
absence, elimination, answer form and pre-clearing all need a statement, and
there isn't one yet.

**Shortest route I can see.** Pattern-match the spec's variable names against
the rule's nouns and write four formulas without opening an action body. That's
shorter than intended, and whether it works turns on names the reference author
hasn't chosen yet.

**ROUTE: provisional.** I can't answer this honestly at step 0. The route
defence lives entirely in the frozen spec's naming, so it has to be decided at
step 4.

## Vector fit

**Parties.** One pharmacist. `Dispense` and `Receive` are both his. Nothing
arrives unprompted, so step sources 0 holds.

**Rules, and their kind.**

1. Stock for a drug is never negative. One-state claim.
2. A prescription is never filled past its allowance. One-state claim.
3. A prescription's fill count never falls. Step rule.
4. A drug's stock falls only on a dispense of that drug. Step rule.

Four lines, two of them step rules, none needing "eventually". That's kind 2
and count 1.

**State estimate.** Two drugs with stock 0 to 3, two prescriptions with
allowance 2. That's 4 × 4 × 3 × 3 = 144 in the type space and fewer reachable.
Under 1,000 and sub-second. INFERRED, not measured.

**What the domain wants that the vector won't give.** Nothing I found. Expiry
dates and controlled-substance rules are the obvious extras and the statement
can leave them out.

## Frank's schema

Weakest of the three. He isn't a pharmacist, but a lay model of "you get N
refills, then you need a new script" is common property. §3.10 wants a domain
he has no working model of, and this one is close to public knowledge.

## The holdout rhyme

This is the objection that decides candidate 1 for me, so it gets its own
section rather than a bullet.

The withdrawn domain is apprenticeship hour logging with per-category minimums.
Its mechanism is a vector of per-key accumulators compared against per-key
bounds, with a derived status that flips when all the bounds are met. Refill
limits is a vector of per-key counters compared against per-key bounds, with a
guard that blocks the action when a bound is reached.

Shared: the per-key counter, the per-key bound, the monotonicity, the
comparison. Not shared: apprenticeship has the conjunctive status flip, which
is the part the brief's examples all turn on. Refills has a second conserved
resource with a two-sided balance, and hours has no analogue of that.

So it's a partial rhyme rather than a hit. My read is that it's a near miss.
But the cost of being wrong isn't symmetric. A false negative corrupts the only
transfer measurement in the plan, and a false positive costs us one domain out
of three on a list central drafted in an afternoon. That asymmetry is why I'd
leave it.

---

# Candidate 2: bonded warehouse excise ledger, `BondedStore`

One warehouse keeper. Goods enter under bond with duty unpaid. They leave
either released for sale with duty paid, or moved under bond to another
warehouse with duty still unpaid.

## §5.7, the mechanism screen

Two phrasings. The first came back BURNED:

```
=== CANDIDATE: bonded warehouse excise ledger with duty unpaid goods released or moved under bond
--- step 1: NAME collision
    query: 'BondedStore language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    mechanism terms: reachability,mutual exclusion
    tlaplus/Examples README (cache: harness/fixtures/screen/examples-README.md):
      reachability         1 README row(s) -> BURNED
                             Misra Reachability Algorithm (specifications/MisraReachability)
      mutual exclusion     2 README row(s) -> BURNED
                             Distributed Mutual Exclusion (specifications/lamport_mutex)
                             Dijkstra's Mutual Exclusion Algorithm (specifications/dijkstra-mutex)
--- §5.7 VERDICT: BURNED   (name: CLEAR | mechanism: BURNED)
```

```
=== CANDIDATE: conserved partition of a population between a liable status and a discharged status
--- step 1: NAME collision
    query: 'BondedStore language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

**The BURNED is a substring artifact, and I have a probe for it.**
`harness/screen.sh:112` carries the map row `warehouse|robot`, which fires on
the bare word "warehouse". That row was authored for warehouse robot
coordination, which §5.7 names as `MisraReachability` plus mutual exclusion. A
bonded warehouse has no robots, no floor graph and nothing to exclude.

The probe. I reran the same phrasing with "warehouse" swapped for "store" and
changed nothing else:

```
=== CANDIDATE: bonded excise store ledger with duty unpaid goods released or moved under bond
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
--- §5.7 VERDICT: CLEAR   (name: SKIPPED | mechanism: CLEAR)
```

One word is the whole delta. I'd treat the BURNED as a false positive of the
map and not of the domain, and I'd rather fix the map than route around it.
See the follow-up at the end.

Named by hand: **the mechanism is a one-way status transition over a
partitioned population, with a liability that tracks the status.** Every lot
sits in exactly one place. Movement out of bond is irreversible, and the duty
flag is a biconditional on one of the exits.

Why the nearest burned mechanisms don't fit. The honest neighbour is RFC 3506's
Voucher Transaction System, which has an issue-and-redeem lifecycle with
one-way redemption. It's a transaction system with several roles and a trusted
third party, and we have one keeper and no transaction. Petri-net token
conservation is the other neighbour, and it's a modeling formalism rather than
a mechanism anybody solved. Atomic commitment needs a vote and an abort. The
allocator needs contention.

`gh api -X GET search/code -f q='excise language:tla'` returns 1.

## §5.7b, the puzzle screen, spec-in-hand form

| # | Question | My answer |
|---|---|---|
| 1 | Spec and rules in hand, anything left to model? | **The requirements.** One rule relates two fields the spec keeps apart, so the learner has to notice they're separable before writing it. |
| 2 | Requirements given as formal claims, or decided? | **Split, and better than candidate 1.** Kind is given. Which fields a rule ranges over is decided, and one rule ranges over two. |
| 3 | What is asked? | **Is this design correct.** |
| 4 | Who works once it compiles? | **The learner writes the properties, TLC checks them.** |
| 5 | Where does the difficulty live? | **Telling status apart from liability.** The state space is nothing. |
| 6 | Agents, fallibility, interleaving? | **One, infallible.** Mandated by the vector. Puzzle row. |
| 7 | Delete TLC, decision left? | **Yes.** The biconditional and the one-way transition are both defensible on paper. |
| 8 | Names an optimum? | **No.** |

One clear puzzle row of eight, plus a split on Q2. Under the threshold.

**KIND: ACCEPT, system.**

## R, the route

**Intended route.** As candidate 1. Read the spec, find how each rule's nouns
live in the state, write the formula, run TLC.

**Probes.** Tiling is free and finds nothing, same as every rung-1 candidate.
Recall finds nothing: no published spec of duty suspension turned up, and the
excise search returned 1. The rest need a statement.

**Shortest route I can see, and why it's better here.** Three of the four rules
below can be pattern-matched from a variable name. The duty rule can't, because
it isn't about one field. A learner who never reads the spec closely enough to
see that status and duty are separate will write a tautology and TLC will pass
it. That's one rule of four that resists the shortcut, which is thin but it's
more than candidate 3 has.

**ROUTE: provisional, leaning accept.** Same caveat as candidate 1. The route
turns on the frozen spec, and step 4 decides it.

## Vector fit

**Parties.** One warehouse keeper. `Enter`, `Release` and `MoveOn` are all his.

Two boundaries the statement has to draw, and I'd hand both to the statement
author rather than leave them implied.

The keeper enters the goods. If the statement says goods "arrive", that's a
step assigned to no party, and step sources jumps from 0 to 3. The rung breaks.

The receiving warehouse is outside the system. A move under bond is a departure
that leaves duty unpaid, and nothing on the far side is modeled. §3.2 obliges
the statement to fix the system completely, so it has to say this in a
sentence.

**Rules, and their kind.**

1. Every lot held in the store is under bond. One-state claim.
2. Duty is paid on exactly the released lots. One-state claim.
3. A lot that leaves the store never comes back. Step rule.
4. The set of duty-paid lots never shrinks. Step rule.

Four lines, two step rules, none needing "eventually". The keeper is under no
obligation to release anything, so nothing has to happen and kind stays at 2
rather than 3.

Rule 2 is the one with content, and it only has content if the spec carries
duty as its own field rather than deriving it from status. Derive it and the
rule is true by construction and the learner writes `TRUE` in a costume. Worth
pinning for the reference author.

**State estimate.** Three lots. Status in `{outside, inBond, released, movedOn}`
and a duty flag per lot gives 8³ = 512 in the type space. Reachable is smaller,
since paid implies released, so I make it about 4³ = 64. Under 1,000 and
sub-second with room. INFERRED, not measured.

**What the domain wants that the vector won't give.** Bond periods expire in
the real thing, and that's a calendar. The statement has to leave it out, or
step sources goes to 3 and the state space grows. Everything else in the domain
fits.

## Frank's schema

Strongest of the three. Duty suspension and bonded storage is specialist
customs vocabulary, it isn't industrial IoT or facility management, and it
isn't software. My read is he'd know the words and hold no working model behind
them, which is what §3.10 asks for.

**The vocabulary load, since it's the obvious objection.** Two terms, "under
bond" and "duty", and both can be defined in the sentence that introduces them.
Three sentences do the whole domain. I think that's inside what rung 1's
statement can carry, and it's less than the blood-bank compatibility table at
rung 5.

---

# Candidate 3: breed registry with parentage rules, `StudBook`

One registrar. An animal is registered with a named sire and dam, each already
registered or marked foundation. A registration is never removed.

## §5.7, the mechanism screen

```
=== CANDIDATE: breed registry with parentage rules and foundation animals
--- step 1: NAME collision
    query: 'StudBook language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: append only record set where each new record names already present predecessors
--- step 1: NAME collision
    query: 'StudBook language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

Named by hand: **the mechanism is referential integrity over a grow-only set,
where each insertion names predecessors that must already be present.**
Acyclicity falls out for free, because a parent has to be registered first.

Why the nearest burned mechanisms don't fit. `Transitive Closure` is in the
Examples table and it's the closest thing, but it's an algorithm over a fixed
relation rather than a growing one. `Finitizing Monotonic Systems` is about
bounding a monotone search, not about integrity. Nano Blockchain and DAG-based
Consensus build append-only graphs and spend their whole content on agreement,
which we don't have.

`gh api -X GET search/code -f q='Pedigree language:tla'` returns 0. A
`sire dam language:tla` search returns 4, and all four are Paxos specs where
the words appear as loose word matches. False positives, as far as I can tell
from the paths.

This candidate is the cleanest of the three on §5.7 and it's the one I'd
reject, which is the whole reason the two screens are independent.

## §5.7b, the puzzle screen, spec-in-hand form

| # | Question | My answer |
|---|---|---|
| 1 | Spec and rules in hand, anything left to model? | **Little.** The register is the only state there is, and every rule is a membership test or a subset test over it. |
| 2 | Requirements given as formal claims, or decided? | **Given.** Every rule maps to one obvious formula in the vocabulary the artifact supplies. That's the tell `PUZZLE-SCREEN.md` names. Puzzle row. |
| 3 | What is asked? | **Is this design correct.** |
| 4 | Who works once it compiles? | **The learner writes the properties, TLC checks them.** |
| 5 | Where does the difficulty live? | **Nowhere I can point at.** Three one-line formulas over one variable. Puzzle row. |
| 6 | Agents, fallibility, interleaving? | **One, infallible.** Puzzle row. |
| 7 | Delete TLC, decision left? | **Barely.** I can't name a choice the learner would have to defend. Puzzle row. |
| 8 | Names an optimum? | **No.** |

Four puzzle rows of eight, against a threshold of three.

**KIND: REJECT, puzzle.**

## R, the route

**Shortest route.** Read three rules, write three one-line formulas over the
one variable, run TLC. No action body opened. The route is the whole problem
and it doesn't use judgment the rung is for.

**ROUTE: REJECT.**

## Vector fit

It fits the numbers and fails on content, which is worth separating.

**Parties.** One registrar. `Register` is his. Step sources 0 holds.

**Rules, and their kind.**

1. Every registered animal's sire and dam are registered, or it's a foundation
   animal. One-state claim.
2. The register only grows. Step rule.
3. A recorded sire and dam never change. Step rule.

Three lines, so count 1. Kind 2. It fits.

But two of the three rules are "nothing ever changes" in different words, and
the third is the entire content. The Airlock floor drill already ships one
invariant and two action properties (`exercises/ch11/starters/Airlock.cfg`), so
this is the floor's shape with a bigger spec attached and nothing else.

**The fourth rule, and why I'd leave it out.** "No animal is its own ancestor"
needs a transitive closure, which needs a recursive operator. That's expression
machinery the load vector doesn't measure, and rung 1 shouldn't be where the
learner first writes one. Leave it out and acyclicity is free by construction,
which is the nicest thing about the domain and also removes the last rule with
any weight in it.

**State estimate.** Four animals, each unregistered or registered with a parent
pair drawn from those already in. Well under 1,000. INFERRED.

## Frank's schema

The domain is unfamiliar and the mechanism isn't, which is the wrong way round.
He hasn't run a breed registry. He has spent twenty years around "insert a row
whose foreign key must already exist", and that's what rule 1 is. §3.10 is
about the schema, not the vocabulary.

---

# The recommendation

**Take candidate 2, the bonded warehouse excise ledger, `BondedStore`.**

It's the only one of the three that clears both screens on merit. It has the
strongest §3.10 case, since customs bond isn't in industrial IoT, isn't
facility management and isn't software. Its four rules sit at two one-state
claims and two step rules with nothing needing "eventually", which is exactly
kind 2. And rule 2, the duty biconditional, is the one rule across all three
candidates that a learner can't pattern-match from a variable name. At form 0
that single rule is most of the rung's route defence.

The BURNED verdict is a false positive of one map row and I'd record it as
such, with the one-word probe above as the reason. §6 step 0 provides for
exactly this: proceeding on a BURNED domain is a recorded decision with a
reason, never a skipped check.

**The live alternative is candidate 1, `Dispensary`, and the world where it
wins is this one.** Central reads the refill counter as far enough from the
credentialing accumulator to be safe, and would rather not open batch 2 with a
recorded override of the project's own screening tool. That's a real position.
The domain is the most legible of the three, its stock balance gives a
two-sided step rule that neither of the others has, and the statement writes
itself. If the holdout call goes the other way, take it.

I'd leave candidate 3 out. It's the cleanest on §5.7 and it fails §5.7b at four
puzzle rows of eight, and there's no rescue available that doesn't break the
vector.

# One follow-up worth filing

Narrow `harness/screen.sh:112` from `warehouse|robot` to something that matches
warehouse robots rather than warehouses. The row's authored intent is the
§5.7 example, which is robot coordination. As written it fires on any domain
whose phrasing contains the word, and it'll fire again at step 4 when this
domain is re-screened on the statement. I haven't touched the file, since this
bead grants me one report and nothing else.

The §2.2 suspicion table has the same class of problem already recorded
(V2-PLAN.md:180, bead `tla-stdl`). This is the map side of it rather than the
table side.
