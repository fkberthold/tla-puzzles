# Rung 4 step 0, domain screens

Bead `tla-h2cg.10`, the fourth rung of batch 2 (V2-PLAN.md §7.0, table at line
1625). Both screens run over three candidate domains before anything is
written. §6 step 0 puts this ahead of the reference author, so nothing here
depends on a spec existing.

## The rung, and what it can carry

Rung 4 is shape B in situation S5, lifecycle state machines. The learner gets a
complete spec plus prose requirements, and writes the properties and a cfg.
Reading gate ch11, so PlusCal-era TLA+.

The vector, in §2.5's order:

| dimension | level | reads as |
|---|---|---|
| representation | 1 | a spec ships, the learner writes no state |
| property kind | 3 | at least one `<>` or `~>` formula, plus a fairness conjunct in `Spec` |
| property count | 1 | two to four cfg lines, including a type invariant |
| step sources | 1 | several actors of one kind |
| state space | 0 | under a second, under 1,000 distinct states |
| form left open | 0 | keyword, kind and subscript all given |

Property kind 3 is the single new high. Representation drops from rung 2 and
rung 3's level 2 back to 1, which is free under the sequence rule, and it keeps
liveness from landing on top of a model the learner wrote themselves.

So rung 4 is the first rung with an "eventually" in it, and everything else is
arranged to make that the only new thing in the room.

## Why the domain changed

The §7.0 table drafted tournament brackets with byes and forfeits for this
rung. Central withdrew it before this screen ran, because it's one of the
sealed holdout domains (§7.2, bead `tla-kl5.17`). The holdout only measures
transfer if Frank meets its domains cold. Under §7.0 the domain changes and the
rung keeps its vector, so the three candidates below are all S5 and all written
to the same six levels.

## Four findings that belong to the rung, not to any candidate

They're stated once here, because otherwise they read three times as a fault in
whichever domain is under the microscope.

