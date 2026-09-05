# Step 5, the leakage check on `river-call`

Rung 3 of batch 2, bead `tla-h2cg.9`, shape D at representation 2, form 0.
I didn't write the reference, the statement, or the traces. This is the
adversarial second pass.

The report runs in the order the work ran. Part A is the puzzle screen with
only the learner set open. It's written down here as it was written then,
before I'd read the plan, the reference, the vector, or any upstream report.
Wave 1 found that a reviewer who reads the answers side first can't screen
independently afterwards, so the order is the point rather than a formality.

## Part A. The screen, learner's eyes only

Sources open: `statement/PROBLEM.md`, `statement/RiverCall.cfg`,
`statement/traces/pair-1.md` through `pair-3.md`. Nothing else.

Q1 and Q2 run in their first form. `harness/PUZZLE-SCREEN.md:80-89` routes
shapes B, C and D to the second form on the grounds that all three hand the
learner a spec. That doesn't hold at representation 2. `PROBLEM.md:22` says
"No spec ships. The model is yours to write." So the action-centric pair is
the one that asks something here, and the rubric's routing rule is stale for
this rung.

**Q1. Hand the learner the legal moves. Is anything left to model?**
System. The act vocabulary is handed over, which §3.2 obliges: move your own
gate to any setting in range in one act (rule 3), put a call out, take it
back (rule 6). What's left is the decomposition. Is a call move and a gate
move one act or two? Is rule 4's total-under-flow an enabling guard or a
preserved invariant? Is rule 7's bar on a junior's rise a guard inside the
action, which makes requirement 3 true by construction, or only a checked
property, which sets TLC hunting for it? Nothing in the statement settles
that, and I think it's the decision the problem turns on.

**Q2. Actions given, or must the learner decide what an action is?**
Decided. I'm writing the split down rather than collapsing it to one word.
The vocabulary is given. The unit of atomicity isn't, and rule 7's last
clause (`PROBLEM.md:97-99`) makes that unit load-bearing rather than
cosmetic. Where the priority rule lives, guard or property, isn't given
either.

**Q3. What's being asked?** System. Is this design correct. Four
requirements to establish, then a written argument about a run somebody else
made. No goal state and no reachability question anywhere in the statement.

**Q4. Who does the work once the spec compiles?** System. The learner
models and TLC checks. The last section goes further: the two questions at
`PROBLEM.md:261-262` ask what a green run does and doesn't establish, which
TLC can't answer at all.

**Q5. Where does the difficulty live?** System. Abstraction choice. The
search is 136 distinct states in under a second (`PROBLEM.md:233-234`), so
none of this is about state-space size.

**Q6. How many agents act, and can any fail, stall, or interleave?** System.
Several, fallible. A fixed finite set of owners, each turning their own
wheel (`PROBLEM.md:38-41`). Interleaving is stated outright at
`PROBLEM.md:44-45`. Stalling is the whole of rule 9.

**Q7. Delete TLC. Is a modeling decision still left to defend?** System, and
strongly. The argument that requirement 3 can't be written as an invariant
over any model of this system (`PROBLEM.md:173-179`) is pen and paper. So is
the diagnosis.

**Q8. Does the statement name an optimum?** System. A grep over the learner
set for `optimal|optimum|minimum|fewest|best |maximiz|minimiz|as few|is it
possible` returned nothing, rc=1.

Tally: zero of eight read puzzle. **KIND: ACCEPT, system.**

One system tell is missing and I want it on the record. §9.6's list includes
an observation operator whose shape is left open. Here the shape is pinned
to two fields with fixed types (`PROBLEM.md:132-139`). That's a house
decision, because grading compares values. It costs a tell rather than
earning a puzzle row.

### R. The route

The route I read the statement as intending: decide what one act is, model
the stretch from prose, write four formulas over `Observe`, run TLC at three
owners and decree 2 and flow 3, hold the model against three trace pairs,
then reason about the handed run at flow 6.

The probes.

**Tiling.** Four numbered requirements against four declared checks in
`RiverCall.cfg:10-14`. No holes. The statement closes its own list at
`PROBLEM.md:167`. Tiling finds nothing here, which is the instrument
working rather than the instrument sleeping.

