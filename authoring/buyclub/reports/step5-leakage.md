# BuyClub, step 5: leakage check and delivery-boundary audit

Adversarial pass over problem P3 per V2-PLAN §9.7, §6 step 5. Bead `tla-7fbx`.
Author-only. Nothing in this file goes to a blind panelist or into
`~/tla-practice/`.

I read everything under `authoring/buyclub/`. The learner-facing candidate set
is `statement/PROBLEM.md` plus the nine files under `statement/traces/`, ten
files in total. Everything else is author-only and my job is to say whether the
ten are clean of it.

**Verdict: SHIP.** One minor defect, arrow to step 4, and it isn't leakage. The
findings that matter are in section 3 and section 6.

## 1. What the greps say

Four mechanical sweeps over the ten files. All four are clean, and the commands
are worth recording because they're cheap to re-run after any reword.

**Reference identifiers.** Every top-level name in `reference/BuyClub.tla`, run
as a word-boundary grep over `statement/`:

```
$ grep -rnwE 'DeliveryComes|ForwardPhases|OneHandAtATime|OneHandOnTheBook|Opening|
PhasesRunForward|PledgeAmounts|SharesMoveTwoWays|SharesTellTheBook|Snapshot|
SnapshotAtPlacement|Spec|Threshold|ThresholdAtPlacement|TwoWaysOnly|TypeOK|Init|
Next|Place|Pledge|Collect|Deliver|Total|Phases|vars' authoring/buyclub/statement
PROBLEM.md:106:6. **Phases run forward.** Every product is always open, placed, or
PROBLEM.md:174:is a run your model allows. Deliver your module and the `.cfg` you
traces/requirement-6.md:3:Phases move only open to placed to arrived, one product
traces/requirement-6.md:45:One delivery step moves both products to arrived at once.
```

Four hits, all four English. "Phases" starts a sentence and "Deliver" is an
imperative verb. No identifier reference in the set.

**Variant ids.** `grep -rnE 'V[0-9]{2}' authoring/buyclub/statement` returns
rc=1. The thirty rows of the step-2 matrix are invisible from the learner set.

**Internals and paths.** A sweep for `reference`, `BuyClub`, `authoring/`,
`author-notes`, `HANDOFF`, `FREEZE`, `sha256`, `variant`, `harness`,
`verdict.sh`, `V2-PLAN`, `pilot`, `bead`, `tla-`, `answer key`, the cfg's model
values `m1`/`m2`/`m3`/`p1`/`p2`, and the TLA+ tokens `EXCEPT`, `UNCHANGED`,
`WF_`, `SF_`, `CHOOSE`, `PROPERTIES`, `CONSTANTS`, `EXTENDS`. Seven hits, every
one domain prose: the supplier's "obligation" in rule 4, the club's "fairness
rule" on `Cap`, `Observe.book`, and the four constant names the statement
declares on purpose.

**Classification vocabulary.** No hit for `liveness`, `safety`, `temporal`,
`action property`, `weak fair`, `strong fair`, or `stutter`. This one is worth
more than it looks. `DESCRIPTION.md:126` tells the reference author which items
are invariants, which are action properties, and which is the one liveness
obligation. That classification is a real modeling judgment and it stayed on the
author side. The statement says "eventually" three times, in the requirement's
own English, and never names the machinery.

The state count stayed back too. `step4-screens.md:50` puts the instance at
roughly 20k distinct states and `DESCRIPTION.md:213` walks the arithmetic.
`PROBLEM.md:154` says only "TLC should finish in seconds". A count would be a
weak oracle, since a learner could tune a model until the number matched, so I'm
glad it isn't there.

## 2. The requirement titles read like the reference's operator names

Seven of the nine requirement headings in `PROBLEM.md` are the reference's
obligation names with spaces put in. "One hand on the book" against
`OneHandOnTheBook`. "Shares tell the book's truth" against `SharesTellTheBook`.
"Delivery comes" against `DeliveryComes`, and four more.

