# Practice plan

This replaces `V2-PLAN.md` as the live plan. `V2-PLAN.md` stays in the repo as the
record of how we got here. Nothing in it is deleted, and nothing in it is being
rewritten. Where the two disagree, this one is current.

Written 2026-09-05, the day the direction changed. Amended 2026-10-01, because
the source changed again the next day and this file never caught up.

## Two direction changes

This file has two layers and until today it only owned up to one.

The 2026-09-05 layer is everything under "What changed", "What we have instead"
and "The decisions". It says a problem starts from a published, human-authored
TLA+ specification.

The 2026-09-06 layer replaced that source with external prose, meaning documented
failures and prose behavioural specifications. Bead `tla-frpu` carries the
argument and `sources/README.md` carries the survey that settled which prose. The
short version is that the public TLA+ corpus is search puzzles at the easy end
and consensus protocols everywhere else. About a dozen rows in 143 read as
ordinary application engineering. People publish specifications of novel
protocols. Nobody publishes one of a config rollout.

Nothing from 09-05 is deleted, which is the habit this file already applies to
`V2-PLAN.md`. A decision the second change overturned carries an AMENDED note
where it sits. A reader who hits a stale one finds the correction in the same
place. I think that beats a rewrite, which would lose the argument that got us
here.

| 09-05 decision | what happened to it |
|---|---|
| curate from published TLA+ specs | retired, the source is external prose |
| the shipped spec is the example implementation | the spike is |
| only the statement is authored fresh | stands, and its rule is unchanged |
| no grader | stands |
| difficulty is one 1-to-5 scale, assigned after | stands |
| directories are tier-prefixed | reversed on 09-18, they carry the order now |
| the load vector and the ramp rule are retired | reversed on 10-02, both are live again |

That last row is the one that cost something, and it has its own note under "What
is retired".

## What changed

Batch 2 shipped seven problems. I worked the easiest one and found five defects in
an hour. Independent reviews of five more problems found the same shapes in each of
them. Three surveys ran after that, and this section is what they measured. Every
number below is from today.

**The load vector set the shape, not the material.** Six of six problems examined
had their shape set by a load-vector band. Property count is measured in reference
`.cfg` lines, and a line count doesn't change when you join two formulas with `/\`.
So an author who needs a smaller number joins two obligations, and the count comes
out legal. Measured on assay-office: the split version gives identical verdicts on
all 26 rows, and across 9 caught variants the shipped set names 2 causes where the
split names 5. The learner loses three labels and the number on the form stays the
same.

**Cold English-to-TLA+ is 16 correct in 100.** TLA+-Bench, arXiv:2607.23425, Claude
Opus 4.5. About 6 in 100 after screening out specs that never leave their initial
state and specs that check only a type invariant. The benchmark's authors say the
plain rate "overstates genuine capability by roughly 2.5 times".

**A model judging a learner's work over-validates at 69 to 71%.** It marks wrong
solutions valid. arXiv:2605.16207, over 10,836 solution-feedback pairs.

**Our own blind test agrees.** The holdout build's first five seeded mutants went 4
of 5 uncaught. The pilot went 5 of 11.

**`Observe` is unattested.** Building a record from the variables and stating
properties over it appears nowhere in published practice. 176 such records across
666 modules, and 0 of them declared as an `INVARIANT` or a `PROPERTY`.

Put the first three together and the machine-authored, machine-graded pipeline
doesn't hold up. A model authoring cold is right about 6 times in 100, and a model
checking that work calls wrong work right about 7 times in 10. Our own seeded-mutant
numbers land where those two would put them.

## What we have instead

The exercisable corpus is 67 systems. The funnel: 662 modules, 208 specs, 107
distinct systems, 99 describable, 68 fast enough to check, 67 after licence.

| tier | systems |
|---|---|
| 1 | 9 |
| 2 | 11 |
| 3 | 1 |
| 4 | 6 |
| 5 | 40 |

Prose ships with 50 of the 67, and with 34 of the 40 at tier 5. So the corpus is
top-heavy, tier 3 is close to empty, and the systems that come with an explanation
are mostly the hard ones. I come back to that under what's open.

**AMENDED 2026-10-01, and the tier-3 row is wrong.** Measured from
`corpus/manifest.tsv` on `tla-t64z`. Of the 24 systems the manifest puts at level
3, 23 are describable and 21 of those carry a licence. Of the 21, five are
confirmed fast enough to check and eleven were never attempted. So the filtered
count is somewhere between 5 and 16. Even the floor is five times what this table
says.