**Elimination.** Both `Observe` fields carry behavioural checks. `diverted`
sits under requirements 1, 2 and 3, `calling` under 1, 3 and 4. No orphan
field.

**Vocabulary absence.** "Short" is the statement's load-bearing noun and it
appears nowhere in the cfg. The statement pre-declares the absence and gives
its reason at `PROBLEM.md:141-146`, so the probe fires and is then answered
in the text.

**Pre-clearing.** Six passages of the "this looks wrong and it's fine" kind.
Four are honest scaffolding. Two aren't, and they're the finding below.

**The answer form.** `PROBLEM.md:264-266` narrows what counts as evidence
before the learner has thought about the run. It names three admissible
kinds and calls anything else an opinion. That narrows the shape and not the
target, so I let it stand.

The shortest route I found, and it never opens the model:

1. `PROBLEM.md:219-220` teaches the lever in the author's own words. "A flow
   of 3 against decrees totalling 6 puts the stream under the paper right,
   so shortage is reachable." Read it backwards.
2. `PROBLEM.md:243` gives the handed instance. Three owners, decreed 2 each,
   flow 6. Six against six, so the stream isn't under the paper right, so
   shortage isn't reachable, so no call is ever honest, so no call ever goes
   out, so requirements 3 and 4 are never exercised.
3. Or skip step 2. `PROBLEM.md:252` reports 27 distinct states,
   `PROBLEM.md:233` says to expect 136, and `PROBLEM.md:237-238` says "A run
   that finds fewer than 100 distinct states isn't exploring this system,
   whatever verdict it reports." Twenty-seven is under a hundred.

That's two sentences of arithmetic. The third step is the statement handing
the reader its own conclusion, with "whatever verdict it reports" pointing
at the run two sections down.

The modeling half survives it. Task steps 1 to 4 are untouched, and
`PROBLEM.md:264-266` still demands a behavior shown step by step or a check
with a verdict, which nobody can fabricate. But the insight is the graded
thing, and the insight is reachable by reading two numbers off the page.

The shortcut lives in the prose at both sites, so a reword closes it.

**ROUTE: REJECT as written. ACCEPT with those two sentences reworded.**

Part A ends here. Everything below was written after I opened the answers
side.

## Part B. The answers side

**Verdict: SHIP after D1 and D2.** Both are single sentences in
`PROBLEM.md`, both hand the learner the diagnosis, and both close with a
reword. Nothing I found is upstream in the reference, and nothing needs the
statement rebuilt.

### 1. The plan's own question

Does the statement give away the state representation? Mostly no, and the
two sentences that do give something away give away the seed rather than the
representation. Here's what I flagged and what happened to each.

**The `Observe` field names.** `PROBLEM.md:126-131` names the fields
`diverted` and `calling`. Those are the reference's two variables
(`reference/RiverCall.tla:12`), and the reference's `Observe` is the
identity over them (`:16`). So the statement's interface is the reference's
state, name for name.

I cleared it on provenance. `DESCRIPTION.md:161` and `:164` name both fields
in the section 1 to 4 block that was pasted into the §9.4 reference-author
brief, so the reference took its variable names from the description and not
the other way round. The statement is entitled to the description's names.
The residual cost is real and both documents already carry it:
`DESCRIPTION.md:177-180` says a field says what has to be reportable rather
than what the state is, and `PROBLEM.md:123-125` carries that to the learner
in the learner's own words.

**The seniority order.** `PROBLEM.md:212-213` names the owners 1, 2 and 3
and makes the name the priority date. `reference/RiverCall.tla:18` is
`Senior(a, b) == a < b`. The instance closes the description's seniority
fork (`DESCRIPTION.md:279`), which offered a date, a rank, or an order
relation. The step 4 author flagged this against themselves at
`reports/step4-screens.md:167-179` and argued the alternative changes the
instance step 2 measured. I agree, and I'd add that a constant isn't state,
so the representation dimension doesn't move on it.

