# Step 5, leakage check: assay-office

Rung 4 of batch 2, bead `tla-h2cg.10`, spec `AssayOffice`. Grid cell S5, shape B, form 0,
kind 3. I did not write the reference, the statement, or the traces. This is the
adversarial second pass.

The report runs in the order I worked. Part A is the puzzle screen, and I wrote it down
before I opened a single file on the answers side. Part B is everything that needed the
reference, the trace map and the plan.

## Part A: the puzzle screen, learner's eyes only

What I had read at this point: `statement/PROBLEM.md`, `statement/AssayOffice.tla`, the
three files under `statement/traces/`, and `harness/PUZZLE-SCREEN.md`. Nothing else.

Shape B hands the learner a spec, so Q1 and Q2 run in their second form, about
requirements rather than actions.

**Q1, spec-in-hand.** Hand the learner the spec and the rules it's measured against. Is
anything left to model? **System.** Three formulas over `Observe`, and none of them is
written down anywhere. The learner has to read the module for its own names for the
findings, because `PROBLEM.md` withholds them on purpose at lines 115 to 117. They also
have to see that `Observe` is a record of functions, so the formula is `Observe.marked[w]`
and not `book[w].struck`.

**Q2, spec-in-hand.** Are the requirements given as formal claims, or must the learner
decide what a requirement is? **Split**, and the rubric tells me to write both halves down
rather than collapse them to one word.

Given on shape. Each requirement names its keyword, its kind, and its subscript, at lines
133 to 134, 142 to 148 and 154 to 155. The state-predicate against transition-property
classification is handed over. That's form 0 by construction, and it isn't a defect.

Decided on content. Requirement 1's own last sentence, "So no ware is both struck and
defaced", is the weak consequence of the two clauses above it. A learner who writes only
that passes the model and passes pairs 2 and 3, and fails pair 1's forbidden run. Working
out which sentence is the property is real judgment.

**Q3.** What's being asked? Say what must be true about a design. **System.**

**Q4.** Who works once the spec compiles? The learner writes three formulas, TLC checks
them. **System.**

**Q5.** Where does the difficulty live? Abstraction choice. The run finds 125 states, so
there's no search difficulty at all. **System.**

**Q6.** How many agents, and can they fail, stall, or interleave? Two interchangeable
officers with free interleaving, said outright at lines 37 to 42. They're fallible by
stalling rather than by erring, since nobody mis-assays. That's thin, and stalling is
exactly what requirement 3 is about. **System.**

**Q7.** Delete TLC. Is there a modeling decision left to defend? Yes. Whether requirement
1's third sentence is the property or a consequence of it is arguable without a checker.
**System.**

**Q8.** Does the statement name an optimum? No. **System.**

Tally: eight rows, no clean puzzle answers, one split. The threshold is three.

**KIND: ACCEPT, system.**

### R, the route

**The route I think the problem is for.** Read the module for its finding names and the
shape of `Observe`. Write each requirement as a formula at the altitude its rule sits at.
Run TLC under `FairSpec`. Then hold the three formulas against the three trace pairs and
fix whichever one lets a forbidden run through.

The six probes:

- **Tiling.** Three requirements, three pairs, and line 171 says the mapping is one to
  one. That aims the self-check rather than the answer.
- **Vocabulary absence.** "Fineness" is scene-setting, used once, and disclaimed at line
  11. No repeated technical noun is missing from the artifact.
- **Elimination.** All three `Observe` fields are carried by two or more requirements. No
  lonely field, so no elimination shortcut.
- **Answer form.** Narrows hard. Keyword, kind and subscript for all three, which is what
  form 0 means.
- **Pre-clearing.** Two of them. Lines 145 to 148 warn off subscripting over a single
  field. Lines 157 to 167 explain where the obligation comes from.
- **Recall.** A monotone record with a per-item discharge obligation. I found no corpus
  prior worth naming.

**Shortest route I found.** A learner fluent in `~>` and `[][A]_vars` writes all three in
a few minutes. An implication pair for requirement 1, a per-ware monotonicity conjunction
for requirement 2, and a leads-to under `\A w` for requirement 3.