It doesn't change the direction, and that's the part worth holding onto. The five
that clear every filter are two consensus or replication specs, one atomic
commitment protocol, one logic puzzle and one graph algorithm. Not one of them is
ordinary application engineering. That is what the 09-06 change was about rather
than the count, so raising tier 3 from 1 to 16 would not bring curation back.

The band stays a band, and `corpus/MANIFEST.md` says why under "Checkability".
`checkable` reads `unattempted` for 92 of the 143 rows, and that isn't a gap I can
sweep away. Only 79 of 211 specs ship a `.cfg` for their own module, so for the
rest there was nothing to run. Settling checkability for one of the eleven means
writing a model for it first, which is most of the work of using it. So the band
narrows one row at a time as rows get picked, which is what `tla-mjh5` already
says to do. The funnel's "68 fast enough to check" isn't recomputable here for the
same reason.

## The decisions

These are locked as of today.

**No grader.** The seven delivered problems stand and get no rework. About 3,800
lines of grading, vacuity, refinement and seeded-bug harness stop being maintained.
Nothing is deleted. It sits in the repo and nobody feeds it.

**Curated, not authored.** Each problem starts from a published, human-authored
spec. That spec goes into a subfolder of the problem as one example of an
implementation. It is never an answer key, and the wording is load-bearing. A
learner who models the same system a different way hasn't made a mistake.

**AMENDED 2026-10-01.** The first sentence is superseded. A problem starts from
an external prose document, and the spike that measures it is the example
implementation. Everything after that first sentence still holds. The spike goes
in a subfolder, it is never an answer key, and a learner who models the same
system a different way hasn't made a mistake.

**The statement.** This is the only piece written fresh, and the rule on it is hard.
A statement describes the system and never the spec. No variable is named. No data
structure is implied. No decomposition is suggested. Having the spec open while
writing the statement is the hazard, and I check for that going in, not after.

**The choice note.** Each problem carries a note on what the shipped implementation
chose that the rules don't force. Without it a different and correct model reads as
wrong, and I think that's the failure this shape is most exposed to.

**The techniques.** Each problem lists 3 to 4 techniques that apply, derived by
reading the shipped implementation, so each one is an observation and not a
prediction. Technique level only, never a formula and never a count. The
counterfactual gets stated out loud, e.g. this one used refinement and could be done
without it at a larger state space. A technique is announced on its first appearance
and folded away on later ones.

**Difficulty.** One scale of 1 to 5, assigned after a problem exists, never a
target. No problem gets shaped to hit a level. The list is built by sorting problems
against each other and cutting the sorted list into five, because comparative
judgment beats absolute judgment.

**Directory names.** Directories are tier-prefixed. A number in a name is a
difficulty tier, which is stable, and not a position in an order, which isn't. My
existing seven stay where they are, untouched.

**AMENDED 2026-10-01.** Reversed, by my own request on 09-18 and bead `tla-0lwx`.
The delivered directories carry their ORDER position as `NN_name` now, and the
seven were renamed after all. The order had been living in a separate `ORDER`
file and had already drifted, seven entries against ten directories. A numbered
directory is on the ramp and an unnumbered one is outside it, which is how
`fencing` and `majority-vote` sit there with no number. `scripts/number-problems.sh`
does the rename and `harness/test-number-problems.sh` gates it.

**One step ahead.** Build one problem ahead of me, never thirty. Batch authoring
can't be validated by a reader who can only reach the first few, and that's what
batch 2 demonstrated.

**Validation.** It splits in two, and the split is about what I can actually judge.
I can tell whether the rules are clear, complete and consistent at any tier,
including problems I can't solve, because that part is reading. I can't judge
tiering until I arrive at a problem, and getting a tier wrong is cheap to fix. There
is a third check that needs nobody: read the statement and the spec together, then
list what the spec does that the statement never licensed, and what the statement
claims that the spec doesn't do. That's a consistency check between two artifacts
that already exist.

**The reaction log.** My reactions need somewhere to land. A dated file with a
sentence in it is enough. The old plan's door test kept saying a mis-ordered problem
is one I'd complain about, and it never built anywhere for the complaint to go.

**Chapter 12.** I'm at learntla section 11. Chapter 12 isn't a gate to clear. It's
the territory the work lives in, and it's worth inhabiting rather than passing
through.

## What a problem looks like

Four pieces, from two places.