**Step sources 1 forces the work to exist at `Init`.** Level 1 is several
actors of one kind, and level 3 is a step the statement assigns to no party. If
work arrives at the office during the run, that arrival belongs to somebody
outside the one kind, and the rung breaks. Rung 1's record hit the same wall
from below (`authoring/bonded-store/reports/step0-screens.md`, the bonded
store's parties section). The fix is the same for all three candidates here.
The shipped spec starts with a fixed set of items already lodged, and every
action after that belongs to one of the officers. That's a real constraint on
the statement, and I'd hand it to the statement author rather than leave it
implied.

**The shipped spec carries the fairness, so the reference author decides
whether the learner's liveness claim is true.** At representation 1 the learner
writes no state and no `Spec`. Property kind 3 wants a fairness conjunct in
`Spec`, and that conjunct is in the artifact the learner receives. So the
learner's job is to read `Spec`, find which action is under `WF`, and write a
leads-to that the fairness actually establishes. I think that's the best thing
about this rung. It's a read of the shipped spec that doesn't exist at kind 2,
and it's what rung 4 has instead of rung 1's thinner Q2 defence.

**Weak fairness on an officer's whole next-state relation won't deliver a
per-item obligation.** If the spec conjoins `WF_vars(Officer(o))` over a
disjunction of that officer's actions, an officer who forever takes the other
disjunct satisfies it. The liveness rule then fails, and the reference is
wrong. My read is that the fairness has to sit on the compelled action itself,
per officer. I'm flagging it rather than solving it, because it's a step 2
decision, but it's the way this rung most easily ships a broken reference.

**Central's reading of §2.5's `WF` pin is what keeps the rung legal.** §2.5
says "a named party under `WF` is level 2" (V2-PLAN.md:335). Read as a floor,
any fairness at all puts step sources at 2, and rung 4 would then set two new
highs and break clause (b'). Central reads it as a ceiling instead. I agree,
and I'd add a reason from the domain side. At several actors of one kind the
officers are interchangeable, so a conjunct of the form `\A o \in Officers :
WF_vars(...)` singles out no party at all. The pin bites when fairness names
one distinguished actor, which isn't what any candidate below does. Worth Frank
seeing the argument, since the whole rung rests on it.

---

# Candidate 1: assay office hallmarking, `AssayOffice`

Several assay officers at one office. Silver and gold wares are lodged by their
makers and tested against a fineness standard. A ware that passes is struck
with the hallmark and given back. A ware that fails is defaced, and the office
has no discretion about that.

## §5.7, the mechanism screen

Two phrasings, verdicts pasted.

```
=== CANDIDATE: adjudication of a submitted article against a fixed standard where an adverse verdict compels destruction of the article
--- step 1: NAME collision
    query: 'AssayOffice language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: hallmarking of precious metal wares where substandard wares must be defaced by the office
--- step 1: NAME collision
    query: 'AssayOffice language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

The tool derived no mechanism from either phrasing, and it says itself that
isn't a clean bill. So, by hand:

**The mechanism is a verdict against a fixed standard that compels an
irreversible act on the thing judged.** The ware's identity survives the whole
lifecycle. Its physical form doesn't. The duty runs one way, from the finding
to the act, and the office can't record a failure and then sit on it.

Why the nearest burned mechanisms don't fit. The `Resource Allocator` needs
contention over something finite, and nothing here is scarce. Atomic commitment
needs a vote across parties and an abort path, and one officer's finding is
neither. Knapsack and the assignment problem both need an optimum, and nothing
here asks for one. The closest thing in the Examples table is RFC 3506's
Voucher Transaction System, which has a one-way redemption, and rung 1 already
weighed it for the bonded store. It's a transaction system with several roles
and a trusted third party. We have one kind of officer and no transaction.

Hand searches, three of the allowance:

```
gh api -X GET search/code -f q='hallmark language:tla' --jq '.total_count'
0
gh api -X GET search/code -f q='assay language:tla' --jq '.total_count'
1
gh api -X GET search/code -f q='assay language:tla' --jq '.items[].html_url'
https://github.com/CAPHTECH/kiri/blob/af1db6b.../docs/formal/PathPenaltyMerge.tla
```

The one hit is a path-penalty merge spec. I read it as a loose word match and
not prior art, though I've only looked at the path.

## §5.7b, the puzzle screen, spec-in-hand form

Shape B, so Q1 and Q2 in their second, requirement-centric form.

| # | Question | My answer |
|---|---|---|
| 1 | Spec and rules in hand, anything left to model? | **The requirements, and more than at rung 1.** One rule is only true because `Spec` carries a fairness conjunct, and the learner has to find it to know which officers the claim binds. |
| 2 | Requirements given as formal claims, or decided? | **Split.** Keyword and kind are given by form 0. Which state predicate names each end of the leads-to is decided, and so is the set it ranges over. |
| 3 | What is asked? | **Is this design correct.** No goal state and no reachability. |
| 4 | Who works once it compiles? | **The learner writes the properties, TLC checks them.** |
| 5 | Where does the difficulty live? | **Telling the finding apart from the act it compels, and reading `Spec` for fairness.** The state space is nothing. |
| 6 | Agents, fallibility, interleaving? | **Several of one kind, and they interleave.** Not the puzzle column. Nothing fails, so only half the system column is claimed. |
| 7 | Delete TLC, decision left? | **Yes.** Whether the duty sits on the office or on the officer is arguable on paper, and it changes the formula. |
| 8 | Names an optimum? | **No.** |

Zero clear puzzle rows of eight, one split on Q2 and one half answer on Q6.
Under the threshold of three, with more room than rung 1 had.

Q6 is worth a line on its own. Rung 1's record shows every candidate at that
rung answering Q6 "one, infallible" because the vector mandated it, which is a
puzzle row no domain could rescue. Step sources 1 gives that row back. Rung 4
gets it for free.

**KIND: ACCEPT, system.**

## R, the route

**Intended route.** Read the shipped spec. Find how the finding and the act are
carried in the state, and find which action `Spec` puts under `WF`. Write the
three properties under the keywords the statement names. Run TLC against both
trace sets.

**Probes runnable at step 0.** Tiling is the cheap one and it finds nothing at
count 1 and form 0, because the rules and the cfg lines match one to one by
construction. That's true of every batch-2 rung so far. Recall finds nothing
either, on 0 hits for the domain noun and 1 loose hit for the mechanism noun.
Vocabulary absence, elimination, answer form and pre-clearing all need a
statement, and there isn't one yet.

**Shortest route I can see.** Write the liveness as a blanket `[]<>` over the
whole set of wares without opening `Spec`, and hope the shipped fairness is
generous enough to carry it. That's shorter than intended, and whether it works
turns on how narrow the reference author makes the fairness conjunct. It's
closable at step 2, and closing it is the same decision as the third finding
above.

**ROUTE: provisional, leaning accept.** Step 0 can't settle it, because the
route defence lives in a spec that doesn't exist yet. Step 4 re-runs both
screens on the statement and the frozen spec, and that's where it's decided.

## Vector fit

**Parties.** Two assay officers, one kind, interchangeable. An officer takes up
a ware, tests it, strikes or defaces it, and gives it back. All four actions
belong to an officer, so step sources sits at 1 and not at 3.

The makers are outside the system. Wares are lodged before the run starts, and
§3.2 obliges the statement to say so in a sentence rather than leave it to be
inferred.

**Rules, and their kind.**

1. Every ware is in exactly one stage, and only a struck ware carries a mark.
   One-state claim, and this is the type invariant.
2. No ware is both struck and defaced. One-state claim.
3. A finding once recorded never changes. Step rule.
4. A ware found substandard is eventually defaced. Needs "eventually".

Four lines, so count 1. Rule 4 is the one that carries the "eventually", and
it's the whole reason this rung exists. It's honest because the duty is real.
The office isn't allowed to hand back a substandard ware unmarked, and it isn't
allowed to hold it forever either.

**State estimate.** Three wares and two officers. A ware carries a stage from
six values and a holder from three, and the two are correlated, so I make it
about eight reachable pairs per ware. That's roughly 8^3, a few hundred
distinct states, sub-second. INFERRED, not measured. Step 2 should record the
real number.

**What the domain wants that the vector won't give.** Nothing I found. Real
assay offices have a duty-mark side and a date-letter cycle, and both are
calendar machinery the statement has to leave out or step sources goes to 3.

## Frank's schema

Strongest of the three. Fineness standards, sponsor's marks and the office's
duty to deface are specialist trade vocabulary. It isn't industrial IoT, it
isn't facility management, and it isn't software. He'd know the word "hallmark"
and hold no working model behind it, which is what §3.10 asks for.

The vocabulary load is two terms, "fineness" and "defaced", and both can be
defined in the sentence that introduces them.

---

# Candidate 2: treasure inquest, `TreasureInquest`

Several coroners. Objects reported as possible treasure sit on a docket. A
coroner opens an inquest, may adjourn it to take an expert report into
evidence, and eventually determines whether the find is treasure or not.

## §5.7, the mechanism screen

```
=== CANDIDATE: an open proceeding that may be adjourned indefinitely and must eventually reach a determination
--- step 1: NAME collision
    query: 'TreasureInquest language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: coroner inquest into found objects declared treasure or returned to the finder
--- step 1: NAME collision
    query: 'TreasureInquest language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

Named by hand: **the mechanism is a proceeding with an always-enabled deferral
step, so termination is guaranteed by fairness and by nothing else.**
Adjournment is legal, repeatable and unbounded. Abandonment isn't. That's a
different duty from candidate 1's. There the duty is to carry out a
consequence. Here the duty is to stop deferring.

Why the nearest burned mechanisms don't fit. Consensus and leader election both
need agreement among parties that can disagree, and a coroner determines alone.
Queues need an order, and the docket has none. The Petri net row in the
Examples table carries liveness properties, but it's a modelling formalism
rather than a mechanism somebody solved.

Hand searches, two of the allowance:

```
gh api -X GET search/code -f q='inquest language:tla' --jq '.total_count'
0
gh api -X GET search/code -f q='adjourn language:tla' --jq '.total_count'
0
```

Two zeros. Following the rule about tools reporting nothing, that's a fact
about GitHub code search over `language:tla` and not proof the mechanism is
unspecified.

## §5.7b, the puzzle screen, spec-in-hand form

| # | Question | My answer |
|---|---|---|
| 1 | Spec and rules in hand, anything left to model? | **The requirements.** The learner has to see that an adjournment changes state without being progress, which is the distinction the liveness rule turns on. |
| 2 | Requirements given as formal claims, or decided? | **Split.** Same shape as candidate 1, and for the same reason. |
| 3 | What is asked? | **Is this design correct.** |
| 4 | Who works once it compiles? | **The learner writes the properties, TLC checks them.** |
| 5 | Where does the difficulty live? | **Telling a step that changes state from a step that makes progress.** |
| 6 | Agents, fallibility, interleaving? | **Several of one kind, and they interleave.** |
| 7 | Delete TLC, decision left? | **Yes.** Whether an adjournment is a step at all is defensible either way. |
| 8 | Names an optimum? | **No.** |

Zero clear puzzle rows. **KIND: ACCEPT, system.**

## R, the route

**Intended route.** As candidate 1.

**Shortest route I can see, and why it's shorter here.** There's one thing on
the docket and one thing that can happen to it, so the leads-to writes itself
straight off the English without the spec being opened. Candidate 1 has two
exits and a compelled one, which is at least a choice about which predicate
names the left side. This domain has one.

**ROUTE: provisional, and weaker than candidate 1.** I'd want a second rule
with some bite before I'd take it.

## Vector fit

**Parties.** Two coroners, one kind. Open, adjourn, take a report into
evidence, and determine are all a coroner's acts. The finds are on the docket
at `Init`. If the statement lets a report arrive on its own, step sources goes
to 3 and the rung breaks, so the coroner has to be the one who takes it.

**Rules, and their kind.**

1. Every find is in exactly one stage. One-state claim, the type invariant.
2. A find is never released to its finder while its inquest is open. One-state
   claim.
3. A determination once recorded never changes. Step rule.
4. An inquest once opened is eventually determined. Needs "eventually".

Four lines, count 1, and rule 4 carries the "eventually".

**State estimate.** Three finds and two coroners. A find carries a stage from
five values plus an outstanding-evidence flag, so about seven reachable
combinations each. Roughly 7^3, a few hundred states, sub-second. INFERRED.

**What the domain wants that the vector won't give.** Real treasure inquests
run on statutory time limits and a valuation committee, and both have to be
left out.

**Crispness, which is the real objection.** §3.2 needs the statement to fix the
system completely. The duty to conclude an inquest is stated in law as "as soon
as reasonably practicable", which is a time bound and not a rule. Strip the
time bound and the duty is honest but vaguer than candidate 1's, where the
office either defaces a substandard ware or it doesn't. This is the same class
of risk §2.2 records against beekeeping hive splits, and I'd rather not open
the batch's first liveness rung on it.

## Frank's schema

Good, with one reservation. Treasure trove is folk knowledge in a way assay
offices aren't, so he probably holds a rough model already. The statutory
machinery is specialist and the lifecycle is not what a layman imagines, so I
think §3.10 is satisfied. It's satisfied less comfortably than candidate 1.

---

# Candidate 3: fingerprint bureau re-examination, `PrintBureau`

Several examiners in one bureau. Each case is examined and the identification
signed. An examiner who realises they erred withdraws their identification, and
the case must then be re-examined by a different examiner.

## §5.7, the mechanism screen

```
=== CANDIDATE: retroactive invalidation of one actor completed work obliging it to be redone by a different actor of the same kind
--- step 1: NAME collision
    query: 'PrintBureau language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: fingerprint bureau where an examiner withdraws an identification and a second examiner must re-examine the case
--- step 1: NAME collision
    query: 'PrintBureau language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

Named by hand: **the mechanism is a withdrawal of trust in one actor that
retroactively invalidates that actor's finished work and obliges another actor
of the same kind to redo it.** The duty here is to redo, which is a third
duty again.

Why the nearest burned mechanisms don't fit. Byzantine agreement is the honest
neighbour, since it also has an actor whose output can't be trusted. It spends
its whole content on reaching agreement despite that actor, and we never agree
on anything. Leader election needs a distinguished role, and every examiner is
the same. Replication needs copies.

**The domain noun is the problem, and it isn't a corpus problem.**

```
gh api -X GET search/code -f q='fingerprint language:tla' --jq '.total_count'
387
gh api -X GET search/code -f q='fingerprint language:tla' --jq '.items[0:5][].html_url'
  tlaplus-workshops/ewd998 :: MCEWD998.tla
  tlaplus/tlaplus :: tlatools/.../tlc2/tool/fp/OpenAddressing.tla
  Kuan-Lun/h2hdb :: verification/tla/VerticalFamily.tla
  Kuan-Lun/h2hdb :: verification/tla/MutableVerticalCAS.tla
  zoratu/tlaplusplus :: corpus/internals/FingerprintResize.tla
```

387 hits, and the first five are all TLC's own fingerprint set, which is how
TLC hashes a state. None of them is prior art for a forensic bureau, so this
isn't a §5.7 burn on the mechanism. It's worse in a way §5.7 has no verdict
for. The domain's central noun is the tool's word for a state hash, and the
learner reads TLC's output on every run. I'd not put that collision in front of
a learner who's meeting liveness for the first time.

## §5.7b, the puzzle screen, spec-in-hand form

| # | Question | My answer |
|---|---|---|
| 1 | Spec and rules in hand, anything left to model? | **The requirements, and this is the richest of the three.** A withdrawal reaches backwards into work already recorded. |
| 2 | Requirements given as formal claims, or decided? | **Decided, on the "different examiner" rule.** It ranges over a pair, and no other rule here does. |
| 3 | What is asked? | **Is this design correct.** |
| 4 | Who works once it compiles? | **The learner writes the properties, TLC checks them.** |
| 5 | Where does the difficulty live? | **The retroactive part.** |
| 6 | Agents, fallibility, interleaving? | **Several of one kind, and one of them can be wrong.** This is the only candidate that claims the whole system column. |
| 7 | Delete TLC, decision left? | **Yes.** |
| 8 | Names an optimum? | **No.** |

Zero puzzle rows, and the strongest table of the three.

**KIND: ACCEPT, system.**

This is the candidate I'd reject, and it passes §5.7b better than the one I'd
take. That's the two screens being independent, the same way rung 1's record
found it from the other direction.

## R, the route

**Shortest route.** Longer than either of the others, because the "different
examiner" rule needs a pair and can't be pattern-matched off one field.

**ROUTE: provisional, and the best of the three.** The rejection below is on
vector fit and on the noun, not on the route.

## Vector fit, and why it fails

**Parties.** Examiners, one kind, if the withdrawal is the examiner's own act.
If a supervisor withdraws, that's a second kind of actor and step sources jumps
to 2, which sets a second new high and breaks clause (b'). I can put the
withdrawal on the examiner, but I'd be imposing that on the domain rather than
reading it off. In a real bureau the verification is somebody else's job.

**The liveness is false in a reachable state.** With two examiners, if both
have withdrawn on a case, no different examiner is left and the case can never
be re-examined. The reference then needs a guard, and the guard is machinery
this rung has no room for at property count 1. Three examiners pushes the state
count up and only moves the problem.

**Rules, and their kind.** Type invariant, "no case is reported while an
identification on it stands withdrawn", "a withdrawn identification is never
reinstated", and "a withdrawn identification is eventually replaced by a fresh
examination by a different examiner". Four lines, count 1, and the fourth
carries the "eventually".

**State estimate.** Three cases and two examiners, about seven reachable
combinations per case, so roughly 7^3 plus the examiner state. Under 1,000.
INFERRED.

## Frank's schema

Fine on vocabulary and shaky on mechanism, which is the wrong way round and is
exactly how rung 1's breed registry failed. He hasn't run a fingerprint bureau.
He has spent twenty years around "this result is suspect, re-run everything
that depended on it", which is what the whole domain is. §3.10 is about the
schema and not the vocabulary.

---

# The recommendation

**Take candidate 1, the assay office, `AssayOffice`, slug `assay-office`.**

It's the one whose liveness rule is both real and small. A ware found
substandard must eventually be defaced, the duty belongs to the officers, and
there's nothing else in the domain competing for the learner's attention. Its
rules are the crispest of the three, which matters more than usual at §3.2
because the whole batch has one new thing per rung and this rung's new thing is
already the hardest one so far. Its §3.10 case is the strongest, since fineness
standards and the duty to deface aren't folk knowledge the way treasure trove
is. And it has two safety rules with real content next to the liveness rule, so
property count 1 gets filled with three rules that do work plus a type
invariant, rather than with padding.

**The live alternative is candidate 3, `PrintBureau`, and the world where it
wins is one where central wants the liveness obligation created by another
actor's mistake rather than by a finding about an object.** That's a better
problem, and its §5.7b table says so. Take it if central is willing to spend a
step 2 decision on the guard that keeps the liveness true, and if the noun gets
changed to something TLC doesn't already use. I'd not spend that on the first
liveness rung in the batch, but I can see the argument.

I'd leave candidate 2 out. It clears both screens and its mechanism is the most
elegant fit for a fairness lesson, but its route is the thinnest of the three
and its central duty is stated in law as a time bound, which §3.2 can't carry.

# Two things I'd flag to central

**The `WF` pin reading is load-bearing and it should be written down.** The
fourth rung-level finding above is not a detail. If §2.5:335 is read as a floor
rather than a ceiling, rung 4 has no legal vector and the ramp has a hole at
position 4. Central resolved it in the rung brief. I think the resolution is
right, and I think it belongs in §2.5 rather than in a brief that dies with the
session.

**The fairness conjunct decides whether the reference is correct.** Weak
fairness over a disjunction of an officer's actions doesn't oblige any one of
them. If step 2 ships that, the liveness rule is false, TLC hands back a
counterexample, and the learner is graded against a broken reference. It's the
most likely way this rung ships wrong, and it's cheap to get right if the
reference author is told before they start.