**Does it use the judgment the problem is for?** Mostly, and the two places it bites are
earned rather than advertised. Requirement 1's weak-consequence trap is caught by pair 1's
forbidden state and by nothing in the prose. Requirement 2 needs a guard on the finding
clause, because `none` to `atStandard` is a legal change, and the unguarded equality
fails against the model itself.

**The reservation.** The kind-3 judgment, fairness, is largely handed over in prose. Lines
157 to 167 name `FairSpec`, say it's `Spec` plus a fairness conjunct, tell the learner to
read which step it obliges, and pre-clear the failure that naming `Spec` would cause. The
learner reads the fairness rather than deciding it. Form 0 licenses the shape hand-over,
and I still think it's worth flagging for step 6. If blind critics converge fast on
requirement 3, that block is why.

**ROUTE: ACCEPT**, with the fairness reservation above on the record.

## Part B: the answers side

Everything below was written after I read `V2-PLAN.md` section 9.7, the house form at
`authoring/qsl/reports/step5-leakage.md`, rung 3's report at
`authoring/bonded-store/reports/step5-leakage.md`, `DESCRIPTION.md`, the frozen
reference and its cfg, `reports/step2-variants.md`, `author-notes/step4-trace-map.md`,
`reports/step4-screens.md` and `VECTOR.md`.

Section 9.7's own question is whether the statement gives away the state
representation. Shape B answers that before anybody writes a word. The learner gets the
spec, so the representation is handed over on purpose, and the frame comes out empty
here the way it did on both earlier rungs. So I ran qsl's three questions plus the
plan's own two.

**Verdict: SHIP after D1.** One clause of requirement 1 has no forbidden run, and the
fix is one added pair from a variant that's already committed. Everything else I found
is a note.

### 1. The strip

The reference and the statement differ in three hunks and nothing else [`diff -u`,
rc=1]. Two hunks delete the same four operators, once from the PlusCal define block and
once from the translation: `TypeOK`, `MarksFollowTheFinding`, `TheRecordOnlyGrows` and
`SubstandardIsDefaced`. Those are exactly the four the cfg declares at
`reference/AssayOffice.cfg:7-8,10-11`. The third hunk is the `BEGIN TRANSLATION`
checksum pair, which moved from `a832d6c1`/`d50646b` to `a9da77da`/`fa8830eb`. That's
the right kind of change. It says the translation was regenerated from the edited
PlusCal rather than hand-cut. The frozen reference is the one the hashes name
[`sha256sum -c FREEZE.sha256`, both OK, rc=0].

Nothing leaked back in. The stripped module carries two comment lines and both are
stock PlusCal, `BEGIN TRANSLATION` and `END TRANSLATION`. The one line with trailing
whitespace is `\* END TRANSLATION `, and the reference carries the same line with the
same trailing space [`grep -n ' $'` on both, one hit each]. So there's no whitespace
fingerprint marking where the block came out.

**No orphan operator, which is better than rung 3 managed.** Every definition that
survives has a live consumer. `Findings` feeds the test branch of `officer`, and
`Deface` feeds `FairSpec`. `Observe` has no consumer in the system half, and that's the
point of it rather than a fingerprint, since `PROBLEM.md:107-108` announces it as the
office's public face. Rung 3 left `Places` reading nothing and its checker named it. I
looked for the same thing here and there's nothing to name.

The stripped module stands on its own. With the three requirements written correctly
and the cfg `PROBLEM.md:191-198` tells the learner to write, it reports "Model checking
completed. No error has been found", 601 states generated, 125 distinct, depth 7
[`tlc -workers 1 -deadlock`]. That's the number `PROBLEM.md:200` publishes, so the
tamper check holds.

### 2. Handed-over renderings

`PROBLEM.md` carries exactly one TLA+ operator form in the whole file, the skeleton
`[][A]_Observe` at line 142 [grep for ten operator forms, one hit, plus a separate grep
for the conjunction operator at rc=1]. What it hands over besides that is the keyword,
the kind and the subscript target for each of the three. That's form 0's definition,
and the formula body is left alone in all three cases.

