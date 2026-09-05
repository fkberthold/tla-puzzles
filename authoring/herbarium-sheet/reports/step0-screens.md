# Rung 6 step 0, domain screens

Bead `tla-h2cg.12`, the sixth rung of batch 2 (V2-PLAN.md §7.0, table at line
1622). Both screens run over three candidate domains before anything is
written. §6 step 0 puts this ahead of the reference author.

## The rung, and what it can carry

Rung 6 is shape D in situation S6. S6 is data consistency under concurrent
mutation, so lost update and versioning. Shape D is diagnosis, given a failing
trace or a vacuous pass. Reading gate ch11, so PlusCal-era TLA+.

The vector, in §2.5's order:

| dimension | level | reads as |
|---|---|---|
| representation | 2 | state is the learner's, and the reference's variables are the `Observe` fields |
| property kind | 3 | at least one `<>` or `~>`, plus a fairness conjunct in `Spec` |
| property count | 2 | five to nine cfg lines |
| step sources | 1 | several actors of one kind |
| state space | 0 | under a second, under 1,000 distinct states |
| form left open | 1 | the keyword or kind is given, the subscript target is open |

Form left open 1 is the single new high. Everything else sits at or under the
running maximum after rung 5. So this rung is the first place the learner
decides what a step rule watches, and the domain has to give them a subscript
worth arguing about.

## Why the domain changed

The §7.0 table drafted clinical trial cohort assignment for this rung. Central
withdrew it before this screen ran, because it screened BURNED on assignment
and allocation in August (bead `tla-03d2`), and Frank took the strict reading
on 2026-09-05. Burned means burned. Under §7.0 the domain changes and the rung
keeps its vector, so the three candidates below are all S6 and all written to
the same six levels.

## The finding that belongs to the rung, not to any candidate

S6 sits next to the most heavily published corner of the whole corpus. I ran
the mechanism itself rather than any domain word:

```
gh api -X GET search/code -f q='"lost update" language:tla' --jq '.total_count'
47
```

Thirty distinct works, and six of them are dedicated to it:
`proteanhq/protean :: specs/OCC.tla`, the same repo's `specs/OCCTrace.tla`,
`Cohexa-ai/agent-coherence :: formal/tla/OCC.tla`,
`theoden8/webspace_app :: formal/proofs/no_lost_update.tla`, the same repo's
`formal/store_serial.tla`, and `antflydb/antfly :: zig/specs/tla/occ-2pc.tla`.
`"compare and swap" language:tla` returns 13. The Examples table carries
`SnapshotIsolation`, `Snapshot Key-Value Store`, `Transaction Commit Models`,
two cache-coherence protocols and four CRDT rows.

So the plain reading of S6 is burned. Read a value and its version, do some
work, write it back without checking the version, and you've written the thing
six people already published. `harness/screen.sh` said CLEAR on all six of my
phrasings, and I think it was wrong on one of them. Its `mechanism_map()` has
no row from any S6 vocabulary to optimistic concurrency, so the map's silence
came back as a clean bill. That's the §2.2 finding at V2-PLAN.md:180 running
the other way. There the table was silent while the tool said BURNED. Here the
tool was silent while the corpus said BURNED. Follow-up at the end.

What that leaves is the question the rung block asked. Find concurrent mutation
of a shared record where the loss isn't an overwrite. That's the axis the three
candidates are spread along, and it's what decides between them.

## The shape-D object at representation 2, which I couldn't settle

`harness/PUZZLE-SCREEN.md` says shapes B, C and D hand the learner a spec, and
that a diagnosis problem ships a failing one. Representation 2 says the state
is the learner's. Those two can't both hold for this rung, and rung 3 has the
same pair.

My read is that the diagnosis object at representation 2 is a trace rather than
a spec. The learner is shown a run of `Observe` readings from a system that
misbehaves, models the system themselves, and locates the defect. That keeps
representation at 2 and keeps shape D honest, and the rubric's sentence was
written for a D problem at representation 0 or 1. I've answered Q1 and Q2 in
their requirement-centric form on that reading, with "trace" standing where the
rubric says "spec". I could be wrong, and it's central's call, not mine. It
changes the seeded defect below and nothing else in this report.

---

# Candidate 1: chart correction folio, `ChartFolio`