**Rule 7's "the same act".** `PROBLEM.md:97-99` says a call reaches a
junior's rise if it was standing when the rise began, whatever happens to
the call in the same act. That sentence permits an act that moves a gate and
a call together. The reference can't do that: `Open` carries
`UNCHANGED calling` (`reference/RiverCall.tla:38`) and both call actions
carry `UNCHANGED diverted` (`:49`, `:54`). So the statement describes a
wider system than the reference implements, which is the safe direction, and
`DESCRIPTION.md:364-369` already worked out why a joint step lands on the
same properties. Not a leak, and worth recording as the opposite of one.

**The cfg's four names.** `statement/RiverCall.cfg:10-11` renames the two
invariants to `GatesWellFormed` and `TheFlowHolds`, while `:13-14` keeps
`NobodyOpensAgainstACall` and `ACallIsHonest` verbatim from
`reference/RiverCall.tla:71` and `:77`. The asymmetry caught my eye and it
comes to nothing. All four cfg names track the four requirement headings at
`PROBLEM.md:153-165`, which the learner already holds, and the reference
named its own operators the same way. No information crosses.

### 2. The fields

Both fields are stated as facts with their shapes pinned and nothing more
(`PROBLEM.md:126-139`). Neither shape forces a side of a section 5 fork.
`Observe.diverted` as a function from owners to whole numbers leaves the
settings fork open (`DESCRIPTION.md:276`), because a model can keep pairs or
a seniority-ordered list and still render a function.

There's no none marker in either field and the statement says so at
`:137-139`. That's right for this system, since a shut gate is a real zero
rather than an absence.

One fork the interface closes on purpose, and the description owns the
decision rather than the statement leaking it. `calling` asks for a yes or
no per owner, which rules out carrying only the most senior caller
(`DESCRIPTION.md:287-293`). The statement doesn't mention the alternative,
so nothing is handed over.

The shortness paragraph at `PROBLEM.md:141-146` is the largest narrowing in
the interface, and it's `DESCRIPTION.md:167-175` compressed. I'd keep it.
Without it a learner exposes shortness as a third field, and then
requirement 4 grades their model against their own reading of rule 5.

### 3. The pairs

The traces render two fields, states only, with `yes` and `no` for the
booleans. No TLA+ appears, no action name, no module name, and no obligation
name. The trace map says the stripping was by hand and that `OpenTwo` never
appears (`author-notes/step4-trace-map.md:46-48`). I read all three files
and found nothing.

Each violating half breaks its own requirement and nothing simpler. I walked
each by hand against the checking instance of three owners, decree 2, flow 3.

- Pair 1, forbidden: `(2, 2, 0)` totals 4 against a flow of 3.
- Pair 2, forbidden: owner 3 rises while owner 2 is calling.
- Pair 3, forbidden: owner 1 calls from all shut, with 3 units free.

Pair 1's state is well formed, no call moves, and no rise happens under a
call, so only requirement 2 fires. Pair 2's settings total 3 and no call
goes out, so only requirement 3 fires. Pair 3's state is well formed and
flow legal and nothing rises, so only requirement 4 fires. The map's
obligation column agrees (`step4-trace-map.md:16-18`).

Two discriminators are worth naming because the grading split below uses
them. Pair 2's two halves differ only in who opens last, and both land the
total at 3, so arithmetic alone can't separate them
(`step4-trace-map.md:77-82`). Pair 3's forbidden step moves `calling` and
leaves `diverted` alone, which is what makes it catch a requirement 4
subscripted on the settings (`step4-trace-map.md:89-94`, and step 2 finding
3 at `reports/step2-variants.md:273-280`).

### 4. The diagnose object

`statement/RiverCall.cfg` is `reports/step2-variants/D01.cfg` with a
three-line comment added and the two invariant names changed [`diff`, four
hunks, nothing else]. `D01.tla` differs from the frozen reference only in
its module line [`diff`, one hunk]. So the object is the seed section 7
describes and the spec is otherwise the reference
(`DESCRIPTION.md:391-392`).

