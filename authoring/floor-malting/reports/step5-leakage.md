# Step 5 leakage report: floor malting

Written under V2-PLAN §9.7 against the eight learner-facing files of
`authoring/floor-malting/statement/`. Bead `tla-h2cg.11`, rung 5 of batch 2,
task shape A, form 0, property kind 3. I didn't author the reference, the
statement or the traces. This is the adversarial second pass and it rewrites
nothing.

Author-only. This file names the grading split and every free pass I could
find, so it lives in `reports/` and never travels with the statement.

Part A below was written with the learner set in hand and nothing else, and
it was fixed before I opened `DESCRIPTION.md`, the reference or the author's
own screen. Wave 1's reviewers found they couldn't screen independently after
reading the answers side, so the order is the point.

## Part A: the screen, learner's eyes only

Shape A ships no spec, so Q1 and Q2 run in their first, action-centric form.

| # | Question | My answer |
|---|---|---|
| 1 | Hand over the legal moves. Anything left to model? | **Yes.** No model ships. The prose names three acts and fixes nothing behind them. |
| 2 | Actions given, or decided? | **Split.** The act names are given. What an act is, is decided. |
| 3 | What is asked? | **Is this design correct.** Seven requirements over the learner's own model. |
| 4 | Who works once it compiles? | **The learner models, TLC checks.** |
| 5 | Where does the difficulty live? | **Abstraction choice.** What the count is off the floor, what the subscript watches. |
| 6 | Agents, fallibility, interleaving? | **Several maltsters, uncoordinated, and neglect ruins a bed.** |
| 7 | Delete TLC, decision left? | **Yes.** The count at the boundary and the fairness shape are both arguable on paper. |
| 8 | Names an optimum? | **No.** A case-insensitive grep for the rubric's tells returns nothing, rc=1. |

Q2 gets both halves written down rather than one word. Turning, kilning and
throwing out are named in the prose, so the action set is handed over at the
level of names. The atomicity of taking a piece off and grading it, whether a
maltster carries state, and what happens to the count at the boundary are all
left open. §3.2 obliges a statement to fix the system, so naming the acts is
mandatory rather than a tell.

Zero clean puzzle rows of eight, one split. The threshold is three.

**KIND: ACCEPT, system.**

**R, the route.**

Intended route: design the state, decide how to render the two facts, write
seven formulas of the kind each requirement names, get the fairness right,
then hold the model against seven pairs.

Probes. Tiling gives nothing, since seven rules meet seven requirements one to
one with no holes. Vocabulary absence has no artifact to run against under
shape A. Elimination fires once. `Maltsters` is the one constant nothing
observes and nothing constrains, which quietly answers "do I need maltster
state" as no. The answer form is the loud one: keyword, formula kind and the
literal `[][A]_Observe` are all handed over, and the fairness demand is stated
down to "per piece, on the act that takes that piece off". Pre-clearing shows
up three times, at the marker warning, at the guard warning and at the
paragraph about not typing the count to the marks.

Shortest route found: three actions over two variables, `Observe` as the two
named fields, each requirement transcribed into the form the statement names,
the fairness conjunct the statement dictates, run TLC.

What survives is masking the count off the floor with every mark comparison
guarded, subscripting over the whole record, and the per-piece fairness. Those
three are ch11 material, and the statement hands over their shape and not
their formulas.

**ROUTE: ACCEPT, qualified.** The route is short and the narrowing is heavy. I
couldn't tell from the learner set alone whether the narrowing is sanctioned,
so I carried the question into Part B. Part B settles it, and section 5 below
says how.

## Part B: the answers side

### 0. The delivery boundary

The learner set is eight files, all under `statement/`:

```
statement/PROBLEM.md
statement/traces/pair-1.md ... pair-7.md
```

`statement/` holds those eight and nothing else
[`find authoring/floor-malting/statement -type f`, 8 lines]. No file in the
set names `authoring/`, `reference/`, `author-notes`, `reports/`, `FREEZE`,
`V2-PLAN`, a `tla-` bead id, a `§` section mark, `harness`, `Maltings`,
`VECTOR` or `DESCRIPTION` [two greps over the set, rc=1 on both].