A ship carries one folio of paper charts. Corrections arrive as a bulletin of
numbered notices. Several navigating officers correct the folio by hand. An
officer takes a chart, reads the correction record stamped in its margin, does
the pen and ink work, and stamps the notice number back. What's at stake is a
passage planned on a chart whose margin claims corrections it doesn't carry.

It sits in S6 rather than S5 because nothing here is a lifecycle. The chart has
no states to pass through. It has one value that several people write.

## §5.7, the mechanism screen

Two phrasings, verdicts pasted:

```
=== CANDIDATE: hand correction of one shared chart folio by several officers with a revision stamp
--- step 1: NAME collision
    query: 'ChartFolio language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: read modify write of a single shared record where a stale reader overwrites a newer value
--- step 1: NAME collision
    query: 'ChartFolio language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

Named by hand: **the mechanism is read-modify-write on one shared record
carrying a monotone revision stamp, with no check that the stamp read is still
the stamp on the record when the write lands.** That's optimistic concurrency
control with the compare left out.

That's the mechanism the 47 hits above are about, and six of the thirty works
are dedicated specs of it. I don't think there's a probe that clears this. The
tool's CLEAR came from an absent map row, not from an absent corpus.

**§5.7 verdict, by hand: BURNED.** The tool's CLEAR is overridden and the
reason is the code search, not a phrasing swap.

## §5.7b, the puzzle screen, trace-in-hand form

| # | Question | My answer |
|---|---|---|
| 1 | Trace and rules in hand, anything left to model? | **Yes.** The officer's read has to be state, and that isn't obvious. |
| 2 | Requirements given as formal claims, or decided? | **Decided.** One subscript is open by construction. |
| 3 | What is asked? | **Is this design correct.** |
| 4 | Who works once it compiles? | **The learner models, TLC checks.** |
| 5 | Where does the difficulty live? | **Abstraction choice.** The state space is nothing. |
| 6 | Agents, fallibility, interleaving? | **Several, fallible.** Officers interleave, and the failure is a stale read. |
| 7 | Delete TLC, decision left? | **Yes.** |
| 8 | Names an optimum? | **No.** |

Zero puzzle rows of eight. **KIND: ACCEPT, system.**

## R, the route

**Intended route.** Model the folio and the officers. Decide that what an
officer read has to live in the state. Write the safety rules and the liveness
rule, choose the open subscript, run, and find the defect.

**Shortest route I can see.** Write the version check. A learner who's met
optimistic concurrency once writes `stamp' = stamp + 1` guarded by
`read = stamp` without asking a single modeling question, and every safety rule
falls out of it. The domain's own working practice is that check, so the
statement can't withhold it without lying about the domain.

**ROUTE: REJECT.** The route is a recall of a named pattern, and the recall
probe in `PUZZLE-SCREEN.md` is exactly the one that fires when §5.7 comes back
BURNED. Both screens reject this candidate, independently, which is the pair
behaving.

## Vector fit

Fine on the numbers and dead on the mechanism, so I'll keep it short. Several
officers, one kind, so step sources 1. Six or seven rules land in the five to
nine band. The liveness is that every published notice is eventually stamped
into the folio, under weak fairness on the correction step, so kind 3 holds.
Three charts and three officers is well under 1,000 states. INFERRED, not
measured.

## Frank's schema

Good on the domain and bad on the mechanism. He's not a navigating officer.
He's spent twenty years around read-modify-write races, and this is one with a
sextant.

---

# Candidate 2: herbarium determination slips, `Herbarium`

A herbarium holds one physical sheet per specimen, a pressed plant glued to
card. A botanist who studies a sheet attaches a determination slip carrying the
name they believe it is, their own name, and the point in the sheet's
consultation record at which they read it. Slips are never removed and never
edited. The accepted name of the specimen is the name on the latest slip. What's
at stake is that the accepted name is what a flora, a loan request and a
conservation listing all key off, so a wrong one travels.

The lost update: a botanist consults a sheet, takes the work away, and files a
slip stamped with what they read. Another botanist files in the meantime. The
first slip is on the sheet forever and is not the accepted name, and neither
botanist finds out. Nothing was overwritten. The answer moved.

It sits in S6 rather than S9 because two botanists working the same sheet is the
whole problem. Take the concurrency out and there's nothing left.

