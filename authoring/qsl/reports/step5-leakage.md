# qsl step 5: leakage check and delivery-boundary audit

Written under V2-PLAN §9.7 against the eleven learner-facing files of
`authoring/qsl/statement/`. Bead `tla-kstb`, wave-1 problem P2, task shape B.
I did not author the reference, the statement, or the traces.

Author-only. This file names every obligation the strip removed, so it lives
in `reports/` with the rest and never travels with the statement.

Shape B moves the leakage surface. The learner gets the spec, so "does the
statement give away the state representation" is answered before anybody
writes a word: it gives away all of it, on purpose. §9.7's representation
frame comes out empty here the same way it comes out empty on a column-C
critique problem, and for the same reason. The live surface is the artifact.
So I ran the audit against three questions instead:

1. Did the strip remove the obligation block and nothing else, with nothing
   leaking back in?
2. Does anything left in the spec hand over a property rendering the trace
   pairs are supposed to carry as meaning?
3. Do the pairs reveal the formulas rather than the targets?

**Verdict: SHIP, after one defect.** One learner-facing paragraph is false
about this spec, and I measured it false. Everything else I found is a note
for central, not a blocker.

## 0. The delivery boundary

The pilot's answer key sat in the directory its critics read
(`pilot/reports/agent-d.md` §0). Nothing like that here.

The learner set is eleven files, all under `statement/`:

```
statement/PROBLEM.md
statement/Bureau.tla
statement/traces/pair-1.md ... pair-9.md
```

`statement/` holds those eleven and nothing else
[`find authoring/qsl/statement -type f`, 11 lines]. No file in the set names
a path outside it, and none mentions `authoring/`, `reference/`,
`author-notes`, `reports/`, `FREEZE`, `V2-PLAN`, a `tla-` bead id, or a `§`
section mark [grep over the set, rc=1].

