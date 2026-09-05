# Rung 7 step 0, domain screens

Bead `tla-h2cg.13`, the seventh and last rung of batch 2 (V2-PLAN.md §7.0, table at
line 1622). Both screens run over three candidate domains before anything is
written. §6 step 0 puts this ahead of the reference author.

## The rung, and what it can carry

Rung 7 is shape A in situation S4. The learner reads prose and writes the whole
thing: the state, the actions, the observation operator and the cfg. S4 is time,
expiry and leases, which V2-PLAN.md §2.1 calls gap #6 and says is unserved
anywhere. Reading gate ch11, so PlusCal-era TLA+.

The vector, in §2.5's order:

| dimension | level | reads as |
|---|---|---|
| representation | 2 | state is the learner's, the reference's variables are the `Observe` fields |
| property kind | 3 | at least one `<>` or `~>`, plus a fairness conjunct in `Spec` |
| property count | 2 | five to nine cfg lines |
| step sources | 2 | two or more kinds of actor, none of whose steps is unprompted |
| state space | 0 | under a second, under 1,000 distinct states |
| form left open | 1 | the keyword or kind is given, the subscript target is open |

Step sources 2 is the single new high. Everything else sits at the running maximum
batch 2 has already reached. So rung 7 is the first problem where a second kind of
party acts, and the whole weight of the rung is meant to land there.

## Why the domain changed

The §7.0 table drafted ski pass validation with blackout dates. Central withdrew it
before this screen ran, because it's one of the sealed holdout domains (§7.2, bead
`tla-kl5.17`). Under §7.0 the domain changes and the rung keeps its vector, so the
three candidates below are all S4, all shape A, and all written to the same six
levels.

## Three findings that belong to the rung, not to any candidate

Worth stating once, because otherwise each one reads three times as a fault in
whichever candidate is under the microscope.

**Step sources 2 and situation S4 are in tension, and the tension is the rung.**
S4 is about time running out. Step sources 2 forbids a step the statement assigns
to no party, which is what a clock is. So an S4 problem below rung 8 can't have a
calendar, and the period has to come from somewhere else. There are only two places
I can find. Either the expiry is an act, so a right ends when somebody ends it. Or
the period is counted in a party's own acts, so it takes two inspections rather than
two weeks. All three candidates below take one of those two routes, and I'd rather
say so once than defend it three times. My read is that this isn't a compromise. It's
the question the rung is for, because deciding whether time belongs in the model at
all is exactly the abstraction choice representation 2 is meant to buy.

**The word "expiry" is burned in this project's own tool, and it's the name of the
situation.** `harness/screen.sh:115` carries the map row
`blood bank|inventory|expiry|type compatibility~allocation,matching`. It was
authored for the blood bank domain, where perishable units get matched to
recipients. As written it fires on the bare word. Here is the one-word probe, with
nothing else changed:

```
=== CANDIDATE: found property title passing to the finder on the lapse of the owner claim
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)

=== CANDIDATE: found property title passing to the finder on the expiry of the owner claim
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

"lapse" to "expiry" is the whole delta. This is the same class of fault rung 1 found
in the `warehouse|robot` row, and it'll fire again at step 4 on every S4 statement
that uses the ordinary English word. Follow-up at the end.

**The lease reading of S4 is closed on merit, not by artifact.**
`gh api -X GET search/code -f q='lease language:tla' --jq '.total_count'` returns
2316. The first page of paths is `dfinity/formal-models :: tla/file_based_lease/Lease.tla`,
`daehyeok-kim/redplane-public :: redplane-tla/redplane_lease.tla`,
`FedericoPonzi/tla-plus-specs :: lease-buggy-code/lease.tla` and
`tpjg/rbpmn :: spec/Lease.tla`. Four real lease specs in five results. So the third
noun in S4's own title is occupied, and a candidate whose mechanism is "a term right,
renewed before it runs out, reclaimed when it doesn't" is burned before it starts. I
dropped a cemetery right-of-interment candidate on this, and it's why none of the
three below renews anything.

---

# Candidate 1: the executor's notice to creditors, `EstateNotice`

An executor is winding up the estate of someone who has died. Before she pays
anything to the beneficiaries she advertises a notice, inviting anyone the dead
person owed money to lodge a claim. Creditors lodge while the notice stands. She
admits a claim or rejects it. She closes the notice when she chooses, and after that
nobody can lodge against her. She pays what she admitted, then distributes the rest
to the beneficiaries. A creditor who turns up after that is still owed the money, but
by the beneficiaries and not by the executor. The debt doesn't vanish. It moves.

It sits in S4 because the whole system turns on a right that stops being exercisable,
and it isn't S5 because nothing here is a lifecycle over one entity's status.

## §5.7, the mechanism screen

Two phrasings, verdicts pasted:

```
=== CANDIDATE: notice to creditors closing a liability set before an irreversible distribution
--- step 1: NAME collision
    query: 'EstateNotice language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: protective window that fixes a claim set before a one way payout