## §5.7, the mechanism screen

```
=== CANDIDATE: botanists adding determination slips to one specimen sheet where the newest slip is the accepted name
--- step 1: NAME collision
    query: 'Herbarium language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: append only annotation stack whose derived current value is displaced by a writer who read a stale top
--- step 1: NAME collision
    query: 'Herbarium language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

Named by hand: **the mechanism is a grow-only annotation set over one shared
record, whose accepted value is a maximum over an ordering key the writer
supplies rather than over the order of writing.** The write never conflicts.
The reading does.

Why the nearest burned mechanisms don't fit, and this is the part that decides
the candidate.

The honest neighbour is the last-writer-wins register, which is a CRDT.
`gh api -X GET search/code -f q='"last writer wins" language:tla'` returns 3,
which clears the count. More to the point, a LWW register exists to reconcile
divergent replicas. There's one sheet. No copies, no merge, no convergence
question, so the entire content of the CRDT rows in the Examples table has
nothing to bite on. Snapshot isolation and MVCC keep several versions so a
reader sees a consistent one, and here everybody sees the same card. Atomic
commitment needs a vote and an abort. Consensus needs disagreement about a
value, and nobody here disagrees about what's written down.

Optimistic concurrency is the neighbour I'd worry about, and it's ruled out by
the same fact that makes the domain interesting. There's no cell to compare and
swap. A slip that loses is still on the sheet.

## §5.7b, the puzzle screen, trace-in-hand form

| # | Question | My answer |
|---|---|---|
| 1 | Trace and rules in hand, anything left to model? | **Yes, most of it.** Is the accepted name stored or derived? Is what a botanist read state at all? A learner who says no to the second can't express the failure, and their model passes. |
| 2 | Requirements given as formal claims, or decided? | **Decided.** One rule's subscript is open, and one rule has no form at all unless the read is in the state. |
| 3 | What is asked? | **Is this design correct**, and why a green run isn't evidence. |
| 4 | Who works once it compiles? | **The learner models, TLC checks.** |
| 5 | Where does the difficulty live? | **Abstraction choice.** Two sheets and three botanists is nothing to search. |
| 6 | Agents, fallibility, interleaving? | **Several, fallible.** Botanists interleave consulting and filing, and filing against a stale read is the fallibility. |
| 7 | Delete TLC, decision left? | **Yes.** Whether the read is state, and what the accepted-name rule watches, are both arguable on paper. |
| 8 | Names an optimum? | **No.** |

Zero puzzle rows of eight. **KIND: ACCEPT, system.**

## R, the route

**Intended route.** Model the sheet, the slips and the botanists. Decide that
what a botanist read has to be carried. Write the six safety rules and the one
liveness rule. Choose the subscript on the accepted-name rule. Run, get green,
and find that green means the check never fired.

**Probes I can run at step 0.** Tiling and vocabulary absence both need an
artifact, and there isn't one yet. Recall is the one that fires, and it fires
half clear. A learner who knows optimistic concurrency gets "the newest wins"
for free. What the prior doesn't hand over is that the ordering key is chosen
by the writer, which is where the loss lives, and it hands over nothing at all
about the subscript.

**Shortest route I can see.** Reach for the version check by reflex, write the
safety rules from it, and get them right. That's real and it's short. It stops
at the safety rules, though, because the shipped defect is a vacuous pass and
recall doesn't touch it.

**ROUTE: provisional, leaning accept.** The route defence rests on the seeded
defect and the answer form, and neither exists yet. Step 4 decides it.

## Vector fit

**Parties.** Several botanists, one kind. Three actions, all theirs.
`Consult` bumps the sheet's consultation count and records what this botanist
saw. `Determine` files a slip stamped with what they saw. `Flag` marks a sheet
doubtful.

One boundary the statement author has to hold. The slip's ordering key must be
the sheet's own consultation count, bumped by a botanist, and never a date off
a calendar. A calendar is a step assigned to no party, and step sources jumps
from 1 to 3. The rung breaks. I'd say this in the statement in one sentence,
the way rung 1's record pins the arrival of goods.

Loans to other institutions are the other thing to leave out. A borrowing
curator is a second kind of actor and pushes sources to 2.

**Rules, and their kind.**

1. Every slip names a botanist and a consultation stamp. One-state claim.
2. No two slips on a sheet carry the same stamp. One-state claim.
3. The accepted name is the name on the highest-stamped slip. One-state claim.
4. Slips are never removed and never edited. Step rule.
5. A botanist never files a stamp above the one they read. Step rule.
6. The accepted name changes only on a filing step. Step rule, subscript open.
7. A sheet flagged doubtful is eventually re-determined. Needs `~>`, with weak
   fairness on `Determine`.

Seven cfg lines, so count 2. Rule 7 makes it kind 3. Rules 4, 5 and 6 are the
action properties.

**The open subscript, which is the rung's new high.** Rule 6 is the one. The
statement gives the keyword and says it's an action property, and leaves the
learner to pick what it watches. Watch the accepted name alone and the rule is
true and says nothing about which step moved it. Watch every variable and a
`Consult` step falsifies it, since consulting isn't filing. The answer wanted is
the narrow subscript with the filing named in the action, and both wrong turns
are defensible until you run them.

**The seeded defect, and I'd take the vacuous pass.** Subscript rule 6 on the
flag map. Then `[][...]_flags` only constrains steps that change a flag, every
filing stutters with respect to it, and TLC returns green without ever
evaluating the rule on the step it was written for. The learner is handed a
green run and has to find the check that never fired. §2.1 says nothing public
covers vacuous passes, and this is the rung whose new high is the subscript, so
the defect and the new high are the same thing.

The failing-trace alternative is there if central wants it. Have `Determine`
write the accepted name directly instead of deriving it from the slips. Then a
botanist who consulted at stamp 3 and files after one who consulted at stamp 4
drags the accepted name backwards, rule 3 breaks, and the trace is two
botanists and about six steps. It's the more readable object and it teaches
less, because reading it doesn't need the subscript.

**State estimate.** Two sheets, three botanists, three names, consultation
count 0 to 3, at most three slips a sheet. That's a few hundred reachable
states as I count it, sub-second, and two botanists is the fallback if it
grows. INFERRED, not measured.

**What the domain wants that the vector won't give.** Real nomenclature has
priority, synonymy and basionyms, and the statement has to define the accepted
name as the latest slip and stop. §3.2 wants the system fixed completely, and I
think three sentences do it here.

## Frank's schema

He's not a botanist and hasn't curated a natural history collection.
"Determination" and "accepted name" are two terms, both definable in the
sentence that introduces them, which is less vocabulary than the blood bank
compatibility table at the withdrawn rung 5.

The honest objection is the mechanism, not the domain. He has twenty years of
"the newest row wins", and §3.10 is about the schema rather than the
vocabulary. My answer is that the reflex gets him the safety rules and stops.
The part it doesn't reach is that the ordering key is chosen by the writer, and
that the accepted name is derived rather than stored. I'd rather say that
plainly than claim the domain is further from him than it is.

---

# Candidate 3: consolidated statute text, `StatuteBook`

A jurisdiction keeps one consolidated text of its statutes. Amending acts are
textual. "In section 4(2), for 'seven days' substitute 'fourteen days'." Several
clerks hold a shared queue of enacted amendments and apply them to the
consolidated text, each amendment naming the base revision it was drafted
against. What's at stake is a published text that doesn't say what the law says.

It sits in S6 rather than S7 because there's one text and no coexistence. Two
clerks amending the same section is the problem, not two versions running side
by side.

## §5.7, the mechanism screen

```
=== CANDIDATE: clerks applying enacted amendments to one consolidated statute text against a stated base revision
--- step 1: NAME collision
    query: 'StatuteBook language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: amendment written against a base revision applied to a text that has since moved on