Nine author-only files sit outside that subtree. Two of them carry the graded
answer outright. `DESCRIPTION.md` §2 and `HANDOFF.md` §2 both list the nine
obligations in English **and label their kinds** ("Items 3, 5, and 6 are
invariants. Items 2, 4, 7, and 8 constrain steps"). That is the whole answer
to a shape-B problem, twice: `HANDOFF.md` is `DESCRIPTION.md` §1 to §4 byte
for byte [`diff`, 78 lines of output, all of it §5 and §6].

Two copies of the answer key doubles what a careless brief exposes, and both
sit at the top of `authoring/qsl/` where an `ls` finds them first. The
structural boundary holds, so I'm not calling it a defect. I'd still rather
central knew, because the fix on the brief side is free and the fix after a
panel has read one is not.

### The step-6 blind panel set

Name all eleven files. No directory, no glob. `PROBLEM.md:14` points the
learner at `traces/` as a location, which is right for a learner holding a
delivered directory and wrong for a panel brief. A brief that says "read
`traces/`" in a tree that also holds `author-notes/` is one typo from the
pilot's failure.

The panel solves the learner's task, not a critique task: write the
properties, declare their kinds, run TLC, hold the set against the pairs.
§9.8's recognition control still applies. Ask the published-problem question
up front and the mechanism question last.

### The delivery set for `~/tla-practice/problems/qsl/`

The same eleven, flat, with `traces/` kept as a subdirectory so `PROBLEM.md`
stays true. Nothing else.

Everything else goes to `tla-answers/`, per §6b.2:

```
reference/Bureau.tla, reference/Bureau.cfg, reference/FREEZE.sha256
author-notes/step4-trace-map.md, author-notes/ALTERNATIVES.md
reports/step2-variants.md, reports/step4-screens.md, reports/step5-leakage.md
DESCRIPTION.md, HANDOFF.md
```

The grader reads those. The tutor does not, and §6b.1 is why: an agent that
holds the trace map can be asked which pair a learner missed, and it will
answer.

### Attempt-log fields, §6b.4 plus the shape-B taxonomy

§6b.4's own list carries over unchanged: timestamp, problem id, spec
submitted, verdict object, questions asked, prompts given, whether the unlock
was strategic or specific, and the impasse kind (domain or modeling, asked
directly, never inferred).

Shape B needs three more, because "did they pass" hides the thing worth
measuring. Log per obligation:

- **found**: their set carries a property that does this obligation's work
- **missed**: no property of theirs rejects that pair's forbidden run
- **invented**: a property with no counterpart in the reference set

Split `invented` two ways before anybody reads it as an error. A property the
reference lacks that the spec still satisfies is **sound-and-extra**. One that
rejects an allowed run is **unsound**. §3.5 is the reason: the instructor's
oracle ranks first among correct forms for 33% of exercises, so an invented
property is a finding about the reference at least as often as it is a
mistake by the learner.

Two more per found obligation, both cheap and both diagnostic: did they pick
a kind TLC checks it as, and did they subscript a step rule over the whole of
`Observe`. §4 below says why the second one earns its field.

## 1. The strip

The reference and the statement share their first 40 lines byte for byte
[`cmp`, rc=0]. The diff is one hunk, a clean suffix deletion of lines 41 to
92, removing ten definitions and nothing else [`diff -u`, one hunk, 52 lines]:
`TypeOK`, `Opening`, `FilesWellFormed`, `CreditIsCorroborated`,
`CreditIsMutual`, `FilesOnlyGrow`, `OneEnvelopeAtATime`, `CreditComesWhole`,
`CreditIsPermanent`, `BureauKeepsUp`. The frozen reference is the one the
hashes name [`sha256sum -c FREEZE.sha256`, both OK].

Nothing leaked back in. The stripped file carries no comment of either form
[grep for `\*` and `(*`, rc=1] and no trailing whitespace [rc=1]. Line 40 is
one blank and line 41 is the module terminator, which is the shape the
reference has under `BureauKeepsUp`. No double gap marks where the block was.

One check worth doing that the diff doesn't cover: every definition that
survives has a live consumer in the system half. `vars` feeds `Spec`,
`ClaimsBy` feeds `Mail`, `Observe` feeds `Corroborated`, and `Corroborated`
feeds `Credit`. So the strip leaves no orphan operator, and a learner has no
"why is this here" fingerprint to read the removal off. I think that matters
more than it sounds. An operator defined and never used is a signpost.

The stripped module also stands on its own as a model. It parses and
model-checks against a config holding only `SPECIFICATION Spec` and the two
constants, which is the config `PROBLEM.md:134` tells the learner to write
[`tlc -deadlock Bureau.tla`, "Model checking completed. No error has been
found", 15,625 distinct].

### What the surviving spec hands over

Two operators are the verbatim bodies of two removed obligations.

`ClaimsBy(o)` is `FilesWellFormed` inside out. The obligation reads
`\A o \in Operators : Observe.filed[o] \subseteq ClaimsBy(o)`, and the learner
is handed the right-hand side under the right name.

`Corroborated(a, c, b)` is the whole of `CreditIsCorroborated`'s per-fact
test, and it's also the antecedent `BureauKeepsUp` needs.

Neither is removable. `ClaimsBy` types `Mail`'s envelope and `Corroborated`
guards `Credit`, so cutting them means editing the frozen system half, which
is the one thing the strip must not do. This is the shape's residue rather
than this author's mistake: you can't hand somebody a spec, ask what it
guarantees, and hide the guards. Two of nine obligations come with their
vocabulary attached. The other seven don't, and two of those seven
(`OneEnvelopeAtATime`, `CreditComesWhole`) are multi-line existentials with
no obvious form.

That said, it corrects the author's route analysis. `step4-screens.md` says a
pairs-only reader still has to open the prose, because the pairs don't carry
"the corroboration vocabulary rule 3 supplies". They don't, but the artifact
does, at `statement/Bureau.tla:12`. So the prose isn't forced open by that
route. What survives the shortcut is the kind decisions and the two step
formulas, which is a better reason for the same verdict. More on this in §4.

### The fairness conjunct

`WF_vars(CreditStep)` is visible at `statement/Bureau.tla:39`, by design. The
learner needs it, and pair 9 is why: pair 9's forbidden run is the only one
whose every step is a legal `Next` step, so the only thing that makes it not
a behavior is the fairness conjunct. Without `WF_vars` in view, the pair
would be unjustifiable.

`PROBLEM.md` never draws that line. It mentions `Init`, `Spec` and "the
actions" at line 13, and `SPECIFICATION Spec` at line 134. It never says
fairness, `WF_`, `CreditStep`, `Mail` or `Credit` [grep, 2 hits, both benign].
So the statement shows the conjunct and leaves the learner to work out which
property leans on it. That's the handling my brief asked me to confirm, and
it holds.

## 2. The trace pairs

For shape B the pairs **are** the oracle for what the properties are. Nine
pairs signalling nine obligations is §3.9 working, not a leak. The line is
whether they hand over formulas, and they don't.

The nine files carry a `# Pair N` heading, one shared sentence ("The first
run stays inside the rules. The second breaks at least one rule."), and state
dumps. That's all of it. A sweep for any line that isn't a heading, a fence,
a `State N`, an `Observe` field or that shared sentence returns exactly one
hit across all nine: `pair-9.md:44`, "(from the last state on, nothing ever
changes)".

That line is sanctioned by `PROBLEM.md:120-121` and it can't be removed. A
finite rendering of an infinite stall has to say it stalls. It does tell the
learner that pair 9 is the temporal one, which is residue the author already
recorded and which no reword closes.

No pair file names a rule, a property, a kind, or an obligation. A sweep for
`rule N`, `invariant`, `property`, `step rule`, `opening`, `grow`,
`permanent`, `mutual`, `corroborat`, `whole`, `envelope`, `keeps up` and
`well formed` across `traces/` returns nothing [rc=1]. Nor do the files carry
`Sxx` or `TCx` ids, exit codes, or the variant action names `Expire` and
`CarbonCopy` [rc=1].

I hand-checked all nine allowed runs against `Init`, `Mail` and `Credit`, and
all nine forbidden runs against the same. Each allowed run is a legal step
sequence and each forbidden run breaks the action it claims to break, with
pair 9 the one case needing the fairness conjunct to fail. That matches what
the author machine-validated (`step4-trace-map.md`, nine of nine at rc=12
with an rc=0 control). [INFERRED, by inspection. I did not rerun the
trace-forcing validator.]

### The permanence coupling

My brief asked one thing here: does pair 8's framing tell the learner there
are exactly N properties, or that two of them overlap? Neither.

`pair-8.md` carries the same shared sentence as the other eight. No extra
line, no note. The licence that makes an eight-property answer safe lives in
`PROBLEM.md:118-119` instead, stated generally: a forbidden run can break
more than one rule, and rejecting it for any rule it breaks is right about
that run. It names no pair.

That's the right place for it. Step 2's finding 2 measured that nothing in a
29-config matrix was ever caught by `CreditIsPermanent`, so a learner who
covers pair 8 with their whole-credit step rule is correct and needs to know
it. Saying which pair overlaps would hand over the coupling. Saying that some
pair overlaps costs a little and buys the honesty. I'd have made the same
trade.

## 3. Standard sweeps

All ten removed obligation names, across all eleven learner files: no hits
[rc=1]. `Sxx` and `TCx` ids, `rc=` values, `Expire`, `CarbonCopy`, `variant`,
`seeded`: no hits [rc=1]. Internal paths and plan references: no hits [rc=1].

Classification vocabulary returns two hits, and both are fine.
`statement/Bureau.tla:39` is the fairness conjunct, covered above.
`PROBLEM.md:89` says a corroborated fact "must eventually be credited". No
kind label appears anywhere: not `INVARIANT`, not `PROPERTIES`, not "safety",
"liveness", "action property", or "fairness".

"Eventually" is worth a sentence, because it's the one word that could be
read as a kind hint. I don't think it is. §3.2 obliges the statement to fix
the system, rule 5 is a temporal obligation of the system, and there's no
English for it that isn't temporal. The graded decision is which construct
carries it and where to declare it, and neither is given.

State counts. One number reaches the learner, at `PROBLEM.md:141`, and it's a
tamper check rather than a result: 15,625 distinct states, with a different
count meaning the system half changed. It holds. A plain run gives 740,626
generated and 15,625 distinct at depth 10 [`tlc -deadlock`], and so does a
run with a learner-shaped config carrying an invariant and two temporal
properties [same counts, 47 s]. The generated count and the depth stay
author-side, which is right. The distinct count is derivable by the learner
in one second, so publishing it gives away nothing they don't already hold.

## 4. The puzzle screen, run independently

§9.7 wants a second, adversarial pass over `harness/PUZZLE-SCREEN.md`. One
caveat on how much mine is worth: I read `step4-screens.md` before writing my
rows, because auditing its claims meant reading it. The pilot's checker
recorded answers first (`pilot/reports/agent-d.md:229`) and mine aren't worth
as much for that reason. I did read all eleven learner files in full before
opening any author note, so the reading of the statement is my own.

The screen says so itself: a second run of Q1 to Q8 tells you little, because
every row ships its two answers and a screener picks from a menu. The value
is in R, which has no answer column. I've put the weight there.

### §5.7, on a third phrasing

I ran the mechanism screen on wording neither of the author's two runs used:
"mutual corroboration with permanent joint credit from append-only per-party
claim logs". Name search 1 hit, clear. No mechanism derived. **CLEAR**.

The tool says a non-derivation is not a clean bill, and it's right, so I
checked the instrument fires. "Permit review across parallel departments"
comes back **BURNED** on atomic commitment, 3 README rows, plus two-phase
commit at 2 rows. The mechanism map is keyed on domain phrases, and it has no
row for claim matching, so step 2 is a non-answer here rather than a pass.

Hand-named, I get what the author got: two parties independently append
assertions to their own grow-only logs, and a third party joins matching
pairs into a permanent symmetric record. Not atomic commitment (no vote, no
abort). Not allocation (nothing is scarce, nobody waits). Not consensus (no
agreed value). The nearest published neighbor I can think of is a grow-only
CRDT, and nothing here merges or converges. I concur with CLEAR.

### §5.7b, Q1 to Q8

Shape B, so Q1 and Q2 in their requirement-centric form.

| # | My answer | reads |
|---|---|---|
| 1 | The requirements themselves. Five prose rules in, nine formal obligations out, each needing a kind and a rendering. | system |
| 2 | Decided, with a split (below). | system |
| 3 | Is this design correct. No goal state, no reachability. | system |
| 4 | The learner models the properties. TLC checks them. | system |
| 5 | Abstraction choice, one level up: kind, subscript, and two hard step formulas. The search is 1 s. | system |
| 6 | Several, fallible. Operators mail uncoordinated, can lie, can go silent. | system |
| 7 | Yes. Which rules the interface carries, and as what, is defensible on paper. | system |
| 8 | No [grep for optimal, minimum, fewest, best, rc=1]. | system |

Zero puzzle rows of eight. **KIND: ACCEPT, system.**

The Q2 split, since the screen asks for both halves rather than one word.
Decided: no rule arrives as a formula, no kind is marked, and rule and
property aren't one to one (rule 2 alone feeds three obligations, rule 4
feeds four). Given: the pairs enumerate the targets, and the artifact hands
over two of the nine renderings.

The screen names a tell that would flip Q2 to "given": every stated rule
mapping to one obvious formula in vocabulary the artifact supplies. It
doesn't fire. Two of nine come with their vocabulary, seven don't, and
`CreditComesWhole` is a 12-line existential in the reference.

### R, the route

**Intended route.** Read the five rules. Diff each pair's forbidden run
against its allowed twin and name the rule it breaks. Classify the fault as
wrong start, wrong step, or nothing-ever-happens. Write the formula over
`Observe`, pick its kind, run TLC, hand-check the pairs.

**Six probes.**

Tiling first, since it's cheapest and it's what broke the pilot. There is no
cross-table to build. The artifact declares no checks, and no `.cfg` ships,
so the pilot's route (declared checks against numbered rules, count the
holes) has no foothold here. The only enumerations are five rules and nine
pairs, and they don't align, so a learner can't index one off the other.