The fairness conjunct is visible at `statement/AssayOffice.tla:84`, and it has to be.
Pair 3's forbidden run is a legal `Next` sequence followed by a stall, so the only
thing that makes it not a behavior is the conjunct. Without it in view the pair would
be unjustifiable. `PROBLEM.md` never writes the fairness operator, and it tells the
learner to go read `FairSpec` instead. That's the handling qsl used and it holds here.

**The transcription defence is real, and it's stronger than rung 3's.** The module
declares one variable, `book`, a function from ware to a record of `verdict`, `struck`
and `damaged` (`statement/AssayOffice.tla:41,47-49`). `Observe` renames all three and
turns a record of fields into a field of functions. So `Observe.finding[w]` is a
crossing from state to interface rather than an identity, which is what
`DESCRIPTION.md:275-280` asked for. Rung 3's `Observe` was the identity over its state
and its own checker said so. This one isn't.

**One thing the author's route analysis is right about, and I want to sharpen it.**
`step4-screens.md:186-189` says the three finding names are withheld from the statement
and the traces print the rules' English, so the lookup stays a lookup. Rung 3's checker
found the same withholding worth almost nothing there, because camel-casing the trace
words reconstructed the module's strings. Check the same move here. The traces print
"not tested", "at standard" and "substandard". Camel-case those and two of three land,
and the third is wrong, because the module calls it `"none"`. So a learner who never
opens the module gets one name in three wrong and their run fails on it. The
withholding earns more here than it did at rung 3, and I think that's the module's
naming rather than the author's wording.

### 3. The pairs

I hand-checked all six runs against `Init` and `Next`, and each forbidden run against
all three requirements.

| pair | forbidden run breaks | and nothing else |
|---|---|---|
| 1 | requirement 1, the `marked` clause, at the opening state | 2 has no step to judge. 3 has no substandard finding |
| 2 | requirement 2, the finding-stability clause | 1 holds at every state, nothing is marked or defaced. 3 never leaves a substandard finding standing |
| 3 | requirement 3, through the tail alone | 1 holds, both marks follow their findings. 2 holds, every change is a legal growth |

