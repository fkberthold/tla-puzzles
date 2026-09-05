# Rung 3 step 0, domain screens

Bead `tla-h2cg.9`, the third rung of batch 2 (V2-PLAN.md §7.0, table at line
1622). Both screens run over three candidate domains before anything is
written. §6 step 0 puts this ahead of the reference author.

## The rung, and what it can carry

Rung 3 is shape D in situation S2. The learner gets a failing trace or a
vacuous pass and says what's wrong. S2 is resource allocation and contention.
Reading gate ch11, so PlusCal-era TLA+.

The vector, in §2.5's order:

| dimension | level | reads as |
|---|---|---|
| representation | 2 | state is the learner's, the reference's variables are the `Observe` fields |
| property kind | 2 | at least one `[][A]_v`, no liveness, no fairness |
| property count | 1 | two to four cfg lines including a type invariant |
| step sources | 1 | several actors of one kind |
| state space | 0 | under a second, under 1,000 distinct states |
| form left open | 0 | keyword, kind and subscript all given |

Step sources 1 is the single new high. It's the first rung in the batch where
more than one party acts.

## Why the domain changed

The §7.0 table drafted community garden plot allocation for this rung. It
screened BURNED on allocation and assignment in August, bead `tla-03d2`, and
Frank took the strict reading on 2026-09-05. Burned means burned. Under §7.0
the domain changes and the rung keeps its vector, so the three candidates below
are all S2 and all written to the same six levels.

The strict reading bites hardest here, and it's worth saying why before the
candidates. S2 is contention, and the whole familiar apparatus of contention is
out. The Resource Allocator is burned, queues are burned, assignment and
matching are burned, scheduling is burned. What's left is contention settled by
rules the parties apply to themselves, with nobody granting and nobody waiting.
That narrows the shape to one thing: **every actor's step is legal on its own,
and the joint state isn't.** All three candidates below are built on that.

## Two findings that belong to the rung, not to any candidate

Stating them once, because otherwise they read three times as a fault in
whichever candidate is under the microscope.

**Step sources 1 gives Q6 its first system answer in the batch.** Rungs 1 and 2
sit at step sources 0, so their Q6 reads "one, infallible" whatever the domain
is, and that's a mandated puzzle row. Rung 3 has several actors of one kind who
interleave, so Q6 reads "several" on merit. Don't read the tallies below as
three candidates suddenly getting better. One row moved for free.

**Shape D with a failing trace has a short route by construction, and no domain
fixes it.** The trace names the state where the rule broke. Form 0 hands over
the keyword, the kind and the subscript. So the route is: read the last state,
find the rule it breaks, name the guard that let it through. That's short, and
it's short in every domain, because it's a property of the artifact rather than
of the system.

The defence has to come from the other half of shape D. §2.1 says nothing
public covers vacuous passes, and a vacuous pass is the case where nothing
broke and the learner has to work out why nothing could. The fault usually
lives in the cfg rather than in the spec, so no trace points at it. My read is
that rung 3 should ship the vacuous variant and not the failing-trace variant,
and I've screened each candidate on whether it carries a good one. Two of the
three do.

---

# Candidate 1: co-insurance slip subscription, `SlipLines`

A risk is placed on a slip with a panel of underwriters. Each underwriter has a
written capacity, which is the most they'll put on any one risk. The slip needs
100 percent. Each underwriter writes their own line on their own judgment, in
no fixed order. Nobody assigns lines and nobody waits for a grant. When the
lines total over 100 the slip is over-placed, and the remedy is that every
underwriter cuts their own line pro rata. That's called signing down.

This sits in S2 because the 100 percent is finite and several parties draw on
it at once. It isn't S5, since there's no lifecycle to walk. It isn't S9, since
the parties interleave and the order they write in decides the outcome.

## §5.7, the mechanism screen

Two phrasings, verdicts pasted:

```
=== CANDIDATE: independent underwriters each writing a share of one risk under a personal capacity cap and a hundred percent total
--- step 1: NAME collision
    query: 'SlipLines language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: concurrent commitments against two caps at once, one per party and one over the sum
--- step 1: NAME collision
    query: 'SlipLines language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

The tool derived no mechanism from either phrasing, and it says itself that
isn't a clean bill. So, by hand:

**The mechanism is independent commitments against two caps at once, one per
party and one over the sum, where no party checks the sum for the others.** The
per-party cap is enforceable from inside a single actor's step. The cap over
the sum isn't, and that gap is the whole problem.

Why the nearest burned mechanisms don't fit. The Resource Allocator has a
coordinator that grants and clients that wait, and there's neither here.
Assignment and matching pair actors with items, and here every underwriter
writes on the same item. Knapsack asks for the best subset, and nothing asks
for a best. Bin packing places items in bins, and a line is a quantity rather
than an item.

Hand probe. `gh api -X GET search/code -f q='underwriting language:tla'`
returns 2. Both are the same file in a mirror pair, `ib823/proof` and
`ib823/riina`, at `02_FORMAL/tlaplus/RIINA/Domains/SingaporeHealthInfo.tla`.
That's one distinct work and it isn't co-insurance.

## §5.7b, the puzzle screen, spec-in-hand form

Shape D, so Q1 and Q2 in their second form, about requirements.

| # | Question | My answer |
|---|---|---|
| 1 | Spec and rules in hand, anything left to model? | **The requirements, moderately.** Whether the written total is its own field or a sum over the lines decides whether the rule about it is a check or a restatement. |
| 2 | Requirements given as formal claims, or decided? | **Split.** The kind and keyword are given by form 0. Which field the rule ranges over is decided. |
| 3 | What is asked? | **Is this design correct.** Shape D asks what's wrong with it. |
| 4 | Who works once it compiles? | **The learner diagnoses, TLC checks.** |
| 5 | Where does the difficulty live? | **Telling the per-party cap from the cap over the sum.** The state space is nothing. |
| 6 | Agents, fallibility, interleaving? | **Several, of one kind, interleaving.** Earned, not mandated. |
| 7 | Delete TLC, decision left? | **Yes.** A per-party guard can't enforce a cap over the sum, and that's a paper argument. |
| 8 | Names an optimum? | **No.** Signing down pro rata is a rule, not a best. |

Zero clear puzzle rows of eight, plus a split on Q2. Under the threshold of
three.

**KIND: ACCEPT, system.**

## R, the route

**Intended route.** Read the trace. Work out which of the two caps the shipped
guard enforces. Say why the other one can't be enforced from a per-party guard
at all.

**Probes I can run at step 0.** Tiling is free at count 1 and finds nothing, by
construction. Recall finds nothing, since the two search hits above hand over
no prior. Vocabulary absence, elimination, the answer form and pre-clearing all
need a statement, and there isn't one yet.

**Shortest route on the failing-trace variant.** The last state has the total
at 130 and the cfg has a line naming 100. Read the number, name the line. No
modeling at all. That's the rung-level finding above, and this candidate is the
worst of the three for it, because the violated rule is a single arithmetic
comparison a reader can run in their head.

**The vacuous variant.** Set the capacities so they sum below 100. Then
over-placement is unreachable, the signing-down action is never enabled, and
both interesting rules pass without being exercised. It works. It's also easy
to spot, since three capacity numbers in a cfg add up in one glance.

**ROUTE: provisional, and split.** Reject on the failing-trace variant, weak
accept on the vacuous one.

## Vector fit

**Parties.** Several underwriters, one kind. `WriteLine` and `SignDown` are
both theirs. Nothing arrives unprompted, so step sources 1 holds.

Two boundaries the statement has to draw, and both cost something.

In the real market a leading underwriter sets the terms and the followers
follow. That's two kinds of actor and step sources 2, one level above this
rung. The statement has to say the terms are already agreed and that every
underwriter on the panel writes on the same footing. My read is that's a real
cost, because the leader is most of what a reader would recognize about a slip.

The broker walks the slip round the market. That's an order of service and it
reads as a queue, which is burned. The statement has to leave the broker out
and say the panel writes in any order.

**Rules, and their kind.**

1. Type invariant. One-state claim.
2. No underwriter's line exceeds their capacity. One-state claim.
3. The lines never total over 100. One-state claim.
4. A line only ever falls, and only on a sign-down. Step rule.

Four cfg lines, one of them a step rule, none needing "eventually". That's kind
2 and count 1.

**State estimate.** Three underwriters, lines in steps of 10 up to 40, so five
values each. 125 in the type space and fewer reachable. Under 1,000 and
sub-second. INFERRED, not measured.

**What the domain wants that the vector won't give.** The leader and the
broker, as above. Both have to go, and the domain is thinner for it.

## Frank's schema

Marine and co-insurance underwriting. It isn't industrial IoT, it isn't
facility management and it isn't software. He'd know what insurance is. I think
he holds no model of how a slip gets placed, which is what §3.10 asks for.

---

# Candidate 2: prior-appropriation water rights, `RiverCall`

One stream, and several ditch owners who divert from it. Each owner holds a
decree, which is a maximum amount and a date. The rule is first in time, first
in right. In a short year a junior owner shuts their headgate so a senior can
take their full decree. There's no watermaster on this stretch. Each owner
reads the same public register of decrees and applies the rule to themselves.

This sits in S2 because the flow is short and several parties draw on it. It
isn't S4, since nothing expires and no clock runs. The flow is a constant and
the season never turns.

## §5.7, the mechanism screen

Two phrasings, verdicts pasted:

```
=== CANDIDATE: senior and junior water rights on one stream where a shortfall at a senior holder forbids a junior diversion
--- step 1: NAME collision
    query: 'RiverCall language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: a static seniority order over self served draws from a shared limited flow