Vocabulary absence fires on four nouns and none of them pays. `desk` (1),
`register` (2), `callsign` (1) and `station log` (1) appear in the prose and
never in the artifact. `register` is just English for `credited`, which is in
the artifact. The other three mark the can't-carry set, which `PROBLEM.md:29`
declares open rather than hides. The pilot's hit was a technical noun the
statement leaned on three times over a seeded gap. This isn't that.

Elimination fires twice on liveness, from both directions.
`PROBLEM.md:43-44` says the bureau is the one party with an obligation, and
`Bureau.tla:39` fairs exactly one action. Together they point hard at rule 5
as the temporal one. The author kept the prose half deliberately, and I agree
it has to stay: operators owing nothing is a stated system fact, not a
withholdable hint. The learner still writes the leads-to and gets the
antecedent right.

Answer form. The task at `PROBLEM.md:21-27` fixes the interface (§3.3
requires that) and the declare-your-kinds discipline. It names no per-rule
target and no formula shape. Line 23-24 says a wrong kind can pass without
checking, which is a hazard warning rather than an answer.

Pre-clearing finds three passages, one more than the author listed. Lines
29-30 (some rules can't be carried) and 118-119 (a run can break more than
one rule) are both required honesty and neither points anywhere. The third is
lines 104-108, and I'll take it separately.