--- step 1: NAME collision
    query: 'EstateNotice language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

The tool derived no mechanism from either phrasing, and it says itself that isn't a
clean bill. So, by hand:

**The mechanism is a window that closes an open-ended liability into a fixed set,
after which an irreversible payout is safe, and claims that miss the window survive
against a different party.** The last clause is the part I haven't found anywhere
else. Most deadline mechanisms destroy the late thing. This one re-points it.

Why the nearest burned mechanisms don't fit. Atomic commitment is the serious
neighbour, and it's the one that killed the pilot's domain
(`harness/screen.sh` maps permit review straight to it). Two-phase commit needs the
participants to vote and needs any one of them to be able to abort. Creditors do
neither. They lodge, and the executor decides alone. The commit isn't conditional on
agreement, it's conditional on a deadline she sets herself. The resemblance is
"gather, then act", which isn't atomic commitment. The allocator needs contention
over something finite, and the estate isn't rationed here. Queues need order, and
claims are decided in any order.

**One risk I want on the record.** I didn't get a hand search for `probate` or
`creditor` against the corpus. GitHub returned
`API rate limit exceeded for user ID 4960532` on my fourth hand query tonight, six
screeners sharing ten requests a minute, and I spent the recovered budget on the
`quarantine` check under candidate 2 because that one had a number against it
already. So this candidate's mechanism argument rests on my own reasoning and on the
tool, with no domain-word search behind it. Step 4 should run one.

## §5.7b, the puzzle screen, action-centric form

Shape A, so Q1 and Q2 in their first form.

| # | Question | My answer |
|---|---|---|
| 1 | Hand over the legal moves, anything left to model? | **The actions themselves.** Is closing the notice the same step as distributing? Is a claim a message in flight or a record? Is a late claim in the state at all? |
| 2 | Actions given, or decided? | **Decided.** The late claim is the sharp one. It can be a status, a separate set, or nothing, and each choice makes a different rule writable. |
| 3 | What is asked? | **Is this design correct.** No goal state. |
| 4 | Who works once it compiles? | **The learner models, TLC checks.** |
| 5 | Where does the difficulty live? | **Abstraction choice.** Deciding what protection is. |
| 6 | Agents, fallibility, interleaving? | **Two kinds, and they get in each other's way.** A creditor can lodge in the moment before the close. The executor can close on a claim she hasn't read. |
| 7 | Delete TLC, decision left? | **Yes.** Whether "the executor is protected" is a fact in the state or a claim about the past. That's arguable on paper. |
| 8 | Names an optimum? | **No.** |

No puzzle rows of eight, against a threshold of three.

**KIND: ACCEPT, system.**

## R, the route

**Intended route.** Decide what a claim is and whether the notice is state. Decide
where a late claim lives. Write the actions for two kinds of party. Supply `Observe`.
Write the seven or eight properties, and work out which fairness conjunct the
liveness one needs.