--- step 1: NAME collision
    query: 'RiverCall language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

Named by hand: **the mechanism is a static seniority order over self-served
draws from a shared limited flow, where a shortfall at any senior forbids a
junior from drawing.** The order is fixed before anybody acts, it never
changes, and every party applies it to themselves.

Why the nearest burned mechanisms don't fit. A queue orders by arrival and
serves in that order, and here the order is fixed in advance and nobody is
served. The Resource Allocator has a coordinator that grants and clients that
wait, and there's neither. Scheduling assigns work to time slots, and there are
no slots and no time. Priority scheduling is the closest neighbour I can name,
and it still needs a dispatcher choosing what runs next. Here nobody chooses
for anybody, which is the whole point.

**A hit count that reads BURNED and isn't.**
`gh api -X GET search/code -f q='water rights language:tla'` returns 12, which
is well over the >3 rule. I read the paths rather than the count. All 12 are
two mirrors of one repo, `ib823/proof` and `ib823/riina`, over six distinct
files: `ESGCompliance.tla`, `MalaysiaCybersecurityAct.tla`,
`SingaporeCybersecurityAct.tla`, `IndustryMedia.tla`, `AIMLSecurity.tla` and
`SupplyChainSecurity.tla`. "water" and "rights" are separate loose word matches
in compliance text. None of the six is about water rights.

`gh api -X GET search/code -f q='prior appropriation language:tla'` returns 0.

I don't read either as prior art. See the follow-up at the end, because the >3
rule was written for a name search and this was a phrase search.

## §5.7b, the puzzle screen, spec-in-hand form

