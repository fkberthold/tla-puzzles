# Step 5 leakage report: the bonded store

Bead `tla-h2cg.7`, step 5 of the section 6 pipeline. I didn't write the
reference, the statement or the traces. This is the adversarial second pass.

The report runs in two parts, in the order I worked. Part A is the puzzle
screen with learner's eyes only, and I wrote it down before I opened
`V2-PLAN.md`, the reference, or any of the step 2 to step 4 records. Part B
is everything after that. The wave 1 reports found that a checker who reads
the answers side first can't screen independently afterwards, so the order
is the point and I'm recording that I held it.

## Part A: the screen, learner's eyes only

What I had open for this part: `statement/PROBLEM.md`,
`statement/BondedStore.tla`, and the four files under `statement/traces/`.
Nothing else. The instrument is `harness/PUZZLE-SCREEN.md`, and this is a
shape B problem, so Q1 and Q2 are the requirement-centric pair.

### Q1 to Q8

| # | Question | My answer |
|---|---|---|
| 1 | Hand the learner the spec and the rules it's measured against. Anything left to model? | **System, narrowly.** Requirements 2 and 3 need a per-lot movement guard that nothing in the set supplies. Requirement 1 doesn't need anything. |
| 2 | Are the requirements given as formal claims, or must the learner decide what a requirement is? | **Split, and I'm counting it as given.** The classification is performed for the learner at lines 108, 120 and 134. The formula body is decided. |
| 3 | What's being asked? | **System.** Write the properties that say what must be true, not "is the goal reachable". |
| 4 | Who does the work once the spec compiles? | **System.** The learner writes three formulas and TLC adjudicates. |
| 5 | Where does the difficulty live? | **System.** Abstraction choice, in what counts as a lot moving. Half of it is handed over at lines 124 to 127. |
| 6 | How many agents act, and can any fail, stall or interleave? | **Puzzle.** One keeper, infallible, no clock, nothing goes wrong. Lines 36 to 38 say so in as many words. |
| 7 | Delete TLC. Is there a modeling decision left to defend? | **System.** Whether requirement 2's arms need a movement guard, and what the whole-Observe subscript lets through. |
| 8 | Does the statement name an optimum? | **System.** No optimum, no minimum, no best. |

Two puzzle rows out of eight, against a threshold of three.

**KIND: ACCEPT, system.** Q6 is a real puzzle answer and I'm not softening
it. One infallible actor with no clock is on the rubric's own tell list. It
doesn't sink a shape B problem, because the learner isn't being asked to
decide what the actions are, but it does mean the whole difficulty budget
sits on the requirements and there's no second source of hardness if they
turn out thin.

Q2 is the row I'd argue about. The rubric says the judgment shapes B, C and
D exist to teach is deciding which stated rules are state predicates, which
are transition properties, and which the vocabulary can't carry at all.
This statement performs all of that in advance. Requirement 1 is labeled a
state predicate and assigned to `INVARIANT`. Requirements 2 and 3 are
labeled action properties, assigned to `PROPERTY`, and given the shape
`[][A]_Observe` outright. So I wrote both halves down rather than
collapsing them, the way the rubric asks.

### R: the route

**Intended route**, taken from the statement's own numbered task list at
lines 27 to 32. Read the module. Work out how it carries the nouns the
rules use. Write each requirement as a formula over `Observe`. Declare each
one. Run TLC. Hold the three against the traces.

**Shortest route I found.**

1. Skip step 1. The interface section at lines 88 to 92 already names both
   `Observe` fields, so there's nothing to work out there.
2. Guess the four place values from the statement's own English. "Not yet
   entered" gives `notEntered`, "in the store" gives `inStore`, "released
   for home consumption" gives `released`, "moved on under bond" gives
   `movedOn`. Confirm all four with one look at line 38, which enumerates
   them in the same order rule 1 does.
3. Transliterate requirement 1. "A lot's duty is paid exactly when that lot
   has been released" goes straight to a biconditional over the two fields.
   The kind and the keyword are given, so nothing is decided.
4. Requirements 2 and 3 arrive with their temporal skeleton and their
   subscript already fixed. What's left is the guard, and I think that part
   is real work.