The blind panel gets those eight files, named one by one. No directory and no
glob. `PROBLEM.md:17` points the learner at `traces/` as a location, which is
right for a learner holding a delivered directory and wrong for a panel brief.
The rest of `authoring/floor-malting/` sits one level up.

Twelve author-only paths sit outside the subtree:

```
DESCRIPTION.md, VECTOR.md
reference/Maltings.tla, reference/Maltings.cfg, reference/FREEZE.sha256
author-notes/ALTERNATIVES.md, author-notes/step4-trace-map.md
reports/step0-screens.md, reports/step0b-fit-review.md
reports/step2-variants.md, reports/step2-variants/, reports/step4-screens.md
```

`DESCRIPTION.md` §2 carries the seven must-be-trues in English and labels
their kinds, and §3 walks the sufficiency argument. That's the whole property
half of a shape A answer, and it sits where an `ls` finds it first. The
structural boundary holds, so I'm not calling it a defect. It's the same
finding qsl's step 5 raised about its own two copies, and I'd rather central
saw it twice than not at all. `reports/step2-variants/` holds the committed
seeded-bug modules, which are answer-adjacent for the same reason.

`PROBLEM.md` keeps the harness out of the learner's hands. It says to run TLC
at the checking instance and names no script, so no verdict channel is a
shortcut here.

### 1. Does the statement give away the state representation?

This is §9.7's own question and it goes first. My answer is no, with one
literal hit on the plan's own test that I don't think is a defect.

**The hit.** The reference's variables are `stage` and `modification`
(`reference/Maltings.tla:10`), and the statement's two `Observe` fields are
`stage` and `modification` (`statement/PROBLEM.md:117-120`). The reference's
operator is the identity over them,
`Observe == [stage |-> stage, modification |-> modification]`
(`reference/Maltings.tla:16`). So "a field named after a reference variable"
fires on both fields.

**Why I don't think it's a leak.** The causality runs the other way.
`DESCRIPTION.md` §5 records that at representation 2 the reference's variables
are the `Observe` fields and no others, and that central settled it. Grading
compares values by field name, so the names have to be handed over. The only
way to make this test come back clean is to give the reference variable names
that differ from its own interface, which is a disguise rather than a fix. I'd
report the test itself as misfiring at representation 2 whenever the reference
is the identity over `Observe`, and I'd leave the wording alone here.

The practical cost looks like zero to me. A learner who names their variables
after the fields lands on the reference's exact state, and that's one lawful
choice among the six forks `DESCRIPTION.md` §5 lists. Step 2's finding 3
measured a one-exit model reaching the reference's 216 states and passing all
eight obligations, so the forks aren't graded apart anyway.

**The closest thing to a real leak.** Requirement 7's second paragraph
(`statement/PROBLEM.md:213-218`) says the `Spec` needs a weak fairness
conjunct per piece, on a maltster's act of taking that piece off the floor,
whether the act is a kilning or a throwing out. That's the reference's
`Remove(m, p) == Kiln(m, p) \/ ThrowOut(m, p)` and its
`\A p \in Pieces : WF_vars(...)` described in prose
(`reference/Maltings.tla:40,50`). It names a decomposition present in the
reference, which is what §9.7 asks me to flag.

I still don't think it's a defect, for two reasons. `DESCRIPTION.md` §2 states
the same demand in the same words to the reference author, and §3.2 lets the
description fix the system, so the statement is passing on a requirement
rather than reading the code. And §5's fairness fork is only about which exit
shape the conjunct sits on, with per-piece fixed either way. The statement
fixes the fixed half and leaves the open half open, which is the right split.
There's also no wording that states the obligation without describing the
disjunction, since the obligation is the disjunction.

**The other six forks, one line each.** None is forced.

- Modification as counter, sequence or set: the field's shape is a count, and internal state stays free.
- Place as status or partition: same, the field is a function and the state behind it isn't.
- The loss as one exit act or two: `Observe` shows where a piece went, never how.
- The marks as constants, a set or predicates: the cfg names two constants, and their use is free.
- Maltsters as a process set or bare actions: `Observe` shows no maltster at all.
- Fairness: covered above.

The maltsters fork is worth one prose line, since a PlusCal process set adds a
program counter and pushes the reachable count past 216. `PROBLEM.md:263` says
more than 216 is fine and names carrying an extra fact as the reason, so the
statement keeps that side of the fork open on purpose.