- The statement, written fresh from the system.
- The choice note, on what the implementation picked freely.
- The techniques, 3 to 4, read off the implementation.
- The spec, in a subfolder, as one example.

Only the statement is authored from nothing. The other three get read off an
artifact that already exists, and that's the whole point. An observation can be
checked against its source. A prediction can't.

## The prose pipeline

Six steps, and this is their home. They were written down once, in
`sources/run-2026-09-06/PLAN.md`, which is a dated record of one overnight run.
A run record is the wrong owner for a standing pipeline.

| step | what | who |
|---|---|---|
| 1 | survey the source families | researcher |
| 2 | candidate table on the shape vocabulary | researcher |
| 3 | spike against TLC, measure rather than predict | spike author |
| 4 | statement from the source alone | statement author, never sees the spike |
| 5 | consistency check over source, spike and statement | checker, may send findings back |
| 6 | deliver, capture, push | central |

Step 4's isolation is the point of the whole shape. The statement author and the
spike author work from the same external document and never see each other's
output. So a disagreement between them is a finding rather than something to
reconcile. Step 5 is the only reader that holds both.

Step 3 is where measurement replaces prediction. How hard a source will be to
model can't be read off the source. Over 143 rows the variable-count medians run
3, 2, 6, 7, 8, levels 1 and 2 are inverted, and level 1 spans 1 to 87 variables.
The variable count is the answer rather than a fact about the problem. Asking a
prose source how many variables it needs is asking it for the representation, and
the representation is what the set exists to train.

The prediction line is easy to cross. Predicting difficulty is fine for choosing
and ordering candidates. It must never reach the statement author, because
scoping a statement is the lever that lets someone hit a number.

The shape vocabulary step 2 scores against lives in `sources/README.md`, along
with a ranking of the shapes my own work actually contains. `workflow`,
`two-store`, `lifecycle`, `expiry` and `rollout` are the ones worth building.
`resource` is unattested twice over, from two directions that didn't talk to each
other, and I suspect it's the shape a generic backend course would lead with.

**Three more steps were designed, and they're blocked.** The design cycle at
`drawer_tla_puzzles_decisions_0721f0abe841f73eb9def38d` adds three steps between
5 and 6: a freeze, a vector record and a gated comment pass. The point was to let
the ramp place what the pipeline builds. The vector record has no premise left,
and the ramp gates the comment pass hands off to are the ones in question. The
freeze survives either way. Epic `tla-kv2d` holds all three and `tla-t8jz` has to
settle first.

## The difficulty scale

One scale, anchored on state representation.

| tier | state representation |
|---|---|
| 1 | scalar or set state, an algorithm with invariants over it |
| 2 | one function as state, few entities |
| 3 | several functions, or a nested one, or rules relating entities |
| 4 | tier 3's state, and progress matters or the abstraction boundary is the question |
| 5 | refinement, or behaviour only visible from parties interacting |

State representation is the anchor because it drives counterexample width, and
counterexample width drives the debugging skill I'm getting the most out of. A wider
counterexample is a harder read, and reading them is where the practice actually
happens.

The learntla mapping falls out of that. Chapter 12, meaning `EXCEPT`, `@` and tuple
subscripts, spans tiers 2 through 4. Chapter 13, meaning `INSTANCE`, opens tier 5.
Only tier 1 sits below chapter 12.

## What is retired

Retired means nobody maintains it. Nothing is deleted, no history is rewritten, and
the seven delivered problems are not reworked.

- The grader and its verdict objects.
- The vacuity probes.
- The seeded-bug matrix.
- The domain and puzzle screens.
- The `Observe` interface.
- The load vector and the ramp rule. **Un-retired 10-02**, see the note below.
- The shape taxonomy, columns A through D.
- The blind panel and its spread rule.
- The batch-authoring stages.

**AMENDED 2026-10-01.** Two of those retirements left running gates behind, and
that cost a design cycle. `scripts/test` still runs `harness/test-vector.sh` at
line 196 and `harness/test-sequence.sh` at line 201 on every full gate. Thirteen
`VECTOR.md` records sit under `authoring/` and `pilot/`.
`harness/sequence.sh:591` still hard-fails `exit 2` on an `ORDER` entry with no
vector record. Nothing has touched any of those four files since 09-05.

Retirement deletes nothing, which this section opens by saying, so a green
unmaintained gate is consistent with the plan. It's still a trap. The gate is
green only because the seven numbered problems carry records from 09-05 and
nothing new has entered `ORDER`. It'll hard-fail on the first prose problem that
does, which is what `fencing` hit.