**Does the route use the judgment the problem is for?** Partly. It doesn't
use the classification judgment at all, because the statement does it. It
does use the guard judgment, and the guard is the only place a learner can
get this wrong in an interesting way.

**Where the shortcut lives.** In the prose, at lines 108 to 109, 120 to
122, 124 to 127, and 134 to 136. A reword closes it. That matters for what
a fix would cost, and I'll come back to it in Part B, because handing over
the kind may well be deliberate for the easiest rung of a ramp.

**ROUTE: ACCEPT, narrowly.** The shortest route I can find still goes
through the guard, and the guard is what the problem is for. My reservation
is that one of the three requirements is reachable by transliteration, so
the problem is carrying two thirds of its own weight. I'd want the next
rung up to take the classification back.

### Three things I noticed on the learner set and want on the record

`Places` is defined twice in the shipped spec, at line 10 and line 38, and
nothing in `Init`, `Next` or `Spec` uses it. It's there for the learner's
properties and for nothing else. That's the elimination probe firing. It's
mild, since a learner could enumerate the four values by hand anyway, but
an operator that exists only because an answer needs it is a signpost.

The state count at lines 169 to 171 says the run should find 64 distinct
states. Three lots with four places each is 64, which says `dutyPaid` is
determined by `place`. That's requirement 1, confirmed by arithmetic before
the learner writes it. The count is there so a learner can detect a
modified module, so I don't think it should go, but it does hand over a
check on one third of the answer.

The traces don't witness everything the requirements say. I worked through
all four pairs by hand and the gaps are in Part B, question 5, because
that's where the grading split belongs.

## Part B: the answers side

Everything below was written after I read `V2-PLAN.md` §9.7, the house form
at `authoring/qsl/reports/step5-leakage.md`, `DESCRIPTION.md`, the frozen
reference and its cfg, `reports/step2-variants.md`,
`author-notes/step4-trace-map.md`, `reports/step4-screens.md` and
`VECTOR.md`.

§9.7's own question is whether the statement gives away the state
representation. Shape B answers it before anybody writes a word. The learner
gets the spec, so the representation is given on purpose, and the frame
comes out empty here the same way qsl's did. I ran the three questions qsl
ran, plus the plan's own two.

**Verdict: SHIP after D1.** One requirement's second direction has no
forbidden run, and the fix is one added pair from a variant that's already
committed. Everything else I found is a note.

### 1. The strip

The reference and the statement differ in three hunks and nothing else
[`diff -u`, rc=1]. Two hunks delete the same four operators, once from the
PlusCal define block and once from the translation: `TypeOK`,
`DutyMatchesPlace`, `MovementIsLawful` and `LeavingIsFinal`. Those are
exactly the four the cfg declares at `reference/BondedStore.cfg:5-10`. The
third hunk is the `BEGIN TRANSLATION` checksum line, which moved from
`24038cab`/`7a766261` to `79ef0601`/`af4292c9`.

The checksum change is the right kind of change. It says the translation was
regenerated from the edited PlusCal rather than hand-cut, which is the one
way this strip could have gone wrong without the diff showing it. The frozen
reference is the one the hashes name [`sha256sum -c FREEZE.sha256`, both OK].

The stripped module stands on its own. With the config `PROBLEM.md:161-167`
tells the learner to write, it reports "Model checking completed. No error
has been found", 145 states generated, 64 distinct, depth 7
[`tlc -workers 1`]. That's the number `PROBLEM.md:169` publishes, and the
reference with its own cfg gives the same 145 and 64 [`tlc -workers 1`]. So
the tamper check holds and the four obligations cost nothing in state space.

**One thing the strip left behind.** `Places` has no consumer in the learner
spec. Its only two uses in the reference are inside `TypeOK`
(`reference/BondedStore.tla:15` and `:66`), and the strip removed `TypeOK`,
so line 38 of the learner spec now defines a set nothing reads. qsl ran this
same check and came back clean, which is why I'm naming it here rather than
letting it pass.

I don't think it costs much. What it points at is `TypeOK`, and `TypeOK`
isn't one of the three requirements. A learner who reads the orphan as an
invitation writes a type invariant nobody asked for, which lands as
sound-and-extra rather than as an error. So it's a note, not a defect. I'd
still rather central knew, because the fingerprint is real and the same
check will come round on every shape B problem in the batch.