--- step 1: NAME collision
    query: 'StatuteBook language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

Named by hand: **the mechanism is a patch naming a position and its expected
prior content, applied to a text whose positions and content have moved since
the patch was drafted.**

I drafted this one expecting a third mechanism and I don't think it is one.
Write it down and the clerk's check is "does section 4(2) still say 'seven
days'", which is compare-and-set over a text. The domain's own practice is the
compare. So the same 47 hits and the same six dedicated specs land on it, for
the same reason they land on candidate 1.

`gh api -X GET search/code -f q='"operational transformation" language:tla'`
returns 1, and `amendment language:tla` returns 35. I read the 35 as loose word
matches. The paths are governance and protocol specs, and three of them are our
own pilot's `PermitReview.tla`. Nothing there is a consolidation spec, so the
domain is unoccupied and the mechanism is not.

**§5.7 verdict, by hand: BURNED**, on the same evidence as candidate 1.

## §5.7b, the puzzle screen, trace-in-hand form

| # | Question | My answer |
|---|---|---|
| 1 | Trace and rules in hand, anything left to model? | **Yes, and too much.** How do you model a text at all? |
| 2 | Requirements given as formal claims, or decided? | **Split.** The expected-content rule hands over its own check. |
| 3 | What is asked? | **Is this design correct.** |
| 4 | Who works once it compiles? | **The learner models, TLC checks.** |
| 5 | Where does the difficulty live? | **Abstraction choice**, and it's in the wrong place. See below. |
| 6 | Agents, fallibility, interleaving? | **Several, fallible.** |
| 7 | Delete TLC, decision left? | **Yes.** |
| 8 | Names an optimum? | **No.** |