That matches what the trace map claims at `author-notes/step4-trace-map.md:80-89`. All
three allowed runs are legal step sequences from `Init`. The author machine-validated
those against the stripped spec at rc=12 three of three with an rc=0 control
(`step4-trace-map.md:73-76`). [INFERRED for my own pass. I walked the six runs by hand
and didn't rerun the trace-forcing validator.]

No pair file names a rule, a kind, an obligation or a formula. A sweep for any line
that isn't a heading, a fence, a `State N`, an `Observe` field or the one shared
sentence returns three lines across all three files, and they're the single stall
passage at `pair-3.md:63-65` [`grep -rvn` with the boilerplate pattern]. That passage
is sanctioned by `PROBLEM.md:174-175` and it can't be removed, because a finite
rendering of an infinite stall has to say it stalls.

It does hand the learner the pair-3-to-requirement-3 mapping, since `PROBLEM.md:174`
names requirement 3 by number and only one trace has a tail. I don't think that costs
anything. `PROBLEM.md:32-33` already tells the learner to hold all three properties
against every run, so knowing the mapping doesn't change what they do.

### 4. The delivery boundary

Five files reach a blind panel seat, all under `statement/`:

```
statement/PROBLEM.md
statement/AssayOffice.tla
statement/traces/pair-1.md ... pair-3.md
```

`statement/` holds those five and nothing else [`find`, 5 lines]. Grepping the set for
`authoring/`, `reference/`, `author-notes`, `reports/`, `FREEZE`, `V2-PLAN`, `tla-` and
a section mark returns nothing [rc=1]. A second sweep for `harness`, `grader`,
`grading`, `rubric`, `obligation`, `verdict.sh`, `Gate.tla`, `screen`, `frozen`,
`bead`, `shape B`, `form 0`, `batch`, `rung`, `variant`, `seeded`, an `Sxx` or `P0x` id
and `rc=` returns five hits, all benign. `PROBLEM.md:96,157,162` use "obligation" as
the learner's own English for rule 4's duty, `:119` is the learner's grading contract,
and `:134` matched on the word sitting inside `INVARIANT`. A third sweep for the four
reference obligation names returns two hits, both `Deface` at
`statement/AssayOffice.tla:77,84`, which is the fairness conjunct and belongs there.

Seventy-six author-only files sit outside the subtree, and `DESCRIPTION.md:97-109` is
the graded answer in English with its kinds labeled. The structural boundary holds, so
this isn't a defect. Two things about the shape of the exposure are worth central
knowing.

There's one answer key here rather than qsl's two. No `HANDOFF.md` in this package, so
the duplication qsl's checker flagged didn't recur.

Against that, `reports/step2-variants/` holds 22 complete copies of the reference
module, each carrying all four obligations verbatim in TLA+. So the answer key exists
in executable form 22 times over, not once in English. That's good for the pipeline and
it raises the cost of a loose brief. Rung 3's checker asked for the panel brief to name
its files rather than a directory. I'd ask for it harder here.

**Name all five files in the step 6 brief. No directory, no glob.** `PROBLEM.md:18`
points the learner at `traces/` as a location, which is right for somebody holding a
delivered directory and wrong for a panel brief.

### 5. The grading split

Section 9.7 wants this before any blind agent runs. Per requirement, what counts as
carrying it, and what passes every signal the problem gives without carrying it.

**Requirement 1.** Carrying it is both implications over every ware. Two weakenings
survive the model, and the pairs separate them.

The weakest form is the requirement's own last sentence, no ware both struck and
defaced. It's sound on the model [`verdict.sh`, `OK`, rc=0] and pair 1's forbidden run
catches it, because every ware there is struck and none is defaced, so the no-both form
holds and the learner's hand-check fails. That trap is closed, and it's the sharpest
thing the pair set does.

The `marked`-clause-only form isn't caught by anything. It's sound on the model
[`verdict.sh`, `OK`, rc=0, with correct requirements 2 and 3 alongside], and it rejects
pair 1's forbidden run, so the hand-check passes too. This is D1.

**Requirement 2.** Carrying it is all three clauses, with the guard on the finding, and
subscripted over the whole of `Observe`. Pair 2's forbidden run covers the finding
clause. Neither monotonicity clause has a forbidden run, because no forbidden run in
the set ever erases a mark or undoes a defacing. See N1.

The subscript isn't gradable at all here. A requirement 2 subscripted over
`Observe.marked` passes the model and passes all three pairs, since pair 2's forbidden
step leaves `marked` alone. `PROBLEM.md:145-148` closes that by instruction rather than
by measurement, which is what `step4-trace-map.md:90-95` says it's for. I agree with
keeping it, and the grader should know the learner was told rather than tested.

**Requirement 3.** Carrying it is the leads-to over every ware, with the substandard
finding as the antecedent. Pair 3's forbidden run covers it. The over-general form,
every ware eventually defaced, fails on the learner's own run [`verdict.sh`,
`LIVENESS_VIOLATION`, rc=13], so a learner who over-generalizes gets told by TLC rather
than by a pair. That's the healthiest feedback shape in the problem and it confirms
`step4-screens.md:143-146`.

**The fairness, at kind 3.** The learner writes no fairness. What counts as getting it
right is naming `SPECIFICATION FairSpec` in the cfg, and `PROBLEM.md:164-167` says so
outright. I verified the failure it promises. The correct three requirements under
`SPECIFICATION Spec` come back `LIVENESS_VIOLATION` at rc=13 [`verdict.sh`], so the
paragraph is true about this spec. It also means the fairness half of kind 3 is an
instruction followed rather than a judgment made, which is the reservation I recorded
in Part A before I knew the author's own notes agreed.

**Where the spread lives.** Pair verdicts settle requirement 1's `marked` clause,
requirement 2's finding clause, and requirement 3 in full. Everything else has to be
read off the formula: requirement 1's `defaced` clause until D1 lands, requirement 2's
two monotonicity clauses, and the subscript. I measured the extreme case. A submission
carrying only the three clauses the pairs exercise, and dropping the other three,
passes TLC at rc=0 and rejects all three forbidden runs [`verdict.sh`, `OK`, rc=0]. Two
learners can hand in property sets of visibly different strength with identical
verdicts on every check the statement asks for, and that gap is the whole spread.