### 2. Handed-over renderings

`PROBLEM.md` carries no TLA+ formula operator anywhere. A grep for `\A`,
`\E`, `=>`, `<=>`, `EXCEPT`, `UNCHANGED` and `\in` over it returns nothing
[rc=1]. What it does give is the temporal skeleton `[][A]_Observe` at lines
122 and 135, the two keywords, the two kind labels, and the subscript
target. That's form 0's definition rather than a leak, and the formula body
is left alone in all three cases.

**Now the rendering defence, which is what my brief asked me to weigh.**
`step4-screens.md:147-175` says the shipped spec gives the learner very
little to work out, names three things that survive, and lands on the second
of them. I agree with the landing and I'd move the weight further onto it.

The second point holds and it's the real one. Nothing survives the strip
that models a property, so neither action property has a shape in the text
to copy. Turning "when a lot in the store moves" into a guarded comparison
across a primed `Observe` is work the artifact doesn't show, and I confirmed
it's work the prose doesn't show either.

The first point holds too. Duty is state the release action sets rather than
a reading of place (`reference/BondedStore.tla:100-101`), so requirement 1 is
a claim the module could break. Step 2 finding 12 measured the alternative:
under a derived duty the obligation becomes a tautology over its own
definition, at the reference's own 145 and 64 to the state.

The third point is worth close to nothing, and I'd rather say so plainly
than leave it in the ledger. The traces print `not entered`, `in store`,
`released` and `moved on`. Camel-case each of those and you have the
module's four strings exactly. So the withholding is a space and a capital
letter, and a learner who never opens the module reconstructs all four. The
author already wrote "It's a small thing and I won't claim it's more", so
I'm sharpening a concession rather than contradicting a defence.

**One correction to the route analysis.** `step4-screens.md:126-127` says
there's no route that skips the module, "because the field names and the
four strings live nowhere else". The field names live in the statement, in
bold, at `PROBLEM.md:88-89`. The four strings are recoverable from the
traces by the transformation above. So the stated reason for ROUTE ACCEPT
doesn't hold, and the verdict survives on the second point instead. That's
the same correction qsl's checker made to its own author, and I think it
means the pattern is the shape's rather than either author's.

The `DESCRIPTION.md:212-216` narrowing is worth one line here, since it's
where this thread starts. It says the spec's variables must not carry the
`Observe` field names, and the reference declares `variables place,
dutyPaid` with `Observe` as the identity over them. Step 2 finding 10
already recorded the contradiction and left the call with central. I'd only
add that the statement then names both fields itself, so closing it in the
reference alone wouldn't close it.

### 3. The pairs

I hand-checked all eight runs against `Init` and `Next`, and each forbidden
run against all three obligations.

| pair | forbidden run breaks | and nothing else |
|---|---|---|
| 1 | requirement 1, released and unpaid at state 3 | 2 holds, `inStore` to `released` is lawful. 3 holds, no out lot moves |
| 2 | requirement 2, the way in | 1 holds, released and paid. 3 holds, no out lot moves |
| 3 | requirement 2, the two ways out | 1 holds, nothing is paid. 3 holds, no out lot |
| 4 | requirement 3 | 1 holds, moved on and unpaid. 2 holds, both arms guard on a lot at or before the store |