**Probes I can run at step 0.** Five of the six need a statement, and there isn't
one. Tiling needs the answers side. Vocabulary absence, elimination, the answer form
and pre-clearing all need prose. Recall is the one that runs now, and it needs §5.7
to have come back BURNED, which it didn't. So it finds nothing here.

**Shortest route I can see.** Write six safety properties straight off the rule list
and one liveness property with `WF` on every action. That last move is the shortcut,
because blanket fairness makes the liveness property true without the learner ever
asking which party's stalling matters. Whether the statement can close that is a step
4 question.

**ROUTE: provisional.** Same posture as rung 1. At shape A the route lives in the
statement and the answers side, and neither exists yet.

## Vector fit

**Parties, and the second kind.** The executor is one actor. The creditors are
several actors of one kind. That's two kinds, so step sources 2, and the new high is
paid for honestly rather than by splitting one party in half. The creditors are a
different kind because their step set doesn't overlap the executor's at all. They can
only push a claim in. They can't admit, close, pay or distribute, and she can't lodge.

Nothing arrives unprompted. A creditor lodges because he chooses to. The notice
closes because she chooses to. There's no calendar and no arrival process, so this
stays at 2 and doesn't slip to 3.

**Rules, and their kind.**

1. `TypeOK`. One-state claim.
2. She never distributes while a lodged claim is undecided. One-state claim.
3. She never distributes while the notice is open. One-state claim.
4. Nothing is lodged against her after the notice closes. Step rule.
5. The notice never reopens. Step rule.
6. A decided claim never changes its decision. Step rule.
7. Every claim lodged before the close is eventually paid or rejected. Needs `~>`.
8. The estate is eventually distributed. Needs `<>`.

Eight lines, so count 2. Rule 7 or 8 puts it at kind 3 and forces the fairness
conjunct.

Rule 8 is the one with content, and it's the reason I think this domain earns the
rung. It's false under `WF` on the deciding actions alone, because she can leave the
notice open forever and creditors can keep lodging. It only holds with fairness on
the close as well. So the learner has to work out which party's stalling actually
blocks the outcome, and that question doesn't exist until there are two kinds of
party. The rung's new high pays for itself in one property.

**State estimate.** Two creditors, each claim in
`{none, lodged, admitted, rejected, paid, late}`, the notice open or closed, the
estate distributed or not. That's 6 * 6 * 2 * 2 = 144 in the type space and fewer
reachable, since paid implies admitted and late implies distributed. Under 1,000 and
sub-second. At four creditors the type space is 5,184 and space 0 is at risk, so the
shipped instance wants two or three. INFERRED, not measured.

**What the domain wants that the vector won't give.** Money. Real probate is about
whether the estate covers the debts, and that's arithmetic and a bigger state space.
The statement has to leave amounts out and treat a claim as owed or not. I think
that's a clean cut, and it doesn't touch the deadline, which is the whole point.

## Frank's schema

Strong. Estate administration is specialist legal practice, it isn't industrial IoT
or facility management, and it isn't software. He'll know the words "executor" and
"creditor" and I'd be surprised if he holds a working model of the notice period or
of what it protects. That's what §3.10 asks for. The one soft spot is that the
gather-then-commit shape is familiar from software, and a learner who reads it that
way will reach for a coordinator. My read is that the late claim breaks that reading,
because no commit protocol has a path for a vote arriving after the commit.

---

# Candidate 2: the plant health hold, `PlantHold`

A nursery imports lots of plants. Every lot arrives under a hold and can't be sold or
moved off the site while the hold stands. A plant health inspector visits and either
records the lot clean or records a finding. A lot is released after two consecutive
clean inspections. A finding puts the count back to zero. The inspector can condemn a
lot outright, and a condemned lot is destroyed. The nursery can stand one lot next to
another, and standing a released lot beside a held lot puts the released lot back
under hold with its count at zero.

It sits in S4 because the hold is a period, and the period is counted in the
inspector's own visits rather than in days. It isn't S9, because two parties act and
the order they act in changes the answer.

## §5.7, the mechanism screen