The console block at `PROBLEM.md:250-254` matches what step 2 measured
(`reports/step2-variants.md:262-265`) and what step 4 re-measured
(`reports/step4-screens.md:209`). It ships the OK line, the state counts and
the depth. It does not ship the coverage block, which matters, because
`DESCRIPTION.md:420-422` calls the `CallOut` row at zero total the strongest
of the three signals.

**Does the instance give the seed away by inspection?** Yes, and I think
that part is acceptable. Flow 6 against three decrees of 2 is a sum a reader
does in one glance. But the arithmetic on its own doesn't carry the step
that matters, which is that a flow covering every decree makes shortage
unreachable. `DESCRIPTION.md:409-415` is explicit that reaching that step is
what separates a learner who modelled the system from one who didn't. So the
equality is a prompt rather than an answer, and I'd leave the instance
alone. Changing the flow to 7 would break the equality and probably keep the
same 27 states, but it invalidates a measured green run for a benefit I
can't measure [INFERRED, on the state arithmetic].

What isn't acceptable is that the statement supplies the step as well. That
is D1.

**Does `PROBLEM.md` keep the harness out of the learner's hands?** By name,
yes. The boundary sweep in section 5 finds no mention of `harness`,
`vacuity`, `verdict.sh` or a probe. By value, no, and that is D2.

### 5. The delivery boundary

Five files reach a blind panel seat, all under `statement/`:

```
statement/PROBLEM.md
statement/RiverCall.cfg
statement/traces/pair-1.md
statement/traces/pair-2.md
statement/traces/pair-3.md
```

`statement/` holds those five and nothing else [`find`, 5 lines]. A grep
over the set for `authoring/`, `reference/`, `author-notes`, `reports/`,
`FREEZE`, `V2-PLAN`, `tla-`, `harness`, `vacuity` and `verdict.sh` returns
nothing [rc=1]. A grep for a `§` section mark returns nothing [rc=1].

A second sweep for `grader`, `grading`, `rubric`, `obligation`, `verdict`,
`Gate.tla`, `screen`, `frozen`, `bead`, `shape D`, `form 0`, `batch`,
`rung`, `variant` and `seed` returns nine hits [rc=0], and every one is
learner-legitimate. `INVARIANT` and `INVARIANTS` are TLC keywords that form
0 gives on purpose. "Obligation" at `PROBLEM.md:112` is rule 9's plain
English. "Grading" at `:123` and `:132` is the learner's own grading
contract, the same hit `bonded-store` cleared. "Invariant" at `:178` is the
argument that requirement 3 can't be one. "Verdict" at `:265` is the
learner's own TLC run. "Verdict" at `:237` is D2.

Twenty-eight author-only files sit outside the subtree, and two of them
carry the graded answer outright. `DESCRIPTION.md` section 7 is the seed and
its whole argument. `reports/step2-variants.md` section 3.3 is the same
thing measured, down to the three probe verdicts. The structural boundary
holds, so neither is a defect.

**Name all five files in the step 6 brief. No directory and no glob.**
`PROBLEM.md:18` points the learner at `traces/` as a location, which is
right for somebody holding a delivered directory and wrong for a panel
brief. qsl and `bonded-store` both raised this and I'd raise it a third
time, because a brief saying "read `traces/`" in a tree that also holds
`author-notes/` is one typo from the pilot's failure.

### 6. The grading split

§9.7 wants this before any blind agent runs. Per requirement, what counts as
carrying it, and what passes everything shipped without carrying it.

**Requirement 1, the gates are well formed.** Carrying it is the domain, the
per-owner range `0 .. Decree[o]`, and the boolean typing, as at
`reference/RiverCall.tla:64-67`. There is no pair, and the statement says so
(`PROBLEM.md:206-208`). So the range clause is graded by nothing shipped. A
learner who writes the domain and the shapes but drops the upper bound
passes every check the statement asks them to run, because a correct model
never produces an over-decree setting. Step 2 caught that mutation at rc=12
as S04 (`reports/step2-variants.md:213`), and S04 isn't shipped. The
statement flags the risk in the right words at `PROBLEM.md:169-171` without
being able to grade it. Read requirement 1 off the formula, never off a
verdict.