**Sentences I flagged and cleared.** Rule 6's "the count belongs to the bed
lying on the stones" fixes an observable that requirement 2 grades, so it's a
rule and not a structure. "No two act at once" is an atomicity claim, and
requirement 3 is its graded form, so §3.2 covers it. The `NoCount` model-value
paragraph reproduces the reference's fifth constant and its cfg line, and the
plan's own field question asks for exactly that. The 216 arithmetic reproduces
`DESCRIPTION.md` §4, and it's derivable from the interface the learner already
holds, six records per piece over three independent pieces.

### 2. The fields

Stated as facts, in a maltster's words, with the shapes pinned and nothing
more. `stage` is a function from `Pieces` to the three place values in rule
1's order. `modification` is a function from `Pieces` whose values are a
natural number or `NoCount`, with `NoCount` declared as a model value. That
matches what §9.7 asks a field to carry.

Two paragraphs go past the shapes and both earn it, I think. The marker
warning and the guard warning are honesty about how TLC fails, and without
them a learner reads an evaluation error as a property failing. The paragraph
telling the learner not to type the count to the marks hands over what
`DESCRIPTION.md` §3 calls the one real decision in the operator. That one is a
real transfer of judgment. I'd still keep it, since the alternative is a
learner writing `TRUE` in a costume and getting a green run that nobody can
read as wrong from the outside.

### 3. The pairs

The traces render the two `Observe` fields as state values in the domain's
words, states only. No action name, no formula and no obligation name appears
in any of the seven files. Nothing in them reveals a representation.

Each violating half breaks its own requirement and nothing simpler. I walked
all seven against the reference's eight cfg lines:

| pair | breaks | also breaks |
|---|---|---|
| 1 | `Opening` | nothing, one state, no action property can fire |
| 2 | `CountBelongsToTheFloor` | nothing, `TypeOK` stands since 0 is a natural number |
| 3 | `OnePairOfHands` | nothing, each piece moves by one |
| 4 | `TurningAddsOne` | nothing, 2 is under the mark |
| 5 | `GoodMaltComesFromReady` | nothing, only p1's record changes |
| 6 | `OffTheFloorIsFinal` | nothing, every state satisfies the count rule |
| 7 | `TheFloorGetsCleared` | nothing, the prefix is lawful |

The statement fixes all seven forms, so the pairs carry no kind information
the statement withheld. Under shape A their job is §3.9's second direction,
and pair 7's allowed half is the sharpest of them. It takes the last piece off
at `UpperMark`, so a model that forbids a piece sitting at the mark passes
every check and can't produce that run.

One pair under-witnesses its requirement, and section 6 carries it as a
grading-split entry rather than a defect.

### 4. The vector record

Six dimensions, and every citation resolves to a line that says what the
record says it says. I read each cited line rather than trusting the range.

- representation 2: `PROBLEM.md:20` declines to ship a model, `112-126` is the interface, `Maltings.tla:10,16` is the identity operator.
- property kind 3: `Maltings.cfg:16-22` is the six properties, `Maltings.tla:50` the fairness conjunct, `98-100` the leads-to.
- property count 2: `Maltings.cfg:12-22` is eight declared lines, two invariants and six properties.
- step sources 1: `PROBLEM.md:38-42` is one kind of party, `Maltings.tla:43` is the single existential.
- state space 0: `step2-variants.md:144` reports 216 distinct from 2,377 generated, and `PROBLEM.md:259` quotes the 216.
- form left open 0: all eight cited lines hand over a keyword, a kind or a subscript.

The fairness paragraph at `PROBLEM.md:213-218` sits outside the form-0
citation set. I think it belongs there, since it's the same class of handover
as the eight lines that are cited, and it's the largest one on the page. That
reads to me as a citation gap in the record rather than a level being wrong.

`sha256sum -c reference/FREEZE.sha256` returns OK on both frozen files.

`bash harness/test-vector.sh` ends `FAILED: 30 passed, 2 failed`. The
floor-malting row passes. The two failures are
`authoring/assay-office/VECTOR.md` and `authoring/estate-notice/VECTOR.md`,
both missing at the base I branched from, so they're a fact about sibling
packages frozen ahead of their records rather than about this one.