That looks bad until you check which way it flowed:

```
$ git log --oneline --diff-filter=A -- authoring/buyclub/DESCRIPTION.md \
    authoring/buyclub/reference/BuyClub.tla authoring/buyclub/statement/PROBLEM.md
a9fdbd4 buyclub step 4: the statement and both screens
63d46a4 buyclub: the reference spec, written cold
2cbd025 authoring: a bureau, a buying club, and a consignment counter
```

`DESCRIPTION.md` landed first and its section 2 already carried those headings.
The reference author named their operators after the description's English, and
the statement author drew from the same source. So the statement did not take
names from the reference. Both took them from a common ancestor the learner
never sees.

I don't think the shared names leak anything gradable. §3.5 forbids
reference-comparison grading outright, and a name carries no variable, no shape,
and no step boundary. But there's a reading hazard for step 6 that central
should hold onto. If a panelist's submitted spec uses the same operator names as
the reference, that is not evidence their representation converged. It's
evidence they both read the same headings. §6 says to read the spread as an
argument rather than a verdict, and name-matching is exactly the kind of surface
agreement that could be mistaken for the real thing at a panel size of three.

## 3. Representation, §3.2, and what the rules prose actually adds

This is the section I'd argue about, so I'll show the work.

**The interface.** `PROBLEM.md:137-141` fixes three field names and their exact
types. That is the §3.3 trade, paid knowingly, and the author's own screen record
calls it "the biggest giveaway in the problem" (`step4-screens.md:102-104`). I
agree, and I agree it's structural rather than a wording accident. §3.3 exists
because seeded-bug grading needs a fixed interface, and no reword recovers what
it costs.

**The atomicity clauses.** §9.7 tells me to flag any sentence naming an
atomicity boundary present in the reference, and the rules are full of them.
Rule 1's "writes one entry at a time". Rule 3's "Placement is one step, and
three things happen in it". Rule 4's "Delivery is its own step". Rule 5's "one
step, the whole share, once".

I checked each one against the nine requirements, and every atomicity clause in
the rules is restated as a graded requirement. Rule 1 and rule 2 land in
requirement 2's "changes nothing else". Rule 3 lands in requirements 3, 4 and 6.
Rule 4 lands in requirement 6's "a delivery, in particular, moves its phase and
nothing else". Rule 5 lands in requirement 5. So the rules add no step boundary
the requirements don't already fix, and a learner who skipped the rules entirely
would still have to make placement atomic to satisfy requirement 4.

One clause runs the other way and I want it on record. Rule 3's "the order goes
to the supplier for the book's total" names a thing no field carries and no
requirement constrains. `ALTERNATIVES.md:16-23` records that a stored order
total was considered and dropped. So that clause pushes a learner toward a
representation the reference rejected, which is the opposite of leakage. I'd
leave it exactly where it is.

**Where that leaves §3.2.** Zero incremental representation leak from the rules
over the requirements. The handover that exists is the interface, and §3.3
authorizes it.

## 4. The traces

§3.9 mandates one satisfying and one violating run per property, so the pairs
are required rather than optional. The question my brief asks is whether these
pairs go past the mandate and dictate a formula.

I don't think they do, and the reason is structural. A trace pair constrains the
learner's **behavior set**, not their property formulas. It says allow run A and
rule out run B. The learner still writes their own rendering of the English
requirement, and nine allowed runs plus nine forbidden runs come nowhere near
pinning a transition relation.

Each violator exhibits one wrong step shape: a whole row moving in one pledge, a
placement on an empty book, a share moving while the product is open, two
deliveries in one step. Every one of those is the concrete form of its
requirement's English. The step-4 report's own admission that the pairs leave
frame discipline "half-dictated" (`step4-screens.md:78-85`) is honest about the
magnitude and, I think, correct about the direction. It's §3.9 working, not a
wording slip.