### 6. VECTOR.md

Six rows, and every citation resolves to a line that says what the record says it says.
I checked each by hand [`sed -n` over each cited range].

Representation 1 cites `PROBLEM.md:16-17`, the "what you get" lines naming the shipped
model. Property kind 3 cites `cfg:1` and `cfg:11`, which are the `FairSpec`
specification line and the leads-to obligation, plus
`reference/AssayOffice.tla:89,124-126`, which are the leads-to itself and the whole of
`FairSpec`. Property count 1 cites `cfg:6-11`, which holds four obligation lines, and
four sits in band 1. Step sources 1 cites `PROBLEM.md:37-43`, the parties paragraph,
and `reference/AssayOffice.tla:39`, the single process set. State space 0 cites
`step2-variants.md:139,180-182`, which carry the vector row and the 125 distinct count.
Form left open 0 cites the three places the statement fixes the kind, the shape and the
subscript.

`bash harness/test-vector.sh` final line: **`FAILED: 31 passed, 1 failed`**.

The assay-office row passes: `PASS authoring/assay-office/VECTOR.md records the package
frozen at authoring/assay-office/reference/FREEZE.sha256`. The one failure is
`authoring/estate-notice/VECTOR.md: missing file`. Central told me to expect a sibling
frozen without its record yet, and it isn't mine either way, but the cause turns out to
be my own base rather than a gap in that package.

`authoring/estate-notice/VECTOR.md` is on `main` [`git cat-file -e`, rc=0]. My branch
base is 13 commits behind `main` [`git log --oneline <base>..main`, 13 lines], so the
file landed after I branched and my worktree never had it. I'd expect the suite green
on a current base.

That's the second time this shape has been recorded. Rung 3's checker hit it on
`authoring/laytime/VECTOR.md` and wrote it up as a sibling mid-pipeline before
correcting itself. A stale base makes a suite report a missing file the same way it
makes `git diff --stat main HEAD` report deletions you never made, and both read as
your own bug. I think it's worth a line in the step 5 brief, since two checkers in a
row have now had to work it out from scratch.

### 7. The defect

**D1. Requirement 1's `defaced` clause has no forbidden run.** No state in any of the
three forbidden runs has a defaced ware. The only defaced ware in the whole trace set
sits at `pair-3.md:26`, three lines above that file's `## Forbidden` heading, so it's
in the allowed run [`grep -rn 'w[123] defaced'`, one hit, against `grep -rn '## Forbidden'`].

The consequence is a learner who writes the `marked` implication and stops. Their
property is sound on the shipped spec, TLC passes it, and their hand-check against the
three pairs passes too, because the `marked` clause rejects pair 1's forbidden run on
its own. They've written half of requirement 1 and every signal they have says they're
done. [`verdict.sh -t 300` on the stripped spec with that property plus correct
requirements 2 and 3, `OK`, rc=0.]

Step 2 measured this from the other side and nobody joined the two records. Finding 6
says the one-sided form "misses a whole institution". Drop the `defaced` clause and
S02, which lets an officer deface a ware found at standard, goes from rc=12 to rc=0
over 343 distinct states (`step2-variants.md:431-441`). That's the widening the author
made over the screener's sketch, and it's load-bearing by measurement. The pairs don't
test it.