```
=== CANDIDATE: plant health hold discharged only by a clean inspection and re armed by a finding
--- step 1: NAME collision
    query: 'PlantHold language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: contact between a cleared lot and a held lot pulls the cleared lot back under hold
--- step 1: NAME collision
    query: 'PlantHold language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

Named by hand: **the mechanism is a run-length condition that a second party's own
acts must satisfy consecutively, resettable to zero by a finding or by contact.** The
reset is the distinguishing part. Nothing here accumulates.

Why the nearest burned mechanisms don't fit. Contagion by contact is the one to
watch, because spreading over a contact relation is reachability, and reachability
has a README row (`Misra Reachability Algorithm`). It only stays clear if contact is
a single event between two lots rather than a standing graph the model closes over. I
think the statement can hold that line, but it's a line the reference author has to
be told about, because a learner who models beds and neighbours will build a closure
and the rung has no room for a recursive operator at gate ch11.

**Two hits, and they're why I'm not recommending this one.**
`gh api -X GET search/code -f q='quarantine language:tla' --jq '.total_count'`
returns 84. Two of the first six paths are quarantine specs by name:
`sourcenetwork/defradb.rs :: proofs/tla/PendingDagQuarantine.tla` and
`minto-dane/capsched :: capsched-models/formal/0035-xsk-pagepool-quarantine-model/XskPagePoolQuarantine.tla`.
Both look like software quarantine, which is holding an item until it's validated and
then admitting it, and that's most of my mechanism minus the reset. I couldn't read
either module. Fetching them is a network call I didn't have budget for after the
rate limit, and I'd rather report that than guess at their contents. So this is a
recorded unknown, not a cleared one.

Under the strict reading Frank took on 2026-09-05, an unread neighbour with a
matching name isn't something to open a rung's new high on. The §5.7 verdict on the
spec name is CLEAR and I'm not overriding it. I'm declining to spend the rung on a
domain whose mechanism word has two published specs I couldn't check.

## §5.7b, the puzzle screen, action-centric form

| # | Question | My answer |
|---|---|---|
| 1 | Hand over the legal moves, anything left to model? | **The actions themselves.** Is a hold a fact about the lot or a record the inspector keeps? Is the clean run a counter or a history? |
| 2 | Actions given, or decided? | **Decided.** Contact especially. It can be an event, a relation, or a placement, and only one of those keeps the state space small. |
| 3 | What is asked? | **Is this design correct.** |
| 4 | Who works once it compiles? | **The learner models, TLC checks.** |
| 5 | Where does the difficulty live? | **Abstraction choice.** Whether contact persists. |
| 6 | Agents, fallibility, interleaving? | **Two kinds, and the nursery can undo the inspector's work.** |
| 7 | Delete TLC, decision left? | **Yes.** Whether the reset belongs to the lot or to the inspection record. |
| 8 | Names an optimum? | **No.** |

No puzzle rows of eight.

**KIND: ACCEPT, system.**

## R, the route

**Intended route.** As candidate 1. Decide the state, write two parties' actions,
supply `Observe`, write the properties and place the fairness.

**Probes.** The recall probe is the one that fires. Two named quarantine specs in the
corpus means a solver who has read either one gets the hold-then-admit shape handed
over. That's the probe doing its job, and it's a mark against the candidate rather
than against the statement.

**ROUTE: provisional, with a recall flag.**

## Vector fit

**Parties, and the second kind.** The nursery is one kind, the inspector is another.
They're different kinds because the inspector's acts are judgments and the nursery's
are movements, and neither can do the other's. The nursery takes delivery, stands lots
together, asks for a release and destroys. The inspector inspects, releases and
condemns. Asking for a release doesn't force an inspection, so nothing is prompted.

**Rules, and their kind.**

1. `TypeOK`. One-state claim.
2. A held lot never leaves the site. One-state claim.
3. A condemned lot is never released. One-state claim.
4. A lot's clean run never rises by more than one in a step. Step rule.
5. Condemnation never reverses. Step rule.
6. A lot only leaves hold on the inspector's release. Step rule.
7. A lot the nursery stops touching is eventually released or condemned. Needs `~>`.

Seven lines, so count 2, and rule 7 puts it at kind 3.

Rule 7 carries the same virtue as candidate 1's rule 8, and it's the reason this
candidate stays in the running at all. Written flat it's false, because the nursery
can keep pulling lots back under hold forever. It only holds conditioned on the
nursery stopping. That's a good question and I think it's the best single property
across the three.

**State estimate.** Three lots, status in `{held, released, condemned}` and a clean
run in `0..2`. That's 9 per lot and 729 in the type space, with reachable well under
it since released forces the run to 2. Under 1,000, but the headroom is thin and a
fourth lot breaks it. INFERRED, not measured.

**What the domain wants that the vector won't give.** Geometry. Real nurseries have
benches and blocks, and contact is spatial. Model that and the state space goes over
and a closure arrives with it. The statement has to make contact a pairwise event.

## Frank's schema

Strong. Plant health law is specialist horticulture, it isn't facility management,
and it isn't software. I'd say he holds no working model at all here.

---

# Candidate 3: the lost property office, `LostProperty`

A finder hands an item in to a property office and the clerk logs it. The person who
lost it can claim it back. The clerk runs a disposal round when she chooses, and a
round settles every item logged before the round opened: an item with a claim against
it goes back to its owner, and an item with no claim vests in the finder, who can
then collect it. What the finder doesn't collect the office disposes of. Title never
comes back to the office once it has gone.

It sits in S4 because a claim right stops being exercisable, and unusually the expiry
builds a title rather than destroying one.

## §5.7, the mechanism screen

```
=== CANDIDATE: unclaimed found property vesting in the finder after a disposal round
--- step 1: NAME collision
    query: 'LostProperty language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: unexercised claim right transferring title to a rival party on lapse