Recall: §5.7 CLEAR above, no prior spec to crib a property list from.

**Shortest route found.** Skip the prose. Diff the nine pairs, read the nine
targets off them, and take `ClaimsBy` and `Corroborated` from the artifact
for two of the renderings. That reaches the target list without opening the
rules.

It doesn't reach an answer. Every target still needs a kind, and the two step
properties still need building, and those are where this cell teaches. So the
shortcut lands in the same place the intended route does, one step earlier,
having skipped the part that was never graded.

**ROUTE: ACCEPT**, with one thing recorded rather than rounded off. The
can't-carry judgment that `PROBLEM.md:29-30` advertises as "part of the work"
isn't measured by anything. Nine pairs grade nine writable properties. Nobody
checks whether the learner noticed that "an operator can mail a claim for a
contact that never happened" has no property form. A learner passes without
doing that half.

That's the same shape as the pilot's ROUTE REJECT, and it's a much smaller
fraction of the problem, which is why I land on ACCEPT. On the pilot the
gradable half was table-building and the ungradable half was the whole point.
Here the gradable half is nine formulas including two hard ones, and the
ungradable half is a side observation. Worth handing to the grader and the
step-6 panel as a question to ask out loud, since the answer is telemetry
nothing else collects.

## 5. Defect

**D1. `PROBLEM.md:137-139` is false about this spec.** The paragraph reads:

> Run TLC with deadlock checking off. The flag is `-deadlock`, and despite
> its name it turns the check off. The bureau is allowed to come to rest when
> nothing is left to do, and a default run reports that rest as an error.

A default run doesn't. `tlc -workers 1 Bureau.tla` on the stripped spec with
the statement's own config exits 0 and prints "Model checking completed. No
error has been found", 740,626 generated, 15,625 distinct, depth 10. I ran it
twice, at one worker and at four, same result.

The cause is in the spec. `Mail(o)` draws its envelope from
`(SUBSET ClaimsBy(o)) \ {{}}`, and re-mailing claims already on file is a
legal step that happens to leave the state alone. So `Next` is enabled in
every state, this spec has no deadlock, and TLC's check never fires.

Both sentences are wrong, and the second one is the one I'd fix first. "The
bureau is allowed to come to rest when nothing is left to do" is a claim
about the system, and the artifact contradicts it. A learner reasoning about
pair 9's stall from that sentence starts from a false premise about what
resting means here.

How it got in: every run behind this problem went through
`harness/verdict.sh`, which passes `-deadlock` by default
(`harness/verdict.sh:333-335`). So nobody ever saw a default run, and the
paragraph was written from the flag's reputation rather than from output.
Cheap mistake, and I'd guess it will recur on the next shape-B problem for
the same reason.