**Fix: one more pair, and the material is committed.** S02 is the pick and I re-ran it.
Its counterexample is three states: all wares untested, then w1 found at standard, then
w1 defaced while still at standard [`tlc -workers 1 -deadlock S02.tla`, "Invariant
MarksFollowTheFinding is violated", 15 generated, 9 distinct]. It breaks requirement 1
and nothing simpler. I confirmed that by running S02 against requirements 2 and 3
alone, with the invariant dropped, and it comes back `OK` at rc=0 [`verdict.sh`].

I'd take S02 over S03, the other candidate. S03 strikes a substandard ware, which
breaks the `marked` clause that pair 1 already covers. S02 is the only committed
variant whose counterexample reaches the untested half.

**Arrow: step 4, the pairs.** Nothing frozen moves, the reference doesn't change, and
the load vector doesn't move, since property count reads cfg lines rather than pairs.
The cost is one sentence in `PROBLEM.md`'s trace section, because four pairs for three
requirements needs a line saying so, the way line 171 currently says three.

### 8. Notes for central

**N1. Requirement 2's two monotonicity clauses have no forbidden run either.** Same
shape as D1 and I'm filing it a step lower, with the reason. No forbidden run erases a
mark or undoes a defacing, so a learner who writes only the finding-stability clause
passes everything. Step 2's finding 7 measured all three clauses load-bearing.
`TheRecordOnlyGrows` fires on S04, S05, S06 and S07 (`step2-variants.md:459-465`), and
only S04 ships as a pair. S06 at rc=13 in 4 states and S07 at rc=13 in 4 states are the
committed material if central wants the coverage (`step2-variants.md:250-251`).

Why lower than D1. Requirement 2's English at `PROBLEM.md:137-139` states all three
clauses in three separate sentences, so a learner has to actively drop two to land
thin. Requirement 1's third sentence reads as a summary of the two above it, which
invites the collapse. That's a difference in how likely the weakening is, not in
whether it's catchable, so central may reasonably take both fixes or neither. I'd take
D1 and leave this one to the rung's budget, since this rung's design is that everything
except the liveness stays quiet.

**N2. `Deface(o, w)` never uses `o`.** The definition at
`statement/AssayOffice.tla:77-80` reads only `book[w]`, so the fairness conjunct is the
same formula as a per-ware one with no officer binder. The officer quantifier is
decoration.

That's honest rather than wrong, because the actions are officer-agnostic too. The
translated `officer(self)` never reads `self` either (`:60-69`), so there's no such
thing as "that officer's defacing action" in this model, and the reference delivered
the closest available thing to what `DESCRIPTION.md:112-114` asked for.

It matters in two smaller ways. `step2-variants.md:143-145` reads the conjunct as
fairness on a named step per party, and the per-party half doesn't hold. And
`PROBLEM.md:162` sends the learner to read `FairSpec` for "what the obligation is
quantified over", so a learner will read a per-officer obligation that isn't one. The
vector doesn't move either way. Kind 3 asks for a leads-to plus a fairness conjunct and
both are there, and step sources 1 is right because a universal quantifier over
`Officers` isn't a named party under weak fairness.

**N3. Two prose claims I checked because their siblings turned out false.** qsl's D1
was a false deadlock paragraph, so I ran this one. `PROBLEM.md:194-198` says a default
run reports the story's ending as an error, and it does. The correct submission with no
`CHECK_DEADLOCK` line comes back "Deadlock reached" [`tlc -workers 1`], so the
instruction earns its place. And `PROBLEM.md:200`'s 125 distinct states is the number a
correct learner run produces, at 601 generated and depth 7 [`tlc -workers 1 -deadlock`].

### 9. Verdict

**SHIP after D1.** Add a fourth pair from S02 and the five files are fit to go to a
blind panel.

The strip is clean: three hunks, four operators, a regenerated checksum, no comment, no
whitespace tell and no orphan operator. `PROBLEM.md` hands over one TLA+ form in the
whole file and it's form 0's own skeleton. The pairs carry targets and no formulas, and
the one non-boilerplate passage in three files is a stall marker the shape requires.
Every boundary sweep comes back empty or benign. Both screens accept, KIND at zero
clean puzzle rows of eight, and ROUTE on the finding that the two traps which bite are
caught by the pairs and by TLC rather than advertised in the prose.

What I'd want a reader to carry past the verdict. D1 and N1 are the same finding twice,
and rung 3's checker filed a third instance of it on a different problem. A trace pair
witnesses one clause, and an author who picks one pair per requirement ships coverage
for one clause of each. I think that's worth a line in the step 4 recipe rather than a
third leakage report finding it, because the pair count is chosen from the requirement
count and the requirement count isn't the clause count.
