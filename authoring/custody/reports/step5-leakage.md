# Custody, step 5: leakage check and delivery-boundary audit

Adversarial pass over problem P1 per V2-PLAN §9.7, §6 step 5. Bead `tla-jjo7`.
Author-only. Nothing in this file goes to a blind panelist or into
`~/tla-practice/`.

I read everything under `authoring/custody/`. The learner-facing candidate set is
`statement/PROBLEM.md` plus the twelve files under `statement/traces/`, thirteen
in total. Everything else is author-only, and my job is to say whether the
thirteen are clean of it.

P1 is the first problem the learner receives, so I've held the delivery boundary
tighter than I would on a later problem.

**Verdict: SHIP**, with one precondition on step 6 and three defects, none of
which is leakage. The precondition is in section 5. The findings that matter are
in sections 3, 4 and 5.

## 1. What the greps say

Six sweeps over the thirteen files. The script is reproducible in a few lines and
worth re-running after any reword.

**Reference identifiers.** Every top-level name in `reference/Custody.tla` and
`reference/MCCustody.tla`, plus the three witness probes and their invariants, run
as a word-boundary grep over the learner set. Twelve hits, all twelve English:
`Days` starting a sentence, `Base` in "Base pattern", `Custody` starting a
sentence, and "a swapped day" as an adjective. No identifier reference in the set.

The four that repay a second look:

**`swapped`** is a variable in the reference and an adjective in the statement.
The reference holds a set of swapped days, and the statement says "on a swapped
day, custody is with the parent who would not have it" (`PROBLEM.md:43`). The word
carries no shape. I don't think a learner reads a set out of it.

**`Base`** is a constant in the reference and "the base pattern" in the handoff's
rule 3, which predates the reference. Same flow as the buyclub naming finding: both
took the word from a common ancestor the learner never sees.

**Variant ids.** `grep -rnE '\bV[0-9]{2}\b'` over the set returns nothing. The
26 rows of the step-2 matrix are invisible from the learner side.

**Paths and internals.** A sweep for `authoring/`, `reference/`, `author-notes/`,
`reports/`, `harness/`, `V2-PLAN`, `.tla`, `.cfg`, `tla-puzzles`, `github`,
`fkberthold`, `FREEZE`, `.sha256`, `frozen`, `tmp-variants` and `/home/` returns
nothing. Section 4 is about that result, since it's the one my brief named.

**Classification vocabulary.** No hit for `invariant`, `action property`,
`temporal property`, `liveness`, `safety`, `fairness`, `WF_`, `subscript`,
`obligation`, `verdict`, `rc=`, `seeded`, `variant`, `screen`, `BURNED`, `bead`
or `tla-`. Two hits on the wider pattern: "Grading runs entirely through it"
(`PROBLEM.md:104`) and "a trace that ends in stuttering"
(`traces/property-09.md:32`). Neither names a file and neither names a form.

This sweep is the one I'd weigh most. `HANDOFF.md:148-152` tells the reference
author which items are invariants, which constrain steps, and which is the one
liveness obligation. That's a real modeling judgment and it stayed on the author
side. The statement says "eventually" once, in property 9's own English, and never
names the machinery.

The count of graded obligations stayed back too. `MCCustody.cfg` declares
thirteen, the statement asks for ten, and property 9 carries three of them.
`TypeOK` is over raw state rather than over `Observe`, so it can't travel to a
learner's module at all. A learner who counted checks against properties would get
nothing.

**TLA+ syntax.** No hit for `\A`, `\E`, `\in`, `\cup`, `EXCEPT`, `|->`, `_vars`,
`_Observe` or the box-bracket action form. The only backticked text in the set is
`Observe`, the three field names, and the fourteen-letter schedule string.

## 2. Representation, and which forks the interface eats

`ALTERNATIVES.md` records eight representation decisions the reference author
faced. §9.7 asks me to flag anything in the statement that names or implies one.
Rather than answer yes or no, I walked all eight, because the useful number is how
many the statement closes and for what reason.