| # | Question | My answer |
|---|---|---|
| 1 | Spec and rules in hand, anything left to model? | **The requirements.** "Short" is the hard one. A senior is short against what they're taking now, or against what they'd take if they opened. The rule reads differently under each. |
| 2 | Requirements given as formal claims, or decided? | **Split, and the widest of the three.** Kind and keyword are given. What "short" ranges over is decided, and I don't think it's obvious. |
| 3 | What is asked? | **Is this design correct.** |
| 4 | Who works once it compiles? | **The learner diagnoses, TLC checks.** |
| 5 | Where does the difficulty live? | **Telling the physical limit from the legal one.** The stream can be inside its flow and still be diverted out of priority. |
| 6 | Agents, fallibility, interleaving? | **Several, of one kind, interleaving.** The order they open in decides who goes short. |
| 7 | Delete TLC, decision left? | **Yes.** Whether "short" can be written over the `Observe` interface at all is a paper argument, and §3.3 makes it the interesting one. |
| 8 | Names an optimum? | **No.** |

Zero clear puzzle rows of eight, plus a split on Q2. Under the threshold.

**KIND: ACCEPT, system.**

## R, the route

**Intended route.** Read the trace. See that the diversions total inside the
flow. Then see that a junior is taking water while a senior sits under their
decree, and name the guard that checks the flow and never opens the register.

**Probes.** Tiling is free and finds nothing, same as every count-1 candidate.
Recall finds nothing, on the two searches above. The rest need a statement.

**Shortest route on the failing-trace variant, and why it's better here.** The
last state doesn't break the flow rule, so a reader who only checks the
arithmetic finds nothing wrong and has to keep going. To find the fault they
have to line two owners' decrees up against their diversions and know which
owner is senior. That's still shorter than the intended route. But it isn't a
number a reader runs in their head, and I think it's the shortest one this
domain offers.

**The vacuous variant, and it's the best of the three.** Set the flow at or
above the sum of every decree. Then no owner can ever go short, the priority
rule is never exercised, and TLC returns green on a spec whose priority logic
is absent. The fault lives in one constant in the cfg. Nothing in the trace
points at it, and the spec reads correct on its own terms. That's the shape
§2.1 says nothing public covers.

**ROUTE: provisional, leaning accept, and stronger on the vacuous variant.**
Same caveat as any step-0 route call. The route turns on the frozen spec and
the shipped instance, and step 4 decides it.

## Vector fit

**Parties.** Several ditch owners, one kind. `Open` and `Close` are theirs.

Two boundaries the statement has to draw, and I'd hand both to the statement
author rather than leave them implied.

The flow is a constant. If the statement lets the stream rise and fall on its
own, that's a step assigned to no party, step sources goes from 1 to 3, and the
rung breaks. A short year is a fact about the instance, not an event.

There's no watermaster. A watermaster is a second kind of actor and a
coordinator that grants, so that's step sources 2 and a burned mechanism in one
move. §3.2 obliges the statement to fix the system completely, so it has to say
in a sentence that the register is public and each owner applies it.

**Rules, and their kind.**

1. Type invariant. One-state claim.
2. The diversions never total more than the flow. One-state claim.
3. No owner diverts while a more senior owner sits under their decree.
   One-state claim.
4. A junior's diversion never rises while a senior is short. Step rule.

Four cfg lines, one step rule, none needing "eventually". Nobody is obliged to
divert anything, so nothing has to happen and kind stays at 2 rather than 3.

Rule 3 is the one with content, and it only has content if the reference
carries each owner's decree and date as data. Derive seniority from the order
the variables happen to sit in and the rule is true by construction, and the
learner is reading a tautology. Worth pinning for the reference author.

**State estimate.** Three owners, each diverting 0, 1 or 2, against a constant
flow of 3. 27 in the type space and fewer reachable. Sub-second with room.
INFERRED, not measured.

**What the domain wants that the vector won't give.** A varying flow and a
season. Both are clocks and both have to stay out.

## Frank's schema

Prior appropriation, decrees, calls and headgates are western water law. It's a
legal vocabulary, not an engineering one, and he's had no reason to meet it.