--- step 1: NAME collision
    query: 'LostProperty language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

Named by hand: **the mechanism is a claim right whose lapse vests title in a rival
party, so the deadline is constructive rather than destructive.**

Why the nearest burned mechanisms don't fit. The lease is the one to argue, given the
2316 hits above. A lease returns the thing to whoever granted it. Here the office
never had title and never gets it, and the item goes to a third party who was never
the grantor. That's the whole difference and I think it holds. Allocation needs
contention over a pool, and there's one item and no pool. It's worth saying that
`Lore-Hex/quill-router :: proofs/RegionalQuotaLease.tla` turned up in the unrelated
`quarantine` search, which tells me lease specs are thick enough on the ground to
appear by accident.

## §5.7b, the puzzle screen, action-centric form

| # | Question | My answer |
|---|---|---|
| 1 | Hand over the legal moves, anything left to model? | **The actions, thinly.** Is the round a variable or a step? Is title derived from status or carried alongside it? |
| 2 | Actions given, or decided? | **Split, and it leans given.** The round is a described office procedure, so the statement hands most of the action set over in the domain's own words. |
| 3 | What is asked? | **Is this design correct.** |
| 4 | Who works once it compiles? | **The learner models, TLC checks.** |
| 5 | Where does the difficulty live? | **Abstraction choice, weakly.** Mostly whether the round is time. |
| 6 | Agents, fallibility, interleaving? | **Two kinds.** A claim can land while a round is open. |
| 7 | Delete TLC, decision left? | **Yes, weakly.** Whether a round is a number. |
| 8 | Names an optimum? | **No.** |

One puzzle row of eight, plus two weak system answers. Under the threshold of three,
so it passes.

**KIND: ACCEPT, system.**

## R, the route

**Intended route.** As the others.

**Probes.** Recall finds nothing, since §5.7 came back clear on both phrasings. The
rest need a statement.

**ROUTE: provisional.**

## Vector fit, and why I'd leave it out

It passes both screens and it's the one I'd reject, on the vector rather than on
either screen.

**Parties, and the second kind.** The clerk is one kind. The claimants, meaning the
owner and the finder, are another. They're different kinds because a claimant can only
assert and collect, and the clerk is the only one who settles anything.