### 5. Notes for central, not defects

**Form 0 sanctions the narrowing, and it's worth saying how far.** Part A left
this open and the vector settles it. Every keyword, every formula kind and
every subscript is given, plus the fairness conjunct's shape. Once the state
exists, the seven formulas are close to transcription. That's the level the
rung asks for, so the whole of this problem's judgment sits in the state and
the step rules. No reword moves any of it back, and I'd expect a step 6 panel
to spend most of its time on the marker and the guard rather than on the
properties.

**Pair 5 tests one side of a two-sided window.** Requirement 5 grades both
marks in one line, and `DESCRIPTION.md` §5 says the late side is half of why
this domain was picked. Pair 5's forbidden run is an unturned piece coming out
as good malt, which is the early side. A property carrying only
`modification >= LowerMark` passes the checking instance and rejects that run.
The late side has no pair. I'd have the grader ask for both halves rather than
read a pair 5 rejection as proof, and section 6 says so.

**The `expiry` row is still standing.** `harness/screen.sh:115` returns BURNED
on any S4 phrasing carrying the bare word. Neither the statement nor either
step 4 phrasing uses it, so the row didn't fire. That's a workaround rather
than a clearance, and it's the step 0 finding standing.

**My screen agrees with the author's, row for row.** I wrote Part A first and
read `reports/step4-screens.md` afterwards. Agreement bought less than I'd
like, which is what §5.7b predicts about a rubric with answer columns. What I
added is the fairness handover and the pair 5 gap, and both came from going
off the card.

### 6. The grading split

For each requirement, what carries it and what passes the shipped instance
without carrying it. Step 6's spread rule consumes this pair.

| # | Carries it | Passes without carrying it |
|---|---|---|
| 1 | Both halves, every piece on the floor and every count 0, under `PROPERTY` | The stage half alone, which accepts pair 1's forbidden run |
| 2 | Both directions, floor implies a count at or under `UpperMark`, off-floor implies the marker | The ceiling clause alone, which accepts pair 2's forbidden run |
| 3 | Any piece's record changing forces every other piece's record unchanged | The same formula subscripted over `Observe.stage`, which every turning slips past |
| 4 | Floor before and after implies the count keeps or gains exactly one | A monotone `>=` clause, which accepts pair 4's forbidden run |
| 5 | Becoming malt implies floor before, at or above the lower mark and below the upper | The lower half alone, which still rejects pair 5's forbidden run |
| 6 | Off the floor implies both fields unchanged | The stage half alone, which requirement 2 then has to catch |
| 7 | For each piece, on the floor leads to off it, over `Observe`, under `PROPERTY` | Covered below, the free pass is on the `Spec` side |

Row 5 is the one where the shipped pair doesn't separate the two columns. A
learner writing the lower half alone gets a green run and a clean pair sweep.
Grading has to read the property rather than the verdict there.

Row 6's free pass is sound in combination. An off-floor piece whose count
moves breaks requirement 2, so a stage-only requirement 6 plus a full
requirement 2 is a complete set. I'd log it as sound-and-extra rather than
missed.

**What counts as the fairness being right, at kind 3.** The conjunct has to be
per piece and has to name a step whose effect is that piece leaving the floor.
Weak fairness over the whole next-state relation clears this floor too, since
rule 3 caps the turnings and the rest of a maltster's acts are removals. So it
passes the instance and it isn't what rule 7 says. That's the free pass to
catch, and the statement pre-empts it in so many words.

Two forms I'd mark right rather than wrong. A one-exit model puts the conjunct
on its single removal act, which is the fork `DESCRIPTION.md` §5 leaves open.
A two-exit model that puts it on the kilning alone obliges more than rule 7
asks and still satisfies the property, so I'd log that as sound-and-extra.

### 7. Verdict

**SHIP.** No defect. The statement doesn't give away the state representation,
all six forks stay open, the pairs carry targets rather than formulas, and the
delivery boundary holds at eight files.

Two things go downstream rather than back. Pair 5 witnesses one side of a
two-sided window, so the grading split above is what catches the other side.
And the vector's form-0 row should cite the fairness paragraph alongside its
eight lines, which is a record fix and not a statement fix.