A design cycle opened on 09-21 read the load vector as the live placement
authority, locked four decisions and filed five beads on it, and only found this
line today. So the question is open and it's mine to settle. Either the load
vector comes back, which reverses the 09-05 psychometric ruling, or its gates
retire along with the rule. `tla-t8jz` carries both sides and a third shape that
works either way.

**AMENDED 2026-10-07.** Settled on 10-02, and both come back. My words were
"Agreed, they matter."

The reason is the audience change of the same day. A stranger who reads the set in
order can't skip a badly placed problem the way I could. So the ordering rule does
more work now than it did when I was the only reader. D4's K=1 rule was already
written over the delivered sequence rather than over one person's history, so it
transfers without a change.

This doesn't reverse the measurement at the top of this file. The load vector set
the shape of six problems out of six, and that finding stands. The vector comes
back as a way to place problems that already exist. It stays dead as a target an
author writes toward. The 09-05 ruling on the 1-to-5 scale draws the same line,
which is why I think both can be true at once.

So the two suites stay in the gate, budgeted at 0.5s and 1.5s against a full run
of about 190s. Both check record shape rather than any level value, so neither
enforces a rubric an author could aim at.

Two corrections to the note above. Those suites sit at `scripts/test:220` and
`:225` now, not 196 and 201. And `tla-ahxl` is still open: the audience change
rescues these two and leaves the grader, the vacuity probes and the seeded-bug
matrix wanting a call of their own. Those three are most of the gate's wall clock.

`Observe` is worth calling out on its own, because it dies twice over. The corpus
count above says it isn't a thing practitioners write. The statement rule says a
statement can't name a data structure, and `Observe` is a data structure, so a
statement can't reach it anyway.

The blind panel goes for a measured reason, not a budget one. Its job was to tell a
hard problem from an ambiguous one by reading the spread in the answers, and the
pilot returned byte-identical answers from three seats. A panel that agrees tells
you nothing about the problem.

## What is still open

Three things need me before authoring starts, and none of them is settled.

1. **The manifest.** Nothing about its contents is decided. What a problem entry
   carries, what's indexed and what's derived are all open.
2. **The first three problems.** Not picked. The corpus has 67 systems and the tier
   distribution above says the easy end is thin.
3. **Where the reaction log lives.** A dated file with a sentence in it, and no
   decision on the path, the format or whether it's one file or one per problem.

**AMENDED 2026-10-01.** Two of the three moved.

The manifest exists. `corpus/manifest.tsv` carries 143 candidate systems over 13
columns, with a `why` column giving the `file:line` each level was decided on, and
`harness/test-corpus-manifest.sh` gates it. What a problem _entry_ carries is
still open, and that's a different question from what the corpus list carries.

The first problems are picked, and two shipped. `fencing` went through the prose
pipeline and is delivered unnumbered. `majority-vote` is the curated one and sits
on `tla-fr50`, waiting on me to work it.

The reaction log is still open and now has a bead, `tla-heql`. Nothing tracked it
until today. That matters more than it looks. The complaint is the only human
signal in the whole design, and there's still nowhere for it to land.

Two more I'd want to settle early, and these are my read, not a locked question.

Tier 3 has one system in it. I suspect the tiers need building against what the
corpus holds, not against a flat 1-to-5 shape, and that a tier-3 problem may have
to be made by cutting a tier-4 system down. That's a different move from curation,
and it deserves saying out loud before it happens by accident.

**AMENDED 2026-10-01.** The premise is measured wrong. Tier 3 holds 5 to 16
systems and not one, per the amendment under "What we have instead". So the hole
isn't where I put it.

The conclusion survives anyway, and I think it survives for a better reason than
the count did. All five tier-3 systems that clear every filter are consensus,
atomic commitment, a puzzle or a graph algorithm. So the tiers still want building
against what the corpus holds, and cutting a tier-4 system down is still a
different move from curation. That was true when I thought the count was one.

Prose ships with 50 of 67 systems, so 17 come with nothing but the spec. A statement
written for one of those 17 has no independent description to check against, and the
consistency check in the validation section has only one artifact to work with. I
think those 17 go last, or get dropped, but I'd rather decide it than discover it.

## Retired plan

`V2-PLAN.md` is the record. Read it for how the taxonomy, the load vector and the
harness were arrived at, and for the measurements that stand on their own. Don't
read it for what to build next.