One caveat I'd rather write down than skip, since it's the place a reviewer
could disagree with me. "Flow", "gate" and "shortfall" are words he uses every
day about refrigeration plant. §3.10 is about the schema and not about the
words, and my read is that the schema here is a priority register over a legal
right rather than anything hydraulic. But it's a judgment, and I'd flag it for
Frank rather than settle it myself.

---

# Candidate 3: common-land stints, `BeastGates`

A common carries a fixed number of beast gates. A gate is the right to graze
one animal. The commoners hold the gates between them and the total never
changes. A commoner may let a gate to another commoner for the season. A
commoner turns animals out up to the gates they hold, and takes them in when
they like.

This sits in S2 on the face of it, because the stint is finite and several
commoners draw on it. See below, because that's also why I'd leave it.

## §5.7, the mechanism screen

The first run's name search errored:

```
=== CANDIDATE: common grazing rights that only move between holders and never increase, with turnout bounded by rights held
--- step 1: NAME collision
    query: 'BeastGates language:tla'
    hits: ERROR (code search unavailable) -> SKIPPED
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
--- §5.7 VERDICT: CLEAR   (name: SKIPPED | mechanism: CLEAR)
```

I waited and re-ran the same two phrasings. Both came back clean:

```
=== CANDIDATE: common grazing rights that only move between holders and never increase, with turnout bounded by rights held
--- step 1: NAME collision
    query: 'BeastGates language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: conserved transfer of a fixed pool of entitlements among peers with draws bounded by holdings
--- step 1: NAME collision
    query: 'BeastGates language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

A hand probe of the same query returned 0 as well. The error was the tool
losing the search, not the corpus saying nothing, and the two are worth telling
apart. That's the second follow-up at the end.

Named by hand: **the mechanism is conservation of a fixed pool of entitlements
under peer-to-peer transfer, with draws bounded by holdings.** The sum over all
holders is an invariant and every transfer has to preserve it.

Why the nearest burned mechanisms don't fit. A transfer isn't atomic
commitment, since there's no vote and no abort path. It isn't matching, since
gates are interchangeable and nobody is paired with anything. It isn't the
allocator, since nobody grants.

`gh api -X GET search/code -f q='grazing language:tla'` returns 0.

## §5.7b, the puzzle screen, spec-in-hand form

| # | Question | My answer |
|---|---|---|
| 1 | Spec and rules in hand, anything left to model? | **Little.** The gate holdings are the only state that matters, and every rule is arithmetic over one function. |
| 2 | Requirements given as formal claims, or decided? | **Given.** Each rule maps to one obvious formula over the one variable. That's the tell `PUZZLE-SCREEN.md` names. Puzzle row. |
| 3 | What is asked? | **Is this design correct.** |
| 4 | Who works once it compiles? | **The learner diagnoses, TLC checks.** |
| 5 | Where does the difficulty live? | **Nowhere I can point at.** A sum, a comparison and a transfer. Puzzle row. |
| 6 | Agents, fallibility, interleaving? | **Several, of one kind.** |
| 7 | Delete TLC, decision left? | **Barely.** I can't name a choice the learner would have to defend. Puzzle row. |
| 8 | Names an optimum? | **No.** |

Three puzzle rows of eight, against a threshold of three.

**KIND: REJECT, puzzle.**

## R, the route

**Shortest route.** Read the trace and watch the sum of gates change. Say the
transfer credits the taker without debiting the letter. The sum is one number
and it moves in one step. No action body opened and no domain understanding
used.

**ROUTE: REJECT.**

## The S2 objection, and it's the deeper one

Worth its own section, because the puzzle tally understates it.

There's no contention in this model. The gate total is fixed and every commoner
is bounded by the gates they hold, so no joint state is reachable that some
single commoner's step didn't already make illegal. The grass is never short,
because the stint is the cap and the cap is conserved by construction. That's
the opposite of the shape the rung needs, where each step is legal alone and
the joint state isn't.

So the domain has the vocabulary of contention without the thing. S2 asks for
contention. This is a ledger with sheep on it.

A second objection, weaker but I'd expect it asked. Community garden plot
allocation is shares of a common patch of ground held between several parties,
and so is this. The mechanisms differ, since the withdrawn one was allocation
and this is conservation under transfer. But it's close enough in dress that
the answer would have to be the mechanism argument every single time, and I'd
rather not open the rung owing that answer.

## Vector fit

It fits the numbers and fails on content, which is worth separating.

**Parties.** Several commoners, one kind. `TurnOut`, `TakeIn` and `Let` are
theirs. Step sources 1 holds.

**Rules, and their kind.**

1. Type invariant. One-state claim.
2. The gates held total the common's stint. One-state claim.
3. No commoner turns out more animals than the gates they hold. One-state
   claim.
4. A let moves gates and never creates them. Step rule.

Four lines, kind 2, count 1. It fits.

**State estimate.** Three commoners over four gates, with animals out up to
gates held. Well under 1,000. INFERRED.

## Frank's schema

Stinting, beast gates and levancy and couchancy are obscure English common law,
and he holds none of it. But the mechanism is double-entry bookkeeping, and
he's worked near ledgers for twenty years. That's the same fault rung 1 found
in its breed registry: unfamiliar domain, familiar mechanism, the wrong way
round. §3.10 is about the schema and not the vocabulary.

---

# The recommendation

**Take candidate 2, the prior-appropriation water rights, `RiverCall`.**

It's the only one of the three where the contention is real and the rule that
settles it belongs to the parties. There's no coordinator to delete and no
queue to explain away, because seniority is a static order fixed before anybody
acts. Its failing trace shows a state that's legal on the flow and illegal on
the right, which is a diagnosis worth making rather than an arithmetic
comparison. And its vacuous variant is the best of the three: put the flow
above the sum of the decrees and the whole priority rule goes unexercised while
TLC returns green, with the fault sitting in one cfg constant that no trace
points at. Given the second rung-level finding above, that variant is what I'd
ship.

**The live alternative is candidate 1, `SlipLines`, and there are two worlds
where it wins.** Central reads "senior and junior" as priority scheduling in a
coat, and would rather not site the batch's first multi-actor rung on a
mechanism a step-4 screener may call burned. Or Frank's reviewer reads "flow",
"gate" and "shortfall" as too near his working vocabulary under §3.10. Both are
real positions. `SlipLines` has the cleaner two-cap mechanism and no vocabulary
risk at all. It pays for that by needing the statement to remove the leading
underwriter and the broker, which is most of what a reader would recognize
about a slip.

I'd leave candidate 3 out. It clears §5.7 and fails §5.7b at three puzzle rows
of eight, and the S2 objection is the deeper reason. A domain with the
vocabulary of contention and none of the thing is the wrong domain for this
rung whatever its tally says.

# Two follow-ups worth filing

**A phrase search isn't a name search, and the >3 rule shouldn't be read
across.** `water rights language:tla` returns 12 and not one of the 12 is about
water rights. Rung 1 hit the same shape at `Pharmacy language:tla`, five hits
over three distinct works. Two rungs in a row is a pattern. My read is the
guidance should say to read the paths before the count, and to fold mirrors of
one repo into one work, either in `screen.sh --help` or beside the recall probe
in `PUZZLE-SCREEN.md`.

**A SKIPPED name step reads the same as a passed one in the verdict line.**
`screen.sh` printed `hits: ERROR (code search unavailable) -> SKIPPED` and
still returned `§5.7 VERDICT: CLEAR`. The exit code was 0, so a caller that
trusts the code can't tell a checked candidate from an unchecked one. I think a
SKIPPED name step should carry the run to SUSPECT and exit 1, which is the code
that already means a human has to look. I haven't touched the file, since this
bead grants me one report and nothing else.