**The problem is the round.** Step sources 2 says no step is unprompted, and the
clerk chooses when to run a round, so on the rubric's own reading this places at 2. My
read is that it's inside the letter and against the spirit. A learner will model the
round as a number the clerk increments, and a number that only goes up and settles
everything below it is a clock wearing an apron. The rung's one new high is two kinds
of actor with no clock between them, and I don't want to spend it on a domain that
spends the whole problem arguing with the second half of that sentence. Candidates 1
and 2 have no counter of that shape anywhere.

**Rules, and their kind.**

1. `TypeOK`. One-state claim.
2. An item is never both restored and vested. One-state claim.
3. Title never returns to the office. Step rule.
4. An item is restored only on a claim lodged before its round. Step rule.
5. A round never settles an item logged after it opened. Step rule.
6. Every logged item is eventually settled. Needs `~>`.

Six lines, so count 2, and rule 6 puts it at kind 3. It fits the numbers.

**State estimate.** Two items, status in `{held, restored, vested, disposed}`, a claim
flag each, and a round index in `0..2`. That's 8 per item and 64, times 3 for the
round, so 192. Under 1,000. Three items pushes it to 1,536 and over, which is a second
mark against the round: it's the term that multiplies. INFERRED, not measured.

## Frank's schema

Weakest of the three, and it's the second reason I'd leave it. He isn't a property
clerk, but "hand it in, and if nobody claims it you can keep it" is common property.
§3.10 wants a domain he holds no working model of, and this one is close to public
knowledge.

---

# The recommendation

**Take candidate 1, the executor's notice to creditors, `EstateNotice`.**

It's the only one of the three with nothing recorded against it. Both phrasings came
back CLEAR, the atomic commitment neighbour is arguable and I've argued it, and the
late claim is a move I couldn't find in any deadline mechanism I know: the claim
survives its own expiry against a different party. On §3.10 it's specialist legal
practice with no software in it.

The reason I'd pick it over candidate 2 is what it does with the rung's new high. Rule
8 is false under fairness on the executor's deciding actions alone, because creditors
can keep lodging while she leaves the notice open. It only holds with fairness on the
close as well. That property doesn't exist until there are two kinds of party, and
working out which party's stalling blocks the outcome is exactly what step sources 2
is supposed to buy. One property earns the whole rung.

**The live alternative is candidate 2, `PlantHold`, and the world where it wins is
this one.** Somebody opens `PendingDagQuarantine.tla` and `XskPagePoolQuarantine.tla`,
finds that neither carries a reset, and central would rather have a period that's
countable in a party's acts than one that's purely an act. That's a real position, and
candidate 2's rule 7 is the single best property across all three. It's also the
better §3.10 case. If the two modules read clear, take it.

I'd leave candidate 3 out. It passes both screens and loses on the vector, because the
disposal round is a clock in everything but name and this is the one rung that can't
afford one.

# Two follow-ups worth filing

**Narrow `harness/screen.sh:115`.** The `expiry` alternative in the blood bank row
fires on the ordinary English word, and that word is the name of situation S4. Three of
batch 2's seven rungs are S4 (positions 2, 5 and 7), and every one of them will hit
this at step 4 when the statement is re-screened. Something like `unit expiry` or
`shelf life` would keep the authored intent, which was perishable stock matched to
recipients. I haven't touched the file. This bead grants me one report.

This is the second instance of the same fault. Rung 1 found it in the `warehouse|robot`
row, and V2-PLAN.md:180 already records the table side of it under bead `tla-stdl`. Two
independent hits in one evening is enough to say the map needs a pass rather than a
patch.

**Three of batch 2's seven rungs are S4 shape A.** Positions 2, 5 and 7 sit in the same
cell of the §2.1 grid, and the three of us drafting them tonight can't see each other's
picks. Clause (a) of the §2.5 sequence rule only bans neighbours from sharing, so this
is legal, and it's still three shots at one cell chosen blind. Central should read the
three recommendations together before any of them goes to Frank.