Zero clear puzzle rows, plus a split on Q2. **KIND: ACCEPT, system.**

## R, the route

**Shortest route.** Same as candidate 1. Write the compare-and-set and the
safety rules fall out.

**ROUTE: REJECT**, and for a second reason that's worth recording on its own.
The learner has to invent a model of a text before reaching anything the rung
is about, and §3.2 would push the statement into fixing that model for them.
Say how sections are numbered and you've named the representation. Leave it
open and the state space stops being sub-second. I think that's a §3.2 problem
rather than a screen problem, and it's the one I'd cite if central liked the
domain anyway.

## Vector fit

Several clerks, one kind, so step sources 1. The rules land in the five to nine
band. The liveness is that every enacted amendment is eventually applied, under
weak fairness on the apply step, so kind 3 holds. The state space is the
problem, and it turns on the text model rather than on the instance size.
INFERRED, not measured.

## Frank's schema

Strong on the domain and weak on the mechanism, same as candidate 1. Textual
amendment drafting is specialist and he hasn't done it. Patching against a base
that moved is a Tuesday.

---

# The recommendation

**Take candidate 2, the herbarium determination slips, `Herbarium`.**

It's the only one of the three that survives §5.7 once the mechanism is named
by hand rather than by the tool. The reason it survives is the reason it's the
right domain for S6 at all. Nothing is overwritten, so none of the burned
neighbourhood has anything to bite on, and the lost update lands on a derived
reading instead of a stored cell. That's concurrent mutation of a shared record
that isn't consensus, isn't replication and isn't a transaction, which is what
the rung asked for.

It also puts the new high and the seeded defect in the same place. Rule 6's
subscript is the one open form in the problem, and a vacuous pass on rule 6 is
the defect the learner diagnoses. I think that's worth more than the readability
of the other two, and it's the strongest argument for this candidate.

**The live alternative is candidate 1, `ChartFolio`, and the world where it wins
is this one.** Central reads the corpus's optimistic-concurrency specs as
databases and transactions to a man, decides S6 can't be served at all without
reusing the mechanism, and takes the structural re-skin that §2.1 licenses for
S1 and applies the same logic here. That's a real position, and the reward for
it is the most readable lost-update trace in the batch. If central takes it, I'd
move the diagnosis object from the overwrite to the vacuous pass, because
otherwise the recall probe eats the problem.

I'd leave candidate 3 out. It's burned on the same evidence as candidate 1 and
it carries a §3.2 problem the other two don't.

# One follow-up worth filing

`harness/screen.sh`'s `mechanism_map()` has no row from any S6 vocabulary to
optimistic concurrency, so six phrasings of a mechanism with 47 corpus hits all
returned CLEAR. Rung 1 hit the map firing when it shouldn't. This is the map
staying silent when it should fire, and I think the silent direction is worse,
because a false BURNED gets probed and a false CLEAR gets believed.

Two rows would close it. In `mechanism_map()`:

```
lost update|stale read|version stamp|read modify write|optimistic~optimistic concurrency,compare and swap
```

And in `mechanism_grep()`, entries for `optimistic concurrency` and
`compare and swap`. Neither term has a row in the Examples README, so both fall
through to the code search, which is what caught this.

I haven't touched the file. It's centrally owned and this bead grants me one
report.