| Fork (`ALTERNATIVES.md`) | Status in the learner set | Closed by |
|---|---|---|
| PlusCal against plain TLA+ | open | stated as free at `PROBLEM.md:4` |
| derived against maintained custody | open | nothing in the set touches it |
| `NoDay == 0` against a model value | **closed** | `PROBLEM.md:119` |
| `CONSTANTS A, B` against a `Parents` set | **closed** | `PROBLEM.md:117` |
| `pending` as a total function | field closed, variable open | `PROBLEM.md:114` |
| voiding folded into its causing steps | open | rule 8 states the fact, not the fold |
| actor-free actions | open | the absence at `PROBLEM.md:122` is interface-only |
| fairness on the day-beginning action only | open on the form, narrowed on the site | section 3 |

Two are closed outright, and both are the §3.3 tax rather than a wording slip. The
grader renders the properties over the learner's `Observe`, so it has to be able to
name the parents and to read the no-day marker. A learner free to pick a model
value for "none" hands the grader an unreadable field. I'd pay that price again,
and I'd want it on the record that P1 pays it twice where buyclub paid it once.

The central fork survives untouched, which is the part I care about. The
`custodian` field is an answer, not a store. `HANDOFF.md:171-174` argues that a
deriving model and a maintaining model produce the same field, and nothing in the
thirteen files pushes either way. The reference took the set and derived
(`Custody.tla:31`), and I can't find the sentence that would tell a learner so.

**Where that leaves §3.2.** Zero incremental representation leak from the nine
rules over the ten properties. Every atomicity clause in the rules is restated as a
graded property. Rule 8's immediacy lands in property 6, rule 9's binding lands in
properties 3 and 7, and rule 1's ending lands in properties 8 and 9. A learner who
skipped the rules entirely would still have to fold voiding to satisfy property 6.

## 3. The traces, and where custody sits against the buyclub line

Twelve files, ten properties, one shared satisfying behavior with per-property
callouts pointing into it. My brief asks whether the callouts jointly narrow the
property renderings to transcription past what §3.9 accepts.

I don't think they do, and the reason is the buyclub one. A trace pair constrains
the learner's **behavior set**, not their formulas. Evaluating a property on 24
states tells you its truth value there, not its syntax. The learner still has to
invent the transition relation, and one allowed behavior plus eleven forbidden ones
comes nowhere near pinning it.

The shared satisfier is worth a word, since it's a departure from buyclub's nine
independent ones. It constrains **less**, not more. One allowed behavior against
nine. What the callouts add is where to look, which is pedagogy and is the whole
point of §3.9's negative-instance finding.

**Where custody sits relative to the precedent.** The buyclub pass ruled that the
pairs half-dictating frame discipline was structural rather than a leak. Custody's
shared satisfier does the same thing one notch harder, and the notch is atomicity
rather than framing. §9.7 names atomicity as a flag class, so I'll show the work.

`traces/full-window.md:19` reads "day 3 begins. A's proposal is void that same
moment". `:22` reads "the swap of day 12 is agreed, and the other proposal is void
that same moment". Those two rows render the voiding fold and the same-day race,
which are the two traps the author's R route names.

Three things keep it on the structural side of the line.

The prose is more explicit than the table. `PROBLEM.md:69-73` says "voiding is
immediate", names both causes, and spells the race out in a sentence. §3.2 obliges
the statement to fix the system, and voiding timing is observable, so the fact has
to be there. The trace adds nothing the rules don't already give.

No satisfying trace could show anything else. Property 6 says an outstanding
proposal names a day that hasn't begun. A trace that voided one row later would
violate property 6 and stop being a satisfier. So the fold isn't a choice the trace
made, it's the only rendering available.

The reason stays back. Nothing in the thirteen files says that a separate voiding
step breaks property 6. That derivation is the modeling work, and a learner who
copies the table without it walks into the race with no defense.

**A correction to the author's route claim.** `reports/step4-screens.md:161` says
"the two traps are not in any table". That's false, on the two rows quoted above. I
don't think it changes his ROUTE verdict, for the three reasons just given, but the
supporting claim doesn't hold and shouldn't travel with the verdict.