The traces also carry something the requirements can't, which is worth naming
because it changes how much they're worth. Requirement 2 says a step changes one
member's pledge, and requirement 9 bounds it to `0..Cap`, but neither says a
member may jump straight from 2 to 0. An increment-only model satisfies all nine
requirements and is a different club (`DESCRIPTION.md:226-229`).
`traces/requirement-3.md:30` and `traces/requirement-9.md:30` both show a
withdrawal from 2 to 0 in one step, so the satisfying runs kill it. That is the
over-constraint direction §3.9 is for, and here it's load-bearing rather than
decorative.

**Rendering.** All nine files show three field rows and nothing else, at every
step. No TLA+ record syntax, no raw TLC dump, no internal names. The cfg's model
values `m1`/`m2`/`m3` and `p1`/`p2` are renamed to Ana/Ben/Cai and oats/oil, so
the reference config's own naming stays back as well.

One stylistic split, low severity, recorded rather than flagged. The satisfying
runs annotate steps by actor ("the coordinator places oats") and the violating
runs annotate by field delta ("oats goes open to placed, and Ana's oats share
goes 0 to 1"). That traces to provenance: the violators are rendered TLC
counterexamples and the satisfiers are hand-built
(`author-notes/step4-trace-provenance.md:9-32`). It tells a sharp reader that a
model checker was involved. It doesn't tell them anything about the answer, and
each file already labels which run is which, so nothing is hidden that the style
could give away.

## 5. Tutor material, may-versus-must, and fairness

My brief asks whether anything pre-answers the two judgments the R route says
remain. The answer splits, and the split is the useful part.

**The fact is handed over, and it has to be.** `PROBLEM.md:56-62` says outright
that reaching the minimum never forces a placement, and that a club where
covering the minimum compels the order is a different club. That is a fact about
the system, and §3.2 obliges the statement to fix the system. A statement that
left it out would be underspecified, which §6's spread rule treats as its own
failure.

**The rendering is not handed over.** Nothing in the ten files says where
fairness goes, or that fairness is the mechanism at all. A learner can read
"never forces" and still reach for `SF_vars` on placement by reflex. The step-2
matrix has variants for exactly that failure.

**Requirement 8 makes fairness on delivery close to unavoidable**, since it's the
only "eventually" in the statement. It leaves the exclusivity judgment untouched,
though, and exclusivity is the harder half. No finite trace can refute fairness
on placement, because fairness constrains infinite behavior and every satisfying
run is a finite prefix. `author-notes/step4-trace-provenance.md:68-70` reaches
the same conclusion from the other end, on variant V25.

So the pre-answering I was asked to look for isn't there. What is there is one
clause carrying a judgment nothing downstream can check, and section 6 is about
that.

## 6. The independent puzzle screen

§9.7 makes me run `harness/PUZZLE-SCREEN.md` a second time, adversarially. Task
shape A, so Q1 and Q2 get their action-centric form.

**Disclosure first.** The rubric says to record my answers before reading the
author's, and I couldn't. My brief told me to audit everything under
`authoring/buyclub/`, which includes `reports/step4-screens.md`, and I'd read it
before I knew the screen was mine to run. So my Q1 to Q8 are contaminated and
you should discount their agreement with the author's to roughly nothing. I'd
suggest a brief-ordering fix: a step-5 brief should name the screen before it
names the directory sweep. That's a finding about the brief, not about P3.

R is a different matter. R has no answer column, the author's route is a claim I
can walk and refute rather than a menu to pick from, and I found a shorter one.

**KIND: ACCEPT, system.** Six system rows, two split (Q1 and Q2), zero puzzle
rows. The threshold of three is nowhere near. My qualification on the two split
rows is a little sharper than the author's: Q1's system column here is claimed by
rendering discipline, not by action discovery, because the domain names four
events and the requirements fix each one's step boundary.

**ROUTE: ACCEPT, qualified, and my route is shorter than the author's.**

The author's shortest route reads the six rules and the nine requirements
(`step4-screens.md:71-76`). Mine skips the rules.

> Take the three `Observe` fields as variables. Write `Init` from requirement 1
> verbatim. Derive `Pledge` from requirement 2 plus requirement 9's bound,
> `Place` from requirements 3 and 4, `Deliver` from requirement 6's
> delivery-moves-nothing-else clause, `Collect` from requirement 5. Every frame
> conjunct is dictated by a "changes nothing else" or a "holds still" already in
> the requirement text. Put weak fairness on delivery, because requirement 8 is
> the only "eventually". Check the satisfying runs to catch an increment-only
> pledge. Done, without reading rules 1 through 6.

That route reaches the reference's transition relation, near enough line for
line, from the requirement list and the interface alone. It uses no state-choice
judgment and no decomposition judgment, because both are pre-made.

**What the rules prose still carries, and it's exactly one thing.** Rule 3's
permission. Requirements 1 to 9 don't forbid a model that compels placement at
the minimum, and no trace can, so the only channel for that judgment is the
prose at `PROBLEM.md:56-62`. It's also the one judgment the harness cannot grade,
which `DESCRIPTION.md:179` predicted in advance and the variant pass confirmed.

So the shape of this problem is: the gradable part is largely transcription, and
the part that needs real defending is ungradable. That reads like the pilot's
verdict and it isn't one, and the difference is the proportion. On the pilot the
gradable half was trivial to locate and the judgment half was the whole rest of
the problem, so ROUTE came back REJECT. Here the ungradable clause is one rule
out of six, and the transcription that surrounds it is where 23 of 30 seeded
mutations die (`step4-screens.md:120-122`). A learner still has to get every
frame right, and a wrong model still goes red.

**Where the shortcut lives.** In the requirement list's precision, which §3.9
demands so every requirement can carry a trace pair, and in the interface, which
§3.3 demands so grading has something to read. Both structural. No reword closes
either, and per §6's red-arrow rule that means the arrow points at §3.3 and §3.9
themselves rather than back at step 4. I'm not proposing we relitigate those.
I'm saying the cost showed up here and should be on the record when Stage 5
calibrates.

My honest read is that this ships and that the qualification travels with it. I'd
also suggest central treat the route finding as calibration input for §7.5: if
shape-A problems with a fixed `Observe` reliably land here, the rubric may want a
requirement-centric second form for shape A the way B, C and D got one.

**Column C does not apply.** §9.7's recalibration paragraph and its
grading-split deliverable are both scoped to critique problems. P3 is shape A,
there is no deficient artifact and no seeded gap, so there's no split to propose.
Recording the non-applicability rather than skipping it quietly.

## 7. The delivery boundary

Nothing in the ten files points outside itself. The one path reference is
`PROBLEM.md:158`, "the `traces/` directory holds one file per requirement", and
it points inward.

That sentence carries a condition, though. §6 says a blind agent gets named
files and never a directory or a glob, and here the statement itself names a
directory. So the panelist's `traces/` must hold exactly the nine files and
nothing else. It does today (`ls` confirms nine `requirement-N.md` and no hidden
files), and the trace provenance note lives under `author-notes/` where it
belongs. Anyone assembling a panel directory needs to keep it that way.

No file in the set mentions a reference, a solution, an answer key, or a grader.
`grep -rniE 'solution|answer|key|grader|oracle|reference model'` returns one hit,
`PROBLEM.md:122`, and its "oracle" is the traces themselves.

### Step-6 blind panel set

Exactly ten files, named. No directories, no globs.

1. `authoring/buyclub/statement/PROBLEM.md`
2. `authoring/buyclub/statement/traces/requirement-1.md`
3. `authoring/buyclub/statement/traces/requirement-2.md`
4. `authoring/buyclub/statement/traces/requirement-3.md`
5. `authoring/buyclub/statement/traces/requirement-4.md`
6. `authoring/buyclub/statement/traces/requirement-5.md`
7. `authoring/buyclub/statement/traces/requirement-6.md`
8. `authoring/buyclub/statement/traces/requirement-7.md`
9. `authoring/buyclub/statement/traces/requirement-8.md`
10. `authoring/buyclub/statement/traces/requirement-9.md`

Copy them into a per-panelist directory with `PROBLEM.md` at the root and the
nine traces under `traces/`, so the statement's own directory reference resolves.
Give no panelist a path to `authoring/buyclub/`.

Author-only, and none of it may sit in a tree a panelist reads:
`reference/BuyClub.tla`, `reference/BuyClub.cfg`, `reference/FREEZE.sha256`,
`reports/step2-variants.md`, `reports/step4-screens.md`, this file,
`author-notes/ALTERNATIVES.md`, `author-notes/step4-trace-provenance.md`,
`DESCRIPTION.md`, `HANDOFF.md`.

`step4-screens.md` is the sharpest of those. It carries the shortest-route
analysis and the seeded-mutation counts, so it's closer to an answer key than
anything except the reference itself.

### Delivery to `~/tla-practice/problems/buyclub/`

The same ten files plus one log scaffold, and nothing else.

```
~/tla-practice/problems/buyclub/
  PROBLEM.md
  traces/requirement-1.md .. requirement-9.md
  ATTEMPT-LOG.md
```

The reference and the variant matrix go to the `tla-answers` side per §6b.2,
never here. The grader reads them across the boundary and returns a verdict
object.

### What the attempt-log template must ask

§6b.4 names the fields. One row per attempt, and the template asks for all of
these:

- timestamp
- problem id
- spec submitted, or a path to it
- verdict object
- questions Frank asked
- prompts the tutor gave
- unlock: strategic or specific
- edits before the pass, as a count
- impasse kind: domain or modeling

Two of those need a sentence, because a template that just lists them will get
them wrong.

The verdict object is pass or fail per obligation plus error location, and
nothing else. Never a reference conjunct, never a diff (§6b.2, §3.7). The log
holds whatever the grader returned, so if a diff ever appears in the log the leak
already happened upstream.

The impasse kind is asked, not inferred. §6b.4 is blunt about this, and the
tutor's question is on the record: "is it the rules of the system that are
unclear, or how to model them?" A domain impasse means the statement is broken
and a modeling impasse means the problem is hard, and §7.1's refinement policy
can't run without the distinction.

One buyclub-specific note for whoever builds the log. Given section 6, a domain
impasse on rule 3 would be the highest-signal event this problem can produce. It
would mean the single prose channel for the single ungradable judgment failed to
carry it. I'd want that one flagged rather than counted.

## 8. Defects

**D1, minor, arrow to step 4.** The traces display `book` and `share` grouped by
product, and the statement declares them grouped by member.

`PROBLEM.md:140` says `Observe.book` is a function from members to functions
from products, so `book[m][p]`. Every trace row reads
`book    oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0`, which groups by
product. Each trace file also claims at line 6 to show "the whole of `Observe`
at that moment".

Nothing leaks. The risk is a solver who reads the traces before the interface
section, builds `book[p][m]`, and fails grading on nesting rather than on
modeling. That would be a measurement artifact in the step-6 panel, and I'd
rather not spend a panelist on it.

The fix is one line, either in `PROBLEM.md`'s trace section or in each trace
header, saying the display groups by product for reading and the declared nesting
is member first. Wording, so step 4 owns it. I don't think it blocks ship if
central would rather leave `PROBLEM.md:140` to carry it alone.

## 9. Verdict

**SHIP**, with three things travelling alongside.

The route qualification in section 6 is the one I'd want read before Stage 5
calibrates, since it's structural and no reword touches it. The name-collision
hazard in section 2 is for whoever reads the step-6 spread. D1 is a one-line
reword nobody has to take.

The ten files are clean of reference internals, clean of variant ids, clean of
paths, and clean of the invariant-versus-property classification the author side
holds. I found no factual error in the runs: I checked every placement in all
eighteen traces against `Min = 3` and every pledge against `Cap = 2`, and they
hold.