**Requirement 2, the flow holds.** Carrying it is the total over all owners
against `Flow`. Pair 1 does real work here. The per-owner weakening, each
setting at or under the flow, passes `(2, 2, 0)` at a flow of 3, so pair 1
separates it from the total. What pair 1 can't reach is anything about where
the learner enforces the rule, since requirement 2 is a state predicate and
the reference's guard lives in `Open` (`reference/RiverCall.tla:36`).

**Requirement 3, nobody opens against a call.** Carrying it is both
quantifiers, over every senior rather than the immediate one, in the
pre-state, subscripted over the whole record. The immediate-senior weakening
survives everything shipped. Step 2 measured it as P04 at rc=0 against the
reference and P04S07 at rc=0 over all 136 states
(`reports/step2-variants.md:250`, `:254`). Pair 2 doesn't separate it
either: owner 2 is owner 3's immediate senior in the forbidden run, so the
weak form rejects it too. The subscript is loose here as well. P01
subscripts on the settings and comes back rc=0 against the reference
(`:247`), and pair 2's forbidden step moves the settings, so nothing shipped
notices. Read the second quantifier and the subscript off the formula.

**Requirement 4, a call is honest.** Carrying it is the FALSE-to-TRUE
antecedent, rule 5's reading of shortness, and the whole-record subscript.
This is the best graded of the four. The wrong subscript is caught by pair
3, because the forbidden step moves only `calling`. The own-draw reading of
shortness is caught too: under it owner 1 at zero against a decree of 2
counts as short, so the forbidden run stops being a violation and the
learner sees it. What survives is the seniors-only reading, which step 2
measured uncaught as a system mutation at S12 (`:221`). Whether it also
survives as a property weakening depends on an implication I haven't run
[INFERRED].

**Two holes that no property set can close.** S18 opens with every call
standing, and nothing in the graded set constrains the opening, so a learner
whose model starts with calls out passes all four checks
(`step4-trace-map.md:98-105`). Step 2 recommends leaving it open at this
rung rather than spending a fifth cfg line
(`reports/step2-variants.md:340-350`), and I agree. Grading must not read a
wrong opening as a property-set failure. Separately, pair 1's forbidden half
is a joint step, so a learner whose model has no joint step can't produce it
either way. The pair still asks whether a requirement breaks on it
(`PROBLEM.md:31-32`), so the discrimination survives, but don't mark the
model wrong for the missing step.

**The diagnosis half.** Naming it is saying the run establishes only that
nothing goes wrong on an instance where the priority logic never runs.
Establishing it is naming the mechanism, that a flow at or above the total
of the decrees makes shortage unreachable, and then showing it: a behavior
the rules allow that no check sees, or a check of the learner's own with its
verdict. `PROBLEM.md:264-266` already draws that line. After D1 and D2 land,
the naming half stops being free.

So the spread step 6 should expect lives in requirement 1's range, in
requirement 3's second quantifier and subscript, and in whether the
diagnosis carries a mechanism or an assertion. Two learners can reject all
three forbidden runs with property sets of visibly different strength.

### 7. VECTOR.md

Six rows, six citations, and every one resolves to a line that says what the
record says it says. I checked each by hand.

Representation 2 cites `PROBLEM.md:22`, the no-spec line, `:123`, the
variables-never-leave line, and `:134-135`, the two pinned shapes, against
`reference/RiverCall.tla:12` and `:16`, the variables and the identity
`Observe`. Property kind 2 cites `reference/RiverCall.cfg:9-11`, the
`PROPERTIES` block, and `reference/RiverCall.tla:62`, `:75` and `:80`, the
spec line and the two `]_Observe` subscripts. Property count 1 cites
`reference/RiverCall.cfg:6-11`, four obligation lines. Step sources 1 cites
`PROBLEM.md:38-44`, one kind of actor and several of them. State space 0
cites `reports/step2-variants.md:135-136`, which reads 757 generated, 136
distinct, depth 8, under a second. Form left open 0 cites
`PROBLEM.md:150-165`, the four requirements with keyword and kind given.

`bash harness/test-vector.sh` ends `FAILED: 30 passed, 2 failed`. Both
failures are `authoring/assay-office` and `authoring/estate-notice`, frozen
packages with no `VECTOR.md` yet, which central says is expected. The
`river-call` row passes.