So each violating half breaks its own obligation and nothing simpler, which
is what the trace map claims at `author-notes/step4-trace-map.md:14-19`. All
four allowed runs are legal step sequences from `Init`. The author
machine-validated those against the stripped spec at rc=12 four of four with
an rc=0 control (`step4-trace-map.md:62-76`). [INFERRED for my own pass. I
walked the eight runs by hand and didn't rerun the trace-forcing validator.]

No pair file names a rule, a kind, an obligation or a formula. The four
files carry a heading, one shared sentence and state dumps.

### 4. The delivery boundary

Six files reach a blind panel seat, all under `statement/`:

```
statement/PROBLEM.md
statement/BondedStore.tla
statement/traces/pair-1.md ... pair-4.md
```

`statement/` holds those six and nothing else [`find`, 6 lines]. Grepping
the set for `authoring/`, `reference/`, `author-notes`, `reports/`, `FREEZE`,
`V2-PLAN`, `tla-` and a section mark returns nothing [rc=1]. A second sweep
for `harness`, `grader`, `grading`, `rubric`, `obligation`, `step N`,
`verdict`, `Gate.tla`, `screen`, `frozen`, `bead`, `shape B`, `form 0` and
`batch` returns one hit, `PROBLEM.md:94`, "Grading reads `Observe` and
nothing else". That's the learner's own grading contract and it belongs
there.

Ten author-only files sit outside the subtree, and `DESCRIPTION.md` §2 is
the graded answer in English with its kinds labeled. The structural boundary
holds, so this isn't a defect. It is the reason for the next paragraph.

**Name all six files in the step 6 brief. No directory, no glob.**
`PROBLEM.md:17` points the learner at `traces/` as a location, which is
right for somebody holding a delivered directory and wrong for a panel
brief. qsl's report raised the same hazard and I'd raise it again, because a
brief saying "read `traces/`" in a tree that also holds `author-notes/` is
one typo from the pilot's failure.

### 5. The grading split

§9.7 wants this before any blind agent runs. Per requirement, what counts as
carrying it, and what passes the shipped spec without carrying it.

**Requirement 1.** Carrying it is the biconditional in both directions over
every lot. The weaker form that survives is `place[l] = "released" =>
dutyPaid[l]`. It's sound on the reference, and it rejects pair 1's forbidden
run, so a learner who writes it passes every check the statement asks them to
run. Step 2 measured this from the other side. P05 is that exact weakening,
and the only variant that catches what it drops is S01
(`reports/step2-variants.md:381-392`, results row `P05s01` at rc=0, `:304`).
S01 has no pair. This is D1 below.

**Requirement 2.** Carrying it is both arms, each guarded on the lot's own
place changing, subscripted over the whole of `Observe`. Pairs 2 and 3 cover
one arm each, so a one-armed answer is caught. The unguarded form is caught
too, and by the spec rather than by a pair: drop the `place'[l] # place[l]`
guard and any step where another lot moves refutes it, so TLC fails it on
the reference at once. I think that's the healthiest of the three, because
the learner's own run tells them.

**Requirement 3.** Carrying it is both clauses, place and duty, for out
lots. The weaker form that survives is the place clause alone. It's sound,
and pair 4's forbidden run changes place, so it's rejected. Step 2 finding 3
proves this isn't fixable by a pair. Any step that changes an out lot's duty
leaves that lot released and unpaid or moved on and paid, and requirement 1
refuses both, so the clause can't be exercised alone by any trace on this
system. The reference kept it so the step obligation reads completely, and
the step 2 author's advice was not to expect the harness to defend it.

**The subscript, across both action properties.** `[][A]_(Observe.place)`
passes the reference and rejects all four forbidden runs, because every
forbidden step changes `place`. It isn't exposable by a pair either, for the
reason in the paragraph above. `[][A]_(Observe.dutyPaid)` is different and is
caught: pair 3's forbidden run moves only `place`, so a duty-subscripted
requirement 2 goes blind on it. That's step 2 finding 4 reproducing in the
learner's own oracle.

So the split for step 6's spread rule reads like this. Pair verdicts settle
requirement 2 in full, requirement 3's place clause, requirement 1's
released-implies-paid direction, and the `dutyPaid` subscript error.
Everything else has to be read off the formula: requirement 1's second
direction until D1 lands, requirement 3's duty clause, and the `place`
subscript. Two learners can reject all four forbidden runs with property sets
of visibly different strength, and that gap is where the spread lives.

**This is also the argument for keeping the subscript warning.**
`PROBLEM.md:124-127` is the largest narrowing in the statement and the
author flagged it as such. I'd keep it, and on a firmer footing than "step 2
measured what ignoring it costs". No trace pair can replace it, because the
steps it hides are all states requirement 1 already rejects. Remove the
warning and the hazard isn't restored, it just stops being gradable.

### 6. VECTOR.md

Six rows, and every citation resolves to a line that says what the record
says it says. I checked each by hand.

Representation 1 cites `PROBLEM.md:15-16`, which is the "what you get" line
naming the shipped model. Property kind 2 cites the cfg's `PROPERTIES` block
at `:8-10` and the two `[][A]_Observe` operators at `reference/BondedStore.tla:73`
and `:82`. Property count 1 cites `cfg:5-10`, four obligation lines. Step
sources 0 cites `PROBLEM.md:36-38`, the one-keeper paragraph, and
`reference/BondedStore.tla:38-55`, the single process body. State space 0
cites `step2-variants.md:207` and `:230`, which carry the 64 distinct count
and the 0.50 s wall, and `PROBLEM.md:169`. Form left open 0 cites the four
places the statement fixes the kind, the shape and the subscript.

`bash harness/test-vector.sh` final line: **`FAILED: 27 passed, 1 failed`**.

The failure isn't this problem, and it isn't laytime's either. It reads
`authoring/laytime/VECTOR.md: missing file`, and my first read of that was
wrong. I wrote it up as a sibling still mid-pipeline. It isn't.
`authoring/laytime/VECTOR.md` is on `main` [`git cat-file -e
main:authoring/laytime/VECTOR.md`, rc=0]. My branch base is 18 commits
behind `main` [`git log --oneline <base>..main`, 18 lines], so the file
landed after I branched and my worktree never had it. I'd expect the suite
green on a current base.

Worth recording as a shape rather than as a one-off. A stale base makes a
suite report a missing file the same way it makes `git diff --stat main HEAD`
report deletions you never made, and both read as your own bug. The
bonded-store row passes either way: `PASS authoring/bonded-store/VECTOR.md
records the package frozen at
authoring/bonded-store/reference/FREEZE.sha256`.

### 7. The defect

**D1. Requirement 1's second direction has no forbidden run.** The
requirement states it outright at `PROBLEM.md:105-106`: a lot not yet
entered, in the store, or moved on all have their duty unpaid. No state in
any of the four forbidden runs has duty paid with place anything other than
released, so nothing in the learner's oracle tests that half.

The consequence is a learner who writes `released => paid` and stops. Their
property is sound on the shipped spec, TLC passes it, and their hand-check
against the four pairs passes too. They've written half of requirement 1 and
every signal they have says they're done.

I don't think this one is the shape's residue. It's the same argument the
trace map already made about requirement 2, at
`step4-trace-map.md:25-36`: one operator carrying two arms needs a pair per
arm, or a learner passes a tidy set with half a property. Requirement 1 is a
biconditional carrying two directions and got one pair.

**Fix: one more pair, and the material is committed.** Either variant works.

- S01 pays the duty on a lot still in the store, 3 states
  (`reports/step2-variants/S01.tla`, results row at `step2-variants.md:255`).
- S03 moves a lot on under bond and pays its duty in the same step, 3 states
  (`step2-variants.md:257`).

I'd take S03. Its every step changes `place`, so it reads as a keeper's
mistake in an ordinary run, which is the reason step 2 gave for preferring
S02 over S17 and S11 over S14. S01's step changes only `dutyPaid`, which is
a stranger thing to show a learner at rung 1. Either one breaks requirement
1 and nothing else, so the pair stays clean.

**Arrow: step 4, the pairs.** Nothing frozen moves, the reference doesn't
change, and the load vector doesn't move, since property count reads cfg
lines rather than pairs. The cost is one sentence in `PROBLEM.md`'s trace
section, because five pairs for three requirements needs the same kind of
line that line 148 already gives for requirement 2.

### 8. Notes for central

**N1. `Places` is orphaned by the strip.** §1 above. Low, and it points at
`TypeOK`, which no learner is asked for.

**N2. Two author-only reports cite the same wrong line pair.**
`step4-screens.md:167` and `step4-trace-map.md:57` both cite
`PROBLEM.md:100-101` for the claim that the statement tells the learner to
read the module for the four names. That claim lives at `PROBLEM.md:91-92`.
Lines 100-101 are "Three of them. Each one says which keyword to declare it
under and what kind of formula it is." `PROBLEM.md` has one commit
[`git log`, c354f59], so the citation was never right rather than having
gone stale. Neither report's conclusion turns on it.

**N3. Name all six files in the step 6 brief.** §4 above.

**N4. `test-vector.sh` is red on `authoring/laytime`, from a stale base.**
§6 above. Not this bead's and not laytime's. Worth someone knowing before
they read a red suite as ours.