**Arrow: step 4, the prose.** A reword closes it. The `-deadlock` instruction
itself is harmless, so keeping it costs nothing. Nothing in the properties,
the traces, or the spec moves.

## 6. Notes for central, not defects

**N1. The subscript warning resolves a graded decision.**
`PROBLEM.md:104-108` tells the learner to subscript step rules over the whole
of `Observe` and describes what goes wrong otherwise. The author's own Q5
names three places the difficulty lives, and the subscript target is one of
the three.

Two things pull against calling it a leak, and I don't. It fixes the
interface, which §3.3 obliges, and it hands over no formula, no kind and no
count.

One thing pulls the other way, and it's new. The pairs already catch the
error without the warning. Step 2's finding 8 measured `FilesOnlyGrow` going
blind to mail steps under a wrong subscript. Pair 2's forbidden run is
mail-only, and I read no other reference obligation that rejects it, so a
learner with a blind `FilesOnlyGrow` fails their own step-4 hand-check. The
warning converts a discovery into an instruction. [INFERRED. I hand-evaluated
pair 2's three states against the reference set rather than running it.]

Central's call, not mine. I'd note only that the concession is larger than
"interface terms only" suggests, and that removing it costs a learner one
extra iteration rather than a wrong answer.

**N2. Two answer keys, both at the top of `authoring/qsl/`.** Covered in §0.
`HANDOFF.md` is a strict subset of `DESCRIPTION.md`. Whether the duplicate
survives is a housekeeping question, but the eleven-file brief matters either
way.

**N3. The route correction in §1.** `step4-screens.md`'s reason for ROUTE
ACCEPT rests on the prose supplying corroboration vocabulary. The artifact
supplies it. The verdict survives on a different argument, which §4 gives.

## 7. The grading split

§9.7 wants the split proposed before any blind agent runs, so step 6's spread
rule has something to consume. Translated to shape B, per obligation:

**(a) Named.** The learner's set rejects that pair's forbidden run and admits
its allowed run. This is the conclusion. Nine pairs, nine judgments.

**(b) Established.** The property is declared under a kind TLC checks it as,
subscripted over the whole of `Observe`, and the spec passes it. This is the
instrument.

(a) without (b) is a property that says the right thing and checks nothing.
That isn't a hypothetical here. Step 2's finding 7 measured `CreditComesWhole`
at rc=13 under `_Observe` and rc=0 under a wrong field subscript, same
mutation. A learner can score (a) on all nine and establish four.

Three rules on top:

1. **Pair 8 admits two shapes, both full credit.** A separate permanence
   property scores (a). So does covering pair 8 with the whole-credit step
   rule. Step 2 found nothing in 29 configs that permanence caught alone, so
   penalizing either shape penalizes the learner for the measurement.
2. **An invented property is not a miss.** Score it sound-and-extra or
   unsound (§0). §3.5 says the reference oracle is first among correct forms
   only a third of the time.
3. **Read the argument, not the count.** Two learners can both reject all
   nine forbidden runs, one with nine properties TLC checks and one with nine
   properties three of which are blind. Same (a) column. That's where the
   spread lives, same as the pilot.

## 8. Verdict

**SHIP, after D1.** Fix the deadlock paragraph at step 4 and the eleven files
are fit to go to a blind panel.

The strip is clean: one hunk, ten definitions, no comment, no whitespace
tell, no orphan operator. The pairs carry targets and no formulas, and the
one non-boilerplate line in nine files is a stall marker the shape requires.
Zero hits across every sweep for obligation names, ids, paths, kind labels
and author-side counts. The one learner-visible number holds under two
configs.

Both screens accept. KIND at zero puzzle rows of eight, ROUTE on the finding
that the shortcut skips only what was never graded.

What I'd want a reader to carry away past the verdict: the two structural
findings aren't about this wording. The artifact hands over two of nine
renderings because a shape-B problem can't hide its guards, and the
can't-carry judgment the statement advertises isn't measured by anything the
problem ships. Both will land again on every shape-B problem in the batch,
and neither closes with a reword.