**Fairness.** `traces/property-09.md:14` calls its first violator "a model where
nothing obliges a day to begin", and `:30-31` says "your model has to make that
true, not merely possible". That names the site, which buyclub's set did not. I
read it as structural anyway: property 9 carries the only "eventually" and only a
day-beginning moves `today`, so the site is forced by the property's own English.
The weak-against-strong judgment is untouched.

The direction that isn't covered is worth carrying. Nothing grades a learner who
puts fairness on the parents' actions too. `ALTERNATIVES.md:91-94` records that the
reference deliberately doesn't, since nothing compels acceptance, and
`step4-screens.md:98-101` names the same class as ungradable. This is P1's version
of buyclub's one ungradable judgment, and the count is the same: one.

**Rendering.** All twelve files show the three observation fields and a narration
column, at every state. No TLA+ record syntax, no raw TLC dump, no internal names.
The traces README says outright that the narration "is not a fourth field, and your
model does not have to name any of it" (`traces/README.md:31`).

One stylistic split, recorded rather than flagged. The satisfying rows name the
actor ("A withdraws it") and the violating rows describe the delta ("day 1 goes to
B, out of nowhere"). That traces to provenance, since the violators are rendered
TLC counterexamples and the satisfier is hand-shaped
(`author-notes/step4-trace-provenance.md:24-25`, `:62`). It tells a sharp reader a
model checker was involved and nothing about the answer. Same finding buyclub got,
same size.

**The satisfier is sound, and I checked both halves.** The replay probe verifies
the encoded states, not the published markdown, so a table edit could drift without
the probe noticing. I re-derived all 24 rows from `TraceReplay.tla`'s `T` and
diffed against the table: 24 for 24, no mismatch. Then I re-ran the probe itself,
`SAFETY_VIOLATION` rc=12, which is the pass. Freeze verified first,
`sha256sum -c FREEZE.sha256`, all 10 files `OK`.

I also walked the eleven violating tables against the rules and the schedule string
by hand. Day 4 flips to A, day 11 flips to B, the cap trace runs three swaps off a
cap of two, and the two-day jump skips day 1. I found no factual error.

## 4. Public exposure

The named concern. `reports/step4-screens.md:54-60` found that the frozen reference
is indexed on GitHub code search, and filed it for central (bead `tla-g6ew`). My
job is the narrower one: does the learner set make the reference easier to find.

**What I confirmed.** Every file under `authoring/custody/` sits on `origin/main`,
the reference and the statement alike (`git ls-tree -r --name-only origin/main`, 37
paths, `reference/Custody.tla` among them). So the statement and the answer live in
one public repo, three directories apart.

**What the learner set contributes: nothing.** The paths sweep in section 1 comes
back empty. No file name, no module name, no repo path, no "frozen at" language, no
hash. The word `Custody` appears four times and every one starts a sentence.
Nothing asks the learner to name a module anything.

**The route that stands, and whose it is.** Any distinctive sentence of
`PROBLEM.md`, pasted into a code search, resolves to this repo, and `reference/` is
one directory up from there. That route exists because the statement is published,
not because of how it's worded, and no reword closes it. Per §6's red-arrow rule
the arrow points at the publication decision, which is Frank's, and not back at
step 4.

**One co-occurrence, and I'd leave it.** The schedule string `AAABAAA BBBABBB`
appears in all thirteen learner files and in
`author-notes/step4-trace-provenance.md`, which maps every property to its graded
obligation name and its variant id. So a searcher on that string reaches an
author-only file directly. I checked whether that's an independent worsening and I
don't think it is. The general route above already lands in the same repository,
and closing this one hop leaves it standing. Recording it rather than proposing a
fix.

**On the two §5.7 verdicts.** Step 0 screened `SharedCustody` and got 0 hits
(`screens.md:9-10`). Step 4 screened `Custody` and got 37, `BURNED`
(`step4-screens.md:26-28`). The names differ, so the verdicts differ, and five of
the 37 are this repo's own reference. I agree with the author that the collision is
lexical, and the mechanism reading holds: chain-of-custody and asset-swap protocols
have adversaries and refund paths, and this arrangement has neither. I did not
re-run `harness/screen.sh`, since §9.7 mandates the puzzle screen and not the
corpus one.

## 5. The independent puzzle screen

§9.7 makes me run `harness/PUZZLE-SCREEN.md` a second time, as an adversary. Task
shape A, so Q1 and Q2 get their action-centric form.

**Disclosure first**, same one buyclub's checker had to make. My brief told me to
audit everything under `authoring/custody/`, which includes
`reports/step4-screens.md`, and I'd read it before I got to the screen. So Q1 to Q8
are contaminated and their agreement with the author's is worth close to nothing.
The brief-ordering fix buyclub proposed is still unmade, and this is the second
problem it's bitten.

R is different. R has no answer column, the author's route is a claim I can walk,
and I found a shorter one than he did on one axis and confirmed his on the other.

| # | Question | Answer |
|---|---|---|
| 1 | anything left to model? | **The actions themselves.** Rules give outcomes and permissions, never a move list. |
| 2 | actions given or decided? | **Decided.** Rule 8's three fates are two observable events, and the fold is the learner's. |
| 3 | what is asked? | **Is this design correct.** Ten properties, no goal state. |
| 4 | who works? | **The learner models, TLC checks.** Nothing is searched for. |
| 5 | difficulty? | **Abstraction choice.** Voiding atomicity, the race, and what the state holds. |
| 6 | agents / failure? | **Several, fallible.** Two parents plus a calendar nobody drives. |
| 7 | delete TLC, decision left? | **Yes.** The fold needs defending with no checker in the room. |
| 8 | names an optimum? | **No.** `grep -icE "optimal\|minimum\|fewest\|best"` over the set: 0. |

**KIND: ACCEPT, system.** Zero puzzle answers of eight, against a threshold of
three.

### R: the route

**Intended route.** Read the nine rules. Decide what the state holds and what a
step is. Define `Observe` to the contract. Render ten English properties, four of
which only work as claims about steps and one of which needs fairness. Run TLC on a
minutes budget and debug against the traces.

I walked the six probes. Tiling, vocabulary absence, elimination, answer form and
pre-clearing all came back where the author put them, and I'll not re-litigate rows
I can't claim independence on. Recall is the one I'd read differently: a
pattern-matcher who fires on the name gets chain-of-custody, which has an adversary
and an audit log, and this arrangement has neither. If recognition fires here it
costs the learner time rather than saving it.

**Shortest route found: transcription, and I reproduced it rather than taking his
word.** `author-notes/trace-probes/gen-replay-sub.py` builds a submission that
hardcodes `full-window.md`'s 24 states as a deterministic script with no `Next`
behind it. I generated it and ran the shipped gate through `harness/verdict.sh`:

| Run | Token | rc |
|---|---|---|
| all 13 obligations, `obligations.cfg` | `OK` | 0 |
| `CapNotReached` witness probe | `SAFETY_VIOLATION` | 12 |
| `AKeepsEveryScheduledDay` witness probe | `SAFETY_VIOLATION` | 12 |
| `BKeepsEveryScheduledDay` witness probe | `SAFETY_VIOLATION` | 12 |

That's a full pass on a submission with no modeling in it. It reproduces
`step4-screens.md:130-142` and bead `tla-dk7w` on this build.

**The proposed closure works, and now it's measured.** The author suggested a
witness probe chosen off the published thread, and I built one rather than leaving
it as a suggestion. `Day2NeverSwapped == Observe.custodian[2] = Sched(2)`, run as a
must-fail invariant:

| Target | Token | rc | Reading |
|---|---|---|---|
| the frozen reference | `SAFETY_VIOLATION` | 12 | probe fires, spec passes |
| the transcription | `OK` | 0 | probe dead, submission refused |

Day 2 is never swapped in any published trace, so the transcription can't reach it
and a real model can. One probe, six lines, and it discriminates. I'd add it to the
three in `reference/probes/` and I think §5.3 should generalize the pattern, since
every shape-A problem honoring §3.9 has this hole.

**ROUTE: ACCEPT, with one precondition.** For a learner trying to solve it I found
no route shorter than the intended one. The traces show behaviors and no formula,
the transition system still has to be invented, and the fold's reason is nowhere in
the set. The transcription route reaches a passing verdict rather than a correct
model, and its fix lives in the harness, not the prose.

**The precondition is on step 6, not on ship.** A blind panelist has no brief that
mentions a gate, so I doubt one games it on purpose. The risk I'd rather not carry
is on the reading side. Central grades the panel with this gate, and a submission
that pattern-matched the traces into a script scores green. Run the off-thread
probe as part of step-6 grading. It costs one TLC run per panelist.

**Column C does not apply.** §9.7's recalibration paragraph and its grading-split
deliverable are both scoped to critique problems. P1 is shape A, with no deficient
artifact and no seeded gap, so there's no split to propose. Recording the
non-applicability rather than skipping it.

## 6. The delivery boundary

Nothing in the thirteen files points outside itself. The one path reference is
`PROBLEM.md:171`, "the `traces/` directory beside this file", and it points inward.
`traces/property-08.md:24` points at `property-05.md`, and all ten property files
point at `full-window.md`, so the set doesn't separate.

That directory reference carries the same condition buyclub's did. §6 says a blind
agent gets named files and never a directory, and here the statement names one. So
the panelist's `traces/` has to hold twelve files and nothing else. It does today
(`ls -a`, twelve entries, no hidden files), and the provenance note lives under
`author-notes/` where it belongs.

No file in the set names a reference, a solution, an answer key or a variant. The
only hit for the answer vocabulary is `PROBLEM.md:104`, "the grader attaches its
own rendering", which points at no path.

### Step-6 blind panel set

Thirteen files, named. No directories, no globs.

1. `authoring/custody/statement/PROBLEM.md`
2. `authoring/custody/statement/traces/README.md`
3. `authoring/custody/statement/traces/full-window.md`
4. `authoring/custody/statement/traces/property-01.md`
5. `authoring/custody/statement/traces/property-02.md`
6. `authoring/custody/statement/traces/property-03.md`
7. `authoring/custody/statement/traces/property-04.md`
8. `authoring/custody/statement/traces/property-05.md`
9. `authoring/custody/statement/traces/property-06.md`
10. `authoring/custody/statement/traces/property-07.md`
11. `authoring/custody/statement/traces/property-08.md`
12. `authoring/custody/statement/traces/property-09.md`
13. `authoring/custody/statement/traces/property-10.md`

Copy them into a per-panelist directory with `PROBLEM.md` at the root and the
twelve traces under `traces/`, so the statement's own reference resolves. Give no
panelist a path to `authoring/custody/`.

Author-only, and none of it may sit in a tree a panelist reads: `DESCRIPTION.md`,
`HANDOFF.md`, `screens.md`, `reference/` in full including `probes/`,
`reports/step2-variants.md`, `reports/step4-screens.md`, this file,
`author-notes/ALTERNATIVES.md`, `author-notes/step4-trace-provenance.md`, and
`author-notes/trace-probes/` in full.

Two of those are sharper than the rest. `step4-screens.md` carries the shortest
route analysis and the transcription measurement. `step4-trace-provenance.md` maps
each learner-visible property to its graded obligation name and its variant id,
which is the grading key in table form.

### Delivery to `~/tla-practice/problems/custody/`

The same thirteen files plus one log scaffold, and nothing else.

```
~/tla-practice/problems/custody/
  PROBLEM.md
  traces/README.md
  traces/full-window.md
  traces/property-01.md .. property-10.md
  ATTEMPT-LOG.md
```

The reference, the probes and the variant matrix go to the `tla-answers` side per
§6b.2, never here. The grader reads them across the boundary and returns a verdict
object.

§6b.2 also assigns **expected state counts** to `tla-answers/`. Section 7's D1 is
about the one that didn't stay there.

### What the attempt-log template must ask

§6b.4 names the fields. One row per attempt, and the impasse question comes first.

1. impasse kind: are the rules of the system unclear, or how to model them?
2. timestamp
3. problem id
4. spec submitted, or a path to it
5. verdict object
6. questions Frank asked
7. prompts the tutor gave
8. unlock: strategic or specific
9. edits before the pass, as a count

Three of those need a sentence, since a template that just lists them will get them
wrong.

**The impasse kind leads on P1 on purpose.** §6b.4 calls the distinction
load-bearing and says to ask rather than infer. P1 is first contact with the whole
curriculum, so a domain impasse here says the statement is broken before the
learner has any calibration to absorb it. §7.1's refinement policy can't run
without the answer either. Asking it last, after eight bookkeeping fields, is how
it turns into an inference.

**The verdict object is pass or fail per obligation plus error location**, and
nothing else. Never a reference conjunct, never a diff (§6b.2, §3.7). The log holds
whatever the grader returned, so a diff appearing in the log means the leak already
happened upstream.

**One custody-specific note.** Given section 3, a domain impasse on rule 8's
immediacy would be the highest-signal event this problem can produce. It would mean
the single prose channel for the fold failed to carry it, and the fold is where the
modeling work lives. I'd want that one flagged rather than counted.

## 7. Defects

**D1, minor, arrow to step 4. The statement publishes its expected state count.**

`PROBLEM.md:185-187` reads "Expect the state count in the low hundreds of thousands
generated, roughly 100,000 distinct. If your run is orders of magnitude past that,
your model is remembering something the arrangement does not."

§6b.2 lists expected state counts among the things that live in `tla-answers/`. The
second sentence is the part I'd cut: it's an oracle on the learner's state
representation, and `PROBLEM.md:9` names "what your model has to remember" as the
exercise. So the statement sets the exercise and then hands over a check for it.

Two things keep this minor rather than serious. The count doesn't discriminate the
central fork, since a maintained-custodian model reaches the same 106 reachable
custody assignments as the reference's set does. And the check is orders of
magnitude, not a match, so nobody tunes to it.

The sibling statements bracket this. Buyclub gives no count at all, and its own
step-5 pass was glad of the absence (`buyclub/reports/step5-leakage.md:57-61`).
Consign gives "a few hundred distinct states", which barely discriminates. Custody
is the only one of the three with an over-state test attached.

The fix is to drop the two sentences and keep the timing budget at `:179-183`,
which does the "your run is working, not hung" job on its own. Central loses
nothing: the count belongs on the answers side, where it stays available for
grading. Wording, so step 4 owns it. I don't think it blocks ship.

**D2, minor, arrow to step 4. A dropped word in the contractual interface.**

`PROBLEM.md:113` reads "The answer each parent value, A or B." A word is missing,
and this is the section the statement calls contractual two lines earlier. The
meaning survives, but it's the one place where a learner reading around an
ambiguity costs a grading failure rather than a rethink.

**D3, trivial, arrow to step 4. The generated-states figure understates.**

I ran the reference on the shipped instance: 496,735 states generated, 102,460
distinct, `OK` rc=0, 1 minute 57 seconds. "Roughly 100,000 distinct" is right.
"Low hundreds of thousands generated" reads as 100k to 300k, and the real figure is
just under half a million. If D1 is taken, D3 goes with it.

The same run confirms two other things independently. The frozen reference is green
on all thirteen obligations, and the 2 to 3 minute budget at `:181` is honest.

## 8. Verdict

**SHIP.**

The thirteen files are clean of reference internals, clean of variant ids, clean of
paths, clean of the invariant-against-action-property classification, and clean of
anything pointing at the public reference. The §3.3 tax is paid twice rather than
once, both times for a grading reason I'd pay again, and the central representation
fork survives untouched.

Three things travel alongside.

The step-6 precondition in section 5 is the one I'd want acted on before the panel
dispatches. It's one probe and one TLC run per panelist, and without it a
transcription submission reads as a solve.

D1 is a two-sentence cut that puts a state count back where §6b.2 says it lives.

The route correction in section 3 is for whoever reads `step4-screens.md` next. His
verdict holds. The claim under it does not.