### 8. The defects

**D1. `PROBLEM.md:219-220` hands over the mechanism the diagnosis is for.**
The sentence reads "A flow of 3 against decrees totalling 6 puts the stream
under the paper right, so shortage is reachable." It's lifted from
`DESCRIPTION.md:247`, which is author-only reasoning about why the checking
instance was chosen. Read backwards against `PROBLEM.md:243`, which gives
the handed instance as three owners decreed 2 on a flow of 6, it's the seed
in one step. `DESCRIPTION.md:413-414` says the intended route is asking
whether anybody ever goes short, "and that question is the flow against the
sum of the decrees". The statement asks it for them, two pages early, in the
author's own words.

The step 4 author's route analysis grants a shorter cheat and calls it
acceptable, on the grounds that the cheat reaches the answer "with half the
reason" and question 2 asks for the why
(`reports/step4-screens.md:156-163`). That defence needs the why to be
withheld, and it isn't. The author's probe list covers the state counts at
`:146-149` and doesn't reach `:219-220` at all, so I don't think the
sentence was weighed rather than dismissed.

Fix: say shortage is reachable on the checking instance and drop the
arithmetic that generalizes. The sentence lives in the prose, so a step 4
reword closes it and nothing upstream moves.

**D2. `PROBLEM.md:237-238` hands over the vacuity probe's threshold.** The
sentence reads "A run that finds fewer than 100 distinct states isn't
exploring this system, whatever verdict it reports." That 100 is
`vacuity.sh`'s per-problem floor for this problem, proposed at
`reports/step2-variants.md:411`. The handed run reports 27
(`PROBLEM.md:252`), and the probe returns `VACUOUS_EMPTY_SPACE` at rc=3 on
exactly that comparison (`reports/step2-variants.md:300`).

Step 2 accepted the floor's masking cost on the stated grounds that "step 4
keeps the harness away from the learner anyway"
(`reports/step2-variants.md:411-412`), and `DESCRIPTION.md:431` says the
same in stronger words. The harness isn't in the learner's hands by name.
Its threshold is, and "whatever verdict it reports" is what aims it at the
green run rather than at the learner's own.

Fix: scope the sentence to the learner's own run and drop the trailing
clause. The 100 is worth keeping as a self-check on a model that turns out
over-constrained, which I think is why it was written. It just shouldn't be
pointed downstream.

### 9. Notes for central, not defects

**The rubric routes shape D wrongly at this representation.**
`harness/PUZZLE-SCREEN.md:80-89` sends B, C and D to the requirement-centric
Q1 and Q2 because all three hand the learner a spec. Shape D at
representation 2 ships no spec (`PROBLEM.md:22`), so the action-centric pair
is the one with something to ask. The step 4 author hit the same thing and
said so (`reports/step4-screens.md:72`). Two screeners in a row working
around one line is worth a bead.

**S18 needs to reach the grader, not just this report.** The trace map
carries it (`step4-trace-map.md:98-105`) and the trace map never ships. If
the step 6 brief doesn't repeat it, a panel seat that opens with calls
standing gets marked wrong for a gap the pipeline chose to leave open.

**The `-coverage 1` row is the strongest signal and nothing ships it.**
`DESCRIPTION.md:420-422` says so. Keeping it out is right. Worth knowing
that a panel seat who reaches for coverage on their own has found the
cleanest evidence available, and the grading split should credit that.

### 10. Verdict

**SHIP after D1 and D2.**

Both fixes are rewords in `PROBLEM.md`, neither touches the reference, the
cfg, or the traces, and neither changes a measured number. The screen's
KIND verdict is ACCEPT and I found no reason to move it. The ROUTE verdict
is REJECT as the statement stands and ACCEPT once those two sentences are
reworded, which is the same thing the defects say from the other side.

What I'd want the reworded statement checked against: after D1 and D2, is
there still a path to "shortage never happens" that doesn't go through the
learner's own model? I don't think there is, but I'm the wrong person to
time it, and step 6 is where that gets settled.

